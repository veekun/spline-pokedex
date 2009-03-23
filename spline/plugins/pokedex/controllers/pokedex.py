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

    def __before__(self):
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

        # Type efficacy
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

        # Evolution
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
            current_path.insert(0, '')
            # Now pad to four if necessary.
            while len(current_path) < 4:
                current_path.append('')

            c.evolution_table.append(current_path)

        # Sizing
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

        # Flavor text
        c.flavor_text = {}
        for pokemon_flavor_text in c.pokemon.flavor_text:
            c.flavor_text[pokemon_flavor_text.version.name] = pokemon_flavor_text.flavor_text

        return render('/pokedex/pokemon.mako')

    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = dexlib.session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon_flavor.mako')
