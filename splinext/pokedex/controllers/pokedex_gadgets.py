# encoding: utf8
from __future__ import absolute_import, division

from collections import defaultdict, namedtuple
import colorsys
import functools
import itertools
import math

import wtforms.validators
from wtforms import Form, fields
from wtforms.ext.sqlalchemy.fields import QuerySelectField

import pokedex.db
import pokedex.db.tables as t
import pokedex.formulae
from pylons import request, tmpl_context as c, url
from pylons.controllers.util import redirect
from sqlalchemy.orm import joinedload
from sqlalchemy.orm.exc import NoResultFound

from spline.lib.base import render
import spline.lib.helpers as h

from splinext.pokedex import PokedexBaseController
import splinext.pokedex.db as db
import splinext.pokedex.helpers as pokedex_helpers
from splinext.pokedex.forms import DuplicateField, PokedexLookupField, StatField


### Capture rate ("Pokéball performance") stuff
class OptionalLevelField(fields.IntegerField):
    """IntegerField subclass that requires either a number from 1 to 100, or
    nothing.

    Also overrides the usual IntegerField logic to default to an empty field.
    Defaulting to 0 means the field can't be submitted from scratch.
    """
    def __init__(self, label=None, validators=None, **kwargs):
        if validators is None:
            validators = []
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
    pokemon = PokedexLookupField(u'Wild Pokémon', [wtforms.validators.Required()], valid_type='pokemon')
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


class ChainBreedingForm(Form):
    pokemon = PokedexLookupField(u'Target Pokémon', valid_type='pokemon')
    moves = PokedexLookupField(u'Desired move', valid_type='moves')


class StatCalculatorForm(Form):
    pokemon = PokedexLookupField(u'Pokémon', valid_type='pokemon')
    nature = QuerySelectField('Nature',
        query_factory=lambda: db.pokedex_session.query(t.Nature)
            .join(t.Nature.names_local)
            .order_by(t.Nature.names_table.name.asc()),
        get_pk=lambda _: _.name.lower(),
        get_label=lambda _: _.name,
        allow_blank=True,
    )
    hint = QuerySelectField('Characteristic',
        query_factory=lambda: db.pokedex_session.query(t.Characteristic)
            .join(t.Characteristic.text_table)
            .order_by(t.Characteristic.text_table.message.asc()),
        get_pk=lambda _: _.id,
        get_label=lambda _: _.message,
        allow_blank=True,
    )
    hp_type = QuerySelectField('Hidden Power type',
        query_factory=lambda: db.pokedex_session.query(t.Type)
            .filter(t.Type.id < 10000)
            .join(t.Type.names_local)
            .order_by(t.Type.names_table.name.asc()),
        get_pk=lambda _: _.id,
        get_label=lambda _: _.name,
        allow_blank=True,
    )

    shorten = fields.HiddenField(default=u'')
    def __init__(self, formdata=None, obj=None, prefix='', **kwargs):
        self.needs_shortening = bool(formdata.get('shorten', False))

        super(StatCalculatorForm, self).__init__(formdata, obj, prefix, **kwargs)

        if self.needs_shortening:
            # Strip out form data that doesn't need to exist
            sfd = self.short_formdata = formdata.copy().dict_of_lists()
            del sfd['shorten']

            # Shorten the stat fields down to pipe-delimited
            for stat_field_name in ('stat', 'effort'):
                stat_field = self[stat_field_name]
                if not stat_field.data:
                    continue
                for field in stat_field[0]:
                    sfd.pop(field.name, None)
                sfd[stat_field_name] = [subfield.short_data for subfield in stat_field]

            # We always show one more set of level/stat/effort than was
            # submitted, so the user can add more data.  If they submitted the
            # form without adding more data, skip that last set
            sfd['level'] = list(self.level.data)
            if len(self.level.data) > 1 and not any(
                subfield.data for subfield in self.stat[-1]):

                sfd['level'].pop()
                sfd['stat'].pop()
                sfd['effort'].pop()

            # Outright delete stuff that's left blank
            for field in ('nature', 'hint', 'hp_type'):
                if not self[field].data:
                    sfd.pop(field, None)


def stat_graph_chunk_color(gene):
    """Returns a #rrggbb color, given a gene.  Used for the pretty graph."""
    # Normalizing 0-31 to 0-1 is simple division -- however, pure red shouldn't
    # represent both 0 and 31.  Cut this off at bluish purple instead, which is
    # around 5/6
    hue = gene / 31 * 0.83
    r, g, b = colorsys.hls_to_rgb(hue, 0.67, 0.75)
    return "#%02x%02x%02x" % (r * 256, g * 256, b * 256)


class PokedexGadgetsController(PokedexBaseController):

    def capture_rate(self):
        """Calculate the successful capture rate of every Ball given a target
        Pokémon and a set of battle conditions.
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

            # Overrule a 'yes' for opposite genders if this Pokémon is a
            # genderless or single-gender species
            if c.pokemon.species.gender_rate in (-1, 0, 8):
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
                    capture_rate=c.pokemon.species.capture_rate,
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
            is_moony = c.pokemon.species.identifier in (
                u'nidoran-m', u'nidorina', u'nidoqueen',
                u'nidoran-f', u'nidorino', u'nidoking',
                u'cleffa', u'clefairy', u'clefable',
                u'igglybuff', u'jigglypuff', u'wigglytuff',
                u'skitty', u'delcatty',
            )

            is_skittish = c.pokemon.base_stat('speed', 0) >= 100

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
            is_nettable = any(_.identifier in ('bug', 'water')
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
            pokeball_query = db.pokedex_session.query(t.Item) \
                .join(t.ItemCategory, t.ItemPocket) \
                .filter(t.ItemPocket.identifier == 'pokeballs')
            c.pokeballs = dict(
                (item.name, item) for item in pokeball_query
            )

        else:
            c.results = None

        return render('/pokedex/gadgets/capture_rate.mako')

    def chain_breeding(self):
        u"""Given a Pokémon and an egg move it can learn, figure out the
        fastest way to get it that move.
        """

        # XXX validate that the move matches the pokemon, in the form
        # TODO correctly handle e.g. munchlax-vs-snorlax
        # TODO write tests for this man
        c.form = ChainBreedingForm(request.GET)
        if not request.GET or not c.form.validate():
            c.did_anything = False
            return render('/pokedex/gadgets/chain_breeding.mako')

        # The result will be an entire hierarchy of Pokémon, like this:
        # TARGET
        #  |--- something compatible
        #  | '--- something compatible here too
        #  '--- something else compatible
        # ... with Pokémon as high in the tree as possible.

        # TODO make this a control yo
        version_group = db.pokedex_session.query(t.VersionGroup).get(11)  # b/w

        target = c.form.pokemon.data

        # First, find every potential Pokémon in the tree: that is, every
        # Pokémon that can learn this move at all.
        # It's useful to know which methods go with which Pokémon, so let's
        # store the pokemon_moves rows per Pokémon.
        # XXX this should exclude Ditto and unbreedables
        candidates = {}
        pokemon_moves = db.pokedex_session.query(t.PokemonMove) \
            .filter_by(
                move_id=c.form.moves.data.id,
                version_group_id=version_group.id,
            )
        pokemon_by_egg_group = defaultdict(set)
        for pokemon_move in pokemon_moves:
            candidates \
                .setdefault(pokemon_move.pokemon, []) \
                .append(pokemon_move)
            for egg_group in pokemon_move.pokemon.egg_groups:
                pokemon_by_egg_group[egg_group].add(pokemon_move.pokemon)

        # Breeding only really cares about egg group combinations, not the
        # individual Pokémon; for all intents and purposes, any (5, 9) Pokémon
        # can be replaced by any other.  So build the tree out of those, first.
        egg_group_candidates = set(
            tuple(pokemon.egg_groups) for pokemon in candidates.keys()
        )

        # The above are actually edges in a graph; (5, 9) indicates that
        # there's a viable connection between all Pokémon in egg groups 5 and
        # 9.  The target Pokémon is sort of an anonymous node that has edges to
        # its two breeding groups.  So build a graph!
        egg_graph = dict()
        # Create an isolated node for every group
        all_egg_groups = set(egg_group for pair in egg_group_candidates
                                       for egg_group in pair)
        all_egg_groups.add('me')  # special sentinel value for the target
        for egg_group in all_egg_groups:
            egg_graph[egg_group] = dict(
                node=egg_group,
                adjacent=[],
            )
        # Fill in the adjacent edges
        for egg_group in target.egg_groups:
            egg_graph['me']['adjacent'].append(egg_graph[egg_group])
            egg_graph[egg_group]['adjacent'].append(egg_graph['me'])
        for egg_groups in egg_group_candidates:
            if len(egg_groups) == 1:
                # Pokémon in only one egg group aren't useful here
                continue
            a, b = egg_groups
            egg_graph[a]['adjacent'].append(egg_graph[b])
            egg_graph[b]['adjacent'].append(egg_graph[a])

        # And now trim that down to just a tree, where nodes are placed as
        # close to the root as possible.
        # Start from the root ('me'), expand outwards, and remove edges that
        # lead to nodes on a higher level.  Duplicates within a level are OK.
        egg_tree = egg_graph['me']
        seen = set(['me'])
        current_level = [egg_tree]
        current_seen = True
        while current_seen:
            next_level = []
            current_seen = set()

            for node in current_level:
                node['adjacent'] = [_ for _ in node['adjacent'] if _['node'] not in seen]
                node['adjacent'].sort(key=lambda _: _['node'].id)
                current_seen.update(_['node'] for _ in node['adjacent'])
                next_level.extend(node['adjacent'])

            current_level = next_level
            seen.update(current_seen)

        c.pokemon = c.form.pokemon.data
        c.pokemon_by_egg_group = pokemon_by_egg_group
        c.egg_group_tree = egg_tree
        c.did_anything = True
        return render('/pokedex/gadgets/chain_breeding.mako')

    NUM_COMPARED_POKEMON = 9
    def _shorten_compare_pokemon(self, pokemon):
        u"""Returns a query dict for the given list of Pokémon to compare,
        shortened as much as possible.

        This is a bit naughty and examines the context for part of the query.
        """
        params = dict()

        # Drop blank Pokémon off the end of the list
        while pokemon and not pokemon[-1]:
            del pokemon[-1]
        params['pokemon'] = pokemon

        # Only include version group if it's not the default
        if c.version_group != c.version_groups[-1]:
            params['version_group'] = c.version_group.id

        return params

    def compare_pokemon(self):
        u"""Pokémon comparison.  Takes up to eight Pokémon and shows a page
        that lists their stats, moves, etc. side-by-side.
        """
        # Note that this gadget doesn't use wtforms at all, since there're only
        # two fields and the major one is handled very specially.

        c.did_anything = False

        # Form controls use version group
        # We join with VGPMM to filter out version groups which we lack move
        # data for. *coughxycough*
        c.version_groups = db.pokedex_session.query(t.VersionGroup) \
            .join(t.VersionGroupPokemonMoveMethod) \
            .order_by(t.VersionGroup.order.asc()) \
            .options(joinedload('versions')) \
            .all()
        # Grab the version to use for moves, defaulting to the most current
        try:
            c.version_group = db.pokedex_session.query(t.VersionGroup) \
                .filter_by(id=request.params['version_group']).one()
        except (KeyError, NoResultFound):
            c.version_group = c.version_groups[-1]

        # Some manual URL shortening, if necessary...
        if request.params.get('shorten', False):
            short_params = self._shorten_compare_pokemon(
                request.params.getall('pokemon'))
            redirect(url.current(**short_params))

        FoundPokemon = namedtuple('FoundPokemon',
            ['pokemon', 'form', 'suggestions', 'input'])

        # The Pokémon themselves go into c.pokemon.  This list should always
        # have eight FoundPokemon elements
        c.found_pokemon = [None] * self.NUM_COMPARED_POKEMON

        # Run through the list, ensuring at least 8 Pokémon are entered
        pokemon_input = request.params.getall('pokemon') \
            + [u''] * self.NUM_COMPARED_POKEMON
        for i in range(self.NUM_COMPARED_POKEMON):
            raw_pokemon = pokemon_input[i].strip()
            if not raw_pokemon:
                # Use a junk placeholder tuple
                c.found_pokemon[i] = FoundPokemon(
                    pokemon=None, form=None, suggestions=None, input=u'')
                continue

            results = db.pokedex_lookup.lookup(
                raw_pokemon, valid_types=['pokemon_species', 'pokemon_form'])

            # Two separate things to do here.
            # 1: Use the first result as the actual Pokémon
            pokemon = None
            form = None
            if results:
                result = results[0].object
                c.did_anything = True

                # 1.5: Deal with form matches
                if isinstance(result, t.PokemonForm):
                    pokemon = result.pokemon
                    form = result
                else:
                    pokemon = result.default_pokemon
                    form = pokemon.default_form

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
            c.found_pokemon[i] = FoundPokemon(pokemon, form,
                                              suggestions, raw_pokemon)

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
                elif found_pokemon is target and replace_with != None:
                    # Substitute a new Pokémon
                    query_pokemon.append(replace_with)
                else:
                    # Keep what we have now
                    query_pokemon.append(found_pokemon.input)

            short_params = self._shorten_compare_pokemon(query_pokemon)
            return url.current(**short_params)
        c.create_comparison_link = create_comparison_link

        # Setup only done if the page is actually showing
        if c.did_anything:
            c.stats = db.pokedex_session.query(t.Stat) \
                .filter(~ t.Stat.is_battle_only) \
                .all()

            # Relative numbers -- breeding and stats
            # Construct a nested dictionary of label => pokemon => (value, pct)
            # `pct` is percentage from the minimum to maximum value
            c.relatives = dict()
            # Use the label from the page as the key, because why not
            relative_things = [
                (u'Base EXP',       lambda pokemon: pokemon.base_experience),
                (u'Base happiness', lambda pokemon: pokemon.species.base_happiness),
                (u'Capture rate',   lambda pokemon: pokemon.species.capture_rate),
            ]
            def relative_stat_factory(local_stat):
                return lambda pokemon: pokemon.base_stat(local_stat, 0)
            for stat in c.stats:
                relative_things.append((stat.name, relative_stat_factory(stat)))

            relative_things.append((
                u'Base stat total',
                lambda pokemon: sum(pokemon.base_stat(stat, 0) for stat in c.stats)
            ))

            # Assemble the data
            unique_pokemon = set(fp.pokemon
                for fp in c.found_pokemon
                if fp.pokemon
            )
            for label, getter in relative_things:
                c.relatives[label] = dict()

                # Get all the values at once; need to get min and max to figure
                # out relative position
                numbers = dict()
                for pokemon in unique_pokemon:
                    numbers[pokemon] = getter(pokemon)

                min_number = min(numbers.values())
                max_number = max(numbers.values())

                # Rig a little function to figure out the percentage, making
                # sure to avoid division by zero
                if min_number == max_number:
                    calc = lambda n: 1.0
                else:
                    calc = lambda n: 1.0 * (n - min_number) \
                                         / (max_number - min_number)

                for pokemon in unique_pokemon:
                    c.relatives[label][pokemon] \
                        = numbers[pokemon], calc(numbers[pokemon])

            ### Relative sizes
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

            ### Moves
            # Constructs a table like the pokemon-moves table, except each row
            # is a move and it indicates which Pokémon learn it.  Still broken
            # up by method.
            # So, need a dict of method => move => pokemons.
            c.moves = defaultdict(lambda: defaultdict(set))
            # And similarly for level moves, level => pokemon => moves
            c.level_moves = defaultdict(lambda: defaultdict(list))

            # Get all moves — we only need to order by order since we split
            # everything up by method/level anyway
            q = db.pokedex_session.query(t.PokemonMove) \
                .filter(t.PokemonMove.version_group == c.version_group) \
                .filter(t.PokemonMove.pokemon_id.in_(
                    _.id for _ in unique_pokemon)) \
                .order_by(t.PokemonMove.order) \
                .options(
                    joinedload('move'),
                    joinedload('method'),
                )
            for pokemon_move in q:
                c.moves[pokemon_move.method][pokemon_move.move].add(
                    pokemon_move.pokemon)

                if pokemon_move.level:
                    c.level_moves[pokemon_move.level] \
                        [pokemon_move.pokemon].append(pokemon_move.move)

            # Get TM/HM numbers for display purposes
            c.machines = dict(
                (machine.move, machine.machine_number)
                for machine in c.version_group.machines
            )

        return render('/pokedex/gadgets/compare_pokemon.mako')

    def stat_calculator(self):
        """Calculates, well, stats."""
        # XXX this form handling is all pretty bad.  consider ripping it out
        # and really thinking about how this ought to work.
        # possible TODO:
        # - more better error checking
        # - track effort gained on the fly (as well as exp for auto level up?)
        # - track evolutions?
        # - graphs of potential stats?
        #   - given a pokemon and its genes and effort, graph all stats by level
        #   - given a pokemon and its gene results, graph approximate stats by level...?
        #   - given a pokemon, graph its min and max possible calc'd stats...
        # - this logic is pretty hairy; use a state object?

        # Add the stat-based fields
        stat_query = (db.pokedex_session.query(t.Stat)
                      .filter(t.Stat.is_battle_only == False))

        c.stats = (stat_query
                   .order_by(t.Stat.id)
                   .all())

        hidden_power_stats = (stat_query
                              .order_by(t.Stat.game_index)
                              .all())

        # Make sure there are the same number of level, stat, and effort
        # fields.  Add an extra one, for adding more data
        num_dupes = c.num_data_points = len(request.GET.getall('level'))
        num_dupes += 1
        class F(StatCalculatorForm):
            level = DuplicateField(
                fields.IntegerField(u'Level', default=100,
                    validators=[wtforms.validators.NumberRange(1, 100)]),
                min_entries=num_dupes,
            )
            stat = DuplicateField(
                StatField(c.stats, fields.IntegerField(default=0, validators=[
                    wtforms.validators.NumberRange(min=0, max=999)])),
                min_entries=num_dupes,
            )
            effort = DuplicateField(
                StatField(c.stats, fields.IntegerField(default=0, validators=[
                    wtforms.validators.NumberRange(min=0, max=255)])),
                min_entries=num_dupes,
            )

        ### Parse form and so forth
        c.form = F(request.GET)

        c.results = None  # XXX shim
        if not request.GET or not c.form.validate():
            return render('/pokedex/gadgets/stat_calculator.mako')

        if not c.num_data_points:
            # Zero?  How did you manage that?
            # XXX this doesn't actually appear in the page  :D
            c.form.level.errors.append(u"Please enter at least one level")
            return render('/pokedex/gadgets/stat_calculator.mako')

        # Possible shorten and redirect
        if c.form.needs_shortening:
            # This is stupid, but update_params doesn't understand unicode
            kwargs = c.form.short_formdata
            for key, vals in kwargs.iteritems():
                kwargs[key] = [unicode(val).encode('utf8') for val in vals]

            redirect(h.update_params(url.current(), **kwargs))

        def filter_genes(genes, f):
            """Teeny helper function to only keep possible genes that fit the
            given lambda.
            """
            genes &= set(gene for gene in genes if f(gene))

        # Okay, do some work!
        # Dumb method for now -- XXX change this to do a binary search.
        # Run through every possible value for each stat, see if it matches
        # input, and give the green light if so.
        pokemon = c.pokemon = c.form.pokemon.data
        nature = c.form.nature.data
        if nature and nature.is_neutral:
            # Neutral nature is equivalent to none at all
            nature = None
        # Start with lists of possibly valid genes and cut down from there
        c.valid_range = defaultdict(dict)  # stat => level => (min, max)
        valid_genes = {}
        # Stuff for finding the next useful level
        level_indices = sorted(range(c.num_data_points),
            key=lambda i: c.form.level[i].data)
        max_level_index = level_indices[-1]
        max_given_level = c.form.level[max_level_index].data
        c.next_useful_level = 100

        for stat in c.stats:
            ### Bunch of setup, per stat
            # XXX let me stop typing this, christ
            if stat.identifier == u'hp':
                func = pokedex.formulae.calculated_hp
            else:
                func = pokedex.formulae.calculated_stat

            base_stat = pokemon.base_stat(stat, 0)
            if not base_stat:
                valid_genes[stat] = set(range(32))
                continue

            nature_mod = 1.0
            if not nature:
                pass
            elif nature.increased_stat == stat:
                nature_mod = 1.1
            elif nature.decreased_stat == stat:
                nature_mod = 0.9

            meta_calculate_stat = functools.partial(func,
                base_stat=base_stat, nature=nature_mod)

            # Start out with everything being considered valid
            valid_genes[stat] = set(range(32))

            for i in range(c.num_data_points):
                stat_in = c.form.stat[i][stat].data
                effort_in = c.form.effort[i][stat].data
                level = c.form.level[i].data

                calculate_stat = functools.partial(meta_calculate_stat,
                    effort=effort_in, level=level)

                c.valid_range[stat][level] = min_stat, max_stat = \
                    calculate_stat(iv=0), calculate_stat(iv=31)

                ### Actual work!
                # Quick simple check: if the input is totally outside the valid
                # range, no need to calculate anything
                if not min_stat <= stat_in <= max_stat:
                    valid_genes[stat] = set()
                if not valid_genes[stat]:
                    continue

                # Run through and maybe invalidate each gene
                filter_genes(valid_genes[stat],
                    lambda gene: calculate_stat(iv=gene) == stat_in)

            # Find the next "useful" level.  This is the lowest level at which
            # at least two possible genes give different stats, given how much
            # effort the Pokémon has now.
            # TODO should this show the *highest* level necessary to get exact?
            if valid_genes[stat]:
                min_gene = min(valid_genes[stat])
                max_gene = max(valid_genes[stat])
                max_effort = c.form.effort[max_level_index][stat].data
                while level < c.next_useful_level and \
                    meta_calculate_stat(level=level, effort=max_effort, iv=min_gene) == \
                    meta_calculate_stat(level=level, effort=max_effort, iv=max_gene):

                    level += 1
                c.next_useful_level = level

        c.form.level[-1].data = c.next_useful_level

        # Hidden Power type
        if c.form.hp_type.data:
            # Shift the type id to make Fighting (id=2) #0
            hp_type = c.form.hp_type.data.id - 2

            # See below for how this is calculated.
            # We know x * 15 // 63 == hp_type, and want a range for x.
            # hp_type * 63 / 15 is the LOWER bound, though you need to ceil()
            # it to find the lower integral bound.
            # The same thing for (hp_type + 1) is the lower bound for the next
            # type, which is one more than our upper bound.  Cool.
            min_x = int(math.ceil(hp_type * 63 / 15))
            max_x = int(math.ceil((hp_type + 1) * 63 / 15) - 1)

            # Now we need to find how many bits from the left will stay the
            # same throughout this x-range, so we know that those bits must
            # belong to the corresponding stats.  Easy if you note that, if
            # min_x and max_x have the same leftmost n bits, so will every
            # integer between them.
            first_good_bit = None
            for n in range(6):
                # Convert "3" to 0b111000
                # 3 -> 0b1000 -> 0b111 -> 0b111000
                mask = 63 ^ ((1 << n) - 1)
                if min_x & mask == max_x & mask:
                    first_good_bit = n
                    break
            if first_good_bit is not None:
                # OK, cool!  Now we know some number of stats are either
                # definitely odd or definitely even.
                for stat_id in range(first_good_bit, 6):
                    bit = (min_x >> stat_id) & 1
                    stat = hidden_power_stats[stat_id]
                    filter_genes(valid_genes[stat],
                        lambda gene: gene & 1 == bit)

        # Characteristic; needs to be last since it imposes a maximum
        hint = c.form.hint.data
        if hint:
            # Knock out everything that doesn't match its mod-5
            filter_genes(valid_genes[hint.stat],
                lambda gene: gene % 5 == hint.gene_mod_5)

            # Also, the characteristic is only shown for the highest gene.  So,
            # no other stat can be higher than the new maximum for the hinted
            # stat.  (Need the extra -1 in case there are actually no valid
            # genes left; max() dies with an empty sequence.)
            max_gene = max(itertools.chain(valid_genes[hint.stat], (-1,)))
            for genes in valid_genes.values():
                filter_genes(genes, lambda gene: gene <= max_gene)

            # Similarly, this gene can't possibly be lower than the minimum of
            # any other stat.
            for genes in valid_genes.values():
                min_gene = min(itertools.chain(genes, (999,)))
                filter_genes(
                    valid_genes[hint.stat], lambda gene: gene >= min_gene)

        # Possibly calculate Hidden Power's type and power, if the results are
        # exact
        c.exact = all(len(genes) == 1 for genes in valid_genes.values())
        if c.exact:
            # HP uses bit 0 of each gene for the type, and bit 1 for the power.
            # These bits are used to make new six-bit numbers, where HP goes to
            # bit 0, Attack to bit 1, etc.
            type_det = 0
            power_det = 0
            for i, stat in enumerate(hidden_power_stats):
                stat_value, = valid_genes[stat]
                type_det += (stat_value & 0x01) << i
                power_det += (stat_value & 0x02) >> 1 << i

            # Our types are also in the correct order, except that we start
            # from 1 rather than 0, and HP skips Normal
            c.hidden_power_type = db.pokedex_session.query(t.Type) \
                .get(type_det * 15 // 63 + 2)
            c.hidden_power_power = power_det * 40 // 63 + 30

            # Used for a link
            c.hidden_power = db.pokedex_session.query(t.Move) \
                .filter_by(identifier=u'hidden-power').one()

        # Turn those results into something more readable.
        # Template still needs valid_genes for drawing the graph
        c.results = {}
        c.valid_genes = valid_genes
        for stat in c.stats:
            # 1, 2, 3, 5 => "1-3, 5"
            # Find consecutive ranges of numbers and turn them into strings.
            # nb: The final dummy iteration with n = None is to more easily add
            # the last range to the parts list
            left_endpoint = None
            parts = []
            elements = sorted(valid_genes[stat])

            for last_n, n in zip([None] + elements, elements + [None]):
                if (n is None and left_endpoint is not None) or \
                    (last_n is not None and last_n + 1 < n):

                    # End of a subrange; break off what we have
                    if left_endpoint == last_n:
                        parts.append(u"{0}".format(last_n))
                    else:
                        parts.append(u"{0}–{1}".format(left_endpoint, last_n))

                if left_endpoint is None or last_n + 1 < n:
                    # Starting a new subrange; remember the new left end
                    left_endpoint = n

            c.results[stat] = u', '.join(parts)

        c.stat_graph_chunk_color = stat_graph_chunk_color

        c.prompt_for_more = (
            not c.exact and c.next_useful_level > max_given_level)

        return render('/pokedex/gadgets/stat_calculator.mako')

    def whos_that_pokemon(self):
        u"""A silly game that asks you to identify Pokémon by silhouette, cry,
        et al.
        """
        c.javascripts.append(('pokedex', 'whos-that-pokemon'))

        return render('/pokedex/gadgets/whos_that_pokemon.mako')
