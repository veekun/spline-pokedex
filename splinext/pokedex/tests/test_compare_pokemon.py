# encoding: utf8
from spline.tests import TestController, url

class TestComparePokemonController(TestController):
    def do_request(self, *pokemon):
        """Quick accessor to hit the compare gadget."""
        return self.app.get(url(controller='dex_gadgets',
                                action='compare_pokemon',
                                pokemon=pokemon))

    def test_pokemon_query_parsing(self):
        u"""Check that the query is correctly parsed.  Real Pokemon names
        should become real Pokemon, and anything ambiguous should be left blank
        but have suggestions in place.  If there are no definite Pokémon, there
        should be no comparing.
        """
        res = self.do_request(u'eevee')
        self.assertEquals(len(res.tmpl_context.found_pokemon), 9, 'correct name gives right count...')
        self.assertEquals(res.tmpl_context.found_pokemon[0].pokemon.name, u'Eevee', '...and right name')
        self.assert_(res.tmpl_context.found_pokemon[1].pokemon is None, 'other slots are empty')

        res = self.do_request(u'ee*ee')
        self.assert_(res.tmpl_context.found_pokemon[0].suggestions is None, 'single wildcard matches exactly...')
        self.assertEquals(res.tmpl_context.found_pokemon[0].pokemon.name, u'Eevee', '...and correctly')

        res = self.do_request(u'trtle')
        self.assert_(res.tmpl_context.found_pokemon[0].suggestions is not None, 'bad misspelling matches several times...')
        self.assert_(res.tmpl_context.found_pokemon[0].pokemon is not None, '...but something is still used')
