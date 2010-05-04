# encoding: utf8
from __future__ import absolute_import, division

from collections import defaultdict, namedtuple
import colorsys
import json
import logging
import mimetypes

import pokedex.db
import pokedex.db.tables as tables
from pokedex.db.tables import Ability, EggGroup, Generation, Item, Language, Machine, Move, MoveFlagType, Pokemon, PokemonEggGroup, PokemonFormSprite, PokemonMove, PokemonStat, Type, VersionGroup, PokemonType, PokemonAbility
import pkg_resources
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect_to
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased, contains_eager, eagerload, eagerload_all, join
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render
from spline.lib import helpers as h

from spline.plugins.pokedex import db, helpers as pokedex_helpers
from spline.plugins.pokedex.db import pokedex_lookup, pokedex_session

log = logging.getLogger(__name__)

def bar_color(hue, pastelness):
    """Returns a color in the form #rrggbb that has the provided hue and
    lightness/saturation equal to the given "pastelness".
    """
    r, g, b = colorsys.hls_to_rgb(hue, pastelness, pastelness)
    return "#%02x%02x%02x" % (r * 256, g * 256, b * 256)


def first(func, iterable):
    """Returns the first element in iterable for which func(elem) is true.

    Equivalent to next(ifilter(func, iterable)).
    """

    for elem in iterable:
        if func(elem):
            return elem

def _pokemon_move_method_sort_key((method, _)):
    """Sorts methods by id, except that tutors and machines are bumped to the
    bottom, as they tend to be much longer than everything else.
    """
    if method.name in (u'Tutor', u'Machine'):
        return method.id + 1000
    else:
        return method.id

def _collapse_pokemon_move_columns(table, thing):
    """Combines adjacent identical columns in a pokemon_move structure.

    Arguments are the table structure (defined in comments below) and the
    Pokémon or move in question.

    Returns a 2-ruple consisting of:
    - a list of columns like `[ [ rb, y ], [ gs ], [ c ], ...]`
    - a list of indexes in the above list, corresponding to columns that are
      the last of their generation
    """

    # All we really need to know is what versions are ultimately collapsed into
    # each column, so we need a list of lists of version groups:
    move_columns = []
    # We also want to know what columns are the last for a generation, so we
    # can put divider lines between gens.  Accumulate indices of these as we go
    move_divider_columns = []
    # Only even consider versions in which this item actually exists
    q = pokedex_session.query(Generation) \
                       .filter(Generation.id >= thing.generation_id) \
                       .order_by(Generation.id.asc())
    for generation in q:
        last_vg = None
        for i, version_group in enumerate(generation.version_groups):
            if i == 0:
                # Can't collapse these versions anywhere!  Create a new column
                move_columns.append( [version_group] )
                last_vg = version_group
                continue

            # Test to see if this version group column is identical to the one
            # immediately to its left; if so, we can combine them
            squashable = True
            for method, method_list in table:
                # Tutors are special; they will NEVER collapse, so ignore them
                # for now.  When we actually print the table, we'll concatenate
                # all the tutor cells instead of just using the first one like
                # with everything else
                if method.name == 'Tutor':
                    continue

                for move, version_group_data in method_list:
                    if version_group_data.get(version_group, None) \
                        != version_group_data.get(last_vg, None):
                        squashable = False
                        break
                if not squashable:
                    # Definitely can't collapse.  Bail
                    break

            if squashable:
                # Stick this version group in the previous column
                move_columns[-1].append(version_group)
            else:
                # Create a new column
                move_columns.append( [version_group] )

            last_vg = version_group

        # Remember the last column within the generation
        move_divider_columns.append(len(move_columns) - 1)

    return move_columns, move_divider_columns

def _move_tutor_version_groups(table):
    """Tutored moves are never the same between version groups, so the column
    collapsing ignores tutors entirely.  This means that we might end up
    wanting to show several versions as having a tutor within a single column.
    So that "E, FRLG" lines up with "FRLG", there has to be a blank space for
    "E", which requires finding all the version groups that contain tutors.
    """

    move_tutor_version_groups = set()
    for method, method_list in table:
        if method.name != 'Tutor':
            continue
        for move, version_group_data in method_list:
            move_tutor_version_groups.update(version_group_data.keys())

    return move_tutor_version_groups

def level_range(a, b):
    """If a and b are the same, returns 'L{a}'.  Otherwise, returns 'L{a}–{b}'.
    """

    if a == b:
        return u"L{0}".format(a)
    else:
        return u"L{0}–{1}".format(a, b)

class CombinedEncounter(object):
    """Represents several encounter rows, collapsed together.  Rarities and
    level ranges are combined correctly.

    Assumed to have the same terrain.  Also location and area and so forth, but
    those aren't actually needed.
    """
    def __init__(self, encounter=None):
        self.terrain = None
        self.rarity = 0
        self.min_level = 0
        self.max_level = 0

        if encounter:
            self.combine_with(encounter)

    def combine_with(self, encounter):
        if self.terrain and self.terrain != encounter.slot.terrain:
            raise ValueError(
                "Can't combine terrain {0} with {1}"
                .format(self.terrain.name, encounter.slot.terrain.name)
            )

        self.rarity += encounter.slot.rarity
        self.max_level = max(self.max_level, encounter.max_level)

        if not self.min_level:
            self.min_level = encounter.min_level
        else:
            self.min_level = min(self.min_level, encounter.min_level)

    @property
    def level(self):
        return level_range(self.min_level, self.max_level)

class PokedexController(BaseController):

    # Used by lookup disambig pages
    table_labels = {
        tables.Ability: 'ability',
        tables.Item: 'item',
        tables.Location: 'location',
        tables.Move: 'move',
        tables.Nature: 'nature',
        tables.Pokemon: 'Pokémon',
        tables.Type: 'type',
    }

    # Dict of terrain name => icon path
    encounter_terrain_icons = {
        'Surfing':                          'surfing.png',
        'Fishing with an Old Rod':          'old-rod.png',
        'Fishing with a Good Rod':          'good-rod.png',
        'Fishing with a Super Rod':         'super-rod.png',
        'Walking in tall grass or a cave':  'grass.png',
        'Smashing rocks':                   'rock-smash.png',
    }

    # Maps condition value names to representative icons
    encounter_condition_value_icons = {
        # Conditions
        'Not during a swarm':   'swarm-no.png',
        'During a swarm':       'swarm-yes.png',
        'No fishing swarm':     'swarm-no.png',
        'Fishing swarm':        'swarm-yes.png',
        'No surfing swarm':     'swarm-no.png',
        'Surfing swarm':        'swarm-yes.png',
        'In the morning':       'time-morning.png',
        'During the day':       'time-daytime.png',
        'At night':             'time-night.png',
        u'Not using PokéRadar': 'pokéradar-off.png',
        u'Using PokéRadar':     'pokéradar-on.png',
        'No game in slot 2':    'slot2-none.png',
        'Ruby in slot 2':       'slot2-ruby.png',
        'Sapphire in slot 2':   'slot2-sapphire.png',
        'Emerald in slot 2':    'slot2-emerald.png',
        'Fire Red in slot 2':   'slot2-fire-red.png',
        'Leaf Green in slot 2': 'slot2-leaf-green.png',
        'Radio off':            'radio-off.png',
        'Hoenn radio':          'radio-hoenn.png',
        'Sinnoh radio':         'radio-sinnoh.png',
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
        if not name:
            # Nothing entered.  What?  Where did you come from?
            # There's nothing sensible to do here.  Let's use an obscure status
            # code, like 204 No Content.
            abort(204)

        name = name.strip()

        ### Special stuff that bypasses lookup
        if name.lower() == 'obdurate':
            # Pokémon flavor text in the D/P font
            return self._egg_unlock_cheat('obdurate')


        ### Regular lookup
        results = pokedex_lookup.lookup(name)

        if len(results) == 0:
            # Nothing found
            # XXX real error page
            return self._not_found()

        elif len(results) == 1:
            # Only one possibility!  Hooray!

            if not results[0].exact:
                # Wasn't an exact match, but we can only figure out one thing
                # the user might have meant, so redirect to it anyway
                h.flash(u"""Nothing in the Pokédex is exactly called "{0}".  """
                        u"""This is the only close match.""".format(name),
                        icon='spell-check-error')

            return redirect_to(
                pokedex_helpers.make_thingy_url(results[0].object))

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


    def suggest(self):
        """Returns a JSON array of Pokédex lookup suggestions, compatible with
        the OpenSearch spec.
        """

        prefix = request.params.get('prefix', None)
        if not prefix:
            return '[]'

        valid_types = request.params.getall('type')

        suggestions = pokedex_lookup.prefix_lookup(
            prefix,
            valid_types=valid_types,
        )

        names = []     # actual terms that will appear in the list
        metadata = []  # parallel array of metadata my suggest widget uses
        for suggestion in suggestions:
            row = suggestion.object
            names.append(suggestion.name)
            meta = dict(
                type=row.__singlename__,
                indexed_name=suggestion.indexed_name,
            )

            # Get an accompanying image.  Moves get their type; abilities get
            # nothing; everything else gets the obvious corresponding icon
            image = None
            if isinstance(row, Pokemon):
                if row.forme_name:
                    image = u"icons/{0}-{1}.png".format(row.national_id, row.forme_name)
                else:
                    image = u"icons/{0}.png".format(row.national_id)
            elif isinstance(row, Move):
                image = u"chrome/types/{0}.png".format(row.type.name)
            elif isinstance(row, Type):
                image = u"chrome/types/{0}.png".format(row.name)
            elif isinstance(row, Item):
                image = u"items/{0}.png".format(
                    pokedex_helpers.filename_from_name(row.name))

            if image:
                meta['image'] = url(controller='dex', action='media',
                                    path=image,
                                    qualified=True)

            # Give a country icon so JavaScript doesn't have to hardcore Spline
            # paths.  Don't *think* we need to give the long language name...
            meta['language'] = suggestion.iso3166
            meta['language_icon'] = h.static_uri(
                'spline',
                'flags/{0}.png'.format(suggestion.iso3166),
                qualified=True
            )

            metadata.append(meta)

        normalized_name = pokedex_lookup.normalize_name(prefix)
        if ':' in normalized_name:
            _, normalized_name = normalized_name.split(':', 1)

        data = [
            prefix,
            names,
            None,       # descriptions
            None,       # query URLs
            metadata,   # my metadata; outside the spec's range
            normalized_name,  # the key we actually looked for
        ]

        ### Format as JSON.  Also sets the content-type and supports JSONP --
        ### if there's a 'callback' param, the return value will be wrapped
        ### appropriately.
        json_data = json.dumps(data)

        if 'callback' in request.params:
            # Pad and change the content-type to match a script tag
            json_data = "{callback}({json})".format(
                callback=request.params['callback'],
                json=json_data,
            )
            response.headers['Content-Type'] = 'text/javascript; charset=UTF-8'
        else:
            # Just set content type
            response.headers['Content-Type'] = 'application/json; charset=UTF-8'

        return json_data


    def _prev_next_pokemon(self, pokemon):
        """Returns a 2-tuple of the previous and next Pokémon."""
        max_id = pokedex_session.query(Pokemon) \
                                .filter_by(forme_base_pokemon_id=None) \
                                .count()
        prev_pokemon = pokedex_session.query(Pokemon).get(
            (c.pokemon.national_id - 1 - 1) % max_id + 1)
        next_pokemon = pokedex_session.query(Pokemon).get(
            (c.pokemon.national_id - 1 + 1) % max_id + 1)
        return prev_pokemon, next_pokemon

    def pokemon_list(self):
        return render('/pokedex/pokemon_list.mako')

    def pokemon(self, name=None):
        form = request.params.get('form', None)
        try:
            pokemon_q = db.pokemon_query(name, form=form)

            # Need to eagerload some, uh, little stuff
            pokemon_q = pokemon_q.options(
                eagerload('evolution_chain.pokemon'),
                eagerload('evolution_chain.pokemon.evolution_method'),
                eagerload('evolution_chain.pokemon.evolution_parent'),
                eagerload('generation'),
                eagerload('items.item'),
                eagerload('items.version'),
                eagerload('pokemon_color'),
                eagerload('pokemon_habitat'),
                eagerload('shape'),
                eagerload('stats.stat'),
                eagerload('types.target_efficacies'),
                eagerload('types.target_efficacies.damage_type'),

                # XXX SQLAlchemy totally barfs if I try to eagerload things
                # that are only on the normal_form.  No idea why.  This
                # includes: dex_numbers, foreign_names, flavor_text
            )

            # Alright, execute
            c.pokemon = pokemon_q.one()
        except NoResultFound:
            return self._not_found()

        # Some Javascript
        c.javascripts.append(('pokedex', 'pokemon'))

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_pokemon(c.pokemon)

        # Let's cache this bitch
        return self.cache_content(
            key=(name, form),
            template='/pokedex/pokemon.mako',
            do_work=self._do_pokemon,
        )

    def _do_pokemon(self, (name, form)):
        ### Type efficacy
        c.type_efficacies = defaultdict(lambda: 100)
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
        # Stored separately per version due to *rizer shenanigans (grumble).
        # Items also sometimes change over version groups within a generation.
        # So in some 99.9% of cases we want to merge them to some extent,
        # usually collapsing an entire version group or an entire generation.
        # Thus we store these as:
        #   generation => { (version, ...) => [ (item, rarity), ... ] }
        # In the case of all versions within a generation being merged, the
        # key is None instead of a tuple of version objects.
        c.held_items = {}

        # First group by the things we care about
        # n.b.: the keys are tuples of versions, not versions!
        version_held_items = {}
        # Preload with a list of versions so we know which ones are empty
        generations = pokedex_session.query(tables.Generation) \
            .options( eagerload('versions') ) \
            .filter(tables.Generation.id >= max(3, c.pokemon.generation.id))
        for generation in generations:
            version_held_items[generation] = {}
            for version in generation.versions:
                version_held_items[generation][version,] = []

        for pokemon_item in c.pokemon.items:
            generation = pokemon_item.version.generation

            version_held_items[generation][pokemon_item.version,] \
                .append((pokemon_item.item, pokemon_item.rarity))

        # Then group these into the form above
        for generation, gen_held_items in version_held_items.items():
            # gen_held_items: { (versions...): [(item, rarity)...] }
            # Group by item, rarity, sorted by version...
            inverted_held_items = defaultdict(tuple)
            for version_tuple, item_rarity_list in \
                sorted(gen_held_items.items(), key=lambda (k, v): k[0].id):

                inverted_held_items[tuple(item_rarity_list)] += version_tuple

            # Then flip back to versions as keys
            c.held_items[generation] = {}
            for item_rarity_tuple, version_tuple in inverted_held_items.items():
                c.held_items[generation][version_tuple] = item_rarity_tuple

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

        ### Stats
        # This takes a lot of queries  :(
        c.stats = {}  # stat_name => { border, background, percentile }
                      #              (also 'value' for total)
        stat_total = 0
        total_stat_rows = pokedex_session.query(PokemonStat) \
                                         .filter_by(stat=c.pokemon.stats[0].stat) \
                                         .count()
        physical_attack = None
        special_attack = None
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

            if pokemon_stat.stat.name == u'Attack':
                physical_attack = pokemon_stat.base_stat
            elif pokemon_stat.stat.name == u'Special Attack':
                special_attack = pokemon_stat.base_stat

        c.better_damage_class = None
        if physical_attack > special_attack:
            c.better_damage_class = u'Physical'
        elif physical_attack < special_attack:
            c.better_damage_class = u'Special'

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

        ### Encounters -- briefly
        # One row per version, then a list of places the Pokémon appears.
        # version => terrain => location_area => conditions => CombinedEncounters
        c.locations = defaultdict(
            lambda: defaultdict(
                lambda: defaultdict(
                    lambda: defaultdict(
                        CombinedEncounter
                    )
                )
            )
        )

        q = pokedex_session.query(tables.Encounter) \
            .filter_by(pokemon=c.pokemon) \
            .options(
                eagerload_all('condition_value_map.condition_value'),
                eagerload_all('version'),
                eagerload_all('slot.terrain'),
                eagerload_all('location_area.location'),
            )
        for encounter in q:
            condition_values = [cv for cv in encounter.condition_values
                                   if not cv.is_default]
            c.locations[encounter.version] \
                       [encounter.slot.terrain] \
                       [encounter.location_area] \
                       [tuple(condition_values)].combine_with(encounter)

        # Strip each version+location down to just the condition values that
        # are the most common per terrain
        # Results in:
        # version => location_area => terrain => (conditions, combined_encounter)
        for version, terrain_etc in c.locations.items():
            for terrain, area_condition_encounters \
                in terrain_etc.items():
                for location_area, condition_encounters \
                    in area_condition_encounters.items():

                    # Sort these by rarity
                    condition_encounter_items = condition_encounters.items()
                    condition_encounter_items.sort(
                        key=lambda (conditions, combined_encounter):
                            combined_encounter.rarity
                    )

                    # Use the last one, which is most common
                    area_condition_encounters[location_area] \
                        = condition_encounter_items[-1]

        # Used for prettiness
        c.encounter_terrain_icons = self.encounter_terrain_icons

        ### Moves
        # Oh no.
        # Moves are grouped by method.
        # Within a method is a list of move rows.
        # A move row contains a level or other status per version group, plus
        # a move id.
        # Thus: ( method, [ (move, { version_group => data, ... }), ... ] )
        # First, though, we make a dictionary for quick access to each method's
        # list.
        # "data" is a dictionary of whatever per-version information is
        # appropriate for this move method, such as a TM number or level.
        move_methods = defaultdict(list)
        # Grab the rows with a manual query so we can sort them in about the
        # order they go in the table.  This should keep it as compact as
        # possible.  Levels go in level order, and machines go in TM number
        # order
        q = pokedex_session.query(PokemonMove) \
                           .filter_by(pokemon_id=c.pokemon.id) \
                           .outerjoin((Machine, PokemonMove.machine)) \
                           .options(
                                contains_eager(PokemonMove.machine),
                                eagerload_all('move.damage_class'),
                                eagerload_all('move.move_effect'),
                                eagerload_all('move.type'),
                                eagerload_all('version_group'),
                            ) \
                           .order_by(PokemonMove.level.asc(),
                                     Machine.machine_number.asc(),
                                     PokemonMove.order.asc(),
                                     PokemonMove.version_group_id.asc()) \
                           .all()
        for pokemon_move in q:
            method_list = move_methods[pokemon_move.method]
            this_vg = pokemon_move.version_group

            # Create a container for data for this method and version(s)
            vg_data = dict()

            # TMs need to know their own TM number
            if pokemon_move.method.name == 'Machine':
                vg_data['machine'] = pokemon_move.machine.machine_number

            # Find the best place to insert a row.
            # In general, we just want the move names in order, so we can just
            # tack rows on and sort them at the end.  However!  Level-up moves
            # must stay in the same order within a version group, and TMs are
            # similarly ordered by number.  So we have to do some special
            # ordering here.
            # These two vars are the boundaries of where we can find or insert
            # a new row.  Only level-up moves have these restrictions
            lower_bound = None
            upper_bound = None
            if pokemon_move.method.name in ('Level up', 'Machine'):
                vg_data['sort'] = (pokemon_move.level,
                                   vg_data.get('machine', None),
                                   pokemon_move.order)
                vg_data['level'] = pokemon_move.level

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
            # can just add our data to that same row.
            # It's also possible that an existing row for this move can be
            # shifted forwards into our valid range, if there are no
            # intervening rows with levels in the same version groups that that
            # row has.  This is unusual, but happens when a lot of moves have
            # been shuffled around multiple times, like with Pikachu
            valid_row = None
            for i, table_row in enumerate(method_list[0:upper_bound]):
                move, version_group_data = table_row

                # If we've already found a row for version X outside our valid
                # range but run across another row with a level for X, that row
                # cannot be moved up, so it's not usable
                if valid_row and set(valid_row[1].keys()).intersection(
                                     set(version_group_data.keys())):
                    valid_row = None

                if move == pokemon_move.move \
                    and this_vg not in version_group_data:

                    valid_row = table_row
                    # If we're inside the valid range, just take the first row
                    # we find.  If we're outside it, we want the last possible
                    # row to avoid shuffling the table too much.  So only break
                    # if this row is inside lb/ub
                    if i >= lower_bound:
                        break

            if valid_row:
                if method_list.index(valid_row) < lower_bound:
                    # Move the row up if necessary
                    method_list.remove(valid_row)
                    method_list.insert(lower_bound, valid_row)
                valid_row[1][this_vg] = vg_data
                continue

            # Otherwise, just make a new row and stuff it in.
            # Rows are sorted by level before version group.  If we see move X
            # for a level, then move Y for another game, then move X for that
            # other game, the two X's should be able to collapse.  Thus we put
            # the Y before the first X to leave space for the second X -- that
            # is, add new rows as early in the list as possible
            new_row = pokemon_move.move, { this_vg: vg_data }
            method_list.insert(lower_bound or 0, new_row)

        # Convert dictionary to our desired list of tuples
        c.moves = move_methods.items()
        c.moves.sort(key=_pokemon_move_method_sort_key)

        # Sort non-level moves by name
        for method, method_list in c.moves:
            if method.name in ('Level up', 'Machine'):
                continue
            method_list.sort(key=lambda (move, version_group_data): move.name)

        # Finally, collapse identical columns within the same generation
        c.move_columns, c.move_divider_columns \
            = _collapse_pokemon_move_columns(table=c.moves, thing=c.pokemon)

        # Grab list of all the version groups with tutor moves
        c.move_tutor_version_groups = _move_tutor_version_groups(c.moves)

        return


    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = db.pokemon_query(name).one()
        except NoResultFound:
            return self._not_found()

        # Deal with forms.  Remember, this could be either a physical form or
        # an aesthetic form!
        c.form = request.params.get('form', None)
        form_sprites = c.pokemon.form_sprites

        # If we don't have a form name, but this Pokémon has forms, we need to
        # know the default
        if not c.form and c.pokemon.forme_name:
            # If there's a physical form name, just use that.  Don't redirect,
            # as the physical form name is universally treated as the "default"
            # and thus interchangeable with the plain Pokémon name -- that is,
            # Normal Deoxys will always be /dex/pokemon/deoxys and vice versa
            c.form = c.pokemon.forme_name

        elif not c.form \
            and form_sprites and not any(_.name == '' for _ in form_sprites):
            # If there are aesthetic forms, but not one without a name, and we
            # didn't GET a name, then redirect to the default.  In this case,
            # you can't see flavor for "just Unown"; there's no such thing.
            # You have to pick one, and if you don't, then I'll pick one for
            # you
            redirect_to(form=c.pokemon.default_form_sprite.name)

        c.forms = [_.name for _ in c.pokemon.form_sprites]
        c.forms.sort()


        # Every form should have a recorded sprite; find it
        if c.form:
            try:
                spr_form = pokedex_session \
                    .query(PokemonFormSprite) \
                    .filter_by(pokemon_id=c.pokemon.id, name=c.form) \
                    .one()
            except NoResultFound:
                # Not a valid form!
                abort(404)

            c.introduced_in = spr_form.introduced_in
        else:
            c.introduced_in = c.pokemon.generation.version_groups[0]

        # Figure out if a sprite form appears in the overworld.  If this isn't
        # a sprite form, the answer is obviously yes
        c.appears_in_overworld = True
        default_form_sprite = c.pokemon.default_form_sprite
        if c.pokemon.form_group and c.pokemon.form_group.is_battle_only \
            and default_form_sprite and c.form != default_form_sprite.name:
            # That is, if this Pokémon's forms aren't battle-only, and it's not
            # the default
            c.appears_in_overworld = False

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_pokemon(c.pokemon)

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


    def pokemon_locations(self, name):
        """Spits out a page listing detailed location information for this
        Pokémon.
        """
        try:
            c.pokemon = db.pokemon(name)
        except NoResultFound:
            return self._not_found()

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_pokemon(c.pokemon)

        # For the most part, our data represents exactly what we're going to
        # show.  For a given area in a given game, this Pokémon is guaranteed
        # to appear some x% of the time no matter what the state of the world
        # is, and various things like swarms or the radar may add on to this
        # percentage.

        # Encounters are grouped by region -- <h1>s.
        # Then by terrain -- table sections.
        # Then by area -- table rows.
        # Then by version -- table columns.
        # Finally, condition values associated with levels/rarity.
        q = pokedex_session.query(tables.Encounter) \
            .filter(tables.Encounter.pokemon == c.pokemon)

        # region => terrain => area => version => condition =>
        #     condition_values => encounter_bits
        grouped_encounters = defaultdict(
            lambda: defaultdict(
                lambda: defaultdict(
                    lambda: defaultdict(
                        lambda: defaultdict(
                            lambda: defaultdict(
                                list
                            )
                        )
                    )
                )
            )
        )

        # Locations cluster by region, primarily to avoid having a lot of rows
        # where one version group or the other is blank; that doesn't make for
        # fun reading.  To put the correct version headers in each region
        # table, we need to know what versions correspond to which regions.
        # Normally, this can be done by examining region.version_groups.
        # However, some regions (Kanto) appear in a ridiculous number of games.
        # To avoid an ultra-wide table when not necessary, only *generations*
        # that actually contain this Pokémon should appear.
        # So if the Pokémon appears in Kanto in Crystal, show all of G/S/C.  If
        # it doesn't appear in any of the three, show none of them.
        # Last but not least, show generations in reverse order, so the more
        # important (i.e., recent) versions are on the left.
        # Got all that?
        region_generations = defaultdict(set)

        for encounter in q.all():
            # Fetches the list of encounters that match this region, version,
            # terrain, etc.
            region = encounter.location_area.location.region

            # n.b.: conditions and values must be tuples because lists aren't
            # hashable.
            encounter_bits = grouped_encounters \
                [region] \
                [encounter.slot.terrain] \
                [encounter.location_area] \
                [encounter.version] \
                [ tuple(cv.condition for cv in encounter.condition_values) ] \
                [ tuple(encounter.condition_values) ]

            # Combine "level 3-4, 50%" and "level 3-4, 20%" into "level 3-4, 70%".
            existing_encounter = filter(lambda enc: enc['min_level'] == encounter.min_level
                                                and enc['max_level'] == encounter.max_level,
                                        encounter_bits)
            if existing_encounter:
                existing_encounter[0]['rarity'] += encounter.slot.rarity
            else:
                encounter_bits.append({
                    'min_level': encounter.min_level,
                    'max_level': encounter.max_level,
                    'rarity': encounter.slot.rarity,
                })

            # Remember that this generation appears in this region
            region_generations[region].add(encounter.version.version_group.generation)

        c.grouped_encounters = grouped_encounters

        # Pass some data/functions
        c.encounter_terrain_icons = self.encounter_terrain_icons
        c.encounter_condition_value_icons = self.encounter_condition_value_icons
        c.level_range = level_range

        # See above.  Versions for each region are those in that region that
        # are part of a generation where this Pokémon appears -- in reverse
        # generation order.
        c.region_versions = defaultdict(list)
        for region, generations in region_generations.items():
            for version_group in region.version_groups:
                if version_group.generation not in generations:
                    continue
                c.region_versions[region][0:0] = version_group.versions

        return render('/pokedex/pokemon_locations.mako')

    def moves(self, name):
        try:
            c.move = db.get_by_name_query(Move, name) \
                .options(
                    eagerload('damage_class'),
                    eagerload('type.damage_efficacies'),
                    eagerload('type.damage_efficacies.target_type'),
                    eagerload('move_effect'),
                    eagerload('contest_effect'),
                    eagerload('super_contest_effect'),
                ) \
                .one()
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        max_id = pokedex_session.query(Move).count()
        c.prev_move = pokedex_session.query(Move).get(
            (c.move.id - 1 - 1) % max_id + 1)
        c.next_move = pokedex_session.query(Move).get(
            (c.move.id - 1 + 1) % max_id + 1)

        return self.cache_content(
            key=name,
            template='/pokedex/move.mako',
            do_work=self._do_moves,
        )

    def _do_moves(self, name):
        # Used for item linkage
        c.pp_up = pokedex_session.query(tables.Item) \
            .filter_by(name=u'PP Up').one()

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
        raw_machines = {}
        # raw_machines = { generation: { version_group: machine_number } }
        c.machines = {}
        # c.machines: generation => [ (versions, machine_number), ... ]
        # Populate an empty dict first so we know which versions don't have a
        # TM for this move
        for generation in q:
            c.machines[generation] = []
            raw_machines[generation] = {}
            for version_group in generation.version_groups:
                raw_machines[generation][version_group] = None

        # Fetch the actual machine numbers
        for machine in c.move.machines:
            raw_machines[machine.version_group.generation] \
                        [machine.version_group] = machine.machine_number

        # Collapse that into an easily-displayed form
        VersionMachine = namedtuple('VersionMachine',
                                    ['version_group', 'machine_number'])
        # dictionary -> list of tuples
        for generation, vg_numbers in raw_machines.items():
            for version_group, machine_number in vg_numbers.items():
                c.machines[generation].append(
                    VersionMachine(version_group=version_group,
                                   machine_number=machine_number,
                    )
                )
        for generation, vg_numbers in c.machines.items():
            machine_numbers = [_.machine_number for _ in vg_numbers]
            if len(set(machine_numbers)) == 1:
                # Merge generations that have the same machine number everywhere
                c.machines[generation] = [( None, vg_numbers[0].machine_number )]
            else:
                # Otherwise, sort by version group
                vg_numbers.sort(key=lambda item: item.version_group.id)

        ### Pokémon
        # This is kinda like the moves for Pokémon, but backwards.  Imagine
        # that!  We have the same basic structure, a list of:
        #     ( method, [ (pokemon, { version_group => data, ... }), ... ] )
        pokemon_methods = defaultdict(list)
        q = pokedex_session.query(PokemonMove) \
            .options(
                eagerload_all('version_group'),
                eagerload_all('pokemon'),

                # Pokémon table trappings
                eagerload_all('pokemon.abilities'),
                eagerload_all('pokemon.egg_groups'),
                eagerload_all('pokemon.types'),
                eagerload('pokemon.stats.stat'),
            ) \
            .filter_by(move=c.move) \
            .order_by(PokemonMove.level.asc(),
                      PokemonMove.order.asc(),
                      PokemonMove.version_group_id.asc())
        for pokemon_move in q:
            method_list = pokemon_methods[pokemon_move.method]
            this_vg = pokemon_move.version_group

            # Create a container for data for this method and version(s)
            vg_data = dict()

            if pokemon_move.method.name == 'Level up':
                # Level-ups need to know what level
                vg_data['level'] = pokemon_move.level
            elif pokemon_move.method.name == 'Machine':
                # TMs need to know their own TM number
                machine = first(lambda _: _.version_group == this_vg,
                                pokemon_move.move.machines)
                if machine:
                    vg_data['machine'] = machine.machine_number

            # The Pokémon version does sorting here, but we're just going to
            # sort by name regardless of method, so leave that until last

            # Check for a free existing row for this move; if one exists, we
            # can just add our data to that same row
            valid_row = first(
                lambda (pokemon, version_group_data):
                    pokemon == pokemon_move.pokemon and \
                    this_vg not in version_group_data,
                method_list
            )
            if valid_row:
                valid_row[1][this_vg] = vg_data
                continue

            # Otherwise, we need a new row
            method_list.append(( pokemon_move.pokemon, { this_vg: vg_data } ))

        # Convert dictionary to our desired list of tuples
        c.pokemon = pokemon_methods.items()
        c.pokemon.sort(key=_pokemon_move_method_sort_key)

        # Sort by Pokémon number
        for method, method_list in c.pokemon:
            method_list.sort(key=lambda (pokemon, whatever): (pokemon.national_id, pokemon.forme_name))

        # Finally, collapse identical columns within the same generation
        c.pokemon_columns, c.pokemon_divider_columns \
            = _collapse_pokemon_move_columns(table=c.pokemon, thing=c.move)

        # Grab list of all the version groups with tutor moves
        c.move_tutor_version_groups = _move_tutor_version_groups(c.pokemon)

        return


    def types_list(self):
        c.types = pokedex_session.query(tables.Type) \
            .order_by(tables.Type.name) \
            .options(eagerload('damage_efficacies')) \
            .all()
        return render('/pokedex/type_list.mako')

    def types(self, name):
        try:
            c.type = db.get_by_name(Type, name)
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        max_id = pokedex_session.query(Type).count()
        c.prev_type = pokedex_session.query(Type).get(
            (c.type.id - 1 - 1) % max_id + 1)
        c.next_type = pokedex_session.query(Type).get(
            (c.type.id - 1 + 1) % max_id + 1)

        c.moves = pokedex_session.query(Move) \
                                 .filter_by(type_id=c.type.id) \
                                 .order_by(Move.name.asc())

        c.pokemon = pokedex_session.query(Pokemon) \
                                   .join(PokemonType) \
                                   .filter(PokemonType.type_id == c.type.id)

        c.pokemon = sorted(c.pokemon, key=lambda (pokemon): (pokemon.national_id, pokemon.forme_name))

        return render('/pokedex/type.mako')

    def abilities_list(sef):
        c.abilities = pokedex_session.query(tables.Ability) \
            .order_by(tables.Ability.id) \
            .all()
        return render('/pokedex/ability_list.mako')

    def abilities(self, name):
        try:
            c.ability = db.get_by_name(Ability, name)
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        max_id = pokedex_session.query(Ability).count()
        c.prev_ability = pokedex_session.query(Ability).get(
            (c.ability.id - 1 - 1) % max_id + 1)
        c.next_ability = pokedex_session.query(Ability).get(
            (c.ability.id - 1 + 1) % max_id + 1)

        c.pokemon = pokedex_session.query(Pokemon) \
                                   .join(PokemonAbility) \
                                   .filter(PokemonAbility.ability_id == c.ability.id)

        c.pokemon = sorted(c.pokemon, key=lambda (pokemon): (pokemon.national_id, pokemon.forme_name))

        return render('/pokedex/ability.mako')


    def items_list(self):
        c.item_pockets = pokedex_session.query(tables.ItemPocket) \
            .order_by(tables.ItemPocket.id.asc())

        return render('/pokedex/item_list.mako')

    def item_pockets(self, pocket):
        try:
            c.item_pocket = pokedex_session.query(tables.ItemPocket) \
                .filter(tables.ItemPocket.identifier == pocket) \
                .one()
        except NoResultFound:
            # It's possible this is an old item URL; redirect if so
            try:
                item = db.get_by_name(tables.Item, pocket)
                return redirect_to(controller='dex', action='items',
                                   pocket=item.pocket.identifier, name=pocket)
            except NoResultFound:
                return self._not_found()

        # OK, got a valid pocket

        c.item_pockets = pokedex_session.query(tables.ItemPocket) \
            .order_by(tables.ItemPocket.id.asc())

        return render('/pokedex/item_pockets.mako')

    def items(self, pocket, name):
        try:
            c.item = db.get_by_name(Item, name)
        except NoResultFound:
            return self._not_found()

        # These are used for their item linkage
        c.growth_mulch = pokedex_session.query(tables.Item) \
            .filter_by(name=u'Growth Mulch').one()
        c.damp_mulch = pokedex_session.query(tables.Item) \
            .filter_by(name=u'Damp Mulch').one()

        # Pokémon that can hold this item are per version; break this up into a
        # two-dimensional structure of pokemon => version => rarity
        c.holding_pokemon = defaultdict(lambda: defaultdict(int))
        held_generations = set()
        for pokemon_item in c.item.pokemon:
            c.holding_pokemon[pokemon_item.pokemon][pokemon_item.version] = pokemon_item.rarity
            held_generations.add(pokemon_item.version.generation)

        # Craft a list of versions the item appears in at all
        held_generations = list(held_generations)
        held_generations.sort(key=lambda _: _.id)
        c.held_version_columns = []
        c.held_version_last_columns = []
        for generation in held_generations:
            # Oh boy!  More version collapsing logic!
            # Try to make this as simple as possible: have a running list of
            # versions in some column, then switch to a new column when any
            # rarity changes
            current_column = []
            current_group_is_whole = True
            last_version = None
            for version in generation.versions:
                # If the any of the rarities changed, OR the version group
                # changed AND the previous group was broken up, this version
                # needs to begin a new column
                if last_version and (
                        (last_version.version_group != version.version_group
                            and not current_group_is_whole) or
                        any(
                            rarities[last_version] != rarities[version]
                            for rarities in c.holding_pokemon.values()
                        )
                    ):

                    c.held_version_columns.append(current_column)
                    current_column = []

                    # If this broke a group up, remember it
                    if last_version.version_group == version.version_group:
                        current_group_is_whole = False

                if last_version and \
                    last_version.version_group != version.version_group:
                    # If this is a new group, then the "current" group has yet
                    # to be split up
                    current_group_is_whole = True

                current_column.append(version)
                last_version = version

            # Add whatever's left at the end
            if current_column:
                c.held_version_columns.append(current_column)

            # Track which column indexes are the last of a generation
            c.held_version_last_columns.append(len(c.held_version_columns) - 1)

        return render('/pokedex/item.mako')


    def locations(self, name):
        # Note that it isn't against the rules for multiple locations to have
        # the same name.  To avoid complications, the name is stored in
        # c.location_name, and after that we only deal with areas.
        c.locations = pokedex_session.query(tables.Location) \
            .filter(func.lower(tables.Location.name) == name) \
            .all()

        if not c.locations:
            return self._not_found()

        c.location_name = c.locations[0].name

        # TODO: Sort locations/areas by generation

        # Get all the areas in any of these locations
        c.areas = []
        for location in c.locations:
            c.areas.extend(location.areas)
        c.areas.sort(key=lambda area: area.name)

        # For the most part, our data represents exactly what we're going to
        # show.  For a given area in a given game, this Pokémon is guaranteed
        # to appear some x% of the time no matter what the state of the world
        # is, and various things like swarms or the radar may add on to this
        # percentage.

        # Encounters are grouped by area -- <h2>s.
        # Then by terrain -- table sections.
        # Then by pokemon -- table rows.
        # Then by version -- table columns.
        # Finally, condition values associated with levels/rarity.
        q = pokedex_session.query(tables.Encounter) \
            .filter(tables.Encounter.location_area_id.in_(_.id for _ in c.areas))

        # area => terrain => pokemon => version => condition =>
        #     condition_values => encounter_bits
        grouped_encounters = defaultdict(
            lambda: defaultdict(
                lambda: defaultdict(
                    lambda: defaultdict(
                        lambda: defaultdict(
                            lambda: defaultdict(
                                list
                            )
                        )
                    )
                )
            )
        )

        # To avoid an ultra-wide table when not necessary, only *generations*
        # that actually contain this Pokémon should appear.
        # So if the Pokémon appears in Kanto in Crystal, show all of G/S/C.  If
        # it doesn't appear in any of the three, show none of them.
        # Last but not least, show generations in reverse order, so the more
        # important (i.e., recent) versions are on the left.
        # Got all that?
        area_generations = defaultdict(set)

        for encounter in q.all():
            # Fetches the list of encounters that match this region, version,
            # terrain, etc.

            # n.b.: conditions and values must be tuples because lists aren't
            # hashable.
            encounter_bits = grouped_encounters \
                [encounter.location_area] \
                [encounter.slot.terrain] \
                [encounter.pokemon] \
                [encounter.version] \
                [ tuple(cv.condition for cv in encounter.condition_values) ] \
                [ tuple(encounter.condition_values) ]

            # Combine "level 3-4, 50%" and "level 3-4, 20%" into "level 3-4, 70%".
            existing_encounter = filter(lambda enc: enc['min_level'] == encounter.min_level
                                                and enc['max_level'] == encounter.max_level,
                                        encounter_bits)
            if existing_encounter:
                existing_encounter[0]['rarity'] += encounter.slot.rarity
            else:
                encounter_bits.append({
                    'min_level': encounter.min_level,
                    'max_level': encounter.max_level,
                    'rarity': encounter.slot.rarity,
                })

            # Remember that this generation appears in this area
            area_generations[encounter.location_area].add(encounter.version.version_group.generation)

        c.grouped_encounters = grouped_encounters

        # Pass some data/functions
        c.encounter_terrain_icons = self.encounter_terrain_icons
        c.encounter_condition_value_icons = self.encounter_condition_value_icons
        c.level_range = level_range

        # See above.  Versions for each major group are those that are part of
        # a generation where this Pokémon appears -- in reverse generation
        # order.
        c.group_versions = defaultdict(list)
        for area, generations in area_generations.items():
            for version_group in area.location.region.version_groups:
                if version_group.generation not in generations:
                    continue
                c.group_versions[area][0:0] = version_group.versions

        return render('/pokedex/location.mako')


    def natures_list(self):
        c.natures = pokedex_session.query(tables.Nature)

        # Figure out sort order
        c.sort_order = request.params.get('sort', None)
        if c.sort_order == u'stat':
            # Sort neutral natures first, sorted by name, then the others in
            # stat order
            c.natures = c.natures.order_by(
                (tables.Nature.increased_stat_id
                    == tables.Nature.decreased_stat_id).desc(),
                tables.Nature.increased_stat_id.asc(),
                tables.Nature.decreased_stat_id.asc(),
            )
        else:
            c.natures = c.natures.order_by(tables.Nature.name.asc())

        return render('/pokedex/nature_list.mako')

    def natures(self, name):
        try:
            c.nature = db.get_by_name(tables.Nature, name)
        except NoResultFound:
            return self._not_found()

        # Find related natures.
        # Other neutral natures if this one is neutral; otherwise, the inverse
        # of this one
        if c.nature.increased_stat == c.nature.decreased_stat:
            c.neutral_natures = pokedex_session.query(tables.Nature) \
                .filter(tables.Nature.increased_stat_id
                     == tables.Nature.decreased_stat_id) \
                .filter(tables.Nature.id != c.nature.id) \
                .order_by(tables.Nature.name)
        else:
            c.inverse_nature = pokedex_session.query(tables.Nature) \
                .filter_by(
                    increased_stat_id=c.nature.decreased_stat_id,
                    decreased_stat_id=c.nature.increased_stat_id,
                ) \
                .one()

        # Find appropriate example Pokémon.
        # Arbitrarily decided that these are Pokémon for which:
        # - their best and worst stats are at least 10 apart
        # - their best stat is improved by this nature
        # - their worst stat is hindered by this nature
        # Of course, if this is a neutral nature, then find only Pokémon for
        # which the best and worst stats are close together.
        # The useful thing here is that this cannot be done in the Pokémon
        # search, as it requires comparing a Pokémon's stats to themselves.
        # Also, HP doesn't count.  Durp.
        hp = pokedex_session.query(tables.Stat).filter_by(name=u'HP').one()
        if c.nature.increased_stat == c.nature.decreased_stat:
            # Neutral.  Boring!
            # Create a subquery of neutral-ish Pokémon
            stat_subquery = pokedex_session.query(
                    tables.PokemonStat.pokemon_id
                ) \
                .filter(tables.PokemonStat.stat_id != hp.id) \
                .group_by(tables.PokemonStat.pokemon_id) \
                .having(
                    func.max(tables.PokemonStat.base_stat)
                    - func.min(tables.PokemonStat.base_stat)
                    <= 10
                ) \
                .subquery()

            c.pokemon = pokedex_session.query(tables.Pokemon) \
                .join((stat_subquery,
                    stat_subquery.c.pokemon_id == tables.Pokemon.id))

        else:
            # More interesting.
            # Create the subquery again, but..  the other way around.
            grouped_stats = aliased(tables.PokemonStat)
            stat_range_subquery = pokedex_session.query(
                    grouped_stats.pokemon_id,
                    func.max(grouped_stats.base_stat).label('max_stat'),
                    func.min(grouped_stats.base_stat).label('min_stat'),
                ) \
                .filter(grouped_stats.stat_id != hp.id) \
                .group_by(grouped_stats.pokemon_id) \
                .having(
                    func.max(grouped_stats.base_stat)
                    - func.min(grouped_stats.base_stat)
                    > 10
                ) \
                .subquery()

            # Also need to join twice more to PokemonStat to figure out WHICH
            # of those stats is the max or min.  So, yes, joining to the same
            # table three times and two deep.  One to make sure the Pokémon has
            # the right lowest stat; one to make sure it has the right highest
            # stat.
            # Note that I really want to do: range --> min; --> max
            # But SQLAlchemy won't let me start from a subquery like that, so
            # instead I do min --> range --> max.  :(  Whatever.
            min_stats = aliased(tables.PokemonStat)
            max_stats = aliased(tables.PokemonStat)
            minmax_stat_subquery = pokedex_session.query(
                    min_stats
                ) \
                .join((stat_range_subquery, and_(
                        min_stats.base_stat == stat_range_subquery.c.min_stat,
                        min_stats.pokemon_id == stat_range_subquery.c.pokemon_id,
                    )
                )) \
                .join((max_stats, and_(
                        max_stats.base_stat == stat_range_subquery.c.max_stat,
                        max_stats.pokemon_id == stat_range_subquery.c.pokemon_id,
                    )
                )) \
                .filter(min_stats.stat_id == c.nature.decreased_stat_id) \
                .filter(max_stats.stat_id == c.nature.increased_stat_id) \
                .subquery()

            # Finally, just join that mess to pokemon; INNER-ness will do all
            # the filtering
            c.pokemon = pokedex_session.query(tables.Pokemon) \
                .join((minmax_stat_subquery,
                    minmax_stat_subquery.c.pokemon_id == tables.Pokemon.id))

        # Order by id as per usual
        c.pokemon = c.pokemon.order_by(tables.Pokemon.id.asc())

        return render('/pokedex/nature.mako')
