# encoding: utf8
from __future__ import absolute_import, division

from collections import defaultdict
import colorsys
from itertools import izip
from random import randint

import pokedex.db
import pokedex.db.tables as t
from pylons import request, tmpl_context as c
from pylons.controllers.util import abort
import sqlalchemy as sqla
from sqlalchemy.orm.exc import NoResultFound
import wtforms

from spline.lib.base import render
import spline.lib.helpers as h

from splinext.pokedex import PokedexBaseController
import splinext.pokedex.db as db

def bar_color(hue, pastelness):
    """Returns a color in the form #rrggbb that has the provided hue and
    lightness/saturation equal to the given "pastelness".
    """
    r, g, b = colorsys.hls_to_rgb(hue, pastelness, pastelness)
    return "#%02x%02x%02x" % (r * 256, g * 256, b * 256)

class LinkThresholdForm(wtforms.Form):
    """A form for specifying the threshold for max link tables on warrior and
    Pokémon pages.
    """

    link = wtforms.DecimalField(places=0, rounding='ROUND_UP')

class PokedexConquestController(PokedexBaseController):
    def _not_found(self):
        # XXX make this do fuzzy search or whatever
        abort(404)

    def _prev_next_id(self, thing, table, column_name):
        """Returns a 2-tuple of the previous and next thing by their IDs."""
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

    def _prev_next_name(self, table, current, filters=[]):
        """Figure out the previous/next thing for the navigation bar

        table: the table to select from
        current: list of the current values
        filters: a list of filter expressions for the table
        """
        name_table = table.__mapper__.get_property('names').argument
        query = (db.pokedex_session.query(table)
                .join(name_table)
                .filter(name_table.local_language == c.game_language)
            )

        for filter in filters:
            query = query.filter(filter)

        name_col = name_table.name
        name_current = current.name_map[c.game_language]

        lt = name_col < name_current
        gt = name_col > name_current
        asc = name_col.asc()
        desc = name_col.desc()

        # The previous thing is the biggest smaller, wrap around if
        # nothing comes before
        prev = query.filter(lt).order_by(desc).first()
        if prev is None:
            prev = query.order_by(desc).first()

        # Similarly for next
        next = query.filter(gt).order_by(asc).first()
        if next is None:
            next = query.order_by(asc).first()

        return prev, next


    def abilities(self, name):
        try:
            c.ability = db.get_by_name_query(t.Ability, name).one()
        except NoResultFound:
            return self._not_found()

        # XXX The ability might exist, but not in Conquest
        if not c.ability.conquest_pokemon:
            return self._not_found()

        c.prev_ability, c.next_ability = self._prev_next_name(
            t.Ability, c.ability,
            filters=[t.Ability.conquest_pokemon.any()])

        return render('/pokedex/conquest/ability.mako')

    def abilities_list(self):
        c.abilities = (db.pokedex_session.query(t.Ability)
            .join(t.Ability.names_local)
            .filter(t.Ability.conquest_pokemon.any())
            .order_by(t.Ability.names_table.name.asc())
            .all()
        )

        return render('/pokedex/conquest/ability_list.mako')


    def kingdoms(self, name):
        try:
            c.kingdom = db.get_by_name_query(t.ConquestKingdom, name).one()
        except NoResultFound:
            return self._not_found()

        # We have pretty much nothing for kingdoms.  Yet.
        c.prev_kingdom, c.next_kingdom = self._prev_next_id(
            c.kingdom, t.ConquestKingdom, 'id')

        return render('/pokedex/conquest/kingdom.mako')

    def kingdoms_list(self):
        c.kingdoms = (db.pokedex_session.query(t.ConquestKingdom)
            .options(
                sqla.orm.joinedload('type')
            )
            .order_by(t.ConquestKingdom.id)
            .all()
        )

        return render('/pokedex/conquest/kingdom_list.mako')


    def moves(self, name):
        try:
            c.move = (db.get_by_name_query(t.Move, name)
                .options(
                    sqla.orm.joinedload('conquest_data'),
                    sqla.orm.joinedload('conquest_pokemon'),
                    sqla.orm.subqueryload('conquest_pokemon.conquest_abilities'),
                    sqla.orm.subqueryload('conquest_pokemon.conquest_stats'),
                )
                .one())
        except NoResultFound:
            return self._not_found()

        if not c.move.conquest_pokemon:
            return self._not_found()

        ### Prev/next for header
        c.prev_move, c.next_move = self._prev_next_name(t.Move, c.move,
            filters=[t.Move.conquest_pokemon.any()])

        return render('/pokedex/conquest/move.mako')

    def moves_list(self):
        c.moves = (db.pokedex_session.query(t.Move)
            .filter(t.Move.conquest_data.has())
            .options(
                sqla.orm.joinedload('conquest_data'),
                sqla.orm.joinedload('conquest_data.move_displacement'),
            )
            .join(t.Move.names_local)
            .order_by(t.Move.names_table.name.asc())
            .all()
        )

        return render('/pokedex/conquest/move_list.mako')


    def pokemon(self, name=None):
        try:
            c.pokemon = db.pokemon_query(name, None).one()
        except NoResultFound:
            return self._not_found()

        c.semiform_pokemon = c.pokemon
        c.pokemon = c.pokemon.species

        # This Pokémon might exist, but not appear in Conquest
        if c.pokemon.conquest_order is None:
            return self._not_found()

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_id(
            c.pokemon, t.PokemonSpecies, 'conquest_order')

        ### Type efficacy
        c.type_efficacies = defaultdict(lambda: 100)
        for target_type in c.semiform_pokemon.types:
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
        family = (db.pokedex_session.query(t.PokemonSpecies)
            .filter(t.PokemonSpecies.evolution_chain_id ==
                    c.pokemon.evolution_chain_id)
            .options(
                sqla.orm.subqueryload('conquest_evolution'),
                sqla.orm.joinedload('conquest_evolution.stat'),
                sqla.orm.joinedload('conquest_evolution.kingdom'),
                sqla.orm.joinedload('conquest_evolution.gender'),
                sqla.orm.joinedload('conquest_evolution.item'),
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
        # XXX actually do things differently instead of just fudging the same
        #     thing to work
        c.stats = {}  # stat => { border, background, percentile }
        stat_total = 0
        total_stat_rows = db.pokedex_session.query(t.ConquestPokemonStat) \
            .filter_by(stat=c.pokemon.conquest_stats[0].stat) \
            .count()
        for pokemon_stat in c.pokemon.conquest_stats:
            stat_info = c.stats[pokemon_stat.stat.identifier] = {}

            stat_info['value'] = pokemon_stat.base_stat

            if pokemon_stat.stat.is_base:
                stat_total += pokemon_stat.base_stat

            q = db.pokedex_session.query(t.ConquestPokemonStat) \
                               .filter_by(stat=pokemon_stat.stat)
            less = q.filter(t.ConquestPokemonStat.base_stat <
                            pokemon_stat.base_stat).count()
            equal = q.filter(t.ConquestPokemonStat.base_stat ==
                             pokemon_stat.base_stat).count()
            percentile = (less + equal * 0.5) / total_stat_rows
            stat_info['percentile'] = percentile

            # Colors for the stat bars, based on percentile
            stat_info['background'] = bar_color(percentile, 0.9)
            stat_info['border'] = bar_color(percentile, 0.8)

        # Percentile for the total
        # Need to make a derived table that fakes pokemon_id, total_stats
        stat_sum_tbl = db.pokedex_session.query(
                sqla.sql.func.sum(t.ConquestPokemonStat.base_stat)
                .label('stat_total')
            ) \
            .filter(t.ConquestPokemonStat.conquest_stat_id <= 4) \
            .group_by(t.ConquestPokemonStat.pokemon_species_id) \
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
        # We only want to show warriors who have a max link above a certain
        # threshold, because there are 200 warriors and most of them won't
        # have very good links.
        default_link = 70
        c.link_form = LinkThresholdForm(request.params, link=default_link)
        if request.params and c.link_form.validate():
            link_threshold = c.link_form.link.data
        else:
            link_threshold = default_link

        # However, some warriors will only be above this threshold at later
        # ranks.  In these cases, we may as well show all ranks' links.
        # No link ever goes down when a warrior ranks up, so we just need to
        # check their final rank.

        # First, craft a clause to filter out non-final warrior ranks.
        ranks_sub = sqla.orm.aliased(t.ConquestWarriorRank)
        higher_ranks_exist = (sqla.sql.exists([1])
            .where(sqla.and_(
                ranks_sub.warrior_id == t.ConquestWarriorRank.warrior_id,
                ranks_sub.rank > t.ConquestWarriorRank.rank))
        )

        # Next, find final-rank warriors with a max link high enough.
        worthy_warriors = (db.pokedex_session.query(t.ConquestWarrior.id)
            .join(t.ConquestWarriorRank)
            .filter(~higher_ranks_exist)
            .join(t.ConquestMaxLink)
            .filter(t.ConquestMaxLink.pokemon_species_id == c.pokemon.id)
            .filter(t.ConquestMaxLink.max_link >= link_threshold))

        # For Froslass and Gallade, we want to filter out male and female
        # warriors, respectively.
        # XXX Eventually we want to figure out all impossible evolutions, and
        #     show them, but sort them to the bottom and grey them out.
        if (c.pokemon.conquest_evolution is not None and
          c.pokemon.conquest_evolution.warrior_gender_id is not None):
            worthy_warriors = worthy_warriors.filter(
                t.ConquestWarrior.gender_id ==
                    c.pokemon.conquest_evolution.warrior_gender_id)

        # Finally, find ALL the max links for these warriors!
        links_q = (c.pokemon.conquest_max_links
            .join(ranks_sub)
            .filter(ranks_sub.warrior_id.in_(worthy_warriors))
            .options(
                sqla.orm.joinedload('warrior_rank'),
                sqla.orm.subqueryload('warrior_rank.stats'),
                sqla.orm.joinedload('warrior_rank.warrior'),
                sqla.orm.joinedload('warrior_rank.warrior.archetype'),
                sqla.orm.subqueryload('warrior_rank.warrior.types'),
            ))

        c.max_links = links_q.all()


        return render('/pokedex/conquest/pokemon.mako')

    def pokemon_list(self):
        c.pokemon = (db.pokedex_session.query(t.PokemonSpecies)
            .filter(t.PokemonSpecies.conquest_order != None)
            .options(
                sqla.orm.subqueryload('conquest_abilities'),
                sqla.orm.joinedload('conquest_move'),
                sqla.orm.subqueryload('conquest_stats'),
                sqla.orm.subqueryload('default_pokemon.types')
            )
            .order_by(t.PokemonSpecies.conquest_order)
            .all()
        )

        return render('/pokedex/conquest/pokemon_list.mako')


    def skills(self, name):
        try:
            c.skill = (db.get_by_name_query(t.ConquestWarriorSkill, name)
                .one())
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        c.prev_skill, c.next_skill = self._prev_next_name(
            t.ConquestWarriorSkill, c.skill)

        return render('/pokedex/conquest/skill.mako')

    def skills_list(self):
        skills = (db.pokedex_session.query(t.ConquestWarriorSkill)
            .join(t.ConquestWarriorSkill.names_local)
            .order_by(t.ConquestWarriorSkill.names_table.name.asc()))

        # We want to split the list up between generic skills anyone can get
        # and the unique skills a specific warlord gets at a specific rank.
        # The two player characters throw a wrench in that though so we just
        # assume any skill known only by warlords is unique, which happens to
        # work.
        warriors_and_ranks = sqla.orm.join(t.ConquestWarrior,
                                           t.ConquestWarriorRank)

        generic_clause = (sqla.sql.exists(warriors_and_ranks.select())
            .where(sqla.and_(
                t.ConquestWarrior.archetype_id != None,
                t.ConquestWarriorRank.skill_id ==
                    t.ConquestWarriorSkill.id))
        )


        c.generic_skills = skills.filter(generic_clause).all()
        c.unique_skills = (skills.filter(~generic_clause)
            .options(
                sqla.orm.joinedload('warrior_ranks'),
                sqla.orm.joinedload('warrior_ranks.warrior')
            )
            .all())

        # Decide randomly which player gets displayed
        c.player_index = randint(0, 1)

        return render('/pokedex/conquest/skill_list.mako')


    def warriors(self, name):
        try:
            c.warrior = db.get_by_name_query(t.ConquestWarrior, name).one()
        except NoResultFound:
            return self._not_found()

        c.prev_warrior, c.next_warrior = self._prev_next_id(
            c.warrior, t.ConquestWarrior, 'id')

        c.rank_count = len(c.warrior.ranks)

        c.perfect_links = (c.warrior.ranks[-1].max_links
            .filter_by(max_link=100)
            .join(t.PokemonSpecies)
            .order_by(t.PokemonSpecies.conquest_order)
            .all())

        ### Stats
        # Percentiles!  Percentiles are hard.
        stats = t.ConquestWarriorRankStatMap
        all_stats = sqla.orm.aliased(t.ConquestWarriorRankStatMap)

        # We need this to be a float so the percentile equation can divide by it
        stat_count = sqla.cast(sqla.func.count(all_stats.base_stat),
            sqla.types.FLOAT)

        # Grab all of a rank's stats, and also get percentiles
        stat_q = (db.pokedex_session.query(stats.warrior_stat_id, stats.base_stat)
            .join(all_stats, stats.warrior_stat_id == all_stats.warrior_stat_id)
            .group_by(stats.warrior_rank_id, stats.warrior_stat_id,
                      stats.base_stat)
            .order_by(stats.warrior_stat_id)
            .add_columns(
                sqla.func.sum(sqla.cast(stats.base_stat > all_stats.base_stat,
                    sqla.types.INT)) / stat_count +
                sqla.func.sum(sqla.cast(stats.base_stat == all_stats.base_stat,
                    sqla.types.INT)) / stat_count / 2
            )
        )

        # XXX There's probably a better way to query all the names
        stat_names = [stat.name for stat in
            db.pokedex_session.query(t.ConquestWarriorStat)
            .order_by(t.ConquestWarriorStat.id)
            .all()]

        # Go through the query for each rank
        c.stats = []
        for rank in c.warrior.ranks:
            c.stats.append([])
            info = stat_q.filter(stats.warrior_rank_id == rank.id).all()

            # We need a bit more info than what the query directly provides
            for stat, value, percentile in info:
                percentile = float(percentile)
                c.stats[-1].append((
                    stat_names[stat - 1], value, percentile,
                    bar_color(percentile, 0.9), bar_color(percentile, 0.8)
                ))


        ### Max links
        default_link = 70 if c.warrior.archetype else 90

        c.link_form = LinkThresholdForm(request.params, link=default_link)
        if request.params and c.link_form.validate():
            link_threshold = c.link_form.link.data
        else:
            link_threshold = default_link

        link_pokemon = (
            db.pokedex_session.query(t.ConquestMaxLink.pokemon_species_id)
            .filter(t.ConquestMaxLink.warrior_rank_id ==
                    c.warrior.ranks[-1].id)
            .filter(t.ConquestMaxLink.max_link >= link_threshold)
        )

        max_links = []
        for rank in c.warrior.ranks:
            max_links.append(rank.max_links
                .filter(t.ConquestMaxLink.pokemon_species_id
                        .in_(link_pokemon))
                .join(t.PokemonSpecies)
                .order_by(t.PokemonSpecies.conquest_order)
                .options(
                    sqla.orm.joinedload('pokemon'),
                    sqla.orm.subqueryload('pokemon.conquest_abilities'),
                    sqla.orm.subqueryload('pokemon.conquest_stats'),
                )
                .all())

        c.max_links = izip(*max_links)

        return render('/pokedex/conquest/warrior.mako')

    def warriors_list(self):
        c.warriors = (db.pokedex_session.query(t.ConquestWarrior)
            .options(
                sqla.orm.subqueryload('ranks'),
                sqla.orm.subqueryload('ranks.stats'),
                sqla.orm.subqueryload('types')
            )
            .order_by(t.ConquestWarrior.id)
            .all()
        )

        return render('/pokedex/conquest/warrior_list.mako')
