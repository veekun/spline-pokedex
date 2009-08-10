from pkg_resources import resource_filename
from pylons import config

import pokedex.db
import pokedex.db.tables as tables
import spline.plugins.pokedex.controllers.pokedex
from spline.plugins.pokedex import helpers as pokedex_helpers
import spline.lib.helpers as h
from spline.lib.plugin import PluginBase

def add_routes_hook(map, *args, **kwargs):
    """Hook to inject some of our behavior into the routes configuration."""
    map.connect('/dex/media/*path', controller='dex', action='media')
    map.connect('/dex/lookup', controller='dex', action='lookup')

    map.connect('/dex/abilities/{name}', controller='dex', action='abilities')
    map.connect('/dex/items/{name}', controller='dex', action='items')
    map.connect('/dex/moves/{name}', controller='dex', action='moves')
    map.connect('/dex/pokemon/{name}', controller='dex', action='pokemon')
    map.connect('/dex/pokemon/{name}/flavor', controller='dex', action='pokemon_flavor')
    map.connect('/dex/types/{name}', controller='dex', action='types')

class PokedexPlugin(PluginBase):
    def __init__(self):
        """Stuff our helper module in the Pylons h object."""
        # XXX should we really be doing this here?
        h.pokedex = pokedex_helpers

    def controllers(self):
        return {
            'dex': controllers.pokedex.PokedexController,
        }

    def template_dirs(self):
        return [
            (resource_filename(__name__, 'templates'), 3)
        ]

    def static_dir(self):
        return resource_filename(__name__, 'public')

    def content_dir(self):
        return resource_filename(__name__, 'content')

    def hooks(self):
        return [
            ('routes_mapping', 3, add_routes_hook),
        ]

    def widgets(self):
        return [
            ('page_header', 3, 'widgets/pokedex_lookup.mako'),
        ]
