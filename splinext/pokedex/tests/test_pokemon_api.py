# encoding: utf8
from __future__ import absolute_import
from __future__ import unicode_literals

from pokedex.db import connect
from splinext.pokedex import db
from splinext.pokedex.api import APIQuery, pokemon_locus

# XXX yeah yeah
db.pokedex_session = connect(engine_args={
    'url': 'postgresql:///veekun_pokedex',
    'echo': True,
})
import pokedex.lookup
db.pokedex_lookup = pokedex.lookup.PokedexLookup(
    directory='/home/eevee/dev/veekun.virtualenv/veekun.git/data/pokedex-index',
    session=db.pokedex_session,
)

class FakeMultiDict(object):
    def __init__(self, d):
        self.data = d

    def __iter__(self):
        return iter(self.data)

    def __contains__(self, key):
        return key in self.data

    def __getitem__(self, key):
        return self.getall(key)[0]

    def getall(self, key):
        value = self.data.get(key, [])
        if isinstance(value, list):
            return value
        else:
            return [value]

class APIMixin(object):
    """Helpers for the following test classes.

    `data` should always be a dict of strings and/or lists; it'll be wrapped in
    a fake multi-dict wrapper thing.
    """
    def _query_api(self, data):
        db.pokedex_session.rollback()
        apiq = APIQuery(pokemon_locus, db.pokedex_session)
        formdata = FakeMultiDict(data)

        results = apiq.process_query(formdata)
        assert len(results) < 500, "too many results; criteria possibly ignored?"

        return results

    def _assert_retrieves(self, data, wanted, exact=False):
        results = self._query_api(data)
        got = set(result['identifier'] for result in results)
        wanted = set(wanted)
        if exact:
            assert wanted == got
        else:
            assert wanted <= got


class TestSimplePokemonSearch(APIMixin):
    # Test that searching for each property naively works; most of these should
    # return Eevee
    def test_search_by_id(self):
        self._assert_retrieves(
            {'id': '133'},
            ('eevee',), exact=True)

    def test_search_by_growth_rate(self):
        self._assert_retrieves(
            {'growth-rate': 'medium'},
            ('eevee',))

    def test_search_by_generation(self):
        self._assert_retrieves(
            {'generation': '1'},
            ('eevee', 'bulbasaur', 'charmander', 'mewtwo'))

    def test_search_by_type(self):
        self._assert_retrieves(
            {'type': 'normal'},
            ('eevee',))

    def test_search_by_egg_group(self):
        self._assert_retrieves(
            {'egg-group': 'ground'},
            ('eevee',))

    def test_search_by_genus(self):
        self._assert_retrieves(
            {'genus': 'Evolution'},
            ('eevee',), exact=True)

    def test_search_by_color(self):
        self._assert_retrieves(
            {'color': 'brown'},
            ('eevee',))

    def test_search_by_habitat(self):
        self._assert_retrieves(
            {'habitat': 'urban'},
            ('eevee',))

    def test_search_by_shape(self):
        self._assert_retrieves(
            {'shape': 'quadruped'},
            ('eevee',))

    def test_search_by_ability(self):
        self._assert_retrieves(
            {'ability': 'run-away'},
            ('eevee',))

        self._assert_retrieves(
            {'ability.lookup': 'Run Away'},
            ('eevee',))

        self._assert_retrieves(
            {'ability.lookup': u'にげあし'},
            ('eevee',))

    def test_search_by_held_item(self):
        self._assert_retrieves(
            {'held-item': 'lucky-egg'},
            ('chansey',))

        self._assert_retrieves(
            {'held-item.lookup': 'Lucky Egg'},
            ('chansey',))

    def test_search_by_gender(self):
        assert False, "syntax?"
        self._assert_retrieves({'gender': '...'})

    def test_search_by_evolution(self):
        # XXX uhh this is duplicated below
        self._assert_retrieves(
            {'evolution.stage': 'basic'},
            ('eevee',))

    def test_search_by_pokedex_number(self):
        self._assert_retrieves(
            {'pokedex.kanto': '133'},
            ('eevee',), exact=True)

    def test_search_by_hatch_counter(self):
        self._assert_retrieves(
            {'hatch-counter': '35'},
            ('eevee',))

    def test_search_by_base_experience(self):
        self._assert_retrieves(
            {'base-experience': '92'},
            ('eevee',))

    def test_search_by_capture_rate(self):
        self._assert_retrieves(
            {'capture-rate': '45'},
            ('eevee',))

    def test_search_by_height(self):
        self._assert_retrieves(
            {'height': '0.3 m'},
            ('eevee',))

    def test_search_by_weight(self):
        self._assert_retrieves(
            {'weight': '6.5 kg'},
            ('eevee',))

    def test_search_by_move(self):
        self._assert_retrieves(
            {'move': 'trump-card'},
            ('eevee',))


class TestComplexPokemonSearch(APIMixin):
    """Deals with the sticky bits of searching: operators, compound fields,
    etc.
    """

    def test_string_operators(self):
        # Default is substring
        self._assert_retrieves(
            {'name': 'eve'},
            ('eevee',))

        # Also works explicitly, and case-insensitive
        self._assert_retrieves(
            {'name': 'EVE', 'name.match-type': 'substring'},
            ('eevee',))

        # Exact should match...  exactly
        self._assert_retrieves(
            {'name': 'eevee', 'name.match-type': 'exact'},
            ('eevee',))
        self._assert_retrieves(
            {'name': 'vee', 'name.match-type': 'exact'},
            (), exact=True)

        # And wildcards
        self._assert_retrieves(
            {'name': '*ariz?rd', 'name.match-type': 'wildcard'},
            ('charizard',), exact=True)

        # Identifiers should ONLY match exactly, ever
        self._assert_retrieves(
            {'identifier': 'evee'},
            (), exact=True)
        self._assert_retrieves(
            {'identifier': 'Eevee'},
            (), exact=True)

    def test_set_operators(self):
        # Default is "any"
        self._assert_retrieves(
            {'type': ['normal', 'dark']},
            ('eevee', 'umbreon'))
        self._assert_retrieves(
            {'type': ['normal', 'dark'], 'type.match-type': 'any'},
            ('eevee', 'umbreon'))

        # All
        self._assert_retrieves(
            {'type': ['grass', 'fighting'], 'type.match-type': 'all'},
            ('breloom', 'virizion'), exact=True)

        # None
        self._assert_retrieves(
            # TODO finish typing this
            {'type': ['grass', 'fire', 'ground', 'flame', 'electric'], 'type.match-type': 'none'},
            ('eevee',))

        # XXX oops, what were the others
        # XXX test color too; there can only be one of those, the operators are different

    def test_ability_slots(self):
        self._assert_retrieves(
            {
                'ability': 'anticipation',
                'ability.slot': 'hidden',
            },
            ('eevee',), exact=True)

    def test_nested_fields(self):
        # Stats and effort are hashes of their stats
        self._assert_retrieves(
            {'base-stats.attack': '55'},
            ('eevee',))
        self._assert_retrieves(
            {'base-stats.hp': '255'},
            ('blissey',), exact=True)
        self._assert_retrieves(
            {'effort.special-defense': '1'},
            ('eevee',))

        # Evolution is a special dict containing all special values
        self._assert_retrieves(
            {'evolution.stage': 'basic'},
            ('eevee',))
        self._assert_retrieves(
            {'evolution.position': 'only'},
            ('latias', 'kecleon', 'pinsir'))
        self._assert_retrieves(
            {'evolution.fork': 'branching'},
            ('eevee', 'tyrogue'))

        # Abilities and held items have extra stuff to search for
        # TODO I guess
        self._assert_retrieves(
            {'ability': 'anticipation', 'ability.slot': 'hidden'},
            ('eevee',))

        # Moves vary by version and method
        # TODO copy whatever the pokemon search does here
        self._assert_retrieves(
            {'move': 'trump-card'},
            ('eevee',))
        self._assert_retrieves(
            {'move': 'trump-card', 'move.version': 'red'},
            (), exact=True)
        self._assert_retrieves(
            {'move': 'trump-card', 'move.method': 'tutor'},
            (), exact=True)

        # Names vary by language
        # TODO not sure how lookup is going to work


class TestPokemonRetrieval(APIMixin):
    """Test that each property is retrieved as expected."""
    # TODO: test the number of queries done here, too
    def _easy_fetch_test(self, identifier, field_name, value):
        """Dead simple wrapper for doing a query, asking for a single field
        back, and checking that the resulting value is correct.
        """
        results = self._query_api({
            'identifier': identifier, '__version__': 'white', '__fetch__': field_name})
        assert len(results) == 1
        assert results[0][field_name] == value

    def test_fetch_id(self):
        self._easy_fetch_test('eevee', 'id', 133)

    def test_fetch_growth_rate(self):
        self._easy_fetch_test('eevee', 'growth-rate', 'medium')

    def test_fetch_generation(self):
        self._easy_fetch_test('eevee', 'generation', 1)

    def test_fetch_type(self):
        self._easy_fetch_test('eevee', 'type', ['normal'])

    def test_fetch_egg_group(self):
        self._easy_fetch_test('eevee', 'egg-group', ['ground'])

    def test_fetch_genus(self):
        # TODO language
        self._easy_fetch_test('eevee', 'genus', 'Evolution')

    def test_fetch_color(self):
        self._easy_fetch_test('eevee', 'color', 'brown')

    def test_fetch_habitat(self):
        self._easy_fetch_test('eevee', 'habitat', 'urban')

    def test_fetch_shape(self):
        self._easy_fetch_test('eevee', 'shape', 'quadruped')

    def test_fetch_ability(self):
        # XXX how should this actually look?
        self._easy_fetch_test('eevee', 'ability', [
            dict(ability='run-away', slot=1),
            dict(ability='adaptability', slot=2),
            dict(ability='anticipation', slot='hidden'),
        ])

    def test_fetch_held_item(self):
        # XXX how should this actually look?
        # XXX version
        # XXX pick a pokemon that actually holds a thing
        self._easy_fetch_test('eevee', 'held-item', [])

    def test_fetch_gender(self):
        # XXX how should this actually look?
        self._easy_fetch_test('eevee', 'gender', '7/8 male')

    def test_fetch_evolution(self):
        self._easy_fetch_test('eevee', 'evolution',
            dict(stage='basic', position='first', fork='branching'))

    def test_fetch_base_stats(self):
        self._easy_fetch_test('eevee', 'base-stats', {
            'hp': 55,
            'attack': 55,
            'defense': 50,
            'special-attack': 45,
            'special-defense': 65,
            'speed': 55})

    def test_fetch_effort(self):
        self._easy_fetch_test('eevee', 'effort', {
            'hp': 0,
            'attack': 0,
            'defense': 0,
            'special-attack': 0,
            'special-defense': 1,
            'speed': 0})

    def test_fetch_pokedex_numbers(self):
        self._easy_fetch_test('eevee', 'pokedex', {
            u'national': 133,
            u'kanto': 133,
            u'original-johto': 180,
            u'updated-johto': 184,
            u'extended-sinnoh': 163})

    def test_fetch_hatch_counter(self):
        # XXX what about steps to hatch
        self._easy_fetch_test('eevee', 'hatch-counter', 35)

    def test_fetch_base_experience(self):
        # XXX what about changed exp, ick
        self._easy_fetch_test('eevee', 'base-experience', 92)

    def test_fetch_capture_rate(self):
        self._easy_fetch_test('eevee', 'capture-rate', 45)

    def test_fetch_height(self):
        # XXX how should this actually look?
        self._easy_fetch_test('eevee', 'height', '0\'11.8"')

    def test_fetch_weight(self):
        # XXX how should this actually look?
        self._easy_fetch_test('eevee', 'weight', '14.3 lb')

    def test_fetch_move(self):
        # XXX how should this actually look?  should this be allowed??
        """proposal:
        move:
            white:
                level-up:
                    - level: 1, move: tail-whip
                    - ...
        then __version__ and __method__ (???) would just omit nodes from this tree
        """
        self._easy_fetch_test('eevee', 'move', {
            'white': {
                'level-up': [
                    dict(level=1, move='tail-whip'),
                    dict(level=1, move='tackle'),
                    dict(level=1, move='helping-hand'),
                    dict(level=8, move='sand-attack'),
                    dict(level=15, move='growl'),
                    dict(level=22, move='quick-attack'),
                    dict(level=29, move='bite'),
                    dict(level=36, move='baton-pass'),
                    dict(level=43, move='take-down'),
                    dict(level=50, move='last-resort'),
                    dict(level=57, move='trump-card'),
                ],
            },
        })

    # ... XXX fill this in once it's possible to ask for fields...
    # XXX need an 'auto', or default list, or somethin

# XXX need tests for error handling, too
# XXX test giving a name and finding too many matches, or no match, or only vague matches (?)

# XXX sort of a pending and huge question about fetching: how does it work for complex stuff?
# there's __version__ to ask for a certain *version*'s moves, but maybe you only care about level-up moves.
# special fetches: if i ask for pokemon that can learn a move, i probably want to know how they learn it, without fucking around.
