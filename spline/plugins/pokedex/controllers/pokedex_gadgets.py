# encoding: utf8
from __future__ import absolute_import, division

from collections import namedtuple
import logging

from wtforms import Form, ValidationError, fields, validators
from wtforms.ext.sqlalchemy.fields import QueryTextField

import pokedex.db
import pokedex.db.tables as tables
import pokedex.formulae
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect_to
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased, contains_eager, eagerload, eagerload_all, join
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render
from spline.lib import helpers as h

from spline.plugins.pokedex import db, helpers as pokedex_helpers
from spline.plugins.pokedex.db import pokedex_session
from spline.plugins.pokedex.forms import PokedexLookupField

log = logging.getLogger(__name__)


### Capture rate ("Pokéball performance") stuff
class CaptureRateForm(Form):
    pokemon = PokedexLookupField(u'Wild Pokémon', valid_type='pokemon')
    level = fields.IntegerField(u'Its level', [validators.NumberRange(min=1, max=100)])
    current_hp = fields.IntegerField(u'% HP left', [validators.NumberRange(min=1, max=100)])
    status_ailment = fields.SelectField('Status ailment',
        choices=[
            ('', u'—'),
            ('PAR', 'PAR'),
            ('SLP', 'SLP'),
            ('PSN', 'PSN'),
            ('BRN', 'BRN'),
            ('FRZ', 'FRZ'),
        ],
        default=u'',
    )

    ### Extras
    your_level = fields.IntegerField(u'Your Pokémon\'s level', [
        validators.Optional(),
        validators.NumberRange(min=1, max=100),
    ])
    terrain = fields.SelectField(u'Terrain',
        choices=[
            ('land',    u'On land'),
            ('fishing', u'Fishing'),
            ('surfing', u'Surfing'),
        ],
        default='land',
    )
    opposite_gender = fields.BooleanField(u'Wild and your Pokémon are opposite genders')
    caught_before = fields.BooleanField(u'Wild Pokémon is in your Pokédex')
    is_dark = fields.BooleanField(u'Nighttime or walking in a cave')

    # ...
    is_pokemon_master = fields.BooleanField(u'Holding Up+B')


def expected_attempts(catch_chance):
    u"""Given the chance to catch a Pokémon, returns approximately the number
    of attempts required to succeed.
    """
    # Hey, this one's easy!
    return 1 / catch_chance

def expected_attempts_oh_no(partitions):
    """Horrible version of the above, used for Quick and Timer Balls.

    Now there are a few finite partitions at the beginning.  `partitions` looks
    like:

        [
            (catch_chance, number_of_turns),
            (catch_chance, number_of_turns),
            ...
        ]

    For example, a Timer Ball might look like [(0.25, 10), (0.5, 10), ...].

    The final `number_of_turns` must be None to indicate that the final
    `catch_chance` lasts indefinitely.
    """

    turn = 0        # current turn
    p_got_here = 1  # probability that we HAVE NOT caught the Pokémon yet
    expected_attempts = 0

    # To keep this "simple", basically just count forwards each turn until the
    # partitions are exhausted
    for catch_chance, number_of_turns in partitions:
        if number_of_turns is None:
            # Almost done!
            break

        for _ in range(number_of_turns):
            # Add the chance that we'll catch it this turn.  That's the chance that
            # we made it to this turn, times the chance that we'll actually catch
            # it, times the number of turns this attempt has taken
            turn += 1
            expected_attempts += p_got_here * catch_chance * turn

            # Probability that we get to the next turn is decreased by the
            # probability that we didn't catch it this turn
            p_got_here *= 1 - catch_chance

    # The rest of infinity is covered by the usual expected-value formula with
    # the final catch chance, but factoring in the probability that the Pokémon
    # is still uncaught, and that we're starting our count late
    expected_attempts += p_got_here * (1 / catch_chance + turn - 1)

    return expected_attempts

CaptureChance = namedtuple('CaptureChance', ['condition', 'is_active', 'chances'])


class PokedexGadgetsController(BaseController):

    def capture_rate(self):
        """Find a page in the Pokédex given a name.

        Also performs fuzzy search.
        """

        c.form = CaptureRateForm(request.params)

        valid_form = False
        if request.params:
            valid_form = c.form.validate()

        if valid_form:
            c.results = {}

            c.pokemon = c.form.pokemon.data
            level = c.form.level.data

            # Overrule a 'yes' for opposite genders if this Pokémon has no
            # gender
            if c.pokemon.gender_rate == -1:
                c.form.opposite_gender.data = False

            # It's wild, so EVs are all zero.  IVs could be anything, so
            # cheerfully assume the midpoint, 16.  This is all super
            # approximate, anyway
            base_hp = [_ for _ in c.pokemon.stats if _.stat.name == 'HP'][0].base_stat  # XXX what.
            approx_max_hp = pokedex.formulae.calculated_hp(base_hp=base_hp, level=level, iv=16, effort=0)
            approx_hp = int(approx_max_hp * c.form.current_hp.data / 100)

            status_bonus = 1
            if c.form.status_ailment.data in ('PAR', 'BRN', 'PSN'):
                status_bonus = 1.5
            elif c.form.status_ailment.data in ('SLP', 'FRZ'):
                status_bonus = 2

            # Little wrapper around capture_chance...
            def capture_chance(ball_bonus, heavy_modifier=0):
                return pokedex.formulae.capture_chance(
                    current_hp=approx_hp, max_hp=approx_max_hp,
                    capture_rate=c.pokemon.capture_rate,
                    heavy_modifier=heavy_modifier,
                    ball_bonus=ball_bonus, status_bonus=status_bonus,
                )

            ### Do some math!
            # c.results is a dict of ball_name => chance_tuples.
            # (It would be great, but way inconvenient, to use item objects.)
            # chance_tuples is a list of (condition, is_active, chances):
            # - condition: a string describing some mutually-exclusive
            #   condition the ball responds to
            # - is_active: a boolean indicating whether this condition is
            #   currently met
            # - chances: an iterable of chances as returned from capture_chance

            # This is a teeny shortcut.
            only = lambda _: [CaptureChance( '', True, _ )]

            # Gen I
            c.results[u'Poké Ball']   = only(capture_chance(1))
            c.results[u'Great Ball']  = only(capture_chance(1.5))
            c.results[u'Ultra Ball']  = only(capture_chance(2))
            c.results[u'Master Ball'] = only((1.0, 0, 0, 0, 0))
            c.results[u'Safari Ball'] = only(capture_chance(1.5))

            # Gen II
            relative_level = None
            if c.form.your_level.data:
                # -1 because equality counts as bucket zero
                relative_level = (c.form.your_level.data - 1) \
                               // c.form.level.data

            # Heavy Ball partitions by 100kg / 200kg / 300kg.  Weights are
            # stored as...  hectograms.  So.
            weight_class = int((c.pokemon.weight - 1) / 1000)

            # Ugh.
            is_moony = c.pokemon.name in (u'Nidoran♀', u'Nidoran♂',
                                        u'Clefairy', u'Jigglypuff', u'Skitty')

            is_skittish = c.pokemon.name in (
                u'Abra', u'Dragonair', u'Dratini', u'Eevee', u'Entei',
                u'Grimer', u'Latias', u'Latios', u'Magnemite', u'Mr. Mime',
                u'Porygon', u'Quagsire', u'Raikou', u'Suicune', u'Tangela',
            )

            c.results[u'Level Ball']  = [
                CaptureChance(u'Your level ≤ target level',
                    relative_level == 0,
                    capture_chance(1)),
                CaptureChance(u'Target level < your level ≤ 2 * target level',
                    relative_level == 1,
                    capture_chance(2)),
                CaptureChance(u'2 * target level < your level ≤ 4 * target level',
                    relative_level in (2, 3),
                    capture_chance(4)),
                CaptureChance(u'4 * target level < your level',
                    relative_level >= 4,
                    capture_chance(8)),
            ]
            c.results[u'Lure Ball']   = [
                CaptureChance(u'Hooked on a rod',
                    c.form.terrain.data == 'fishing',
                    capture_chance(3)),
                CaptureChance(u'Otherwise',
                    c.form.terrain.data != 'fishing',
                    capture_chance(1)),
            ]
            c.results[u'Moon Ball']   = [
                CaptureChance(u'Target evolves with a Moon Stone',
                    is_moony,
                    capture_chance(4)),
                CaptureChance(u'Otherwise',
                    not is_moony,
                    capture_chance(1)),
            ]
            c.results[u'Friend Ball'] = only(capture_chance(1))
            c.results[u'Love Ball']   = [
                CaptureChance(u'Target is opposite gender of your Pokémon',
                    c.form.opposite_gender.data,
                    capture_chance(8)),
                CaptureChance(u'Otherwise',
                    not c.form.opposite_gender.data,
                    capture_chance(1)),
            ]
            c.results[u'Heavy Ball']   = [
                CaptureChance(u'Target weight ≤ 100 kg',
                    weight_class == 0,
                    capture_chance(1, heavy_modifier=-30)),
                CaptureChance(u'100 < target weight ≤ 200 kg',
                    weight_class == 1,
                    capture_chance(1, heavy_modifier=0)),
                CaptureChance(u'200 < target weight ≤ 300 kg',
                    weight_class == 2,
                    capture_chance(1, heavy_modifier=20)),
                CaptureChance(u'300 < target weight',
                    weight_class >= 3,
                    capture_chance(1, heavy_modifier=30)),
            ]
            c.results[u'Fast Ball']   = [
                CaptureChance(u'Target can run from wild battles',
                    is_skittish,
                    capture_chance(4)),
                CaptureChance(u'Otherwise',
                    not is_skittish,
                    capture_chance(1)),
            ]
            c.results[u'Sport Ball']  = only(capture_chance(1.5))

            # Gen III
            is_nettable = any(_.name in ('bug', 'water')
                              for _ in c.pokemon.types)

            c.results[u'Premier Ball'] = only(capture_chance(1))
            c.results[u'Repeat Ball'] = [
                CaptureChance(u'Target is already in Pokédex',
                    c.form.caught_before.data,
                    capture_chance(3)),
                CaptureChance(u'Otherwise',
                    not c.form.caught_before.data,
                    capture_chance(1)),
            ]
            c.results[u'Timer Ball']  = [
                CaptureChance(u'Turns passed ≤ 10',
                    True,
                    capture_chance(1)),
                CaptureChance(u'10 < turns passed ≤ 20',
                    True,
                    capture_chance(2)),
                CaptureChance(u'20 < turns passed ≤ 30',
                    True,
                    capture_chance(3)),
                CaptureChance(u'30 < turns passed',
                    True,
                    capture_chance(4)),
            ]
            c.results[u'Nest Ball']   = [
                CaptureChance(u'Target level ≤ 19',
                    c.form.level.data <= 19,
                    capture_chance(3)),
                CaptureChance(u'20 ≤ target level ≤ 29',
                    (20 <= c.form.level.data and c.form.level.data <= 29),
                    capture_chance(2)),
                CaptureChance(u'30 ≤ target level',
                    30 <= c.form.level.data,
                    capture_chance(1)),
            ]
            c.results[u'Net Ball']   = [
                CaptureChance(u'Target is Water or Bug',
                    is_nettable,
                    capture_chance(3)),
                CaptureChance(u'Otherwise',
                    not is_nettable,
                    capture_chance(1)),
            ]
            c.results[u'Dive Ball']   = [
                CaptureChance(u'Currently fishing or surfing',
                    c.form.terrain.data in ('fishing', 'surfing'),
                    capture_chance(3.5)),
                CaptureChance(u'Otherwise',
                    c.form.terrain.data == 'land',
                    capture_chance(1)),
            ]
            c.results[u'Luxury Ball']  = only(capture_chance(1))

            # Gen IV
            c.results[u'Heal Ball']    = only(capture_chance(1))
            c.results[u'Quick Ball']  = [
                CaptureChance(u'Turns passed ≤ 5',
                    True,
                    capture_chance(4)),
                CaptureChance(u'5 < turns passed ≤ 10',
                    True,
                    capture_chance(3)),
                CaptureChance(u'10 < turns passed ≤ 15',
                    True,
                    capture_chance(2)),
                CaptureChance(u'15 < turns passed',
                    True,
                    capture_chance(1)),
            ]
            c.results[u'Dusk Ball']    = [
                CaptureChance(u'During the night and while walking in caves',
                    c.form.is_dark.data,
                    capture_chance(4)),
                CaptureChance(u'Otherwise',
                    not c.form.is_dark.data,
                    capture_chance(1)),
            ]
            c.results[u'Cherish Ball'] = only(capture_chance(1))
            c.results[u'Park Ball']    = only(capture_chance(255))


            # Template needs to know how to find expected number of attempts
            c.expected_attempts = expected_attempts
            c.expected_attempts_oh_no = expected_attempts_oh_no

        else:
            c.results = None

        return render('/pokedex/gadgets/capture_rate.mako')
