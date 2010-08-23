from spline.tests import *

class TestPokemonController(TestController):

    def test_pokemon(self):
        response = self.app.get(url(controller='dex', action='pokemon',
                                    name='eevee'))
        self.assertEquals(response.tmpl_context.pokemon.name, u'Eevee',
                          'Correct Pokemon is selected')
