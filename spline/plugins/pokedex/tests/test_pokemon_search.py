# encoding: utf8
from spline.tests import *

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

        results = self.do_search(**criteria).c.results

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

    def test_color(self):
        """Checks searching by color."""
        self.check_search(
            dict(color=u'brown'),
            [ u'Cubone', u'Eevee', u'Feebas', u'Pidgey', u'Spinda', u'Zigzagoon' ],
                # etc.
            'color',
        )

    def test_ability(self):
        """Checks searching by ability."""
        self.check_search(
            dict(ability=u'Bad Dreams'),
            [u'Darkrai'],
            'ability',
            exact=True,
        )

    def test_habitat(self):
        """Checks searching by FR/LG habitat."""
        # I actually checked this by looking at the old search's results.  Hm.
        self.check_search(
            dict(habitat=u'urban'),
            [ u'Abra', u'Eevee', u'Hitmonlee', u'Muk', u'Persian', u'Voltorb' ],
            'habitat',
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
        - branching evolution
        - fully evolved
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
            [ u'Charizard', u'Dragonite', u'Feraligatr', u'Staraptor', u'Tyrannitar', u'Vileplume' ],
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
            dict(evolution_position=u'branch'),
            [ u'Kirlia', u'Nincada' ],
            u'branching evolution',
        )

        # Some combinations of relative positions
        self.check_search(
            dict(evolution_position=[u'first', u'last']),
            [ u'Jirachi', u'Kecleon', u'Latias', u'Mew', u'Shuckle' ],
            u'only evolution',
        )
        self.check_search(
            dict(evolution_position=[u'first', u'branch']),
            [ u'Nincada' ],
            u'first evolution branches',
        )
        self.check_search(
            dict(evolution_position=[u'middle', u'branch']),
            [ u'Kirlia' ],
            u'middle evolution branches',
        )
        self.check_search(
            dict(evolution_position=[u'last', u'branch']),
            [],
            u'last evolution branches (impossible)',
            exact=True,
        )
        self.check_search(
            dict(evolution_position=[u'middle', u'last']),
            [],
            u'middle and last evolution (impossible)',
            exact=True,
        )

    def test_gender_distribution(self):
        """Checks searching by gender frequency.

        Controls look like: [at least|v] [1/8 female|v]

        Remember, the db (and thus the form) store gender rate as
        eighths-female.
        """
        self.check_search(
            dict(gender_rate_constraint=u'less_equal', gender_rate=u'1'),
            [ u'Bulbasaur', u'Chikorita', u'Tauros' ],
            'mostly male',
        )
        self.check_search(
            dict(gender_rate_constraint=u'more_equal', gender_rate=u'6'),
            [ u'Clefairy', u'Kangaskhan', u'Miltank' ],
            'mostly female',
        )
        self.check_search(
            dict(gender_rate_constraint=u'equal', gender_rate=u'4'),
            [ u'Absol', u'Castform', u'Delibird', u'Grimer', u'Teddiursa' ],
            'half and half',
        )
        self.check_search(
            dict(gender_rate_constraint=u'equal', gender_rate=u'-1'),
            [ u'Magneton', u'Voltorb' ],
            'no gender',
        )

        # Check that "<= 0" doesn't include genderless (-1)
        res = self.do_search(gender_rate_constraint=u'less_equal',
                             gender_rate=u'0')
        self.assertFalse(any(_.name == u'Voltorb' for _ in res.c.results))

    # still to go: egg groups, generation, regional pokedex, type, move, stats,
    #              effort, size, held item
