# encoding: utf8
from spline.tests import *

from splinext.pokedex.controllers.pokedex_search import MoveSearchForm

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
        criteria.setdefault('display', 'custom-list')
        criteria.setdefault('sort', 'id')

        results = self.do_search(**criteria).tmpl_context.results

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
              u'ThunderShock', u'ThunderPunch', u'Thunder Fang' ],
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
            dict(type=u'Dragon'),
            [ u'Dual Chop', u'Draco Meteor', u'DragonBreath', u'Dragon Claw',
              u'Dragon Dance', u'Dragon Pulse', u'Dragon Rage', u'Dragon Rush',
              u'Dragon Tail', u'Outrage', u'Roar of Time', u'Spacial Rend',
              u'Twister',
            ],
            'searching by type',
            exact=True,
        )

        self.check_search(
            dict(type=[u'Fire', u'Electric']),
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
            dict(damage_class=u'non-damaging', type=u'Dragon'),
            [u'Dragon Dance'],
            'more precise damage class search',
            exact=True,
        )

    def test_generation(self):
        u"""Checks generation searching."""
        self.check_search(
            dict(introduced_in=u'1'),
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
            [ u'Bubble', u'BubbleBeam', u'Bulldoze', u'Constrict',
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
            [u'Tackle', u'DoubleSlap', u'Ice Punch', u'Bite', u'Fly'],
            'flimsy search by flag',
        )

        self.check_search(
            dict(flag_mirror=u'no'),
            [u'Counter', u'Curse', u'Focus Punch', u'Sunny Day'],
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
            [u'Sing', u'GrassWhistle', u'Supersonic'],
            'searching by accuracy',
            exact=True,
        )
        self.check_search(
            dict(accuracy=u'53-56'),
            [u'Sing', u'GrassWhistle', u'Supersonic'],
            'searching by accuracy range',
            exact=True,
        )

        self.check_search(
            dict(pp=u'1'),
            [u'Sketch'],
            'searching by PP',
            exact=True,
        )

        self.check_search(
            dict(priority=u'-7'),  # XXX oh no what?  this looks like "<7"
            [u'Magic Room', u'Trick Room', u'Wonder Room'],
            'searching by priority',
            exact=True,
        )

        self.check_search(
            dict(power=u'130'),
            [u'Blue Flare', u'Bolt Strike', u'Hi Jump Kick'],
            'searching by power',
            exact=True,
        )

        self.check_search(
            dict(ailment_chance=u'50'),
            [u'Sacred Fire'],
            'searching by status ailment chance',
            exact=True,
        )

        self.check_search(
            dict(flinch_chance=u'100'),
            [u'Fake Out'],
            'searching by flinch chance',
            exact=True,
        )

        self.check_search(
            dict(stat_chance=u'70'),
            [u'Charge Beam'],
            'searching by stat chance',
            exact=True,
        )

    def test_pokemon(self):
        u"""Checks searching by learning Pokémon.

        Unlike the Pokémon search's search-by-move, results are ORed.

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
            dict(pokemon=[u'Ditto', u'Unown']),
            [u'Transform', u'Hidden Power'],
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
                 pokemon_method=[u'level-up', u'tutor', u'machine', u'egg']),
            [],
            '...but not by normal means',
            exact=True,
        )

        # Simple combo
        self.check_search(
            dict(pokemon=u'Venusaur',
                 pokemon_method=u'tutor',
                 pokemon_version_group=[u'7']),
            [ u'Frenzy Plant' ],
            'Venusaur gets elemental beam in FR',
        )

    def test_ailment(self):
        """Checks searching by move ailments: confusion, trapping, etc.

        A move can inflict only one ailment, and it must be one of those
        selected in the form.
        """
        self.check_search(
            dict(ailment=u'ingrain'),
            [u'Ingrain'],
            'dead simple ailment search',
            exact=True,
        )

        # Multiple ailments
        self.check_search(
            dict(ailment=[u'sleep', u'freeze']),
            [u'Sleep Powder', u'Blizzard'],
            'multiple ailment search',
        )

    def test_checkboxes(self):
        """Couple boolean meta things."""
        self.check_search(
            dict(crit_rate=u'y'),
            [u'Aeroblast', u'Air Cutter', u'Karate Chop', u'Slash'],
            'increased crit chance',
        )

        self.check_search(
            dict(multi_hit=u'y'),
            [u'Barrage', u'Gear Grind', u'Tail Slap'],
            'multi-hit',
        )

        self.check_search(
            dict(multi_turn=u'y'),
            [u'Confusion', u'Psybeam', u'Telekinesis'],
            'multi-turn',
        )

    def test_sort(self):
        """Make sure all the sort methods actually work."""
        sort_field = MoveSearchForm.sort
        for value, label in sort_field.kwargs['choices']:
            response = self.do_search(id=u'1', sort=value)
            self.assert_(
                response.tmpl_context.results,
                """Sort by {0} doesn't crash""".format(value)
            )

    def test_display_custom_table(self):
        """Try spitting out a custom table with every column, and make sure it
        doesn't explode.
        """

        column_field = MoveSearchForm.column
        columns = [value for (value, label) in column_field.kwargs['choices']]

        response = self.do_search(id=u'1', display='custom-table',
                                           column=columns)
        self.assert_(
            response.tmpl_context.results,
            """Custom table columns don't crash""".format(value)
        )
