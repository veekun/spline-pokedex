# encoding: utf8
from __future__ import absolute_import, division

from collections import namedtuple
import logging

import wtforms.validators
from wtforms import Form, ValidationError, fields

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
from spline.lib import helpers as h
from spline.lib.base import BaseController, render
from spline.lib.forms import DuplicateField, QueryTextField

from splinext.pokedex import db, helpers as pokedex_helpers
from splinext.pokedex.db import pokedex_lookup, pokedex_session
from splinext.pokedex.forms import PokedexLookupField

log = logging.getLogger(__name__)


### Capture rate ("Pokéball performance") stuff
class OptionalLevelField(fields.IntegerField):
    """IntegerField subclass that requires either a number from 1 to 100, or
    nothing.

    Also overrides the usual IntegerField logic to default to an empty field.
    Defaulting to 0 means the field can't be submitted from scratch.
    """
    def __init__(self, label=u'', validators=[], **kwargs):
        validators.extend([
            wtforms.validators.NumberRange(min=1, max=100),
            wtforms.validators.Optional(),
        ])
        super(OptionalLevelField, self).__init__(label, validators, **kwargs)

    def _value(self):
        if self.raw_data:
            return self.raw_data[0]
        else:
            return unicode(self.data or u'')

class CaptureRateForm(Form):
    pokemon = PokedexLookupField(u'Wild Pokémon', valid_type='pokemon')
    current_hp = fields.IntegerField(u'% HP left', [wtforms.validators.NumberRange(min=1, max=100)],
                                     default=100)
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
    level = OptionalLevelField(u'Wild Pokémon\'s level', default=u'')
    your_level = OptionalLevelField(u'Your Pokémon\'s level', default=u'')
    terrain = fields.SelectField(u'Terrain',
        choices=[
            ('land',    u'On land'),
            ('fishing', u'Fishing'),
            ('surfing', u'Surfing'),
        ],
        default='land',
    )
    twitterpating = fields.BooleanField(u'Wild and your Pokémon are opposite genders AND the same species')
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
            # The rest of infinity is covered by the usual expected-value formula with
            # the final catch chance, but factoring in the probability that the Pokémon
            # is still uncaught, and that turns have already passed
            expected_attempts += p_got_here * (1 / catch_chance + turn)

            # Done!
            break

        for _ in range(number_of_turns):
            # Add the contribution of possibly catching it this turn.  That's
            # the chance that we'll catch it this turn, times the turn number
            # -- times the chance that we made it this long without catching
            turn += 1
            expected_attempts += p_got_here * catch_chance * turn

            # Probability that we get to the next turn is decreased by the
            # probability that we didn't catch it this turn
            p_got_here *= 1 - catch_chance

    return expected_attempts

CaptureChance = namedtuple('CaptureChance', ['condition', 'is_active', 'chances'])


class PokedexGadgetsController(BaseController):

    def capture_rate(self):
        """Find a page in the Pokédex given a name.

        Also performs fuzzy search.
        """

        c.javascripts.append(('pokedex', 'pokedex-gadgets'))
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
                c.form.twitterpating.data = False

            percent_hp = c.form.current_hp.data / 100

            status_bonus = 10
            if c.form.status_ailment.data in ('PAR', 'BRN', 'PSN'):
                status_bonus = 15
            elif c.form.status_ailment.data in ('SLP', 'FRZ'):
                status_bonus = 20

            # Little wrapper around capture_chance...
            def capture_chance(ball_bonus=10, **kwargs):
                return pokedex.formulae.capture_chance(
                    percent_hp=percent_hp,
                    capture_rate=c.pokemon.capture_rate,
                    status_bonus=status_bonus,
                    ball_bonus=ball_bonus,
                    **kwargs
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

            normal_chance = capture_chance()

            # Gen I
            c.results[u'Poké Ball']   = only(normal_chance)
            c.results[u'Great Ball']  = only(capture_chance(15))
            c.results[u'Ultra Ball']  = only(capture_chance(20))
            c.results[u'Master Ball'] = only((1.0, 0, 0, 0, 0))
            c.results[u'Safari Ball'] = only(capture_chance(15))

            # Gen II
            # NOTE: All the Gen II balls, as of HG/SS, modify CAPTURE RATE and
            # leave the ball bonus alone.
            relative_level = None
            if c.form.level.data and c.form.your_level.data:
                # -1 because equality counts as bucket zero
                relative_level = (c.form.your_level.data - 1) \
                               // c.form.level.data

            # Heavy Ball partitions by 102.4 kg.  Weights are stored as...
            # hectograms.  So.
            weight_class = int((c.pokemon.weight - 1) / 1024)

            # Ugh.
            is_moony = c.pokemon.name in (
                u'Nidoran♀', u'Nidorina', u'Nidoqueen',
                u'Nidoran♂', u'Nidorino', u'Nidoking',
                u'Clefairy', u'Clefable', u'Jigglypuff', u'Wigglytuff',
                u'Skitty', u'Delcatty',
            )

            is_skittish = c.pokemon.stat('Speed').base_stat >= 100

            c.results[u'Level Ball']  = [
                CaptureChance(u'Your level ≤ target level',
                    relative_level == 0,
                    normal_chance),
                CaptureChance(u'Target level < your level ≤ 2 * target level',
                    relative_level == 1,
                    capture_chance(capture_bonus=20)),
                CaptureChance(u'2 * target level < your level ≤ 4 * target level',
                    relative_level in (2, 3),
                    capture_chance(capture_bonus=40)),
                CaptureChance(u'4 * target level < your level',
                    relative_level >= 4,
                    capture_chance(capture_bonus=80)),
            ]
            c.results[u'Lure Ball']   = [
                CaptureChance(u'Hooked on a rod',
                    c.form.terrain.data == 'fishing',
                    capture_chance(capture_bonus=30)),
                CaptureChance(u'Otherwise',
                    c.form.terrain.data != 'fishing',
                    normal_chance),
            ]
            c.results[u'Moon Ball']   = [
                CaptureChance(u'Target evolves with a Moon Stone',
                    is_moony,
                    capture_chance(capture_bonus=40)),
                CaptureChance(u'Otherwise',
                    not is_moony,
                    normal_chance),
            ]
            c.results[u'Friend Ball'] = only(normal_chance)
            c.results[u'Love Ball']   = [
                CaptureChance(u'Target is opposite gender of your Pokémon and the same species',
                    c.form.twitterpating.data,
                    capture_chance(capture_bonus=80)),
                CaptureChance(u'Otherwise',
                    not c.form.twitterpating.data,
                    normal_chance),
            ]
            c.results[u'Heavy Ball']   = [
                CaptureChance(u'Target weight ≤ 102.4 kg',
                    weight_class == 0,
                    capture_chance(capture_modifier=-20)),
                CaptureChance(u'102.4 kg < target weight ≤ 204.8 kg',
                    weight_class == 1,
                    capture_chance(capture_modifier=-20)),  # sic; game bug
                CaptureChance(u'204.8 kg < target weight ≤ 307.2 kg',
                    weight_class == 2,
                    capture_chance(capture_modifier=20)),
                CaptureChance(u'307.2 kg < target weight ≤ 409.6 kg',
                    weight_class == 3,
                    capture_chance(capture_modifier=30)),
                CaptureChance(u'409.6 kg < target weight',
                    weight_class >= 4,
                    capture_chance(capture_modifier=40)),
            ]
            c.results[u'Fast Ball']   = [
                CaptureChance(u'Target has base Speed of 100 or more',
                    is_skittish,
                    capture_chance(capture_bonus=40)),
                CaptureChance(u'Otherwise',
                    not is_skittish,
                    normal_chance),
            ]
            c.results[u'Sport Ball']  = only(capture_chance(15))

            # Gen III
            is_nettable = any(_.name in ('bug', 'water')
                              for _ in c.pokemon.types)

            c.results[u'Premier Ball'] = only(normal_chance)
            c.results[u'Repeat Ball'] = [
                CaptureChance(u'Target is already in Pokédex',
                    c.form.caught_before.data,
                    capture_chance(30)),
                CaptureChance(u'Otherwise',
                    not c.form.caught_before.data,
                    normal_chance),
            ]
            # Timer and Nest Balls use a gradient instead of partitions!  Keep
            # the same desc but just inject the right bonus if there's enough
            # to get the bonus correct.  Otherwise, assume the best case
            c.results[u'Timer Ball']  = [
                CaptureChance(u'Better in later turns, caps at turn 30',
                    True,
                    capture_chance(40)),
            ]
            if c.form.level.data:
                c.results[u'Nest Ball']   = [
                    CaptureChance(u'Better against lower-level targets, worst at level 30+',
                        True,
                        capture_chance(max(10, 40 - c.form.level.data)))
                ]
            else:
                c.results[u'Nest Ball']   = [
                    CaptureChance(u'Better against lower-level targets, worst at level 30+',
                        False,
                        capture_chance(40)),
                ]
            c.results[u'Net Ball']   = [
                CaptureChance(u'Target is Water or Bug',
                    is_nettable,
                    capture_chance(30)),
                CaptureChance(u'Otherwise',
                    not is_nettable,
                    normal_chance),
            ]
            c.results[u'Dive Ball']   = [
                CaptureChance(u'Currently fishing or surfing',
                    c.form.terrain.data in ('fishing', 'surfing'),
                    capture_chance(35)),
                CaptureChance(u'Otherwise',
                    c.form.terrain.data == 'land',
                    normal_chance),
            ]
            c.results[u'Luxury Ball']  = only(normal_chance)

            # Gen IV
            c.results[u'Heal Ball']    = only(normal_chance)
            c.results[u'Quick Ball']  = [
                CaptureChance(u'First turn',
                    True,
                    capture_chance(40)),
                CaptureChance(u'Otherwise',
                    True,
                    normal_chance),
            ]
            c.results[u'Dusk Ball']    = [
                CaptureChance(u'During the night and while walking in caves',
                    c.form.is_dark.data,
                    capture_chance(35)),
                CaptureChance(u'Otherwise',
                    not c.form.is_dark.data,
                    normal_chance),
            ]
            c.results[u'Cherish Ball'] = only(normal_chance)
            c.results[u'Park Ball']    = only(capture_chance(2550))


            # Template needs to know how to find expected number of attempts
            c.capture_chance = capture_chance
            c.expected_attempts = expected_attempts
            c.expected_attempts_oh_no = expected_attempts_oh_no

            # Template also needs real item objects to create links
            pokeball_query = pokedex_session.query(tables.Item) \
                .join(tables.ItemCategory, tables.ItemPocket) \
                .filter(tables.ItemPocket.identifier == 'pokeballs')
            c.pokeballs = dict(
                (item.name, item) for item in pokeball_query
            )

        else:
            c.results = None

        return render('/pokedex/gadgets/capture_rate.mako')

    NUM_COMPARED_POKEMON = 8
    def compare_pokemon(self):
        u"""Pokémon comparison.  Takes up to eight Pokémon and shows a page
        that lists their stats, moves, etc. side-by-side.
        """
        # Note that this gadget doesn't use wtforms at all, since there's only
        # one field and it's handled very specially.

        c.did_anything = False

        FoundPokemon = namedtuple('FoundPokemon',
            ['pokemon', 'suggestions', 'input'])

        # The Pokémon themselves go into c.pokemon.  This list should always
        # have eight elements, each either a tuple as above or None
        c.found_pokemon = [None] * self.NUM_COMPARED_POKEMON

        for i, raw_pokemon in enumerate(request.params.getall('pokemon')):
            if i >= self.NUM_COMPARED_POKEMON:
                # Skip any extras; someone has been screwin around
                break

            raw_pokemon = raw_pokemon.strip()
            if not raw_pokemon:
                continue

            results = pokedex_lookup.lookup(raw_pokemon,
                                            valid_types=['pokemon'])

            # Two separate things to do here.
            # 1: Use the first result as the actual Pokémon
            pokemon = None
            if results:
                pokemon = results[0].object
                c.did_anything = True

            # 2: Use the other results as suggestions.  Doing this informs the
            # template that this was a multi-match
            suggestions = None
            if len(results) == 1 and results[0].exact:
                # Don't do anything for exact single matches
                pass
            else:
                # OK, extract options.  But no more than, say, three.
                # Remember both the language and the Pokémon, in the case of
                # foreign matches
                suggestions = [
                    (_.name, _.iso3166)
                    for _ in results[1:4]
                ]

            # Construct a tuple and slap that bitch in there
            c.found_pokemon[i] = FoundPokemon(pokemon, suggestions, raw_pokemon)

        # There are a lot of links to similar incarnations of this page.
        # Provide a closure for constructing the links easily
        def create_comparison_link(target, replace_with=None, move=0):
            u"""Manipulates the list of Pokémon before creating a link.

            `target` is the FoundPokemon to be operated upon.  It can be either
            replaced with a new string or moved left/right.
            """

            new_found_pokemon = c.found_pokemon[:]

            # Do the swapping first
            if move:
                idx1 = new_found_pokemon.index(target)
                idx2 = (idx1 + move) % len(new_found_pokemon)
                new_found_pokemon[idx1], new_found_pokemon[idx2] = \
                    new_found_pokemon[idx2], new_found_pokemon[idx1]

            # Construct a new query
            query_pokemon = []
            for found_pokemon in new_found_pokemon:
                if found_pokemon is None:
                    # Empty slot
                    query_pokemon.append(u'')
                elif found_pokemon is target and replace_with:
                    # Substitute a new Pokémon
                    query_pokemon.append(replace_with)
                else:
                    # Keep what we have now
                    query_pokemon.append(found_pokemon.input)

            return url.current(pokemon=query_pokemon)
        c.create_comparison_link = create_comparison_link

        # Setup only done if the page is actually showing
        if c.did_anything:
            c.stats = pokedex_session.query(tables.Stat).all()

            raw_heights = dict(enumerate(
                fp.pokemon.height if fp and fp.pokemon else 0
                for fp in c.found_pokemon
            ))
            raw_heights['trainer'] = pokedex_helpers.trainer_height
            c.heights = pokedex_helpers.scale_sizes(raw_heights)

            raw_weights = dict(enumerate(
                fp.pokemon.weight if fp and fp.pokemon else 0
                for fp in c.found_pokemon
            ))
            raw_weights['trainer'] = pokedex_helpers.trainer_weight
            c.weights = pokedex_helpers.scale_sizes(raw_weights, dimensions=2)

        return render('/pokedex/gadgets/compare_pokemon.mako')
