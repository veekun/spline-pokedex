# encoding: utf8
from spline.tests import *

class TestMoveSearchController(TestController):

    def do_search(self, **criteria):
        u"""Small wrapper to run a move search for the given criteria."""
        return self.app.get(url(controller='dex_search',
                                action='move_search',
                                **criteria))

    def check_search(self, criteria, expected, message, exact=False):
        """Checks whether the given expected results (a list of names) are
        included in the response from a search.

        If exact is set to True, the search must contain exactly the given
        results.  Otherwise, the search can produce other results.
        """
        # This was stolen from test_pokemon_search, yes.  Alas, I don't think
        # the code is similar enough to be worth factoring out.  :(

        # Unless otherwise specified, the test doesn't care about display or
        # sorting, so skip all the effort the template goes through generating
        # the default table
        criteria.setdefault('display', 'simple-list')
        criteria.setdefault('sort', 'id')

        results = self.do_search(**criteria).c.results

        self.assert_(
            len(results) < 460,
            u"doesn't look like we got every single move: {0}".format(message)
        )

        leftover_results = []
        leftover_expected = expected[:]

        # Remove expected results from the 'leftover' list, and add unexpected
        # results to the other leftover list
        for result in results:
            result_name = result.name

            if result_name in leftover_expected:
                leftover_expected.remove(result_name)
            else:
                leftover_results.append(result_name)

        # The leftovers now contain no names in common
        self.assertEquals(
            leftover_expected, [],
            u"all expected moves found: {0}".format(message)
        )

        if exact:
            self.assertEquals(
                leftover_results, [],
                u"no extra moves found: {0}".format(message)
            )


    def test_name(self):
        u"""Checks basic name searching.  Wildcards are also supported."""

        self.check_search(
            dict(name=u'flamethrower'),
            [u'Flamethrower'],
            'searching by name',
            exact=True,
        )

        self.check_search(
            dict(name=u'durp'),
            [],
            'searching for a nonexistent name',
            exact=True,
        )

        self.check_search(
            dict(name=u'quICk AttACk'),
            [u'Quick Attack'],
            'case is ignored',
            exact=True,
        )

        self.check_search(
            dict(name=u'thunder'),
            [ u'Thunder', u'Thunderbolt', u'Thunder Wave',
              u'ThunderShock', u'ThunderPunch', u'Thunder Fang'],
            'no wildcards is treated as substring',
            exact=True,
        )
        self.check_search(
            dict(name=u'*under'),
            [u'Thunder'],  # not ThunderShock, etc.!
            'splat wildcard works and is not used as substring',
            exact=True,
        )
        self.check_search(
            dict(name=u'b?te'),
            [u'Bite'],  # not Bug Bite!
            'question wildcard works and is not used as substring',
            exact=True,
        )

    def test_type(self):
        u"""Checks type searching."""
        self.check_search(
            dict(type=u'???'),
            [u'Curse'],
            'searching by type',
            exact=True,
        )

        self.check_search(
            dict(type=[u'fire', u'electric']),
            [u'Thunder', u'ThunderShock', u'Flamethrower', u'Ember'],
            'searching for multiple types',
        )

    def test_damage_class(self):
        u"""Checks searching by damage class (physical, special, effect)."""
        self.check_search(
            dict(damage_class=u'physical'),
            [u'Mega Punch', u'Quick Attack', u'Bite'],
            'very general damage class search',
        )

        self.check_search(
            dict(damage_class=u'none', type=u'dragon'),
            [u'Dragon Dance'],
            'more precise damage class search',
            exact=True,
        )

    def test_generation(self):
        u"""Checks generation searching."""
        self.check_search(
            dict(generation=u'1'),
            [u'Tackle', u'Gust', u'Thunder Wave', u'Hyper Beam'],
            'searching by generation',
        )

    def test_effect(self):
        u"""Checks searching by move effect.  Rather than being first-class
        objects themselves, move effects are represented by any move with that
        effect.
        """
        self.check_search(
            dict(similar_to=u'icy wind'),
            [ u'Bubble', u'BubbleBeam', u'Constrict',
              u'Icy Wind', u'Mud Shot', u'Rock Tomb' ],
            'searching by effect',
            exact=True,
        )
        self.check_search(
            dict(similar_to=u'splash'),
            [u'Splash'],
            'searching by unique effect',
            exact=True,
        )

    def test_flags(self):
        u"""Checks searching by some combination of flags."""
        self.check_search(
            dict(flag_contact=u'yes'),
            [u'Tackle', u'Double-Slap', u'Ice Punch', u'Bite', u'Fly'],
            'flimsy search by flag',
        )

        self.check_search(
            dict(flag_accuracy=u'no'),
            [u'Swift'],
            'better search by flag',
        )

        self.check_search(
            dict(flag_contact=u'no', name=u'punch'),
            [],
            'searching by nega-flag',
            exact=True,
        )

    def test_numbers(self):
        u"""Checks range searching for basic stats like power, accuracy, etc.

        The range syntax is covered pretty well by the Pokémon search tests,
        and isn't retested in such depth here.
        """
        self.check_search(
            dict(accuracy=u'55'),
            [u'Sing', u'Poison Gas', u'GrassWhistle', u'Supersonic'],
            'searching by accuracy',
            exact=True,
        )
        self.check_search(
            dict(accuracy=u'53-56'),
            [u'Sing', u'Poison Gas', u'GrassWhistle', u'Supersonic'],
            'searching by accuracy range',
            exact=True,
        )

        self.check_search(
            dict(pp=u'1'),
            [u'Sketch', u'Struggle'],
            'searching by PP',
            exact=True,
        )

        self.check_search(
            dict(priority=u'-7'),  # XXX oh no what?  this looks like "<7"
            [u'Trick Room'],
            'searching by priority',
            exact=True,
        )

        self.check_search(
            dict(power=u'130'),
            [u'Last Resort'],
            'searching by power',
            exact=True,
        )

        self.check_search(
            dict(effect_chance=u'70'),
            [u'Charge Beam'],
            'searching by effect chance',
            exact=True,
        )

    def test_pokemon(self):
        u"""Checks searching by learning Pokémon.

        Just like the Pokémon search's search-by-move, results are ANDed.

        Besides a Pokémon name, we can also specify:
        - The version(s) to search.
        - The method(s) by which the Pokémon learns the move.
        """
        self.check_search(
            dict(pokemon=u'Ditto'),
            [u'Transform'],
            'simple search by pokemon',
            exact=True,
        )
        self.check_search(
            dict(pokemon=[u'Ditto', u'Mew']),
            [u'Transform'],
            'search by multiple pokemon',
            exact=True,
        )

        # Restrict by version
        self.check_search(
            dict(pokemon=u'Arceus', pokemon_version_group=[u'1', u'2']),
            [],
            u'gen 4 Pokémon don\'t learn moves in gen 1',
            exact=True,
        )
        self.check_search(
            dict(pokemon=u'Bulbasaur',
                 pokemon_method=u'level-up',
                 name=u'SolarBeam'),
            [u'SolarBeam'],
            'Bulbasaur used to learn SolarBeam...',
            exact=True,
        )
        self.check_search(
            dict(pokemon=u'Bulbasaur',
                 pokemon_method=u'level-up',
                 pokemon_version_group=[u'8', u'9', u'10'],
                 name=u'SolarBeam'),
            [],
            '...but lost it in gen 4',
            exact=True,
        )

        # Restrict by method
        self.check_search(
            dict(name=u'Volt Tackle', pokemon=u'Pichu'),
            [ u'Volt Tackle' ],
            'Pichu learns Volt Tackle...',
            exact=True,
        )
        self.check_search(
            dict(name=u'Volt Tackle',
                 pokemon=u'Pichu',
                 move_method=[u'level-up', u'tutor', u'machine', u'egg']),
            [],
            '...but not by normal means',
            exact=True,
        )

        # Simple combo
        self.check_search(
            dict(move=u'Venusaur',
                 move_method=u'tutor',
                 move_version_group=[u'7']),
            [ u'Frenzy Plant' ],
            'Venusaur gets elemental beam in FR',
        )

    def test_category(self):
        """Checks searching by move categories.

        Categories are like types: must include at least one of the selected
        categories.  There's no AND; I can't see that being useful.
        """
        # XXX identifiers would be groovy
        self.check_search(
            dict(category=u'36:self'),  # trap
            [u'Ingrain'],
            'simple category search, vs self',
            exact=True,
        )
        self.check_search(
            dict(category=u'14:target'),  # protect
            [u'Conversion 2', u'False Swipe'],
            'simple category search, vs target',
            exact=True,
        )

        self.check_search(
            dict(category=[u'29:self', u'15:target']),  # sleep; attack up
            [u'Rest', u'Swagger'],
            'multiple category search',
            exact=True,
        )
