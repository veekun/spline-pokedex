# encoding: utf8
import os.path
from pkg_resources import resource_filename

import markdown
import markdown.inlinepatterns
from pylons import config, tmpl_context as c
from routes import url_for as url
from sqlalchemy.orm.exc import NoResultFound

import pokedex.db
from pokedex.db.markdown import MarkdownString
import pokedex.db.tables as tables
import pokedex.lookup
import spline.lib.markdown
import splinext.pokedex.model
import splinext.pokedex.db
from splinext.pokedex import helpers as pokedex_helpers
import spline.lib.helpers as h
from spline.lib.plugin import PluginBase, PluginLink, Priority
from splinext.pokedex import i18n
from spline.lib.base import BaseController


def add_routes_hook(map, *args, **kwargs):
    """Hook to inject some of our behavior into the routes configuration."""
    map.connect('/dex/media/*path', controller='dex', action='media')
    map.connect('/dex/lookup', controller='dex', action='lookup')
    map.connect('/dex/suggest', controller='dex', action='suggest')
    map.connect('/dex/parse_size', controller='dex', action='parse_size')

    # These are more specific than the general pages below, so must be first
    map.connect('/dex/moves/search', controller='dex_search', action='move_search')
    map.connect('/dex/pokemon/search', controller='dex_search', action='pokemon_search')

    map.connect('/dex/abilities/{name}', controller='dex', action='abilities')
    map.connect('/dex/items/{pocket}', controller='dex', action='item_pockets')
    map.connect('/dex/items/{pocket}/{name}', controller='dex', action='items')
    map.connect('/dex/locations/{name}', controller='dex', action='locations')
    map.connect('/dex/moves/{name}', controller='dex', action='moves')
    map.connect('/dex/natures/{name}', controller='dex', action='natures')
    map.connect('/dex/pokemon/{name}', controller='dex', action='pokemon')
    map.connect('/dex/pokemon/{name}/flavor', controller='dex', action='pokemon_flavor')
    map.connect('/dex/pokemon/{name}/locations', controller='dex', action='pokemon_locations')
    map.connect('/dex/types/{name}', controller='dex', action='types')

    map.connect('/dex/abilities', controller='dex', action='abilities_list')
    map.connect('/dex/items', controller='dex', action='items_list')
    map.connect('/dex/natures', controller='dex', action='natures_list')
    map.connect('/dex/moves', controller='dex', action='moves_list')
    map.connect('/dex/pokemon', controller='dex', action='pokemon_list')
    map.connect('/dex/types', controller='dex', action='types_list')

    map.connect('/dex/gadgets/chain_breeding', controller='dex_gadgets', action='chain_breeding')
    map.connect('/dex/gadgets/compare_pokemon', controller='dex_gadgets', action='compare_pokemon')
    map.connect('/dex/gadgets/pokeballs', controller='dex_gadgets', action='capture_rate')
    map.connect('/dex/gadgets/stat_calculator', controller='dex_gadgets', action='stat_calculator')
    map.connect('/dex/gadgets/whos_that_pokemon', controller='dex_gadgets', action='whos_that_pokemon')

    # JSON API
    map.connect('/dex/api/pokemon', controller='dex_api', action='pokemon')

class PokedexBaseController(BaseController):
    def __before__(self, action, **params):
        super(PokedexBaseController, self).__before__(action, **params)

        identifier_query = splinext.pokedex.db.get_by_identifier_query
        try:
            c.language = identifier_query(tables.Language, c.lang or 'en').one()
        except NoResultFound:
            c.language = identifier_query(tables.Language, u'en').one()

        c.game_language = identifier_query(tables.Language, u'en').one()
        db.pokedex_session.default_language = c.game_language.id

    def __call__(self, *args, **params):
        """Run the controller, making sure to discard the Pokédex session when
        we're done.

        Stolen from the default Pylons lib.base.__call__.
        """
        try:
            return super(PokedexBaseController, self).__call__(*args, **params)
        finally:
            db.pokedex_session.remove()


### Extend markdown to turn [Eevee]{pokemon} into a link in effects and
### descriptions

class PokedexLinkPattern(markdown.inlinepatterns.Pattern):
    def __init__(self, table):
        """Generates a pattern-matcher for a type of link, given a table."""
        self.thingy_table = table
        self.thingy_type = table.__name__

        # Match [target]{tablename} and [label]{tablename:target}
        regex = ur'(?x) \[ ([^]]+) \] \s* \{' + table.__singlename__ + ur'(?: :([^}]+) )? \}'

        # old-style classes augh!
        markdown.inlinepatterns.Pattern.__init__(self, regex)

    def handleMatch(self, m):
        if m.group(3):
            # [A]{foo:B} -- A is the label, B is the target
            manual_label = m.group(2)
            target = m.group(3)
        else:
            # [A]{foo} -- A is the label and the target
            manual_label = None
            target = m.group(2)

        # Find the thingy and figure out its URL
        if self.thingy_type.lower() == u'pokemon':
            obj = splinext.pokedex.db.pokemon_query(target).one()
            name = obj.name
        else:
            obj = splinext.pokedex.db.get_by_name_query(self.thingy_table, target).one()
            name = obj.name
        url = pokedex_helpers.make_thingy_url(obj)

        # Construct a link node
        el = markdown.etree.Element('a')
        el.set('href', url)
        el.text = markdown.AtomicString(manual_label or name)
        return el

class PokedexMechanicsPattern(markdown.inlinepatterns.Pattern):
    """Matches [target]{mechanic} and [label]{mechanic:target}.  For now, this
    doesn't actually do anything.
    """
    def handleMatch(self, m):
        # Don't do anything for now
        el = markdown.etree.Element('span')
        el.text = markdown.AtomicString(m.group(2))
        return el

class PokedexExtension(markdown.Extension):
    """Plugs the [foo]{bar} syntax into the markdown parser."""
    def extendMarkdown(self, md, md_globals):
        for table in (tables.Ability, tables.Item, tables.Location,
                      tables.Move, tables.Pokemon, tables.Type):
            key = "pokedex-link-{table.__tablename__}".format(table=table)
            md.inlinePatterns[key] = PokedexLinkPattern(table)

        mechanics_regex = ur'(?x) \[ ([^]]+) \] \s* \{mechanic(?: :([^}]+) )?\}'
        md.inlinePatterns['pokedex-mechanics'] \
            = PokedexMechanicsPattern(mechanics_regex)


def after_setup_hook(config, *args, **kwargs):
    """Hook to do some housekeeping after the app starts."""
    # Connect to the database
    splinext.pokedex.db.connect(config)

    # Extend Markdown via monkey-patching..  boo  :(
    MarkdownString.markdown_extensions.append(PokedexExtension())

    # And extend spline's markdowning a slightly less terrible way
    spline.lib.markdown.register_extension(PokedexExtension())

def before_controller_hook(*args, **kwargs):
    """Hook to inject suggestion-box Javascript into every page."""
    c.javascripts.append(('pokedex', 'pokedex-suggestions'))


class PokedexPlugin(PluginBase):
    def __init__(self, *args, **kwargs):
        """Stuff our helper module in the Pylons h object."""
        super(PokedexPlugin, self).__init__(*args, **kwargs)

        # XXX should we really be doing this here?
        h.pokedex = pokedex_helpers

    def controllers(self):
        import splinext.pokedex.controllers.pokedex
        import splinext.pokedex.controllers.pokedex_api
        import splinext.pokedex.controllers.pokedex_search
        import splinext.pokedex.controllers.pokedex_gadgets

        return {
            'dex': controllers.pokedex.PokedexController,
            'dex_api': controllers.pokedex_api.PokedexAPIController,
            'dex_search': controllers.pokedex_search.PokedexSearchController,
            'dex_gadgets': controllers.pokedex_gadgets.PokedexGadgetsController,
        }

    def hooks(self):
        return [
            ('routes_mapping',    Priority.NORMAL, add_routes_hook),
            ('after_setup',       Priority.NORMAL, after_setup_hook),
            ('before_controller', Priority.NORMAL, before_controller_hook),
        ]

    def links(self):
        _ = unicode  # _ is a no-op here, only used for marking the texts for translation
        # Wrap PluginLink do that the correct translator is given
        # (Unfortunately it's too early in the bootstrapping process to actually translate now)
        def TranslatablePluginLink(*args, **kwargs):
            kwargs.setdefault('translator_class', i18n.Translator)
            return PluginLink(*args, **kwargs)
        # All good, return the structure now
        return [
            TranslatablePluginLink(_(u'Pokédex'), url('/dex'), children=[
                TranslatablePluginLink(_(u'Core pages'), None, children=[
                    TranslatablePluginLink(_(u'Pokémon'), url(controller='dex', action='pokemon_list'), i18n_context='plural', children=[
                        TranslatablePluginLink(_(u'Awesome search'), url(controller='dex_search', action='pokemon_search')),
                    ]),
                    TranslatablePluginLink(_(u'Moves'), url(controller='dex', action='moves_list'), children=[
                        TranslatablePluginLink(_(u'Awesome search'), url(controller='dex_search', action='move_search')),
                    ]),
                    TranslatablePluginLink(_(u'Types'), url(controller='dex', action='types_list')),
                    TranslatablePluginLink(_(u'Abilities'), url(controller='dex', action='abilities_list')),
                    TranslatablePluginLink(_(u'Items'), url(controller='dex', action='items_list')),
                    TranslatablePluginLink(_(u'Natures'), url(controller='dex', action='natures_list')),
                ]),
                TranslatablePluginLink(_(u'Gadgets'), None, children=[
                    TranslatablePluginLink(_(u'Compare Pokémon'), url(controller='dex_gadgets', action='compare_pokemon')),
                    TranslatablePluginLink(_(u'Pokéball performance'), url(controller='dex_gadgets', action='capture_rate')),
                    TranslatablePluginLink(_(u'Stat calculator'), url(controller='dex_gadgets', action='stat_calculator')),
                ]),
                TranslatablePluginLink(_(u'Etc.'), None, children=[
                    TranslatablePluginLink(_(u'Downloads'), url('/dex/downloads')),
                ]),
            ]),
        ]

    def widgets(self):
        return [
            ('page_header', Priority.NORMAL, 'widgets/pokedex_lookup.mako'),
            ('head_tag',    Priority.NORMAL, 'widgets/pokedex_suggestion_css.mako'),
        ]
