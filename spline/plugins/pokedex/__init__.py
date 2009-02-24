from pkg_resources import resource_filename
from pylons import config

import controllers.pokedex
import controllers.pokedex_image
from spline.lib.plugin import PluginBase

def add_routes_hook(*args, **kwargs):
    """Hook to inject some of our behavior into the routes configuration."""
    map = config['routes.map']

    map.connect('/dex/images/*image_path', controller='dex', action='images')
    map.connect('/dex/pokemon/{name}', controller='dex', action='pokemon')
    map.connect('/dex/pokemon/{name}/flavor', controller='dex', action='pokemon_flavor')

class PokedexPlugin(PluginBase):
    def controllers(self):
        return {
            'dex': controllers.pokedex.PokedexController,
            'dex-images': controllers.pokedex_image.PokedexImageController,
        }

    def template_dirs(self):
        return [ resource_filename(__name__, 'templates') ]

    def hooks(self):
        return [
            ('after_setup', 3, add_routes_hook),
        ]
