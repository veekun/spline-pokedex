# encoding: utf8
from spline.tests import TestController, url

from splinext.pokedex.controllers.pokedex_search import MoveSearchForm

class TestMoveSearchController(TestController):

    def do_search(self, **criteria):
        u"""Small wrapper to run a move search for the given criteria."""
        return self.app.get(url(controller='dex_search',
                                action='move_search',
                                **criteria))

    def check_search(self, criteria, expected, message, exact=False):
        """Checks whether the given expected results (a list of identifiers) are
        included in the response from a search.

        If exact is set to True, the search must contain exactly the given
        results.  Otherwise, the search can produce other results.
        """

        # Unless otherwise specified, the test doesn't care about display or
        # sorting, so skip all the effort the template goes through generating
        # the default table
        criteria.setdefault('display', 'custom-list')
        criteria.setdefault('sort', 'id')

        results = self.do_search(**criteria).tmpl_context.results

        if len(results) > 460:
            self.fail("{0}: got way too many results")

        result_identifiers = [result.identifier for result in results]
        result_identifiers.sort()

        expected = expected[:]
        expected.sort()

        if exact:
            if expected != result_identifiers:
                self.fail("{0}: got {1}, expected {2}".format(message, result_identifiers, expected))
        else:
            if not set(expected).issubset(set(result_identifiers)):
                self.fail("{0}: got {1}, expected at least {2}".format(message, result_identifiers, expected))

    def test_name(self):
        u"""Checks basic name searching.  Wildcards are also supported."""

        self.check_search(
            dict(name=u'flamethrower'),
            [u'flamethrower'],
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
            [u'quick-attack'],
            'case is ignored',
            exact=True,
        )

        self.check_search(
            dict(name=u'thunder'),
            [ u'thunder', u'thunderbolt', u'thunder-wave',
              u'thunder-shock', u'thunder-punch', u'thunder-fang' ],
            'no wildcards is treated as substring',
            exact=True,
        )
        self.check_search(
            dict(name=u'*under'),
            [u'thunder'],  # not ThunderShock, etc.!
            'splat wildcard works and is not used as substring',
            exact=True,
        )
        self.check_search(
            dict(name=u'b?te'),
            [u'bite'],  # not Bug Bite!
            'question wildcard works and is not used as substring',
            exact=True,
        )

    def test_type(self):
        u"""Checks type searching."""
        self.check_search(
            dict(type=u'dragon'),
            [ u'dual-chop', u'draco-meteor', u'dragon-breath', u'dragon-claw',
              u'dragon-dance', u'dragon-pulse', u'dragon-rage', u'dragon-rush',
              u'dragon-tail', u'outrage', u'roar-of-time', u'spacial-rend',
              u'twister',
            ],
            'searching by type',
            exact=True,
        )

        self.check_search(
            dict(type=[u'fire', u'electric']),
            [u'thunder', u'thunder-shock', u'flamethrower', u'ember'],
            'searching for multiple types',
        )

    def test_damage_class(self):
        u"""Checks searching by damage class (physical, special, effect)."""
        self.check_search(
            dict(damage_class=u'physical'),
            [u'mega-punch', u'quick-attack', u'bite'],
            'very general damage class search',
        )

        self.check_search(
            dict(damage_class=u'status', type=u'dragon'),
            [u'dragon-dance'],
            'more precise damage class search',
            exact=True,
        )

    def test_generation(self):
        u"""Checks generation searching."""
        self.check_search(
            dict(introduced_in=u'1'),
            [u'tackle', u'gust', u'thunder-wave', u'hyper-beam'],
            'searching by generation',
        )

    def test_effect(self):
        u"""Checks searching by move effect.  Rather than being first-class
        objects themselves, move effects are represented by any move with that
        effect.
        """
        self.check_search(
            dict(similar_to=u'icy wind'),
            [ u'bubble', u'bubble-beam', u'bulldoze', u'constrict',
              u'icy-wind', u'mud-shot', u'rock-tomb' ],
            'searching by effect',
            exact=True,
        )
        self.check_search(
            dict(similar_to=u'splash'),
            [u'splash'],
            'searching by unique effect',
            exact=True,
        )

    def test_flags(self):
        u"""Checks searching by some combination of flags."""
        self.check_search(
            dict(flag_contact=u'yes'),
            [u'tackle', u'double-slap', u'ice-punch', u'bite', u'fly'],
            'flimsy search by flag',
        )

        self.check_search(
            dict(flag_mirror=u'no'),
            [u'counter', u'curse', u'focus-punch', u'sunny-day'],
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
            [u'sing', u'grass-whistle', u'supersonic'],
            'searching by accuracy',
            exact=True,
        )
        self.check_search(
            dict(accuracy=u'53-56'),
            [u'sing', u'grass-whistle', u'supersonic'],
            'searching by accuracy range',
            exact=True,
        )

        self.check_search(
            dict(pp=u'1'),
            [u'sketch'],
            'searching by PP',
            exact=True,
        )

        self.check_search(
            dict(priority=u'-7'),  # XXX oh no what?  this looks like "<7"
            [u'trick-room'],
            'searching by priority',
            exact=True,
        )

        self.check_search(
            dict(power=u'130'),
            [u'blue-flare', u'bolt-strike', u'draco-meteor', u'high-jump-kick',
             u'leaf-storm', u'overheat', u'skull-bash'],
            'searching by power',
            exact=True,
        )

        self.check_search(
            dict(recoil=u'-50'),
            [u'absorb', u'mega-drain', u'giga-drain'],
            'searching by negative recoil (drain)',
        )
        self.check_search(
            dict(recoil=u'50'),
            [u'head-smash', u'light-of-ruin'],
            'searching by recoil',
            exact=True,
        )

        self.check_search(
            dict(healing=u'-25'),
            [u'struggle'],
            'searching by negative healing',
            exact=True,
        )

        self.check_search(
            dict(ailment_chance=u'50'),
            [u'poison-fang', u'sacred-fire'],
            'searching by status ailment chance',
            exact=True,
        )

        self.check_search(
            dict(flinch_chance=u'100'),
            [u'fake-out'],
            'searching by flinch chance',
            exact=True,
        )

        self.check_search(
            dict(stat_chance=u'70'),
            [u'charge-beam'],
            'searching by stat chance',
            exact=True,
        )

    def test_stat_changes(self):
        u"""Similar to the above but for stats changes."""
        self.check_search(
            dict(stat_change_accuracy=u'1'),
            [u'coil', u'hone-claws'],
            'searching by accuracy change',
            exact=True,
        )

    def test_pokemon(self):
        u"""Checks searching by learning Pokemon.

        Unlike the Pokémon search's search-by-move, results are ORed.

        Besides a Pokémon name, we can also specify:
        - The version(s) to search.
        - The method(s) by which the Pokémon learns the move.
        """
        self.check_search(
            dict(pokemon=u'Ditto'),
            [u'transform'],
            'simple search by pokemon',
            exact=True,
        )
        self.check_search(
            dict(pokemon=[u'Ditto', u'Unown']),
            [u'transform', u'hidden-power'],
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
                 name=u'Solar Beam'),
            [u'solar-beam'],
            'Bulbasaur used to learn Solar Beam...',
            exact=True,
        )
        self.check_search(
            dict(pokemon=u'Bulbasaur',
                 pokemon_method=u'level-up',
                 pokemon_version_group=[u'8', u'9', u'10'],
                 name=u'Solar Beam'),
            [],
            '...but lost it in gen 4',
            exact=True,
        )

        # Restrict by method
        self.check_search(
            dict(name=u'Volt Tackle', pokemon=u'Pichu'),
            [ u'volt-tackle' ],
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
            [ u'frenzy-plant' ],
            'Venusaur gets elemental beam in FR',
        )

    def test_ailment(self):
        """Checks searching by move ailments: confusion, trapping, etc.

        A move can inflict only one ailment, and it must be one of those
        selected in the form.
        """
        self.check_search(
            dict(ailment=u'ingrain'),
            [u'ingrain'],
            'dead simple ailment search',
            exact=True,
        )

        # Multiple ailments
        self.check_search(
            dict(ailment=[u'sleep', u'freeze']),
            [u'sleep-powder', u'blizzard'],
            'multiple ailment search',
        )

    def test_checkboxes(self):
        """Couple boolean meta things."""
        self.check_search(
            dict(crit_rate=u'y'),
            [u'aeroblast', u'air-cutter', u'karate-chop', u'slash'],
            'increased crit chance',
        )

        self.check_search(
            dict(multi_hit=u'y'),
            [u'barrage', u'gear-grind', u'tail-slap'],
            'multi-hit',
        )

        self.check_search(
            dict(multi_turn=u'y'),
            [u'confusion', u'psybeam', u'telekinesis'],
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
