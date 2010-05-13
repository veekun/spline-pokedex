# encoding: utf8
from spline.tests import *

class TestPokemonFlavorController(TestController):

    def test_pokemon_flavor_redirect(self):
        u"""Flavor pages for Pokemon with multiple forms try to redirect to a
        form when they're requested blank and there's no sane "default" --
        i.e., Unown shouldn't be shown form-less, but Pichu can be.

        Ensure that this behavior works correctly.
        """

        tests = [
            (u'Pichu',    None),
            (u'Wormadam', None),
            (u'Unown',    u'j'),  # TODO should be F
            (u'Shellos',  u'west'),
            (u'Castform', None),
        ]

        for pokemon, default_form in tests:
            res = self.app.get(url(controller='dex', action='pokemon_flavor',
                                   name=pokemon.lower()))

            if default_form is None:
                # Shouldn't be redirected
                self.assertEqual(
                    res.status, 200,
                    u"main flavor for {0} doesn't redirect".format(pokemon),
                )
            else:
                # Should be redirected!
                self.assertEqual(
                    res.status, 302,
                    u"main flavor for {0} redirects".format(pokemon),
                )
                self.assert_(
                    'form=' + default_form in res.header('location'),
                    u"main flavor for {0} redirects correctly".format(pokemon),
                )
