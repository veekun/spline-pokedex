from pkg_resources import resource_filename

from pylons import c, session

from spline.lib.plugin import PluginBase
from spline.lib.plugin import PluginBase, PluginLink, Priority
import splinext.gts.controllers.gts

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

    def hooks(self):
        return [
            ('routes_mapping',    Priority.NORMAL,      add_routes_hook),
        ]
