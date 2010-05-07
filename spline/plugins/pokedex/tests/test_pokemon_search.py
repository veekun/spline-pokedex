# encoding: utf8
from spline.tests import *

from spline.plugins.pokedex.controllers.pokedex_search import PokemonSearchForm

class TestPokemonSearchController(TestController):

    def do_search(self, **criteria):
        u"""Small wrapper to run a Pokémon search for the given criteria."""
        return self.app.get(url(controller='dex_search',
                                action='pokemon_search',
                                **criteria))

    def check_search(self, criteria, expected, message, exact=False):
        """Checks whether the given expected results (a list of names or (name,
        forme_name) tuples) are included in the response from a search.

        If exact is set to True, the search must contain exactly the given
        results.  Otherwise, the search can produce other results.
        """

        # Unless otherwise specified, the test doesn't care about display or
        # sorting, so skip all the effort the template goes through generating
        # the default table
        criteria.setdefault('display', 'simple-list')
        criteria.setdefault('sort', 'id')

        results = self.do_search(**criteria).c.results

        self.assert_(
            len(results) < 490,
            u"doesn't look like we got every single Pokémon: {0}".format(message)
        )

        leftover_results = []
        leftover_expected = []

        # Normalize expecteds to (name, forme_name)
        for name in expected:
            if isinstance(name, tuple):
                leftover_expected.append(name)
            else:
                leftover_expected.append((name, None))

        # Remove expected results from the 'leftover' list, and add unexpected
        # results to the other leftover list
        for result in results:
            result_name = result.name, result.forme_name

            if result_name in leftover_expected:
                leftover_expected.remove(result_name)
            else:
                leftover_results.append(result_name)

        # The leftovers now contain no names in common
        self.assertEquals(
            leftover_expected, [],
            u"all expected Pokémon found: {0}".format(message)
        )

        if exact:
            self.assertEquals(
                leftover_results, [],
                u"no extra Pokémon found: {0}".format(message)
            )


    def test_name(self):
        """Checks basic name searching.

        Anything that would get an exact match via lookup should work -- i.e.,
        plain names, forme + name, and wildcards.
        """
        self.check_search(
            dict(name=u'eevee'),
            [u'Eevee'],
            'searching by name',
            exact=True,
        )

        self.check_search(
            dict(name=u'speed deoxys'),
            [(u'Deoxys', u'speed')],
            'searching by forme name',
            exact=True,
        )

        self.check_search(
            dict(name=u'bogus'),
            [],
            'searching for a bogus name',
            exact=True,
        )

        self.check_search(
            dict(name=u'MeOwTh'),
            [u'Meowth'],
            'case is ignored',
            exact=True,
        )

        self.check_search(
            dict(name=u'*eon'),
            [ u'Flareon', u'Kecleon', u'Lumineon', u'Empoleon' ], # etc.
            'wildcards',
        )
        self.check_search(
            dict(name=u'feralig?tr'),
            [ u'Feraligatr' ],
            'more wildcards!',
            exact=True,
        )
        self.check_search(
            dict(name=u'pikac?'),
            [],
            'wildcards are trusted',
            exact=True,
        )


    def test_ability(self):
        """Checks searching by ability."""
        self.check_search(
            dict(ability=u'Bad Dreams'),
            [u'Darkrai'],
            'ability',
            exact=True,
        )


    def test_held_item(self):
        """Check that searching by held item works correctly."""
        self.check_search(
            dict(held_item=u'magmarizer'),
            [ u'Magby', u'Magmar', u'Magmortar' ],
            'simple held-item search',
            exact=True,
        )


    def test_growth_rate(self):
        """Check that searching by growth rate works correctly."""
        self.check_search(
            dict(growth_rate=u'1059860'),
            # All the starters are like this
            [ u'Bulbasaur', u'Charmander', u'Totodile', u'Piplup' ],
            'growth rate',
        )


    def test_species(self):
        """Checks searching by species flavor."""
        self.check_search(
            dict(species=u'evolutio'),
            [ u'Eevee' ],
            'species',
            exact=True,
        )


    def test_color(self):
        """Checks searching by color."""
        self.check_search(
            dict(color=u'brown'),
            [ u'Cubone', u'Eevee', u'Feebas', u'Pidgey', u'Spinda', u'Zigzagoon' ],
                # etc.
            'color',
        )


    def test_habitat(self):
        """Checks searching by FR/LG habitat."""
        # I actually checked this by looking at the old search's results.  Hm.
        self.check_search(
            dict(habitat=u'urban'),
            [ u'Abra', u'Eevee', u'Hitmonlee', u'Muk', u'Persian', u'Voltorb' ],
            'habitat',
        )


    def test_shape(self):
        """Checks searching by flavor shape."""
        self.check_search(
            dict(shape=u'arms'),
            [ u'Baltoy', u'Drifloon', u'Grimer', u'Haunter', u'Porygon-Z', u'Spoink' ],
            'shape',
        )


    def test_evolution_stage(self):
        """Checks the evolution stage searches:
        - baby
        - basic
        - stage 1
        - stage 2

        And the evolution position searches:
        - not evolved
        - middle evolution
        - fully evolved
        - only evolution

        And some special things:
        - branching evolution
        - branched evolution
        """
        # Actual stages
        self.check_search(
            dict(evolution_stage=u'baby'),
            [ u'Magby', u'Munchlax', u'Phione', u'Pichu', u'Riolu', u'Smoochum' ],
            u'baby Pokémon',
        )
        self.check_search(
            dict(evolution_stage=u'basic'),
            [ u'Charmander', u'Eevee', u'Manaphy', u'Scyther', u'Treecko' ],
            u'basic form Pokémon',
        )
        self.check_search(
            dict(evolution_stage=u'stage1'),
            [ u'Electivire', u'Gloom', u'Jolteon', u'Scizor', u'Wartortle' ],
            u'stage 1 Pokémon',
        )
        self.check_search(
            dict(evolution_stage=u'stage2'),
            [ u'Charizard', u'Dragonite', u'Feraligatr', u'Staraptor', u'Tyranitar', u'Vileplume' ],
            u'stage 2 Pokémon',
        )

        # Relative position in a family
        self.check_search(
            dict(evolution_position=u'first'),
            [ u'Charmander', u'Eevee', u'Riolu', u'Togepi' ],
            u'first evolution',
        )
        self.check_search(
            dict(evolution_position=u'last'),
            [ u'Charizard', u'Farfetch\'d', u'Jolteon', u'Scizor', u'Togekiss' ],
            u'final evolution',
        )
        self.check_search(
            dict(evolution_position=u'middle'),
            [ u'Charmeleon', u'Dragonair', u'Gloom', u'Pikachu' ],
            u'middle evolution',
        )
        self.check_search(
            dict(evolution_position=u'only'),
            [ u'Ditto', u'Farfetch\'d', u'Latias', u'Mew', u'Tauros' ],
            u'only evolution',
        )

        # Special stuff
        self.check_search(
            dict(evolution_special=u'branching'),
            [ u'Eevee', u'Tyrogue' ],
            u'branching evolution',
        )
        self.check_search(
            dict(evolution_special=u'branched'),
            [
                u'Gardevoir', u'Gallade',
                u'Ninjask',   u'Shedinja',
            ],
            u'branched evolution',
        )

        # Some combinations of options
        self.check_search(
            dict(evolution_position=[u'first', u'last']),
            [ u'Jirachi', u'Kecleon', u'Latias', u'Mew', u'Shuckle' ],
            u'only evolution',
        )
        self.check_search(
            dict(evolution_position=u'last', evolution_special=u'branching'),
            [],
            u'last evolution branching (impossible)',
        )
        self.check_search(
            dict(evolution_position=u'first', evolution_special=u'branched'),
            [],
            u'first evolution branched (impossible)',
        )
        self.check_search(
            dict(evolution_position=u'middle', evolution_special=u'branched'),
            [ u'Silcoon', u'Cascoon' ],
            u'middle evolution branched',
            exact=True,
        )
        self.check_search(
            dict(evolution_position=u'last', evolution_special=u'branched'),
            [ u'Jolteon', u'Bellossom' ],
            u'last evolution branched',
        )
        self.check_search(
            dict(evolution_position=[u'middle', u'last']),
            [ u'Charmeleon', u'Charizard' ],
            u'middle or last evolution',
        )


    def test_gender_distribution(self):
        """Checks searching by gender frequency.

        Controls look like: [at least|v] [1/8 female|v]

        Remember, the db (and thus the form) store gender rate as
        eighths-female.
        """
        self.check_search(
            dict(gender_rate_operator=u'less_equal', gender_rate=u'1'),
            [ u'Bulbasaur', u'Chikorita', u'Tauros' ],
            'mostly male',
        )
        self.check_search(
            dict(gender_rate_operator=u'more_equal', gender_rate=u'6'),
            [ u'Clefairy', u'Kangaskhan', u'Miltank' ],
            'mostly female',
        )
        self.check_search(
            dict(gender_rate_operator=u'equal', gender_rate=u'4'),
            [ u'Absol', u'Castform', u'Delibird', u'Grimer', u'Teddiursa' ],
            'half and half',
        )
        self.check_search(
            dict(gender_rate_operator=u'equal', gender_rate=u'-1'),
            [ u'Magneton', u'Voltorb' ],
            'no gender',
        )

        # Check that "<= 0" doesn't include genderless (-1)
        res = self.do_search(gender_rate_operator=u'less_equal',
                             gender_rate=u'0')
        self.assertFalse(any(_.name == u'Voltorb' for _ in res.c.results))


    def test_egg_groups(self):
        """Checks searching by egg groups."""
        self.check_search(
            dict(egg_group_operator=u'all', egg_group=u'15'),
            [ u'Latias', u'Mew' ],
            'no eggs',
        )
        # 6 + 11 == Fairy + Indeterminate
        self.check_search(
            dict(egg_group_operator=u'all', egg_group=[u'6', u'11']),
            [ u'Castform' ],
            'fairy + indeterm; only one result',
            exact=True,
        )
        # Water 1; Water 3
        self.check_search(
            dict(egg_group_operator=u'any', egg_group=[u'2', u'9']),
            [ u'Bidoof', u'Corsola', u'Krabby' ],
            'water 1 OR water 3',
        )


    def test_generation(self):
        """Checks searching by generation introduced."""
        self.check_search(
            dict(introduced_in=u'1'),
            [ u'Eevee', u'Pikachu', u'Shellder' ],
            'introduced in Kanto',
        )
        self.check_search(
            dict(introduced_in=u'4'),
            [ u'Lucario', u'Munchlax', u'Roserade' ],
            'introduced in Sinnoh',
        )

        # and several at once for good measure
        self.check_search(
            dict(introduced_in=[u'1', u'4']),
            [ u'Eevee', u'Pikachu', u'Shellder', u'Lucario', u'Munchlax', u'Roserade' ],
            'introduced in Kanto or Sinnoh',
        )


    def test_pokedex(self):
        u"""Checks searching by Pokédex."""
        self.check_search(
            dict(in_pokedex=u'4'),
            [ u'Sandshrew', u'Crobat', u'Lombre' ],
            u'in Hoenn Pokedex',
        )
        self.check_search(
            dict(in_pokedex=u'6'),
            [ u'Eevee', u'Staraptor', (u'Giratina', u'altered') ],
            u'in Sinnoh Pokedex',
        )

        # and several at once for good measure
        self.check_search(
            dict(in_pokedex=[u'7', u'4']),
            [ u'Eevee', u'Espeon', u'Celebi', u'Silcoon', u'Nuzleaf', u'Aron' ],
            u'in Johto or Hoenn Pokedex',
        )


    def test_type(self):
        """Checks searching by type.

        There are three options for type:
        - must have at least one of the selected types
        - must have exactly the selected type combination
        - must have only the selected types
        """
        self.check_search(
            dict(type_operator=u'any', type=[u'dark', u'steel']),
            [ u'Houndoom', u'Magnemite', u'Murkrow', u'Steelix' ],
            'one-of some types',
        )
        self.check_search(
            dict(type_operator=u'exact', type=[u'dragon', u'ground']),
            [ u'Flygon', u'Gabite', u'Garchomp', u'Gible', u'Vibrava' ],
            'exact type combo',
            exact=True,
        )
        self.check_search(
            dict(type_operator=u'only', type=[u'ice', u'steel']),
            [
                u'Mawile', u'Registeel',                        # pure steel
                u'Glaceon', u'Glalie', u'Regice', u'Snorunt',   # pure ice
            ],
            'only selected types',
        )

        # Make sure the default selection doesn't affect results
        self.check_search(
            dict(type_operator=u'any', name=u'eevee'),
            [ u'Eevee' ],
            'empty type selection doesn\'t affect results',
        )


    def test_move(self):
        """Checks searching by move.

        Besides a move name, moves have several ancillary settings:
        - Whether to search for the exact move, an identical move, or any
          similar move.
        - The version(s) to search.
        - The method(s) by which the move is learned.
        """
        self.check_search(
            dict(move=u'Transform'),
            [ u'Ditto', u'Mew' ],
            'simple search by move',
            exact=True,
        )

        # Try searching for identical moves -- that is, moves with the same
        # effect id.
        self.check_search(
            dict(move=u'Thief', move_fuzz=u'same-effect'),
            [
                # These can learn Thief
                u'Abra', u'Bidoof', u'Ekans', u'Meowth', u'Pidgey',
                # These can learn Covet, which is identical
                u'Cleffa', u'Cyndaquil', u'Slakoth',
            ],
            'search by identical move',
        )

        # Restrict by version
        self.check_search(
            dict(move=u'Roar of Time', move_version_group=[u'1', u'2']),
            [],
            'gen 4 moves aren\'t learned in gen 1',
            exact=True,
        )
        self.check_search(
            dict(move=u'SolarBeam',
                 move_method=u'level-up',
                 move_version_group=[u'8', u'9', u'10'],
                 name=u'Bulbasaur'),
            [],
            'Bulbasaur lost SolarBeam in gen 4',
            exact=True,
        )

        # Restrict by method
        self.check_search(
            dict(move=u'Volt Tackle'),
            [ u'Pichu' ],
            'Pichu learns Volt Tackle...',
            exact=True,
        )
        self.check_search(
            dict(move=u'Volt Tackle',
                 move_method=[u'level-up', u'tutor', u'machine', u'egg']),
            [],
            '...but not by normal means',
            exact=True,
        )

        # Simple combo
        self.check_search(
            dict(move=u'Frenzy Plant',
                 move_method=u'tutor',
                 move_version_group=[u'7']),
            [ u'Venusaur' ],
            'only Venusaur gets elemental beam in FR',
            exact=True,
        )


    def test_range_parsing(self):
        u"""Checks to make sure that stats, effort, and size searching can
        parse number ranges.

        They can be any of the following, joined by commas, with space ignored:
        - n
        - n-m
        - n–m
        - n+ or +m
        - n- or -m  (negative numbers are impossible)
        - n~m or n±m
        - n~ or ~m
        - <n or >n

        In the case of size, there's extra parsing to do for units; however,
        that won't conflict with any of the above rules.
        """

        # For the ultimate simplicity, test this against national dex number
        self.check_search(
            dict(id=u'133'),
            [ u'Eevee' ],
            'range: exact number',
            exact=True,
        )
        self.check_search(
            dict(id=u'133, 352'),
            [ u'Eevee', u'Kecleon' ],
            'range: several exact numbers',
            exact=True,
        )
        self.check_search(
            dict(id=u'133-135'),
            [ u'Eevee', u'Vaporeon', u'Jolteon' ],
            'range: n-m',
            exact=True,
        )

        self.check_search(
            dict(id=u'492+'),
            [ (u'Shaymin', u'land'), (u'Shaymin', u'sky'), u'Arceus' ],
            'range: n+',
            exact=True,
        )
        self.check_search(
            dict(id=u'492-'),
            [ (u'Shaymin', u'land'), (u'Shaymin', u'sky'), u'Arceus' ],
            'range: n-',
            exact=True,
        )
        self.check_search(
            dict(id=u'>=492'),
            [ (u'Shaymin', u'land'), (u'Shaymin', u'sky'), u'Arceus' ],
            'range: >=n',
            exact=True,
        )

        self.check_search(
            dict(id=u'+3'),
            [ u'Bulbasaur', u'Ivysaur', u'Venusaur' ],
            'range: +m',
            exact=True,
        )
        self.check_search(
            dict(id=u'–3'),
            [ u'Bulbasaur', u'Ivysaur', u'Venusaur' ],
            'range: endash-m',
            exact=True,
        )
        self.check_search(
            dict(id=u'<4'),
            [ u'Bulbasaur', u'Ivysaur', u'Venusaur' ],
            'range: <m',
            exact=True,
        )

        self.check_search(
            dict(id=u'5~1'),
            [ u'Charmander', u'Charmeleon', u'Charizard' ],
            'range: n~m',
            exact=True,
        )
        self.check_search(
            dict(id=u'133~'),
            [ u'Eevee' ],
            'range: n~ (same as just n)',
            exact=True,
        )
        self.check_search(
            dict(id=u'~9'),
            [ u'Wartortle', u'Blastoise', u'Caterpie' ],
            'range: ~m',
            exact=True,
        )

    def test_stats(self):
        """Check that searching by stats works correctly."""
        self.check_search(
            dict(stat_hp=u'1,255'),
            [ u'Blissey', u'Shedinja' ],
            'HP of 1 or 255',
            exact=True,
        )
        self.check_search(
            dict(stat_special_attack=u'130-131'),
            [ u'Espeon', u'Gengar', u'Glaceon', u'Heatran', u'Latios', u'Magnezone' ],
            'special attack of 130',
            exact=True,
        )

    def test_effort(self):
        """Check that searching by effort works correctly."""
        self.check_search(
            dict(effort_special_attack=u'2', effort_special_defense=u'1'),
            [ u'Butterfree', u'Togekiss', u'Venusaur' ],
            'effort',
            exact=True,
        )

    def test_steps_to_hatch(self):
        """Checks searching by base experience."""
        self.check_search(
            dict(base_experience=u'255'),
            [ u'Arceus', u'Blissey', u'Chansey', u'Happiny' ],
            'base EXP',
        )

    def test_base_experience(self):
        """Checks searching by base experience."""
        self.check_search(
            dict(base_experience=u'255'),
            [ u'Arceus', u'Blissey', u'Chansey', u'Happiny' ],
            'base EXP',
        )

    def test_capture_rate(self):
        """Checks searching by capture rate."""
        self.check_search(
            dict(capture_rate=u'5'),
            [ u'Groudon', u'Kyogre' ],
            'capture rate',
            exact=True,
        )

    def test_base_happiness(self):
        """Checks searching by base happiness."""
        self.check_search(
            dict(base_happiness=u'140'),
            [
                u'Azelf', u'Blissey', u'Chansey', u'Clefable', u'Clefairy',
                u'Cleffa', u'Happiny', u'Lopunny', u'Mesprit', u'Uxie',
            ],
            'base happiness',
            exact=True,
        )

    def test_size(self):
        """Check that searching by size works correctly."""
        # XXX what should a size with no units do?  default american units?  just fail?
        self.check_search(
            dict(height=u'0m-8in'),
            [ u'Natu' ],
            'dumb height range',
        )

        self.check_search(
            dict(weight=u'450lb–210kg'),
            [ u'Rayquaza' ],
            'dumb weight range',
        )

        self.check_search(
            dict(weight=u'14.3 lb'),
            [ u'Eevee' ],
            'converted units match',
        )


    def test_sort(self):
        """Make sure all the sort methods actually work."""
        sort_field = PokemonSearchForm.sort
        for value, label in sort_field.kwargs['choices']:
            response = self.do_search(id=u'1', sort=value)
            self.assert_(
                response.c.results,
                """Sort by {0} doesn't crash""".format(value)
            )

    def test_display_custom_table(self):
        """Try spitting out a custom table with every column, and make sure it
        doesn't explode.
        """

        column_field = PokemonSearchForm.column
        columns = [value for (value, label) in column_field.kwargs['choices']]

        response = self.do_search(id=u'1', display='custom-table',
                                           column=columns)
        self.assert_(
            response.c.results,
            """Custom table columns don't crash""".format(value)
        )


    def test_crash_vague_join(self):
        """Tests for a crash that occurred when searching by evolution position
        and sorting by color, because the join to PokemonColor was vague.
        """
        self.check_search(
            dict(evolution_stage=u'stage1', sort=u'color'),
            [ u'Raichu' ],
            u'joins to other tables still work when searching by evo',
        )
