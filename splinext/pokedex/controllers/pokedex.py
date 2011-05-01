# encoding: utf8
from __future__ import absolute_import, division

from collections import defaultdict, namedtuple
import colorsys
import json
import logging
import mimetypes
import os.path
import re
import warnings

import pokedex.db
import pokedex.db.tables as tables
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from pylons.decorators import jsonify
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased, contains_eager, eagerload, eagerload_all, join, joinedload, joinedload_all, subqueryload, subqueryload_all
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import exists, func

from spline import model
from spline.model import meta
from spline.lib.base import render
from spline.lib import helpers as h

from splinext.pokedex import db, helpers as pokedex_helpers, PokedexBaseController
import splinext.pokedex.db as db
from splinext.pokedex.magnitude import parse_size

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
    # XXX see FakeMoveMethod for explanation of this abomination
    try:
        p = -method.pokemon.order
    except AttributeError:
        p = None
    if method.name in (u'Tutor', u'Machine'):
        return method.id + 1000, p
    else:
        return method.id, p

def _collapse_pokemon_move_columns(table, thing):
    """Combines adjacent identical columns in a pokemon_move structure.

    Arguments are the table structure (defined in comments below) and the
    Pokémon or move in question.

    Returns a list of column groups, each represented by a list of its columns,
    like `[ [ [gs, c] ], [ [rs, e], [fl] ], ... ]`
    """

    # What we really need to know is what versions are ultimately collapsed
    # into each column.  We also need to know how the columns are grouped into
    # generations.  So we need a list of lists of lists of version groups:
    move_columns = []

    # Only even consider versions in which this thing actually exists
    q = db.pokedex_session.query(tables.Generation) \
                       .filter(tables.Generation.id >= thing.generation_id) \
                       .options(joinedload('version_groups')) \
                       .order_by(tables.Generation.id.asc())
    for generation in q:
        move_columns.append( [] ) # A new column group for this generation
        for i, version_group in enumerate(generation.version_groups):
            if i == 0:
                # Can't collapse these versions anywhere!  Create a new column
                move_columns[-1].append( [version_group] )
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
                    if version_group_data.get(version_group, None) != \
                       version_group_data.get(move_columns[-1][-1][-1], None):
                        break
                else:
                    continue

                break # We broke out and didn't get to continue—not squashable
            else:
                # Stick this version group in the previous column
                move_columns[-1][-1].append(version_group)
                continue

            # Create a new column
            move_columns[-1].append( [version_group] )

    return move_columns

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

    Assumed to have the same method.  Also location and area and so forth, but
    those aren't actually needed.
    """
    def __init__(self, encounter=None):
        self.method = None
        self.rarity = 0
        self.min_level = 0
        self.max_level = 0

        if encounter:
            self.combine_with(encounter)

    def combine_with(self, encounter):
        if self.method and self.method != encounter.slot.method:
            raise ValueError(
                "Can't combine method {0} with {1}"
                .format(self.method.name, encounter.slot.method.name)
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

def wsgi_stream_file(f):
    while True:
        buf = f.read(4096)
        if not buf:
            break
        yield buf

class PokedexController(PokedexBaseController):

    # Used by lookup disambig pages
    table_labels = {
        tables.Ability: 'ability',
        tables.Item: 'item',
        tables.Location: 'location',
        tables.Move: 'move',
        tables.Nature: 'nature',
        tables.Pokemon: u'Pokémon',
        tables.PokemonForm: u'Pokémon form',
        tables.Type: 'type',
    }

    # Dict of method identifier => icon path
    encounter_method_icons = {
        'surf': 'surfing.png',
        'old-rod': 'old-rod.png',
        'good-rod': 'good-rod.png',
        'super-rod': 'super-rod.png',
        'walk': 'grass.png',
        'rock-smash': 'rock-smash.png',
    }

    # Maps condition value identifiers to representative icons
    encounter_condition_value_icons = {
        'swarm-no': 'swarm-no.png',
        'swarm-yes': 'swarm-yes.png',
        'time-morning': 'time-morning.png',
        'time-day': 'time-daytime.png',
        'time-night': 'time-night.png',
        'radar-off': 'pokeradar-off.png',
        'radar-on': 'pokeradar-on.png',
        'slot2-none': 'slot2-none.png',
        'slot2-ruby': 'slot2-ruby.png',
        'slot2-sapphire': 'slot2-sapphire.png',
        'slot2-emerald': 'slot2-emerald.png',
        'slot2-firered': 'slot2-firered.png',
        'slot2-leafgreen': 'slot2-leafgreen.png',
        'radio-off': 'radio-off.png',
        'radio-hoenn': 'radio-hoenn.png',
        'radio-sinnoh': 'radio-sinnoh.png',
    }

    def __before__(self, action, **params):
        super(PokedexController, self).__before__(action, **params)

        c.javascripts.append(('pokedex', 'pokedex'))

    def cache_content(self, key, do_work, template):
        key = key + '-' + c.game_language.identifier
        return super(PokedexController, self).cache_content(key, do_work, template)

    def index(self):
        return ''

    def media(self, path):
        media_dir = config.get('spline-pokedex.media_directory', None)
        if not media_dir:
            warnings.warn(
                "No media_directory found; "
                "you may want to clone pokedex-media.git")
            abort(404)

        (mimetype, _) = mimetypes.guess_type(path)
        response.headers['content-type'] = mimetype

        media_path = os.path.join(media_dir, path)
        return wsgi_stream_file(open(media_path))

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
        lookup = name.lower()

        ### Special stuff that bypasses lookup
        if lookup == 'obdurate':
            # Pokémon flavor text in the D/P font
            return self._egg_unlock_cheat('obdurate')


        ### Regular lookup
        valid_types = []
        c.subpage = None
        # Subpage suffixes: 'flavor' and 'locations' for Pokémon bits
        if lookup.endswith((u' flavor', u' flavour')):
            c.subpage = 'flavor'
            valid_types = [u'pokemon', u'pokemon_forms']
            name = re.sub('(?i) flavou?r$', '', name)
        elif lookup.endswith(u' locations'):
            c.subpage = 'locations'
            valid_types = [u'pokemon']
            name = re.sub('(?i) locations$', '', name)

        results = db.pokedex_lookup.lookup(name, valid_types=valid_types)

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

            return redirect(pokedex_helpers.make_thingy_url(
                results[0].object, subpage=c.subpage))

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

        suggestions = db.pokedex_lookup.prefix_lookup(
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
            if isinstance(row, tables.Pokemon):
                if row.form_name:
                    image = u"pokemon/icons/{0}-{1}.png".format(row.normal_form.id, row.form_name.lower())
                else:
                    image = u"pokemon/icons/{0}.png".format(row.normal_form.id)
            elif isinstance(row, tables.PokemonForm):
                if row.name:
                    image = u"pokemon/icons/{0}-{1}.png".format(row.form_base_pokemon_id, row.name.lower())
                else:
                    image = u"pokemon/icons/{0}.png".format(row.form_base_pokemon_id)
            elif isinstance(row, tables.Move):
                image = u"types/{1}/{0}.png".format(row.type.name.lower(),
                        c.game_language.identifier)
            elif isinstance(row, tables.Type):
                image = u"types/{1}/{0}.png".format(row.name.lower(),
                        c.game_language.identifier)
            elif isinstance(row, tables.Item):
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

        normalized_name = db.pokedex_lookup.normalize_name(prefix)
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


    def _prev_next(self, table, current, filters=[]):
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

    def _prev_next_pokemon(self, pokemon):
        """Returns a 2-tuple of the previous and next Pokémon."""
        max_id = db.pokedex_session.query(tables.Pokemon) \
                                .filter(tables.Pokemon.forms.any()) \
                                .count()
        prev_pokemon = db.pokedex_session.query(tables.PokemonSpecies).get(
            (c.pokemon.species.id - 1 - 1) % max_id + 1).default_pokemon
        next_pokemon = db.pokedex_session.query(tables.PokemonSpecies).get(
            (c.pokemon.species.id - 1 + 1) % max_id + 1).default_pokemon
        return prev_pokemon, next_pokemon

    @jsonify
    def parse_size(self):
        u"""Parses a height or weight and returns a bare number in Pokémon
        units.

        Query params are `size`, the string, and `mode`, either 'height' or
        'weight'.
        """

        size = request.params.get('size', None)
        mode = request.params.get('mode', None)

        if not size or mode not in (u'height', u'weight'):
            # Totally bogus!
            abort(400)

        try:
            return parse_size(size, mode)
        except (IndexError, ValueError):
            abort(400)

    def pokemon_list(self):
        return render('/pokedex/pokemon_list.mako')

    def pokemon(self, name=None):
        form = request.params.get('form', None)
        try:
            pokemon_q = db.pokemon_query(name, form)

            # Need to eagerload some, uh, little stuff
            pokemon_q = pokemon_q.options(
                joinedload(tables.Pokemon.abilities, tables.Ability.prose_local),
                joinedload(tables.Pokemon.dream_ability, tables.Ability.prose_local),
                eagerload('evolution_chain.pokemon'),
                eagerload('generation'),
                eagerload('items.item'),
                eagerload('items.version'),
                eagerload('species'),
                eagerload('species.color'),
                eagerload('species.habitat'),
                eagerload('species.shape'),
                eagerload('species.egg_groups'),
                subqueryload_all('stats.stat'),
                subqueryload_all('types.target_efficacies.damage_type'),
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
            key=c.pokemon.default_form.name,
            template='/pokedex/pokemon.mako',
            do_work=self._do_pokemon,
        )

    def _do_pokemon(self, name_plus_form):

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
        if c.pokemon.species.gender_rate == -1:
            # Genderless; Ditto only
            ditto = db.pokedex_session.query(tables.PokemonSpecies) \
                .filter_by(identifier='ditto').one()
            c.compatible_families = [ditto]
        elif c.pokemon.species.egg_groups[0].id == 15:
            # No Eggs group
            pass
        else:
            parent_a = aliased(tables.PokemonSpecies)
            grandparent_a = aliased(tables.PokemonSpecies)
            egg_group_ids = [group.id for group in c.pokemon.species.egg_groups]
            q = db.pokedex_session.query(tables.PokemonSpecies)
            q = q.join(tables.PokemonEggGroup) \
                 .outerjoin((parent_a, tables.PokemonSpecies.parent_species)) \
                 .outerjoin((grandparent_a, parent_a.parent_species)) \
                 .filter(tables.PokemonSpecies.gender_rate != -1) \
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
                             grandparent_a.id == None),
                    )
                 ) \
                 .filter(tables.PokemonEggGroup.egg_group_id.in_(egg_group_ids)) \
                 .options(joinedload('unique_form')) \
                 .order_by(tables.PokemonSpecies.id)
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
        # n.b.: the keys are tuples of versions, not individual versions!
        version_held_items = {}
        # Preload with a list of versions so we know which ones are empty
        generations = db.pokedex_session.query(tables.Generation) \
            .options( eagerload('versions') ) \
            .filter(tables.Generation.id >= max(3, c.pokemon.species.generation_id))
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
        # The Pokémon are actually dictionaries with 'pokemon' and 'span' keys,
        # where the span is used as the HTML cell's rowspan -- e.g., Eevee has a
        # total of seven descendents, so it would need to span 7 rows.
        c.evolution_table = []
        # Prefetch the evolution details
        family = db.pokedex_session.query(tables.PokemonSpecies) \
            .filter(tables.PokemonSpecies.evolution_chain_id ==
                    c.pokemon.species.evolution_chain_id) \
            .options(
                subqueryload('evolutions'),
                joinedload('evolutions.trigger'),
                joinedload('evolutions.trigger_item'),
                joinedload('evolutions.held_item'),
                joinedload('evolutions.location'),
                joinedload('evolutions.known_move'),
                joinedload('evolutions.party_pokemon'),
                joinedload('parent_pokemon'),
                joinedload('unique_form'),
            ) \
            .all()
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
        # This takes a lot of queries  :(
        c.stats = {}  # stat_name => { border, background, percentile }
                      #              (also 'value' for total)
        stat_total = 0
        total_stat_rows = db.pokedex_session.query(tables.PokemonStat) \
                                         .filter_by(stat=c.pokemon.stats[0].stat) \
                                         .count()
        physical_attack = None
        special_attack = None
        for pokemon_stat in c.pokemon.stats:
            stat_info = c.stats[pokemon_stat.stat.name] = {}
            stat_total += pokemon_stat.base_stat
            q = db.pokedex_session.query(tables.PokemonStat) \
                               .filter_by(stat=pokemon_stat.stat)
            less = q.filter(tables.PokemonStat.base_stat < pokemon_stat.base_stat) \
                    .count()
            equal = q.filter(tables.PokemonStat.base_stat == pokemon_stat.base_stat) \
                     .count()
            percentile = (less + equal * 0.5) / total_stat_rows
            stat_info['percentile'] = percentile

            # Colors for the stat bars, based on percentile
            stat_info['background'] = bar_color(percentile, 0.9)
            stat_info['border'] = bar_color(percentile, 0.8)

        c.better_damage_class = c.pokemon.better_damage_class

        # Percentile for the total
        # Need to make a derived table that fakes pokemon_id, total_stats
        stat_sum_tbl = db.pokedex_session.query(
                func.sum(tables.PokemonStat.base_stat).label('stat_total')
            ) \
            .group_by(tables.PokemonStat.pokemon_id) \
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

        ### Pokéathlon stats
        # Unown collapses to letters and punctuation.  Shellos and Gastrodon
        # can collapse entirely.  Nothing else collapses at all.  (Arceus
        # /could/ have two pairs of types collapse, but who cares.)

        # Show all forms' stats for the base form, or else just this form's
        forms = [form for form in c.pokemon.forms or [c.pokemon.unique_form]
                 if form.pokeathlon_stats]

        if not forms:
            # No stats
            c.pokeathlon_stats = None
        elif len(forms) == 1 or c.pokemon.id in (422, 423):
            # Only one set of stats, or Shellos/Gastrodon
            c.pokeathlon_stats = [(None, forms[0].pokeathlon_stats)]
        elif c.pokemon.id == 201:
            # Use Unown A's stats for all the letters and !'s stats for ! and ?
            c.pokeathlon_stats = [('A-Z', forms[0].pokeathlon_stats),
                                  ('! and ?', forms[26].pokeathlon_stats)]
        else:
            # Different stats for every form
            c.pokeathlon_stats = [(form.full_name or 'Normal',
                                   form.pokeathlon_stats) for form in forms]

        ### Sizing
        c.trainer_height = pokedex_helpers.trainer_height
        c.trainer_weight = pokedex_helpers.trainer_weight
        heights = dict(pokemon=c.pokemon.height, trainer=c.trainer_height)
        c.heights = pokedex_helpers.scale_sizes(heights)
        # Strictly speaking, weight takes three dimensions.  But the real
        # measurement here is just "space taken up", and these are sprites, so
        # the space they actually take up is two-dimensional.
        weights = dict(pokemon=c.pokemon.weight, trainer=c.trainer_weight)
        c.weights = pokedex_helpers.scale_sizes(weights, dimensions=2)

        ### Encounters -- briefly
        # One row per version, then a list of places the Pokémon appears.
        # version => method => location_area => conditions => CombinedEncounters
        c.locations = defaultdict(
            lambda: defaultdict(
                lambda: defaultdict(
                    lambda: defaultdict(
                        CombinedEncounter
                    )
                )
            )
        )

        q = db.pokedex_session.query(tables.Encounter) \
            .filter_by(pokemon=c.pokemon) \
            .options(
                eagerload_all('condition_value_map.condition_value'),
                eagerload_all('version'),
                eagerload_all('slot.method'),
                eagerload_all('location_area.location'),
            )
        for encounter in q:
            condition_values = [cv for cv in encounter.condition_values
                                   if not cv.is_default]
            c.locations[encounter.version] \
                       [encounter.slot.method] \
                       [encounter.location_area] \
                       [tuple(condition_values)].combine_with(encounter)

        # Strip each version+location down to just the condition values that
        # are the most common per method
        # Results in:
        # version => location_area => method => (conditions, combined_encounter)
        for version, method_etc in c.locations.items():
            for method, area_condition_encounters \
                in method_etc.items():
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
        c.encounter_method_icons = self.encounter_method_icons

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
        q = db.pokedex_session.query(tables.PokemonMove) \
            .outerjoin((tables.Machine, tables.PokemonMove.machine)) \
            .outerjoin((tables.PokemonMoveMethod, tables.PokemonMove.method))
        # Evolved Pokémon ought to show their predecessors' egg moves.
        # So far, no species evolves from a parent with multiple functional
        # forms, but don't rely on that
        possible_ancestors = set([c.pokemon])
        ancestors = []
        while possible_ancestors:
            ancestor = possible_ancestors.pop()
            ancestors.append(ancestor)
            parent_species = ancestor.species.parent_species
            if parent_species:
                possible_ancestors.update(parent_species.pokemon)
        if ancestors:
            # Include any moves learnable by an ancestor...
            ancestor_ids = [p.id for p in ancestors]
            ancestor_ids.append(c.pokemon.id)
            q = q.filter(tables.PokemonMove.pokemon_id.in_(ancestor_ids))

            # That AREN'T learnable by this Pokémon.  This NOT EXISTS strips
            # out moves that are also learned by a "higher-ordered" Pokémon.
            pm_outer = tables.PokemonMove
            p_outer = tables.Pokemon
            pm_inner = aliased(tables.PokemonMove)
            p_inner = aliased(tables.Pokemon)

            from_inner = join(pm_inner, p_inner, onclause=pm_inner.pokemon)
            clause = exists(from_inner.select()).where(and_(
                pm_outer.version_group_id == pm_inner.version_group_id,
                pm_outer.move_id == pm_inner.move_id,
                pm_outer.pokemon_move_method_id == pm_inner.pokemon_move_method_id,
                pm_inner.pokemon_id.in_(ancestor_ids),
                p_outer.order < p_inner.order,
            ))

            q = q.outerjoin(tables.PokemonMove.pokemon).filter(~ clause)
        else:
            q = q.filter(tables.PokemonMove.pokemon_id == c.pokemon.id)
        # Grab the rows with a manual query so we can sort them in about the
        # order they go in the table.  This should keep it as compact as
        # possible.  Levels go in level order, and machines go in TM number
        # order
        q = q.options(
                 contains_eager(tables.PokemonMove.machine),
                 contains_eager(tables.PokemonMove.method),
                 # n.b: contains_eager interacts badly with joinedload with
                 # innerjoin=True.  Disable the inner joining explicitly.
                 # See: http://www.sqlalchemy.org/trac/ticket/2120
                 joinedload(
                     tables.PokemonMove.machine, tables.Machine.version_group,
                     innerjoin=False),
                 eagerload_all('move.damage_class'),
                 joinedload_all(tables.PokemonMove.move,
                     tables.Move.move_effect,
                     tables.MoveEffect.prose_local),
                 eagerload_all('move.type'),
                 eagerload_all('version_group'),
             ) \
            .order_by(tables.PokemonMove.level.asc(),
                      tables.Machine.machine_number.asc(),
                      tables.PokemonMove.order.asc(),
                      tables.PokemonMove.version_group_id.asc()) \
            .all()
        # TODO this nonsense is to allow methods that don't actually exist,
        # such as for parent's egg moves.  should go away once move tables get
        # their own rendery class
        FakeMoveMethod = namedtuple('FakeMoveMethod',
            ['id', 'name', 'description', 'pokemon'])
        methods_cache = {}
        def find_method(pm):
            key = pm.method, pm.pokemon
            if key not in methods_cache:
                methods_cache[key] = FakeMoveMethod(
                    id=pm.method.id, name=pm.method.name,
                    description=pm.method.description,
                    pokemon=pm.pokemon)
            return methods_cache[key]

        for pokemon_move in q:
            method = find_method(pokemon_move)
            method_list = move_methods[method]
            this_vg = pokemon_move.version_group

            # Create a container for data for this method and version(s)
            vg_data = dict()

            # TMs need to know their own TM number
            if method.name == 'Machine':
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
            if method.name in ('Level up', 'Machine'):
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
        c.move_columns \
            = _collapse_pokemon_move_columns(table=c.moves, thing=c.pokemon.species)

        # Grab list of all the version groups with tutor moves
        c.move_tutor_version_groups = _move_tutor_version_groups(c.moves)

        return


    def pokemon_flavor(self, name):
        form = request.params.get('form', None)

        try:
            c.form = db.pokemon_form_query(name, form=form).one()
        except NoResultFound:
            return self._not_found()

        c.pokemon = c.form.pokemon

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_pokemon(c.pokemon)

        return self.cache_content(
            key=u';'.join((c.pokemon.name, c.form.name or u'')),
            template='/pokedex/pokemon_flavor.mako',
            do_work=self._do_pokemon_flavor,
        )

    def _do_pokemon_flavor(self, name_plus_form):
        c.sprites = {}

        def sprite_exists(directory):
            """Return whether or not a sprite exists for this Pokémon in the
            specified directory, checking if need be.

            Avoids calling resource_exists() multiple times per sprite.
            """

            # n.b. calling dict.setdefault always evaluates the default
            if directory not in c.sprites:
                c.sprites[directory] = pokedex_helpers.pokemon_has_media(
                    c.form, directory, 'png')
            return c.sprites[directory]
        c.sprite_exists = sprite_exists

        # Figure out if a sprite form appears in the overworld
        c.appears_in_overworld = c.form.is_default or (
            c.form.form_base_pokemon.form_group and not
            c.form.form_base_pokemon.form_group.is_battle_only
        )

        # Some sprite-existence shortcuts based on this information
        c.sprites['overworld'] = (c.appears_in_overworld and
            c.form.introduced_in_version_group_id <= 10)
        c.sprites['emerald/animated'] = (c.appears_in_overworld and
            c.form.introduced_in_version_group_id <= 6)

        ### Sizing
        c.trainer_height = pokedex_helpers.trainer_height
        c.trainer_weight = pokedex_helpers.trainer_weight

        heights = {'pokemon': c.pokemon.height, 'trainer': c.trainer_height}
        c.heights = pokedex_helpers.scale_sizes(heights)

        # Strictly speaking, weight takes three dimensions.  But the real
        # measurement here is just "space taken up", and these are sprites, so
        # the space they actually take up is two-dimensional.
        weights = {'pokemon': c.pokemon.weight, 'trainer': c.trainer_weight}
        c.weights = pokedex_helpers.scale_sizes(weights, dimensions=2)


    def pokemon_locations(self, name):
        """Spits out a page listing detailed location information for this
        Pokémon.
        """
        try:
            c.pokemon = db.pokemon_query(name).one()
        except NoResultFound:
            return self._not_found()

        ### Previous and next for the header
        c.prev_pokemon, c.next_pokemon = self._prev_next_pokemon(c.pokemon)

        # Cache it yo
        return self.cache_content(
            key=c.pokemon.name,
            template='/pokedex/pokemon_locations.mako',
            do_work=self._do_pokemon_locations,
        )

    def _do_pokemon_locations(self, name):
        # For the most part, our data represents exactly what we're going to
        # show.  For a given area in a given game, this Pokémon is guaranteed
        # to appear some x% of the time no matter what the state of the world
        # is, and various things like swarms or the radar may add on to this
        # percentage.

        # Encounters are grouped by region -- <h1>s.
        # Then by method -- table sections.
        # Then by area -- table rows.
        # Then by version -- table columns.
        # Finally, condition values associated with levels/rarity.
        q = db.pokedex_session.query(tables.Encounter) \
            .options(
                eagerload_all('condition_value_map.condition_value'),
                eagerload_all('version'),
                eagerload_all('slot.method'),
                eagerload_all('location_area.location'),
            )\
            .filter(tables.Encounter.pokemon == c.pokemon)

        # region => method => area => version => condition =>
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
            # method, etc.
            region = encounter.location_area.location.region

            # n.b.: conditions and values must be tuples because lists aren't
            # hashable.
            encounter_bits = grouped_encounters \
                [region] \
                [encounter.slot.method] \
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
        c.encounter_method_icons = self.encounter_method_icons
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

        return

    def moves_list(self):
        return render('/pokedex/move_list.mako')

    def moves(self, name):
        try:
            c.move = db.get_by_name_query(tables.Move, name).one()
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        # Shadow moves have the prev/next Shadow move; other moves skip them
        if c.move.type_id == 10002:
            shadowness = tables.Move.type_id == 10002
        else:
            shadowness = tables.Move.type_id != 10002

        c.prev_move, c.next_move = self._prev_next(
                table=tables.Move,
                filters=[shadowness],
                current=c.move,
            )

        return self.cache_content(
            key=c.move.name,
            template='/pokedex/move.mako',
            do_work=self._do_moves,
        )

    def _do_moves(self, name):
        # Eagerload
        db.pokedex_session.query(tables.Move) \
            .filter_by(id=c.move.id) \
            .options(
                eagerload('damage_class'),
                eagerload('type'),
                subqueryload('type.damage_efficacies'),
                joinedload('type.damage_efficacies.target_type'),
                eagerload('target'),
                eagerload('move_effect'),
                eagerload_all(tables.Move.contest_effect, tables.ContestEffect.prose),
                eagerload('contest_type'),
                #eagerload('super_contest_effect'),
                joinedload('move_flags.flag'),
                subqueryload_all('names'),
                joinedload(tables.Move.flavor_text, tables.MoveFlavorText.version_group),
                joinedload(tables.Move.flavor_text, tables.MoveFlavorText.version_group, tables.VersionGroup.generation),
                joinedload(tables.Move.flavor_text, tables.MoveFlavorText.version_group, tables.VersionGroup.versions),
                joinedload('contest_combo_first.second'),
                joinedload('contest_combo_second.first'),
                joinedload('super_contest_combo_first.second'),
                joinedload('super_contest_combo_second.first'),
            ) \
            .one()

        # Used for item linkage
        c.pp_up = db.pokedex_session.query(tables.Item) \
            .filter_by(identifier=u'pp-up').one()

        ### Power percentile
        if c.move.power in (0, 1):
            c.power_percentile = None
        else:
            q = db.pokedex_session.query(tables.Move) \
                .filter(tables.Move.power > 1)
            less = q.filter(tables.Move.power < c.move.power).count()
            equal = q.filter(tables.Move.power == c.move.power).count()
            c.power_percentile = (less + equal * 0.5) / q.count()

        ### Flags
        c.flags = []
        move_flags = db.pokedex_session.query(tables.MoveFlag) \
                                    .order_by(tables.MoveFlag.id.asc())
        for flag in move_flags:
            has_flag = flag in c.move.flags
            c.flags.append((flag, has_flag))

        ### Machines
        q = db.pokedex_session.query(tables.Generation) \
            .filter(tables.Generation.id >= c.move.generation.id) \
            .options(
                eagerload('version_groups'),
            ) \
            .order_by(tables.Generation.id.asc())
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

        ### Similar moves
        c.similar_moves = db.pokedex_session.query(tables.Move) \
            .join(tables.Move.move_effect) \
            .filter(tables.MoveEffect.id == c.move.effect_id) \
            .filter(tables.Move.id != c.move.id) \
            .options(eagerload('type')) \
            .all()

        ### Pokémon
        # This is kinda like the moves for Pokémon, but backwards.  Imagine
        # that!  We have the same basic structure, a list of:
        #     (method, [ (pokemon, { version_group => data, ... }), ... ])
        pokemon_methods = defaultdict(dict)
        # Sort by descending level because the LAST level seen is the one that
        # ends up in the table, and the lowest level is the most useful
        q = db.pokedex_session.query(tables.PokemonMove) \
            .options(
                eagerload('method'),
                eagerload('pokemon'),
                eagerload('version_group'),
                eagerload('pokemon.form_group'),
                eagerload('pokemon.stats.stat'),
                eagerload('pokemon.stats.stat.damage_class'),
                eagerload('pokemon.unique_form'),

                # Pokémon table stuff
                subqueryload('pokemon.abilities'),
                subqueryload('pokemon.dream_ability'),
                subqueryload('pokemon.species'),
                subqueryload('pokemon.species.egg_groups'),
                subqueryload('pokemon.stats'),
                subqueryload('pokemon.types'),
            ) \
            .filter(tables.PokemonMove.move_id == c.move.id) \
            .order_by(tables.PokemonMove.level.desc())
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
                                c.move.machines)
                if machine:
                    vg_data['machine'] = machine.machine_number

            # The Pokémon version does sorting here, but we're just going to
            # sort by name regardless of method, so leave that until last

            # Add in the move method for this Pokémon
            if pokemon_move.pokemon not in method_list:
                method_list[pokemon_move.pokemon] = dict()

            method_list[pokemon_move.pokemon][this_vg] = vg_data

        # Convert each method dictionary to a list of tuples
        c.better_damage_classes = {}
        for method in pokemon_methods.keys():
            # Also grab Pokémon's better damage classes
            for pokemon in pokemon_methods[method].keys():
                if pokemon not in c.better_damage_classes:
                    c.better_damage_classes[pokemon] = \
                        pokemon.better_damage_class

            pokemon_methods[method] = pokemon_methods[method].items()

        # Convert the entire dictionary to a list of tuples and sort it
        c.pokemon = pokemon_methods.items()
        c.pokemon.sort(key=_pokemon_move_method_sort_key)

        for method, method_list in c.pokemon:
            # Sort each method's rows by their Pokémon
            method_list.sort(key=lambda row: row[0].order)

        # Finally, collapse identical columns within the same generation
        c.pokemon_columns \
            = _collapse_pokemon_move_columns(table=c.pokemon, thing=c.move)

        # Grab list of all the version groups with tutor moves
        c.move_tutor_version_groups = _move_tutor_version_groups(c.pokemon)

        return


    def types_list(self):
        c.types = db.pokedex_session.query(tables.Type) \
            .join(tables.Type.names_local) \
            .filter(tables.Type.damage_efficacies.any()) \
            .order_by(tables.Type.names_table.name) \
            .options(contains_eager(tables.Type.names_local)) \
            .options(eagerload('damage_efficacies')) \
            .all()

        if 'secondary' in request.params:
            try:
                c.secondary_type = db.get_by_name_query(
                        tables.Type, request.params['secondary'].lower()) \
                    .filter(tables.Type.damage_efficacies.any()) \
                    .options(eagerload('target_efficacies')) \
                    .one()
            except NoResultFound:
                abort(404)

            c.secondary_efficacy = dict(
                (efficacy.damage_type, efficacy.damage_factor)
                for efficacy in c.secondary_type.target_efficacies
            )
        else:
            c.secondary_type = None
            c.secondary_efficacy = defaultdict(lambda: 100)

        # Count up a relative score for each type, both attacking and
        # defending.  Normal damage counts for 0; super effective counts for
        # +1; not very effective counts for -1.  Ineffective counts for -2.
        # With dual types, x4 is +2 and x1/4 is -2; ineffective is -4.
        # Everything is of course the other way around for defense.
        attacking_score_conversion = {
            400: +2,
            200: +1,
            100:  0,
             50: -1,
             25: -2,
              0: -2,
        }
        if c.secondary_type:
            attacking_score_conversion[0] = -4

        c.attacking_scores = defaultdict(int)
        c.defending_scores = defaultdict(int)
        for attacking_type in c.types:
            for efficacy in attacking_type.damage_efficacies:
                defending_type = efficacy.target_type
                factor = efficacy.damage_factor * \
                    c.secondary_efficacy[attacking_type] // 100

                c.attacking_scores[attacking_type] += attacking_score_conversion[factor]
                c.defending_scores[defending_type] -= attacking_score_conversion[factor]

        return render('/pokedex/type_list.mako')

    def types(self, name):
        try:
            c.type = db.get_by_name_query(tables.Type, name).one()
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        c.prev_type, c.next_type = self._prev_next(
                table=tables.Type,
                current=c.type,
            )

        return self.cache_content(
            key=c.type.name,
            template='/pokedex/type.mako',
            do_work=self._do_types,
        )

    def _do_types(self, name):
        # Eagerload a bit of type stuff
        db.pokedex_session.query(tables.Type) \
            .filter_by(id=c.type.id) \
            .options(
                subqueryload('damage_efficacies'),
                joinedload('damage_efficacies.target_type'),
                subqueryload('target_efficacies'),
                joinedload('target_efficacies.damage_type'),

                # Move stuff
                subqueryload('moves'),
                joinedload('moves.damage_class'),
                joinedload('moves.generation'),
                joinedload('moves.move_effect'),
                joinedload('moves.type'),

                # Pokémon stuff
                subqueryload('pokemon'),
                joinedload('pokemon.abilities'),
                joinedload('pokemon.dream_ability'),
                joinedload('pokemon.species'),
                subqueryload('pokemon.species.egg_groups'),
                joinedload('pokemon.types'),
                joinedload('pokemon.stats'),
            ) \
            .one()

        return

    def abilities_list(sef):
        c.abilities = db.pokedex_session.query(tables.Ability) \
            .join(tables.Ability.names_local) \
            .options(eagerload('short_effect')) \
            .order_by(tables.Ability.generation_id.asc(),
                tables.Ability.names_table.name.asc()) \
            .all()
        return render('/pokedex/ability_list.mako')

    def abilities(self, name):
        try:
            c.ability = db.get_by_name_query(tables.Ability, name).one()
        except NoResultFound:
            return self._not_found()

        ### Prev/next for header
        c.prev_ability, c.next_ability = self._prev_next(
                table=tables.Ability,
                current=c.ability,
            )

        return self.cache_content(
            key=c.ability.name,
            template='/pokedex/ability.mako',
            do_work=self._do_ability,
        )

    def _do_ability(self, name):
        # Eagerload
        db.pokedex_session.query(tables.Ability) \
            .filter_by(id=c.ability.id) \
            .options(
                joinedload(tables.Ability.names_local),

                subqueryload(tables.Ability.flavor_text),
                joinedload(tables.Ability.flavor_text, tables.AbilityFlavorText.version_group),
                joinedload(tables.Ability.flavor_text, tables.AbilityFlavorText.version_group, tables.VersionGroup.versions),

                # Pokémon stuff
                subqueryload(tables.Ability.pokemon),
                subqueryload(tables.Ability.dream_pokemon),
                subqueryload(tables.Ability.all_pokemon),
                subqueryload(tables.Ability.all_pokemon, tables.Pokemon.abilities),
                subqueryload(tables.Ability.all_pokemon, tables.Pokemon.species, tables.PokemonSpecies.egg_groups),
                subqueryload(tables.Ability.all_pokemon, tables.Pokemon.types),
                subqueryload(tables.Ability.all_pokemon, tables.Pokemon.stats),
                joinedload(tables.Ability.all_pokemon, tables.Pokemon.stats, tables.PokemonStat.stat),
            ) \
            .one()

        c.method_labels = {
            'Normal': u'May be found normally on Pokémon.',
            'Dream': u'Found on Dream World Pokémon and a few Pokémon from '
                     u'specific in-game encounters.',
        }

        dream_pokemon = [pokemon for pokemon in c.ability.dream_pokemon if
                         pokemon not in c.ability.pokemon]

        c.pokemon = []
        if c.ability.pokemon:
            c.pokemon.append(('Normal', c.ability.pokemon))
        if dream_pokemon:
            c.pokemon.append(('Dream', dream_pokemon))

        move_flag = None
        if c.ability.name == 'Soundproof':
            move_flag = 'sound'
        elif c.ability.name == 'Iron Fist':
            move_flag = 'punch'

        c.moves = None
        if move_flag:
            c.moves = db.pokedex_session.query(tables.Move) \
                .join(tables.MoveFlagMap, tables.MoveFlag) \
                .filter(tables.MoveFlag.identifier == move_flag) \
                .join(tables.Move.names_local) \
                .order_by(tables.Move.names_table.name) \
                .options(
                    subqueryload('move_effect'),
                    subqueryload('type'),
                    subqueryload('damage_class')
                )

        return


    def items_list(self):
        c.item_pockets = db.pokedex_session.query(tables.ItemPocket) \
            .order_by(tables.ItemPocket.id.asc())

        return render('/pokedex/item_list.mako')

    def item_pockets(self, pocket):
        try:
            c.item_pocket = db.pokedex_session.query(tables.ItemPocket) \
                .filter(tables.ItemPocket.identifier == pocket) \
                .options(
                    joinedload_all('categories.items.berry'),
                    joinedload_all('categories.items.prose_local'),
                ) \
                .one()
        except NoResultFound:
            # It's possible this is an old item URL; redirect if so
            try:
                item = db.get_by_name_query(tables.Item, pocket).one()
                return redirect(
                    url(controller='dex', action='items',
                        pocket=item.pocket.identifier, name=pocket),
                )
            except NoResultFound:
                return self._not_found()

        # OK, got a valid pocket

        # Eagerload TM info if it's actually needed
        if c.item_pocket.identifier == u'machines':
            db.pokedex_session.query(tables.ItemPocket) \
                .options(eagerload_all('categories.items.machines.move.type')) \
                .get(c.item_pocket.id)

        c.item_pockets = db.pokedex_session.query(tables.ItemPocket) \
            .order_by(tables.ItemPocket.id.asc())

        return render('/pokedex/item_pockets.mako')

    def items(self, pocket, name):
        try:
            c.item = db.get_by_name_query(tables.Item, name).one()
        except NoResultFound:
            return self._not_found()

        # These are used for their item linkage
        c.growth_mulch = db.pokedex_session.query(tables.Item) \
            .filter_by(identifier=u'growth-mulch').one()
        c.damp_mulch = db.pokedex_session.query(tables.Item) \
            .filter_by(identifier=u'damp-mulch').one()

        # Pokémon that can hold this item are per version; break this up into a
        # two-dimensional structure of pokemon => version => rarity
        c.holding_pokemon = defaultdict(lambda: defaultdict(int))
        held_generations = set()
        for pokemon_item in c.item.pokemon:
            c.holding_pokemon[pokemon_item.pokemon][pokemon_item.version] = pokemon_item.rarity
            held_generations.add(pokemon_item.version.generation)

        # Craft a list of versions, collapsed into columns, grouped by gen
        held_generations = sorted(held_generations, key=lambda gen: gen.id)
        c.held_version_columns = []
        for generation in held_generations:
            # Oh boy!  More version collapsing logic!
            # Try to make this as simple as possible: have a running list of
            # versions in some column, then switch to a new column when any
            # rarity changes
            c.held_version_columns.append( [[]] )  # New colgroup, empty column
            last_version = None
            for version in generation.versions:
                # If the any of the rarities changed, this version needs to
                # begin a new column
                if last_version and any(
                    rarities[last_version] != rarities[version]
                    for rarities in c.holding_pokemon.values()
                ):
                    c.held_version_columns[-1].append([])

                c.held_version_columns[-1][-1].append(version)
                last_version = version

        return render('/pokedex/item.mako')


    def locations_list(self):
        c.locations = (db.pokedex_session.query(tables.Location)
            .join(tables.Location.names_local)
            .join(tables.LocationArea, tables.Encounter)
            .order_by(tables.Location.region_id, tables.Location.names_table.name)
            .all()
        )

        return render('/pokedex/location_list.mako')

    def locations(self, name):
        # Note that it isn't against the rules for multiple locations to have
        # the same name.  To avoid complications, the name is stored in
        # c.location_name, and after that we only deal with areas.
        c.locations = db.get_by_name_query(tables.Location, name).all()

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
        # Then by method -- table sections.
        # Then by pokemon -- table rows.
        # Then by version -- table columns.
        # Finally, condition values associated with levels/rarity.
        q = db.pokedex_session.query(tables.Encounter) \
            .options(
                eagerload_all('condition_value_map.condition_value'),
                eagerload_all('slot.method'),
                eagerload_all('pokemon.species'),
                eagerload('version'),
            ) \
            .filter(tables.Encounter.location_area_id.in_(x.id for x in c.areas))

        # area => method => pokemon => version => condition =>
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
            # method, etc.

            # n.b.: conditions and values must be tuples because lists aren't
            # hashable.
            encounter_bits = grouped_encounters \
                [encounter.location_area] \
                [encounter.slot.method] \
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
        c.encounter_method_icons = self.encounter_method_icons
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
        c.natures = db.pokedex_session.query(tables.Nature) \
            .join(tables.Nature.names_local) \
            .options(
                contains_eager(tables.Nature.names_local),
                joinedload(tables.Nature.likes_flavor),
                joinedload(tables.Nature.hates_flavor),
                joinedload(tables.Nature.increased_stat),
                joinedload(tables.Nature.decreased_stat),
            )

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
            c.natures = c.natures.order_by(
                tables.Nature.names_table.name.asc())

        return render('/pokedex/nature_list.mako')

    def natures(self, name):
        try:
            c.nature = db.get_by_name_query(tables.Nature, name).one()
        except NoResultFound:
            return self._not_found()

        # Find related natures.
        # Other neutral natures if this one is neutral; otherwise, the inverse
        # of this one
        if c.nature.increased_stat == c.nature.decreased_stat:
            c.neutral_natures = db.pokedex_session.query(tables.Nature) \
                .join(tables.Nature.names_local) \
                .filter(tables.Nature.increased_stat_id
                     == tables.Nature.decreased_stat_id) \
                .filter(tables.Nature.id != c.nature.id) \
                .order_by(tables.Nature.names_table.name)
        else:
            c.inverse_nature = db.pokedex_session.query(tables.Nature) \
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
        hp = db.pokedex_session.query(tables.Stat).filter_by(identifier=u'hp').one()
        if c.nature.increased_stat == c.nature.decreased_stat:
            # Neutral.  Boring!
            # Create a subquery of neutral-ish Pokémon
            stat_subquery = db.pokedex_session.query(
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

            query = db.pokedex_session.query(tables.Pokemon) \
                .join((stat_subquery,
                    stat_subquery.c.pokemon_id == tables.Pokemon.id)) \
                .order_by(tables.Pokemon.order)

        else:
            # More interesting.
            # Create the subquery again, but..  the other way around.
            grouped_stats = aliased(tables.PokemonStat)
            stat_range_subquery = db.pokedex_session.query(
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
            minmax_stat_subquery = db.pokedex_session.query(
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
            query = db.pokedex_session.query(tables.Pokemon) \
                .join((minmax_stat_subquery,
                    minmax_stat_subquery.c.pokemon_id == tables.Pokemon.id)) \
                .order_by(tables.Pokemon.order)

        c.pokemon = query.all()

        return render('/pokedex/nature.mako')
