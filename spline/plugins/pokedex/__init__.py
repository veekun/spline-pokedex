from pkg_resources import resource_filename
from pylons import config

import controllers.pokedex
from spline.lib.plugin import PluginBase

def add_routes_hook(map, *args, **kwargs):
    """Hook to inject some of our behavior into the routes configuration."""
    map.connect('/dex/media/*path', controller='dex', action='media')
    map.connect('/dex/pokemon/{name}', controller='dex', action='pokemon')
    map.connect('/dex/pokemon/{name}/flavor', controller='dex', action='pokemon_flavor')

class PokedexPlugin(PluginBase):
    def controllers(self):
        return {
            'dex': controllers.pokedex.PokedexController,
        }

    def template_dirs(self):
        return [
            (resource_filename(__name__, 'templates'), 3)
        ]

    def static_dirs(self):
        return [ resource_filename(__name__, 'public') ]

    def hooks(self):
        return [
            ('routes_mapping', 3, add_routes_hook),
        ]
