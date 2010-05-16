from pkg_resources import resource_filename

from pylons import c, session

from spline.lib.plugin import PluginBase
from spline.lib.plugin import PluginBase, PluginLink, Priority
import spline.model as model
import spline.model.meta as meta

import splinext.gts.controllers.gts
import splinext.gts.model

def add_routes_hook(map, *args, **kwargs):
    """Hook to inject some of our behavior into the routes configuration."""
    # These are the GTS URLs
    map.connect('/pokemondpds/worldexchange/{page}.asp', controller='gts', action='dispatch')
    map.connect('/pokemondpds/common/{page}.asp', controller='gts', action='dispatch')


class GTSPlugin(PluginBase):
    def controllers(self):
        return dict(
            gts = splinext.gts.controllers.gts.GTSController,
        )

    def model(self):
        return [
            splinext.gts.model.GTSPokemon,
        ]

    def template_dirs(self):
        return [
            (resource_filename(__name__, 'templates'), Priority.NORMAL)
        ]

    def hooks(self):
        return [
            ('routes_mapping',    Priority.NORMAL,      add_routes_hook),
        ]
