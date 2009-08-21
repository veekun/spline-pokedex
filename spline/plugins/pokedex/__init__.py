# encoding: utf8
import os.path
from pkg_resources import resource_filename

from pylons import config

import pokedex.db
import pokedex.db.tables as tables
import pokedex.lookup
import spline.plugins.pokedex.controllers.pokedex
from spline.plugins.pokedex import helpers as pokedex_helpers
from spline.plugins.pokedex.db import pokedex_session
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

def after_setup_hook(*args, **kwargs):
    """Hook to grab a Pokédex whoosh index and remember it in the Pylons
    config.
    """
    # Don't force a recreate when in debug mode!  It adds a ~2s delay for the
    # server restart every time a file is changed
    recreate = not config['debug']

    config['spline.pokedex.index'] = pokedex.lookup.open_index(
        directory=os.path.join(config['pylons.paths']['root'], 'data'),
        session=pokedex_session,
        recreate=recreate,
    )


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
            ('after_setup', 3, after_setup_hook),
        ]

    def widgets(self):
        return [
            ('page_header', 3, 'widgets/pokedex_lookup.mako'),
        ]
