# encoding: utf8
from __future__ import absolute_import

import collections
import logging
import mimetypes

import pokedex.db
from pokedex.db.tables import Generation, Pokemon, Type
import pkg_resources
from pylons import config, request, response, session, tmpl_context as c
from pylons.controllers.util import abort, redirect_to
from routes import url_for, request_config
from sqlalchemy.orm.exc import NoResultFound

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render

from spline.plugins.pokedex import helpers as pokedex_helpers
from spline.plugins.pokedex.lib import session as pokedex_session

log = logging.getLogger(__name__)

class PokedexController(BaseController):

    # List of (slot_type.name, condition_group.name)
    # These are ordered roughly in increasing order of inconvenience and when
    # in the game they become available -- i.e. it's arbitrary
    encounter_method_order = [
        ('Walking in grass/caves', None),
        ('Walking in grass/caves', u'Time of day'),
        ('Fishing with Old Rod', None),
        ('Fishing with Good Rod', None),
        ('Surfing', None),
        ('Fishing with Super Rod', None),
        ('Walking in grass/caves', u'Swarm'),
        ('Walking in grass/caves', u'Gen 3 game in slot 2'),
        ('Walking in grass/caves', u'PokéRadar'),
    ]

    # Dict of type/condition name => icon path
    # Key is condition name if one exists; otherwise type name
    encounter_method_icons = {
        # Encounter types, no special conditions
        'Surfing': 'chrome/surf.png',
        'Fishing with Old Rod': 'items/old-rod.png',
        'Fishing with Good Rod': 'items/good-rod.png',
        'Fishing with Super Rod': 'items/super-rod.png',
        'Walking in grass/caves': 'chrome/grass.png',

        # Conditions
        'During a swarm': 'items/teachy-tv.png',
        'Morning': 'chrome/morning.png',
        'Day': 'chrome/daytime.png',
        'Night': 'chrome/night.png',
        u'Using PokéRadar': 'items/poke-radar.png',
        'Ruby': 'versions/ruby.png',
        'Sapphire': 'versions/sapphire.png',
        'Emerald': 'versions/emerald.png',
        'Fire Red': 'versions/fire-red.png',
        'Leaf Green': 'versions/leaf-green.png',
    }

    def __before__(self, action, **params):
        super(PokedexController, self).__before__(action, **params)

        c.javascripts.append(('pokedex', 'pokedex'))

    def __call__(self, *args, **params):
        """Run the controller, making sure to discard the Pokédex session when
        we're done.

        This is largely copied from the default Pylons lib.base.__call__.
        """
        try:
            return super(PokedexController, self).__call__(*args, **params)
        finally:
            pokedex_session.remove()

    def index(self):
        return ''

    def media(self, path):
        (mimetype, whatever) = mimetypes.guess_type(path)
        response.headers['content-type'] = mimetype
        pkg_path = "data/media/%s" % path
        return pkg_resources.resource_string('pokedex', pkg_path)

    def _not_found(self):
        # XXX make this do fuzzy search or whatever
        abort(404)

    def pokemon(self, name=None, forme=None):
        q = pokedex_session.query(Pokemon).filter_by(name=name)
        if forme == None:
            # "Basic" Formes still have names, but they don't have a base forme
            # id since they are already the base
            q = q.filter_by(forme_base_pokemon_id=None)

        try:
            c.pokemon = q.one()
        except NoResultFound:
            return self._not_found()

        # Some Javascript
        c.javascripts.append(('pokedex', 'pokemon'))

        ### Type efficacy
        c.type_efficacies = collections.defaultdict(lambda: 100)
        for target_type in c.pokemon.types:
            for type_efficacy in target_type.target_efficacies:
                c.type_efficacies[type_efficacy.damage_type] *= \
                    type_efficacy.damage_factor

                # The defaultdict starts at 100, and every damage factor is
                # a percentage.  Dividing by 100 with every iteration turns the
                # damage factor into a decimal percentage taken of the starting
                # 100, without using floats and regardless of number of types
                c.type_efficacies[type_efficacy.damage_type] /= 100

        ### Evolution
        # Format is a matrix as follows:
        # [
        #   [ None, Eevee, Vaporeon, None ]
        #   [ None, None, Jolteon, None ]
        #   [ None, None, Flareon, None ]
        #   ... etc ...
        # ]
        # That is, each row is a physical row in the resulting table, and each
        # contains four elements, one per row: Baby, Base, Stage 1, Stage 2.
        # The Pokemon are actually dictionaries with 'pokemon' and 'span' keys,
        # where the span is used as the HTML cell's rowspan -- e.g., Eevee has a
        # total of seven descendents, so it would need to span 7 rows.
        c.evolution_table = []
        family = c.pokemon.evolution_chain.pokemon
        # Strategy: build this table going backwards.
        # Find a leaf, build the path going back up to its root.  Remember all
        # of the nodes seen along the way.  Find another leaf not seen so far.
        # Build its path backwards, sticking it to a seen node if one exists.
        # Repeat until there are no unseen nodes.
        seen_nodes = {}
        while True:
            # First, find some unseen nodes
            unseen_leaves = []
            for pokemon in family:
                if pokemon in seen_nodes:
                    continue

                children = []
                # A Pokemon is a leaf if it has no evolutionary children, so...
                for possible_child in family:
                    if possible_child in seen_nodes:
                        continue
                    if possible_child.evolution_parent == pokemon:
                        children.append(possible_child)
                if len(children) == 0:
                    unseen_leaves.append(pokemon)

            # If there are none, we're done!  Bail.
            # Note that it is impossible to have any unseen non-leaves if there
            # are no unseen leaves; every leaf's ancestors become seen when we
            # build a path to it.
            if len(unseen_leaves) == 0:
                break

            # Go in order by id; arbitrary, but should DTRT given how numbering
            # tends to work.  This will put Vaporeon before Jolteon, etc.
            unseen_leaves.sort(key=lambda x: x.id)
            leaf = unseen_leaves[0]

            # root, parent_n, ... parent2, parent1, leaf
            current_path = []

            # Finally, go back up the tree to the root
            current_pokemon = leaf
            while current_pokemon:
                # The loop bails just after current_pokemon is no longer the
                # root, so this will give us the root after the loop ends;
                # we need to know if it's a baby to see whether to indent the
                # entire table below
                root_pokemon = current_pokemon

                if current_pokemon in seen_nodes:
                    current_node = seen_nodes[current_pokemon]
                    # Don't need to repeat this node; the first instance will
                    # have a rowspan
                    current_path.insert(0, None)
                else:
                    current_node = {
                        'pokemon': current_pokemon,
                        'span':    0,
                    }
                    current_path.insert(0, current_node)
                    seen_nodes[current_pokemon] = current_node

                # This node has one more row to span: our current leaf
                current_node['span'] += 1

                current_pokemon = current_pokemon.evolution_parent

            # We want every path to have four nodes: baby, basic, stage 1 and 2.
            # Every root node is basic, unless it's defined as being a baby.
            # So first, add an empty baby node at the beginning if this is not
            # a baby.
            # We use an empty string to indicate an empty cell, as opposed to a
            # complete lack of cell due to a tall cell from an earlier row.
            if not root_pokemon.is_baby:
                current_path.insert(0, '')
            # Now pad to four if necessary.
            while len(current_path) < 4:
                current_path.append('')

            c.evolution_table.append(current_path)

        ### Sizing
        # Note that these are totally hardcoded average sizes in Pokemon units:
        # Male: 17.5 dm, 860 hg
        # Female: 16 dm, 720 hg
        heights = dict(pokemon=c.pokemon.height, male=17.5, female=16)
        c.heights = pokedex_helpers.scale_sizes(heights)
        weights = dict(pokemon=c.pokemon.weight, male=860, female=720)
        # Strictly speaking, weight takes three dimensions.  But the real
        # measurement here is just "space taken up", and these are sprites, so
        # the space they actually take up is two-dimensional.
        c.weights = pokedex_helpers.scale_sizes(weights, dimensions=2)

        ### Flavor text
        c.flavor_text = {}
        for pokemon_flavor_text in c.pokemon.flavor_text:
            c.flavor_text[pokemon_flavor_text.version.name] = pokemon_flavor_text.flavor_text

        ### Encounters
        # The table is sorted by location, then area, with each row containing
        # Diamond, Pearl, then Platinum locations.  Thus we build a dictionary:
        #   encounters[location_area][version]
        #       = [dict(type=type, condition=condition,
        #               rarity=30, level="2-3"), ...]
        encounters = {}

        # We want to filter each group of encounters down to just the one(s)
        # with the LEAST interesting catch method.  That is, if something shows
        # up during the day walking around, we don't care if it also shows up
        # while using the PokéRadar.
        # Note that we effectively HAVE to do this to avoid a lot of mucking
        # around.  If, say, a Pokémon appears in a condition-less slot with a
        # rarity of 10%, but ALSO appears another 5% of the time when the
        # PokéRadar is in use, we will naively report that as 5% from
        # PokéRadar.  But since we're discarding PokéRadar values as long as
        # the Pokémon still appears normally, this can't happen.
        # We accomplish all this by only tracking the least-interesting methods
        # seen so far, and wiping the list if we see an even less interesting
        # one later for a given area/version.
        # XXX: Note that this approach also strips out times of day, even if
        # there are entries for all of morning/day/night.  Does that happen?
        # (Don't think so.)  Is there a sane fix?
        for encounter in c.pokemon.encounters:
            # Long way to say encounters[location_area][version], with defaults
            method_list = encounters.setdefault(encounter.location_area, {}) \
                                    .setdefault(encounter.version, [])

            # Find priority for this combination of slot/condition.
            # Priorities are the encounter_method_order at the top of the class
            condition_group = None
            if encounter.condition:
                condition_group = encounter.condition.group.name
            priority = self.encounter_method_order.index(
                           (encounter.slot.type.name, condition_group))

            if not method_list or priority == method_list[0]['priority']:
                # Same priority; just add this encounter to what we have
                pass
            elif priority > method_list[0]['priority']:
                # Worse priority: already have something better, so skip this
                continue
            elif priority < method_list[0]['priority']:
                # Better priority: better than what we have, so nuke them
                method_list[0:len(method_list)] = []

            # Find the dictionary for this type/condition and create/update it
            method_dicts = filter(lambda x: x['condition'] == encounter.condition
                                        and x['type'] == encounter.slot.type,
                                  method_list)
            if method_dicts:
                method_dict = method_dicts[0]
                method_dict['rarity'] += encounter.slot.rarity
                method_dict['min_level'] = min(method_dict['min_level'],
                                               encounter.min_level)
                method_dict['max_level'] = max(method_dict['max_level'],
                                               encounter.max_level)
            else:
                method_dict = dict(type=encounter.slot.type,
                                   condition=encounter.condition,
                                   min_level=encounter.min_level,
                                   max_level=encounter.max_level,
                                   rarity=encounter.slot.rarity,
                                   priority=priority,
                                   )
                method_list.append(method_dict)

        # Do some post-formatting on the method dictionaries: add icons
        # representing each method, and collapse the level range into a single
        # string
        for version_encounters in encounters.values():
            for method_list in version_encounters.values():
                for method_dict in method_list:
                    # Construct a level string; collapse "2 - 2" into "2"
                    if method_dict['min_level'] == method_dict['max_level']:
                        method_dict['level'] = str(method_dict['min_level'])
                    else:
                        method_dict['level'] = "%(min_level)d–%(max_level)d" \
                                             % method_dict

                    type = method_dict['type']
                    condition = method_dict['condition']

                    # Give each type/condition combo a helpful icon
                    if method_dict['condition']:
                        key = method_dict['condition'].name
                    else:
                        key = method_dict['type'].name

                    method_dict['name'] = key
                    method_dict['icon'] = self.encounter_method_icons \
                                              .get(key, 'icons/0.png')

                # Sort the method dicts so they come out in consistent order
                method_list.sort(key=lambda x: x['name'])

                # Merge identical RSEFL into one Gen3 row.  The following
                # approach assumes that RSEFL will only appear alone, which is
                # true since only one condition can appear
                condition_names = [x['condition'].name for x in method_list
                                                       if x['condition']]
                if set(condition_names) == set(['Ruby', 'Sapphire', 'Emerald',
                                           'Fire Red', 'Leaf Green']):
                    del method_list[1:]
                    method_list[0]['icon'] = 'versions/generation-3.png'
                    method_list[0]['name'] = 'Gen 3 game in slot 2'

        # And finally stuff this monstrosity into the template stash
        c.encounters = encounters

        return render('/pokedex/pokemon.mako')

    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = pokedex_session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon_flavor.mako')
