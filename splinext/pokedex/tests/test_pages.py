# Encoding: UTF-8

from spline.tests import SplineTest, url

class TestPagesController(SplineTest):

    def check_pokemon(self, default_form_name, urlargs):
        response = self.hit_page(urlargs)
        result_name = response.tmpl_context.pokemon.default_form.name
        assert result_name == default_form_name, 'Correct Pokemon is selected: %s != %s' % (
                result_name, default_form_name)

    def hit_page(self, urlargs):
        urlargs.setdefault('controller', 'dex')
        response = self.app.get(url(**urlargs))
        return response

    def test_selected_pokemon(self):
        for action in 'pokemon pokemon_flavor pokemon_locations'.split():
            yield self.check_pokemon, 'Eevee', dict(name='eevee', action=action)

            # Forms
            yield self.check_pokemon, 'Normal Deoxys', dict(name='deoxys', action=action)
            yield self.check_pokemon, 'Unown A', dict(name='unown', action=action)
            yield self.check_pokemon, 'Unown A', dict(name='unown', form='z', action='pokemon')

            # Babies & weird evo chains
            yield self.check_pokemon, 'Pichu', dict(name='pichu', action=action)
            yield self.check_pokemon, 'Manaphy', dict(name='manaphy', action=action)
            yield self.check_pokemon, 'Mothim', dict(name='mothim', action=action)
            yield self.check_pokemon, 'Accelgor', dict(name='accelgor', action=action)
            yield self.check_pokemon, 'Steelix', dict(name='steelix', action=action)
            yield self.check_pokemon, 'Feebas', dict(name='feebas', action=action)
            yield self.check_pokemon, 'Nincada', dict(name='nincada', action=action)
            # (Eevee & Mr. Mime handles elsewhere)

            # Weird URIs
            yield self.check_pokemon, 'Mr. Mime', dict(name='mr. mime', action=action)
            yield self.check_pokemon, 'Ho-Oh', dict(name='ho-oh', action=action)
            yield self.check_pokemon, u'Nidoran♀', dict(name=u'nidoran♀', action=action)

            # Prev/next wrapping
            yield self.check_pokemon, 'Bulbasaur', dict(name='bulbasaur', action=action)
            yield self.check_pokemon, 'Genesect', dict(name='genesect', action=action)
        yield self.check_pokemon, 'Attack Deoxys', dict(name='deoxys', form='attack', action='pokemon')
        yield self.check_pokemon, 'Attack Deoxys', dict(name='deoxys', form='attack', action='pokemon_flavor')
        yield self.check_pokemon, 'Normal Deoxys', dict(name='deoxys', form='attack', action='pokemon_locations')

    def test_selected_pages(self):
        for url_params in (
                dict(action='pokemon_list'),

                dict(action='abilities_list'),
                dict(action='abilities', name='static'),
                dict(action='abilities', name='wonder guard'),

                dict(action='items_list'),
                dict(action='item_pockets', pocket='key'),
                dict(action='items', pocket='pokeballs', name='park ball'),
                dict(action='items', pocket='misc', name='yellow shard'),
                dict(action='items', pocket='beries', name='aguav berry'),

                dict(action='locations_list'),
                dict(action='locations', name='route 3'),
                dict(action='locations', name=u'pokémon movie 11'),

                dict(action='moves_list'),
                dict(action='moves', name='tackle'),
                dict(action='moves', name='will-o-wisp'),
                dict(action='moves', name='ice beam'),

                dict(action='natures_list'),
                dict(action='natures', name='adamant'),
                dict(action='natures', name='bashful'),

                dict(action='types_list'),
                dict(action='types_list', secondary='flying'),
                dict(action='types', name='ground'),
                dict(action='types', name='???'),
                dict(action='types', name='shadow'),

                dict(controller='dex_gadgets', action='chain_breeding'),
                dict(controller='dex_gadgets', action='compare_pokemon'),
                dict(controller='dex_gadgets', action='capture_rate'),
                dict(controller='dex_gadgets', action='stat_calculator'),
                dict(controller='dex_gadgets', action='whos_that_pokemon'),

                dict(controller='dex_gadgets', action='stat_calculator',
                        pokemon='Sky Shaymin', stat='310|211|155|245|155|259',
                        level='100', effort='0|0|0|0|0|0', nature='bashful'),

                dict(action='lookup', lookup='eevee'),
                dict(action='lookup', lookup='arceus'),
                dict(action='lookup', lookup='flying arceus'),
                dict(action='lookup', lookup='eevee locations'),
                dict(action='lookup', lookup='eevee flavor'),
                dict(action='lookup', lookup='unown y'),
                dict(action='lookup', lookup='unown f flavor'),
                dict(action='lookup', lookup='unown l locations'),
                dict(action='lookup', lookup='metronome'),
                dict(action='lookup', lookup='dragontie'),

                dict(action='suggest', prefix='ee'),
                dict(action='suggest', prefix='eev'),

                dict(action='parse_size', size='3 yanmega', mode='weight'),
                dict(action='parse_size', size='2cm+', mode='height'),
            ):
            yield self.hit_page, url_params
