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
        leftover_expected = []

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
        u"""Checks basic name searching.

        Same as Pokémon search, anything that does exact matches in lookup
        should work here.
        """
        self.check_search(
            dict(name=u'flamethrower'),
            [u'Flamethrower'],
            'searching by name',
            exact=True,
        )
