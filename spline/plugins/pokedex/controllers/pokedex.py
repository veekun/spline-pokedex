# encoding: utf8
from __future__ import absolute_import

import collections
import logging
import mimetypes

import pokedex.db
from pokedex.db.tables import Generation, Pokemon, Type
import pokedex.formulae
import pkg_resources
from pylons import config, request, response, session, tmpl_context as c
from pylons.controllers.util import abort, redirect_to
from routes import url_for, request_config
from sqlalchemy.orm.exc import NoResultFound

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render
from spline.plugins.pokedex import lib as dexlib

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

    def __before__(self, action, **params):
        super(PokedexController, self).__before__(action, **params)

        c.javascripts.append('pokedex')

        c.dexlib = dexlib
        c.dex_formulae = pokedex.formulae

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
        q = dexlib.session.query(Pokemon).filter_by(name=name)
        if forme == None:
            # "Basic" Formes still have names, but they don't have a base forme
            # id since they are already the base
            q = q.filter_by(forme_base_pokemon_id=None)

        try:
            c.pokemon = q.one()
        except NoResultFound:
            return self._not_found()

        # Some Javascript
        c.javascripts.append('pokedex.pokemon')

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
        c.heights = c.dexlib.scale_sizes(heights)
        weights = dict(pokemon=c.pokemon.weight, male=860, female=720)
        # Strictly speaking, weight takes three dimensions.  But the real
        # measurement here is just "space taken up", and these are sprites, so
        # the space they actually take up is two-dimensional.
        c.weights = c.dexlib.scale_sizes(weights, dimensions=2)

        ### Flavor text
        c.flavor_text = {}
        for pokemon_flavor_text in c.pokemon.flavor_text:
            c.flavor_text[pokemon_flavor_text.version.name] = pokemon_flavor_text.flavor_text

        ### Encounters
        # The table is sorted by location, then area, with each row containing
        # Diamond, Pearl, then Platinum locations.  Thus we build a dictionary:
        #   encounters[location_area][version] = [ ...list of methods... ]
        # The values will later become dictionaries; see below.
        encounters = {}
        # First, group the encounters by area/version
        for encounter in c.pokemon.encounters:
            encounters.setdefault(encounter.location_area, {}) \
                      .setdefault(encounter.version, []) \
                      .append(encounter)

        # Now we want to filter each group of encounters down to just the one
        # with the LEAST interesting catch method.  That is, if something shows
        # up during the day walking around, we don't care if it also shows up
        # while using the PokéRadar.
        # Note that we effectively HAVE to do this to avoid a lot of mucking
        # around.  If, say, a Pokémon appears in a condition-less slot with a
        # rarity of 10%, but ALSO appears another 5% of the time when the
        # PokéRadar is in use, we will naively report that as 5% from
        # PokéRadar.  But since we're discarding PokéRadar values as long as
        # the Pokémon still appears normally, this can't happen.
        for version_encounters in encounters.values():
            for version, encounter_list in version_encounters.items():
                # Group encounters by type and condition.  We need to both
                # drop everything with a low-priority condition and merge
                # "level 3, 20%" and "level 2, 10%" into just "level 2-3, 30%".
                # This requires scrapping the encounter objects for dicts so we
                # can mess with properties as we want.

                # type, condition => encounter_dict
                encounter_groups = collections.defaultdict(
                    lambda: dict(rarity=0, min_level=100, max_level=0)
                )
                # best_priority will end up as the lowest index in the 
                # encounter_method_order list at the top of this class.  Any
                # groups with this priority will survive and appear on the page
                best_priority = len(self.encounter_method_order)
                for encounter in encounter_list:
                    enc_dict = encounter_groups[encounter.slot.type,
                                                encounter.condition]
                    enc_dict['type'] = encounter.slot.type
                    if encounter.condition:
                        enc_dict['condition_group'] = encounter.condition.group
                    else:
                        enc_dict['condition_group'] = None

                    enc_dict['rarity'] += encounter.slot.rarity
                    enc_dict['min_level'] = min(enc_dict['min_level'],
                                                encounter.min_level)
                    enc_dict['max_level'] = max(enc_dict['max_level'],
                                                encounter.max_level)

                    # Find the priority for this group
                    if 'priority' not in enc_dict:
                        if encounter.condition:
                            condition_group = encounter.condition.group.name
                        else:
                            condition_group = None
                        priority = self.encounter_method_order.index(
                                   (encounter.slot.type.name, condition_group))
                        best_priority = min(best_priority, priority)
                        enc_dict['priority'] = priority

                for k, v in encounter_groups.items():
                    if v['priority'] != best_priority:
                        del encounter_groups[k]
                        continue

                    # Construct a level string; collapse "2 - 2" into "2"
                    if v['min_level'] == v['max_level']:
                        v['level'] = str(v['min_level'])
                    else:
                        v['level'] = "%d - %d" % (v['min_level'], v['max_level'])



                # We're going to use ONLY the first combination of encounter
                # type and condition group (e.g. 'swarm') that appears in 
                # XXX FILTER OUT TYPE/CONDITION KEYS WE DON'T WANT
                # We don't strip out different types, so surfing, fishing, and
                # walking can all coexist.  Only strip out walking conditions,
                # with the following order of prorities:
                #   none > time of day > swarm > radar > slot 2
                # I don't believe many (if any) encounters fall into more than
                # one of swarm/radar/slot 2, so the order there doesn't matter.
                # XXX:
                # Note that this approach also strips out times of day, even if
                # there are entries for all of morning/day/night.  Ought to use
                # default_condition here.

                # Give each type/condition combo a helpful icon
                for (type, condition), enc_dict in encounter_groups.items():
                    if type.name == 'Surfing':
                        # Lapras.  Hopefully this is obvious enough
                        enc_dict['icon_url'] = 'icons/131.png'
                    elif type.name == 'Fishing with Old Rod':
                        enc_dict['icon_url'] = 'items/old-rod.png'
                    elif type.name == 'Fishing with Good Rod':
                        enc_dict['icon_url'] = 'items/old-rod.png'
                    elif type.name == 'Fishing with Super Rod':
                        enc_dict['icon_url'] = 'items/old-rod.png'
                    elif condition == None:
                        enc_dict['icon_url'] = 'icons/0.png'
                    elif condition.name == 'Ruby':
                        enc_dict['icon_url'] = 'versions/ruby.png'
                    elif condition.name == 'Sapphire':
                        enc_dict['icon_url'] = 'versions/sapphire.png'
                    elif condition.name == 'Emerald':
                        enc_dict['icon_url'] = 'versions/emerald.png'
                    elif condition.name == 'Fire Red':
                        enc_dict['icon_url'] = 'versions/fire-red.png'
                    elif condition.name == 'Leaf Green':
                        enc_dict['icon_url'] = 'versions/leaf-green.png'
                    else:
                        enc_dict['icon_url'] = 'chrome/types/?????.png'

                # Replace the dumb list of encounters with our spiffy shortened
                # list
                version_encounters[version] = encounter_groups

        # The final structure looks like this:
        #   encounters[location_area][version][type, condition]
        #       = [dict(rarity=30, min_level=2, max_level=3), ...]
        # XXX NO IT SHOULDN'T; SHOULD BE
        #   encounters[location_area][version]
        #       = [dict(type=type, condition=condition,
        #               rarity=30, level="2-3"), ...]
        c.encounters = encounters

        return render('/pokedex/pokemon.mako')

    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = dexlib.session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon_flavor.mako')
