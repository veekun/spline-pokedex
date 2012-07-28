# encoding: utf8
from __future__ import absolute_import, division

from collections import defaultdict
import colorsys
import logging

import pokedex.db
import pokedex.db.tables as tables
from pylons import request, tmpl_context as c
from pylons.controllers.util import abort
import sqlalchemy as sqla
from sqlalchemy.orm import aliased, eagerload, eagerload_all, joinedload, subqueryload
import sqlalchemy.orm
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import exists, func

from spline.lib.base import render

from splinext.pokedex import PokedexBaseController
import splinext.pokedex.db as db

log = logging.getLogger(__name__)

def bar_color(hue, pastelness):
    """Returns a color in the form #rrggbb that has the provided hue and
    lightness/saturation equal to the given "pastelness".
    """
    r, g, b = colorsys.hls_to_rgb(hue, pastelness, pastelness)
    return "#%02x%02x%02x" % (r * 256, g * 256, b * 256)

class PokedexConquestController(PokedexBaseController):
    def _not_found(self):
        # XXX make this do fuzzy search or whatever
        abort(404)

    def _prev_next_id(self, thing, table, column_name):
        """Returns a 2-tuple of the previous and next kingdom."""
        column = getattr(table, column_name)
        thing_id = getattr(thing, column_name)

        max_id = (db.pokedex_session.query(table)
                  .filter(column != None)
                  .count())
        prev_thing = db.pokedex_session.query(table).filter(
            column == (thing_id - 1 - 1) % max_id + 1).one()
        next_thing = db.pokedex_session.query(table).filter(
            column == (thing_id - 1 + 1) % max_id + 1).one()

        return prev_thing, next_thing

    def kingdoms(self, name):
        try:
            c.kingdom = db.get_by_name_query(tables.ConquestKingdom, name).one()
        except NoResultFound:
            return self._not_found()

        # We have pretty much nothing for kingdoms.  Yet.
        c.prev_kingdom, c.next_kingdom = self._prev_next_id(c.kingdom, tables.ConquestKingdom, 'id')

        return render('/pokedex/conquest/kingdom.mako')

    def pokemon(self, name=None):
        try:
            pokemon_q = db.pokemon_query(name, None)

            pokemon_q = pokemon_q.options(
                eagerload('species'),
            )

            c.pokemon = pokemon_q.one()
        except NoResultFound:
            return self._not_found()

        c.struct_pokemon = c.pokemon
        c.pokemon = c.pokemon.species

        if c.pokemon.conquest_order is None:
            return self._not_found()

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_id(c.pokemon, tables.PokemonSpecies, 'conquest_order')

        ### Type efficacy
        c.type_efficacies = defaultdict(lambda: 100)
        for target_type in c.struct_pokemon.types:
            for type_efficacy in target_type.target_efficacies:
                c.type_efficacies[type_efficacy.damage_type] *= \
                    type_efficacy.damage_factor

                # The defaultdict starts at 100, and every damage factor is
                # a percentage.  Dividing by 100 with every iteration turns the
                # damage factor into a decimal percentage taken of the starting
                # 100, without using floats and regardless of number of types
                c.type_efficacies[type_efficacy.damage_type] //= 100


        ### Evolution
        # Shamelessly lifted from the main controller and tweaked.
        #
        # Format is a matrix as follows:
        # [
        #   [ None, Eevee, Vaporeon, None ]
        #   [ None, None, Jolteon, None ]
        #   [ None, None, Flareon, None ]
        #   ... etc ...
        # ]
        # That is, each row is a physical row in the resulting table, and each
        # contains four elements, one per row: Baby, Base, Stage 1, Stage 2.
        # The Pokémon are actually dictionaries with 'pokemon' and 'span' keys,
        # where the span is used as the HTML cell's rowspan -- e.g., Eevee has a
        # total of seven descendents, so it would need to span 7 rows.
        c.evolution_table = []
        # Prefetch the evolution details
        family = (db.pokedex_session.query(tables.PokemonSpecies) 
            .filter(tables.PokemonSpecies.evolution_chain_id ==
                    c.pokemon.evolution_chain_id)
            .options(
                subqueryload('conquest_evolution'),
                joinedload('conquest_evolution.stat'),
                joinedload('conquest_evolution.kingdom'),
                joinedload('conquest_evolution.gender'),
                joinedload('conquest_evolution.item'),
            )
            .all())
        # Strategy: build this table going backwards.
        # Find a leaf, build the path going back up to its root.  Remember all
        # of the nodes seen along the way.  Find another leaf not seen so far.
        # Build its path backwards, sticking it to a seen node if one exists.
        # Repeat until there are no unseen nodes.
        seen_nodes = {}
        while True:
            # First, find some unseen nodes
            unseen_leaves = []
            for species in family:
                if species in seen_nodes:
                    continue

                children = []
                # A Pokémon is a leaf if it has no evolutionary children, so...
                for possible_child in family:
                    if possible_child in seen_nodes:
                        continue
                    if possible_child.parent_species == species:
                        children.append(possible_child)
                if len(children) == 0:
                    unseen_leaves.append(species)

            # If there are none, we're done!  Bail.
            # Note that it is impossible to have any unseen non-leaves if there
            # are no unseen leaves; every leaf's ancestors become seen when we
            # build a path to it.
            if len(unseen_leaves) == 0:
                break

            unseen_leaves.sort(key=lambda x: x.id)
            leaf = unseen_leaves[0]

            # root, parent_n, ... parent2, parent1, leaf
            current_path = []

            # Finally, go back up the tree to the root
            current_species = leaf
            while current_species:
                # The loop bails just after current_species is no longer the
                # root, so this will give us the root after the loop ends;
                # we need to know if it's a baby to see whether to indent the
                # entire table below
                root_pokemon = current_species

                if current_species in seen_nodes:
                    current_node = seen_nodes[current_species]
                    # Don't need to repeat this node; the first instance will
                    # have a rowspan
                    current_path.insert(0, None)
                else:
                    current_node = {
                        'species': current_species,
                        'span':    0,
                    }
                    current_path.insert(0, current_node)
                    seen_nodes[current_species] = current_node

                # This node has one more row to span: our current leaf
                current_node['span'] += 1

                current_species = current_species.parent_species

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


        ### Stats
        # Conquest has a nonstandard stat, Range, which shouldn't be included
        # in the total, so we have to do things a bit differently.
        c.stats = {}  # stat => { border, background, percentile }
        stat_total = 0
        total_stat_rows = db.pokedex_session.query(tables.ConquestPokemonStat) \
                                         .filter_by(stat=c.pokemon.conquest_stats[0].stat) \
                                         .count()
        for pokemon_stat in c.pokemon.conquest_stats:
            stat_info = c.stats[pokemon_stat.stat.identifier] = {}

            stat_info['value'] = pokemon_stat.base_stat

            if pokemon_stat.stat.is_base:
                stat_total += pokemon_stat.base_stat

            q = db.pokedex_session.query(tables.ConquestPokemonStat) \
                               .filter_by(stat=pokemon_stat.stat)
            less = q.filter(tables.ConquestPokemonStat.base_stat < pokemon_stat.base_stat) \
                    .count()
            equal = q.filter(tables.ConquestPokemonStat.base_stat == pokemon_stat.base_stat) \
                     .count()
            percentile = (less + equal * 0.5) / total_stat_rows
            stat_info['percentile'] = percentile

            # Colors for the stat bars, based on percentile
            stat_info['background'] = bar_color(percentile, 0.9)
            stat_info['border'] = bar_color(percentile, 0.8)

        # Percentile for the total
        # Need to make a derived table that fakes pokemon_id, total_stats
        stat_sum_tbl = db.pokedex_session.query(
                func.sum(tables.ConquestPokemonStat.base_stat).label('stat_total')
            ) \
            .filter(tables.ConquestPokemonStat.conquest_stat_id <= 4) \
            .group_by(tables.ConquestPokemonStat.pokemon_species_id) \
            .subquery()

        q = db.pokedex_session.query(stat_sum_tbl)
        less = q.filter(stat_sum_tbl.c.stat_total < stat_total).count()
        equal = q.filter(stat_sum_tbl.c.stat_total == stat_total).count()
        percentile = (less + equal * 0.5) / total_stat_rows
        c.stats['total'] = {
            'percentile': percentile,
            'value': stat_total,
            'background': bar_color(percentile, 0.9),
            'border': bar_color(percentile, 0.8),
        }

        ### Max links
        c.link_threshold = int(request.params.get('link', 70))

        links_q = (c.pokemon.conquest_max_links
            .options(
                eagerload('warrior_rank'),
                eagerload('warrior_rank.skill'),
                eagerload('warrior_rank.warrior'),
                eagerload('warrior_rank.warrior.types'),
                eagerload('warrior_rank.warrior.names')
            ))

        c.max_links = links_q.all()


        return render('/pokedex/conquest/pokemon.mako')
