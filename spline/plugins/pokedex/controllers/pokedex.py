# encoding: utf8
from __future__ import absolute_import, division

import collections
import colorsys
import logging
import mimetypes

import pokedex.db
from pokedex.db.tables import Ability, EggGroup, Generation, Item, Move, MoveFlagType, Pokemon, PokemonEggGroup, PokemonFormSprite, PokemonMove, PokemonStat, Type, VersionGroup
import pokedex.lookup
import pkg_resources
from pylons import config, request, response, session, tmpl_context as c
from pylons.controllers.util import abort, redirect_to
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render

from spline.plugins.pokedex import db, helpers as pokedex_helpers
from spline.plugins.pokedex.db import pokedex_session

log = logging.getLogger(__name__)

def bar_color(hue, pastelness):
    """Returns a color in the form #rrggbb that has the provided hue and
    lightness/saturation equal to the given "pastelness".
    """
    r, g, b = colorsys.hls_to_rgb(hue, pastelness, pastelness)
    return "#%02x%02x%02x" % (r * 256, g * 256, b * 256)


class PokedexController(BaseController):

    # Used by lookup disambig pages
    table_labels = {
        Ability: 'ability',
        Item: 'item',
        Move: 'move',
        Pokemon: 'Pokémon',
        Type: 'type',
    }

    # List of (slot_type.name, condition_group.name)
    # These are ordered roughly in increasing order of inconvenience and when
    # in the game they become available -- i.e. it's arbitrary
    encounter_method_order = [
        ('Walking in grass/caves', None),
        ('Walking in grass/caves', u'Time of day'),
        ('Rock Smash', None),
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
        u'Using PokéRadar': 'items/poké-radar.png',
        'Ruby': 'versions/ruby.png',
        'Sapphire': 'versions/sapphire.png',
        'Emerald': 'versions/emerald.png',
        'Fire Red': 'versions/fire-red.png',
        'Leaf Green': 'versions/leaf-green.png',
    }

    def __before__(self, action, **params):
        super(PokedexController, self).__before__(action, **params)

        c.javascripts.append(('pokedex', 'lib/jquery.cookie'))
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

    def lookup(self):
        """Find a page in the Pokédex given a name.

        Also performs fuzzy search.
        """
        name = request.params.get('lookup', None)
        name = name.strip()

        ### Special stuff that bypasses lookup
        if name.lower() == 'obdurate':
            # Pokémon flavor text in the D/P font
            return self._egg_unlock_cheat('obdurate')


        ### Regular lookup
        results = pokedex.lookup.lookup(
            name,
            session=pokedex_session,
            indices=config['spline.pokedex.index'],
        )

        if len(results) == 0:
            # Nothing found
            # XXX real error page
            return self._not_found()

        elif len(results) == 1:
            # Only one possibility!  Hooray!

            if not results[0].exact:
                # Wasn't an exact match, but we can only figure out one thing
                # the user might have meant, so redirect to it anyway
                # XXX add an informative message here
                pass

            # Using the table name as an action directly looks kinda gross, but
            # I can't think of anywhere I've ever broken this convention, and
            # making a dictionary to get data I already have is just silly
            form = {}
            if getattr(results[0].object, 'forme_base_pokemon_id', None):
                form['form'] = results[0].object.forme_name
            redirect_to(controller='dex',
                        action=results[0].object.__tablename__,
                        name=results[0].object.name.lower(),
                        **form)

        else:
            # Multiple matches.  Could be exact (e.g., Metronome) or a fuzzy
            # match.  Result page looks about the same either way
            c.input = name
            c.exact = results[0].exact
            c.results = results
            c.table_labels = self.table_labels
            return render('/pokedex/lookup_results.mako')

    def _not_found(self):
        # XXX make this do fuzzy search or whatever
        abort(404)


    def _egg_unlock_cheat(self, cheat):
        """Easter egg that writes Pokédex data in the Pokémon font."""
        cheat_key = "cheat_%s" % cheat
        session[cheat_key] = not session.get(cheat_key, False)
        session.save()
        c.this_cheat_key = cheat_key
        return render('/pokedex/cheat_unlocked.mako')


    def pokemon(self, name=None):
        form = request.params.get('form', None)
        try:
            c.pokemon = db.pokemon(name, form=form)
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
                c.type_efficacies[type_efficacy.damage_type] //= 100

        ### Breeding compatibility
        # To simplify this list considerably, we want to find the BASE FORM of
        # every Pokémon compatible with this one.  The base form is either:
        # - a Pokémon that has breeding groups and no evolution parent, or
        # - a Pokémon whose parent has no breeding groups (i.e. 15 only)
        #   and no evolution parent.
        # The below query self-joins `pokemon` to itself and tests the above
        # conditions.
        # ASSUMPTION: Every base-form Pokémon in a breedable family can breed.
        # ASSUMPTION: Every family has the same breeding groups throughout.
        if c.pokemon.gender_rate == -1:
            # Genderless; Ditto only
            ditto = pokedex_session.query(Pokemon).filter_by(name=u'Ditto') \
                                   .one()
            c.compatible_families = [ditto]
        elif c.pokemon.egg_groups[0].id == 15:
            # No Eggs group
            pass
        else:
            parent_a = aliased(Pokemon)
            egg_group_ids = [_.id for _ in c.pokemon.egg_groups]
            q = pokedex_session.query(Pokemon)
            q = q.join(PokemonEggGroup) \
                 .outerjoin((parent_a, Pokemon.evolution_parent)) \
                 .filter(Pokemon.gender_rate != -1) \
                 .filter(Pokemon.forme_base_pokemon_id == None) \
                 .filter(
                    # This is a "base form" iff either:
                    or_(
                        # This is the root form (no parent)
                        # (It has to be breedable too, but we're filtering by
                        # an egg group so that's granted)
                        parent_a.id == None,
                        # Or this can breed and evolves from something that
                        # can't
                        and_(parent_a.egg_groups.any(id=15),
                             parent_a.evolution_parent_pokemon_id == None),
                    )
                 ) \
                 .filter(PokemonEggGroup.egg_group_id.in_(egg_group_ids)) \
                 .order_by(Pokemon.id)
            c.compatible_families = q.all()

        ### Wild held items
        # Stored separately per version due to *rizer shenanigans (grumble),
        # so in some 99.9% of cases we want to merge them all into a single
        # per-generation list.
        # I also want to look to the future (past?) and expect supporting held
        # items from older games, so I'm trying not to assume gen-4-only here.
        # Thus we have to store these as:
        #   generation => { version => [ (item, rarity), ... ] }
        # In the case of all versions within a generation being merged, the
        # key is None instead of a version object.
        c.held_items = {}
        version_held_items = {}  # version => [ (item, rarity), ... ]
        for pokemon_item in c.pokemon.items:
            version_held_items.setdefault(pokemon_item.version, []) \
                              .append((pokemon_item.item, pokemon_item.rarity))
        for generation in [db.generation(4)]:
            # Figure out if we can merge the versions for this gen, i.e., if
            # every list of (item, rarity) tuples is identical
            can_merge = True
            first_held_items = version_held_items.setdefault(generation.versions[0], [])
            for version in generation.versions[1:]:
                # XXX HG/SS aren't out yet, and we don't want to show 'None'
                # rows because that's not really correct.  So skip them
                if version.name in (u'Heart Gold', u'Soul Silver'):
                    continue

                version_held_items.setdefault(version, [])
                if version_held_items[version] != first_held_items:
                    can_merge = False
                    break

            # Copy appropriate per-version item lists to the final dictionary.
            # If we can merge, stick any version's list under the key None;
            # otherwise, we have to copy them all
            if can_merge:
                c.held_items[generation] = { None: first_held_items }
            else:
                version_dict = {}
                c.held_items[generation] = version_dict
                for version in generation.versions:
                    # XXX HG/SS aren't out yet, and we don't want to show 'None'
                    # rows because that's not really correct.  So skip them
                    if version.name in (u'Heart Gold', u'Soul Silver'):
                        continue
                    version_dict[version] = version_held_items.get(version, [])

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

            # Sort by id, then by forme if any.  This keeps evolutions in about
            # the order people expect, while clustering formes together.
            unseen_leaves.sort(key=lambda x: (x.national_id, x.forme_name))
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

        c.stats = {}  # stat_name => { border, background, percentile }
                      #              (also 'value' for total)
        stat_total = 0
        total_stat_rows = pokedex_session.query(PokemonStat) \
                                         .filter_by(stat=c.pokemon.stats[0].stat) \
                                         .count()
        for pokemon_stat in c.pokemon.stats:
            stat_info = c.stats[pokemon_stat.stat.name] = {}
            stat_total += pokemon_stat.base_stat
            q = pokedex_session.query(PokemonStat) \
                               .filter_by(stat=pokemon_stat.stat)
            less = q.filter(PokemonStat.base_stat < pokemon_stat.base_stat) \
                    .count()
            equal = q.filter(PokemonStat.base_stat == pokemon_stat.base_stat) \
                     .count()
            percentile = (less + equal * 0.5) / total_stat_rows
            stat_info['percentile'] = percentile

            # Colors for the stat bars, based on percentile
            stat_info['background'] = bar_color(percentile, 0.9)
            stat_info['border'] = bar_color(percentile, 0.8)

        # Percentile for the total
        # Need to make a derived table that fakes pokemon_id, total_stats
        stat_sum_tbl = pokedex_session.query(func.sum(PokemonStat.base_stat)
                                                 .label('stat_total')) \
                                      .group_by(PokemonStat.pokemon_id) \
                                      .subquery()

        q = pokedex_session.query(stat_sum_tbl)
        less = q.filter(stat_sum_tbl.c.stat_total < stat_total).count()
        equal = q.filter(stat_sum_tbl.c.stat_total == stat_total).count()
        percentile = (less + equal * 0.5) / total_stat_rows
        c.stats['total'] = {
            'percentile': percentile,
            'value': stat_total,
            'background': bar_color(percentile, 0.9),
            'border': bar_color(percentile, 0.8),
        }

        ### Sizing
        # These are totally hardcoded average sizes in Pokemon units:
        c.trainer_height = 17.8  # dm
        c.trainer_weight = 780   # hg
        heights = dict(pokemon=c.pokemon.height, trainer=c.trainer_height)
        c.heights = pokedex_helpers.scale_sizes(heights)
        # Strictly speaking, weight takes three dimensions.  But the real
        # measurement here is just "space taken up", and these are sprites, so
        # the space they actually take up is two-dimensional.
        weights = dict(pokemon=c.pokemon.weight, trainer=c.trainer_weight)
        c.weights = pokedex_helpers.scale_sizes(weights, dimensions=2)

        ### Flavor text
        c.flavor_text = {}
        for pokemon_flavor_text in c.pokemon.normal_form.flavor_text:
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
                                    .setdefault(encounter.version.name, [])

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

        ### Moves
        # Oh no.
        # Moves are grouped by method.
        # Within a method is a list of move rows.
        # A move row contains a level or other status per version group, plus
        # a move id.
        # Thus: method => [ (move, { version_group => data, ... }), ... ]
        # "data" is a dictionary of whatever per-version information is
        # appropriate for this move method, such as a TM number or level.
        c.moves = collections.defaultdict(list)
        # Grab the rows with a manual query so we can sort thm in about the row
        # they go in the table.  This should keep it as compact as possible
        q = pokedex_session.query(PokemonMove) \
                           .filter_by(pokemon_id=c.pokemon.id) \
                           .order_by(PokemonMove.level.asc(),
                                     PokemonMove.order.asc(),
                                     PokemonMove.version_group_id.asc())
        for pokemon_move in q:
            method_list = c.moves[pokemon_move.method]
            this_vg = pokemon_move.version_group

            # Create a container for data for this method and version(s)
            vg_data = dict()

            # TMs need to know their own TM number
            for machine in pokemon_move.move.machines:
                if machine.generation == this_vg.generation:
                    vg_data['machine'] = machine.machine_number
                    break

            # Find the best place to insert a row.
            # In general, we just want the move names in order, so we can just
            # tack rows on and sort them at the end.  However!  Level-up moves
            # must stay in the same order within a version group.  So we have
            # to do some special ordering here.
            # These two vars are the boundaries of where we can find or insert
            # a new row.  Only level-up moves have these restrictions
            lower_bound = None
            upper_bound = None
            if pokemon_move.method.name == 'Level up':
                vg_data['sort'] = (pokemon_move.level, pokemon_move.order)
                vg_data['level'] = pokemon_move.level
                # Level 1 is generally thought of as a special category of starter
                # move, so the table will be easier to read if it indicates this
                if vg_data['level'] == 1:
                    vg_data['level'] = '—'  # em dash

                # Find the next-lowest and next-highest rows.  Our row must fit
                # between those
                for i, (move, version_group_data) in enumerate(method_list):
                    if this_vg not in version_group_data:
                        # Can't be a bound; not related to this version!
                        continue

                    if version_group_data[this_vg]['sort'] > vg_data['sort']:
                        if not upper_bound or i < upper_bound:
                            upper_bound = i
                    if version_group_data[this_vg]['sort'] < vg_data['sort']:
                        if not lower_bound or i > lower_bound:
                            lower_bound = i

            # We're using Python's slice syntax, which includes the lower bound
            # and excludes the upper.  But we want to exclude both, so bump the
            # lower bound
            if lower_bound != None:
                lower_bound += 1

            # Check for a free existing row for this move; if one exists, we
            # can just add our data to that same row
            valid_row = None
            for table_row in method_list[lower_bound:upper_bound]:
                move, version_group_data = table_row
                if move == pokemon_move.move and this_vg not in version_group_data:
                    valid_row = table_row
                    break
            if valid_row:
                valid_row[1][this_vg] = vg_data
                continue

            # Otherwise, just make a new row and stuff it in.
            # Rows are sorted by level going up, so any future ones wanting to
            # use this row will have higher levels.  Let's put this as close to
            # the end as we can, then, or we risk making multiple rows for the
            # same move unnecessarily
            new_row = pokemon_move.move, { this_vg: vg_data }
            method_list.insert(upper_bound or len(method_list), new_row)

        for method, method_list in c.moves.items():
            if method.name == 'Level up':
                continue
            method_list.sort(key=lambda (move, version_group_data): move.name)

        # Finally, we want to collapse identical adjacent columns within the
        # same generation.
        # All we really need to know is what versions are ultimately collapsed
        # into each column, so we need a list of lists of version groups:
        # [ [ rb, y ], [ gs ], [ c ], ... ]
        c.move_columns = []
        # We also want to know what columns are the last for a generation, so
        # we can put divider lines between gens.  Accumulate indices of these
        # columns as we go
        c.move_divider_columns = []
        # Only even consider versions in which this Pokémon actually exists
        q = pokedex_session.query(Generation) \
                           .filter(Generation.id >= c.pokemon.generation_id) \
                           .order_by(Generation.id.asc())
        for generation in q:
            last_vg = None
            for i, version_group in enumerate(generation.version_groups):
                if i == 0:
                    # Can't collapse this column anywhere!  Just add it as a
                    # new column
                    c.move_columns.append( [version_group] )
                    last_vg = version_group
                    continue

                # Test to see if this version group column is identical to the
                # one immediately to its left; if so, we can combine them
                squashable = True
                for method, method_list in c.moves.items():
                    # Tutors are special; they will NEVER collapse, so ignore
                    # them for now.  When we actually print the table, we'll
                    # concatenate all the tutor cells instead of just using the
                    # first one like with everything else
                    if method.name == 'Tutor':
                        continue

                    for move, version_group_data in method_list:
                        if version_group_data.get(version_group, None) \
                            != version_group_data.get(last_vg, None):
                            squashable = False
                            break
                    if not squashable:
                        break

                if squashable:
                    # Stick this version group in the previous column
                    c.move_columns[-1].append(version_group)
                else:
                    # Create a new column
                    c.move_columns.append( [version_group] )

                last_vg = version_group

            # Remember the last column within the generation
            c.move_divider_columns.append(len(c.move_columns) - 1)

        # Used for tutored moves: we want to leave a blank space for collapsed
        # columns with tutored versions in them so all the versions line up,
        # and to do that we need to know which versions actually have tutored
        # moves -- otherwise we'd leave space for R/S, D/P, etc
        c.move_tutor_version_groups = []
        for method, method_list in c.moves.items():
            if method.name != 'Tutor':
                continue
            for move, version_group_data in method_list:
                c.move_tutor_version_groups.extend(version_group_data.keys())

        return render('/pokedex/pokemon.mako')


    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = db.pokemon(name)
        except NoResultFound:
            return self._not_found()

        # Deal with forms.  Sprite forms, remember!
        c.form = request.params.get('form', None)
        c.forms = [_.name for _ in c.pokemon.form_sprites]
        c.forms.sort()

        if c.form:
            try:
                spr_form = pokedex_session.query(PokemonFormSprite) \
                                          .filter_by(pokemon_id=c.pokemon.id,
                                                     name=c.form) \
                                          .one()
            except NoResultFound:
                # Not a valid form!
                abort(404)

            c.introduced_in = spr_form.introduced_in
        else:
            c.introduced_in = c.pokemon.generation.version_groups[0]

        if c.form:
            c.sprite_filename = u"%d-%s" % (c.pokemon.id, c.form)
        else:
            c.sprite_filename = unicode(c.pokemon.id)

        ### Flavor text
        c.flavor_text = {}  # generation => [ ( versions, text ) ]
        db_flavor_text = c.pokemon.flavor_text
        db_flavor_text.sort(key=lambda _: _.version_id)

        for flavor_text in db_flavor_text:
            flavor_tuple = ([flavor_text.version], flavor_text.flavor_text)
            gen_text = c.flavor_text.setdefault(flavor_text.version.generation,
                                                [])

            # Check for an existing tuple with the same text and a version from
            # the same group; i.e., if we're doing Blue and the text matches
            # Red's, stick them in the same tuple
            found_existing = False
            for versions, text in gen_text:
                if versions[0].version_group_id == \
                        flavor_text.version.version_group_id \
                    and text == flavor_text.flavor_text:

                    versions.append(flavor_text.version)
                    found_existing = True
                    break

            if not found_existing:
                # No matches; add a new row
                gen_text.append(flavor_tuple)

        return render('/pokedex/pokemon_flavor.mako')


    def moves(self, name):
        try:
            c.move = db.get_by_name(Move, name)
        except NoResultFound:
            return self._not_found()

        ### Type efficacy
        c.type_efficacies = {}
        for type_efficacy in c.move.type.damage_efficacies:
            c.type_efficacies[type_efficacy.target_type] = \
                type_efficacy.damage_factor

        ### Flags
        c.flags = []
        move_flags = pokedex_session.query(MoveFlagType) \
                                    .order_by(MoveFlagType.id.asc())
        for flag in move_flags:
            has_flag = flag in c.move.flags
            c.flags.append((flag, has_flag))

        ### Machines
        q = pokedex_session.query(Generation) \
                           .filter(Generation.id >= c.move.generation.id) \
                           .order_by(Generation.id.asc())
        c.generations = {}
        c.machines = {}
        for generation in q:
            c.machines[generation] = None

        for machine in c.move.machines:
            print machine.__dict__
            c.machines[machine.generation] = machine.machine_number

        return render('/pokedex/move.mako')


    def types(self, name):
        try:
            c.type = db.get_by_name(Type, name)
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/type.mako')


    def abilities(self, name):
        try:
            c.ability = db.get_by_name(Ability, name)
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/ability.mako')


    def items(self, name):
        try:
            c.item = db.get_by_name(Item, name)
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/item.mako')


