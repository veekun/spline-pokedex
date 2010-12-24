# encoding: utf8
"""Collection of small functions and scraps of data that don't belong in the
pokedex core -- either because they're inherently Web-related, or because
they're very flavorful and don't belong or fit well in a database.
"""

from __future__ import absolute_import, division

import math
import re
from itertools import groupby, chain, repeat
from operator import attrgetter

from pylons import url

import pokedex.db.tables as tables
import pokedex.formulae as formulae
from pokedex.roomaji import romanize

import spline.lib.helpers as h


def make_thingy_url(thingy, subpage=None):
    u"""Given a thingy (Pokémon, move, type, whatever), returns a URL to it.
    """
    # Using the table name as an action directly looks kinda gross, but I can't
    # think of anywhere I've ever broken this convention, and making a
    # dictionary to get data I already have is just silly
    args = {}

    # Pokémon with forms need the form attached to the URL
    if isinstance(thingy, tables.PokemonForm):
        action = 'pokemon'
        args['form'] = thingy.name.lower()
        args['name'] = thingy.form_base_pokemon.name.lower()

        if thingy.unique_pokemon is None:
            subpage = 'flavor'
    else:
        action = thingy.__tablename__
        args['name'] = thingy.name.lower()

    # Items are split up by pocket
    if isinstance(thingy, tables.Item):
        args['pocket'] = thingy.pocket.identifier

    if subpage:
        action += '_' + subpage

    return url(controller='dex',
               action=action,
               **args)

pokemon_sort_key = attrgetter('order')

def render_flavor_text(flavor_text, literal=False):
    """Makes flavor text suitable for HTML presentation.

    If `literal` is false, collapses broken lines into single lines.

    If `literal` is true, linebreaks are preserved exactly as they are in the
    games.
    """

    # n.b.: \u00ad is soft hyphen

    # Somehow, the games occasionally have \n\f, which makes no sense at all
    # and wouldn't render in-game anyway.  Fix this
    flavor_text = flavor_text.replace('\n\f', '\f')

    if literal:
        # Page breaks become two linebreaks.
        # Soft hyphens become real hyphens.
        # Newlines become linebreaks.
        html = flavor_text.replace(u'\f',       u'<br><br>') \
                          .replace(u'\u00ad',   u'-') \
                          .replace(u'\n',       u'<br>')

    else:
        # Page breaks are treated just like newlines.
        # Soft hyphens followed by newlines vanish.
        # Letter-hyphen-newline becomes letter-hyphen, to preserve real
        # hyphenation.
        # Any other newline becomes a space.
        html = flavor_text.replace(u'\f',       u'\n') \
                          .replace(u'\u00ad\n', u'') \
                          .replace(u'\u00ad',   u'') \
                          .replace(u' -\n',     u' - ') \
                          .replace(u'-\n',      u'-') \
                          .replace(u'\n',       u' ')

    return h.literal(html)

## Collapsing

def collapse_flavor_text_key(literal=True):
    """A wrapper around `render_flavor_text`. Returns a function to be used
    as a key for `collapse_versions`, or any other function which takes a key.
    """
    def key(text):
        return render_flavor_text(text.flavor_text, literal=literal)
    return key

def group_by_generation(things):
    """A wrapper around itertools.groupby which groups by generation."""
    things = iter(things)
    try:
        a_thing = things.next()
    except StopIteration:
        return ()
    key = get_generation_key(a_thing)
    return groupby(chain([a_thing], things), key)

def get_generation_key(sample_object):
    """Given an object, return a function which retrieves the generation.

    Tries x.generation, x.version_group.generation, and x.version.generation.
    """
    if hasattr(sample_object, 'generation'):
        return attrgetter('generation')
    elif hasattr(sample_object, 'version_group'):
        return (lambda x: x.version_group.generation)
    elif hasattr(sample_object, 'version'):
        return (lambda x: x.version.generation)
    raise AttributeError

def collapse_versions(things, key):
    """Collapse adjacent equal objects and remember their versions.

    Yields tuples of ([versions], key(x)). Uses itertools.groupby internally.
    """
    things = iter(things)
    # let the StopIteration bubble up
    a_thing = things.next()

    if hasattr(a_thing, 'version'):
        def get_versions(things):
            return [x.version for x in things]
    elif hasattr(a_thing, 'version_group'):
        def get_versions(things):
            return sum((x.version_group.versions for x in things), [])

    for collapsed_key, group in groupby(chain([a_thing], things), key):
        yield get_versions(group), collapsed_key

### Images and links

def filename_from_name(name):
    """Shorten the name of a whatever to something suitable as a filename.

    e.g. Water's Edge -> waters-edge
    """
    name = unicode(name)
    name = name.lower()

    # TMs and HMs share sprites
    if re.match(u'^[th]m\d{2}$', name):
        if name[0:2] == u'tm':
            return u'tm-normal'
        else:
            return u'hm-normal'

    # As do data cards
    if re.match(u'^data card \d+$', name):
        return u'data-card'

    name = re.sub(u'[ _]+', u'-', name)
    name = re.sub(u'[\'.]', u'', name)
    return name

def pokedex_img(src, **attr):
    return h.HTML.img(src=url(controller='dex', action='media', path=src), **attr)


# XXX Should these be able to promote to db objects, rather than demoting to
# strings and integers?  If so, how to do that without requiring db access
# from here?
def generation_icon(generation):
    """Returns a generation icon, given a generation number."""
    # Convert generation to int if necessary
    if not isinstance(generation, int):
        generation = generation.id

    return pokedex_img('versions/generation-%d.png' % generation,
                       alt=u"Generation %d" % generation,
                       title=u"Generation %d" % generation)

def version_icons(*versions):
    """Returns some version icons, given a list of version names."""
    version_icons = u''
    comma = chain([u''], repeat(u', '))
    for version in versions:
        # Convert version to string if necessary
        if not isinstance(version, basestring):
            version = version.name

        version_filename = filename_from_name(version)
        version_icons += pokedex_img(u'versions/%s.png' % version_filename,
                                     alt=comma.next() + version, title=version)

    return version_icons


def pokemon_sprite(pokemon, prefix='black-white', **attr):
    """Returns an <img> tag for a Pokémon sprite."""

    if isinstance(pokemon, tables.PokemonForm):
        form = attr.pop('form', pokemon.name)
        alt_text = pokemon.pokemon_name
        pokemon = pokemon.form_base_pokemon
    elif isinstance(pokemon, tables.Pokemon):
        form = attr.pop('form', pokemon.form_name)
        alt_text = pokemon.full_name

    if 'animated' in prefix:
        ext = 'gif'
    else:
        ext = 'png'

    if form:
        filename = '{id}-{form}.{ext}'
    else:
        filename = '{id}.{ext}'

    attr.setdefault('alt', alt_text)
    attr.setdefault('title', alt_text)

    filename = filename.format(id=pokemon.normal_form.id,
                               form=filename_from_name(form),
                               ext=ext)

    return pokedex_img('/'.join((prefix, filename)), **attr)

def pokemon_link(pokemon, content=None, to_flavor=False, **attr):
    """Returns a link to a Pokémon page.

    `pokemon`
        A Pokémon object.

    `content`
        Link text (or image, or whatever).

    `form`
        A string name of an alternate form to link to.  If the form is flavor-
        only, the link will be to the flavor page.

    `to_flavor`
        If True, the link will always be to the flavor page, regardless of
        form.
    """

    # If the Pokémon represents a specific form, use that form by default
    form = attr.pop('form', pokemon.form_name)

    # Content defaults to the name of the Pokémon
    if not content:
        if form:
            content = u'{0} {1}'.format(form, pokemon.name)
        else:
            content = pokemon.name

    url_kwargs = {}
    if form and not form == pokemon.normal_form.form_name:
        # Don't want a ?form=None, or a ?form=default on Pokémon whose forms
        # aren't just flavor
        url_kwargs['form'] = form.lower()

    action = 'pokemon'
    if to_flavor or (form and not pokemon.unique_form):
        # If a Pokémon's forms are flavor-only, then a form link only makes
        # sense if it's to a flavor page
        action = 'pokemon_flavor'

    return h.HTML.a(
        content,
        href=url(controller='dex', action=action,
                       name=pokemon.name.lower(), **url_kwargs),
        **attr
        )


def damage_class_icon(damage_class):
    return pokedex_img(
        "chrome/damage-classes/%s.png" % damage_class.name,
        alt=damage_class.name,
        title="%s: %s" % (damage_class.name.capitalize(), damage_class.description),
    )


def type_icon(type):
    if not isinstance(type, basestring):
        type = type.name
    return pokedex_img('chrome/types/%s.png' % type.lower(), alt=type, title=type)

def type_link(type):
    return h.HTML.a(
        type_icon(type),
        href=url(controller='dex', action='types', name=type.name.lower()),
    )


def item_link(item, include_icon=True):
    """Returns a link to the requested item."""

    item_name = item.name

    if include_icon:
        if item.pocket.identifier == u'machines':
            machines = item.machines
            prefix = u'hm' if machines[-1].is_hm else u'tm'
            filename = prefix + u'-' + machines[-1].move.type.name.lower()
        else:
            filename = filename_from_name(item_name)

        label = pokedex_img("items/%s.png" % filename,
            alt=item_name, title=item_name) + ' ' + item_name

    else:
        label = item_name

    return h.HTML.a(label,
        href=url(controller='dex', action='items',
                 pocket=item.pocket.identifier, name=item_name.lower()),
    )


### Labels

# Type efficacy, from percents to Unicode fractions
type_efficacy_label = {
    0: '0',
    25: u'¼',
    50: u'½',
    100: '1',
    200: '2',
    400: '4',
}

# Gender rates, translated from -1..8 to useful text
gender_rate_label = {
    -1: u'genderless',
    0: u'always male',
    1: u'⅞ male, ⅛ female',
    2: u'¾ male, ¼ female',
    3: u'⅝ male, ⅜ female',
    4: u'½ male, ½ female',
    5: u'⅜ male, ⅝ female',
    6: u'¼ male, ¾ female',
    7: u'⅛ male, ⅞ female',
    8: u'always female',
}

def article(noun):
    """Returns 'a' or 'an', as appropriate."""
    if noun[0].lower() in u'aeiou':
        return u'an'
    return u'a'

def evolution_description(evolution):
    """Crafts a human-readable description from a `pokemon_evolution` row
    object.
    """
    chunks = []

    # Trigger
    if evolution.trigger.identifier == u'level_up':
        chunks.append(u'Level up')
    elif evolution.trigger.identifier == u'trade':
        chunks.append(u'Trade')
    elif evolution.trigger.identifier == u'use_item':
        chunks.append(u"Use {article} {item}".format(
            article=article(evolution.trigger_item.name),
            item=evolution.trigger_item.name))
    elif evolution.trigger.identifier == u'shed':
        chunks.append(
            u"Evolve {from_pokemon} ({to_pokemon} will consume "
            u"a Poké Ball and appear in a free party slot)".format(
                from_pokemon=evolution.from_pokemon.full_name,
                to_pokemon=evolution.to_pokemon.full_name))
    else:
        chunks.append(u'Do something')

    # Conditions
    if evolution.gender:
        chunks.append(u"{0}s only".format(evolution.gender))
    if evolution.time_of_day:
        chunks.append(u"during the {0}".format(evolution.time_of_day))
    if evolution.minimum_level:
        chunks.append(u"starting at level {0}".format(evolution.minimum_level))
    if evolution.location_id:
        chunks.append(u"around {0}".format(evolution.location.name))
    if evolution.held_item_id:
        chunks.append(u"while holding {article} {item}".format(
            article=article(evolution.held_item.name),
            item=evolution.held_item.name))
    if evolution.known_move_id:
        chunks.append(u"knowing {0}".format(evolution.known_move.name))
    if evolution.minimum_happiness:
        chunks.append(u"with at least {0} happiness".format(
            evolution.minimum_happiness))
    if evolution.minimum_beauty:
        chunks.append(u"with at least {0} beauty".format(
            evolution.minimum_beauty))
    if evolution.relative_physical_stats is not None:
        if evolution.relative_physical_stats < 0:
            op = u'<'
        elif evolution.relative_physical_stats > 0:
            op = u'>'
        else:
            op = u'='
        chunks.append(u"when Attack {0} Defense".format(op))
    if evolution.party_pokemon_id:
        chunks.append(u"with {0} in the party".format(
            evolution.party_pokemon.name))
    if evolution.trade_pokemon_id:
        chunks.append(u"in exchange for {0}"
            .format(evolution.trade_pokemon.name))

    return u', '.join(chunks)


### Formatting

# Attempts at reasonable defaults for trainer size, based on the average
# American
trainer_height = 17.8  # dm
trainer_weight = 780   # hg

def format_height_metric(height):
    """Formats a height in decimeters as M m."""
    return "%.1f m" % (height / 10)

def format_height_imperial(height):
    """Formats a height in decimeters as F'I"."""
    return "%d'%.1f\"" % (
        height * 0.32808399,
        (height * 0.32808399 % 1) * 12,
    )

def format_weight_metric(weight):
    """Formats a weight in hectograms as K kg."""
    return "%.1f kg" % (weight / 10)

def format_weight_imperial(weight):
    """Formats a weight in hectograms as L lb."""
    return "%.1f lb" % (weight / 10 * 2.20462262)


### General data munging

def scale_sizes(size_dict, dimensions=1):
    """Normalizes a list of sizes so the largest is 1.0.

    Use `dimensions` if the sizes are non-linear, i.e. 2 for scaling area.
    """

    # x -> (x/max)^(1/dimensions)
    max_size = float(max(size_dict.values()))
    scaled_sizes = dict()
    for k, v in size_dict.items():
        scaled_sizes[k] = math.pow(v / max_size, 1.0 / dimensions)
    return scaled_sizes


def apply_pokemon_template(template, pokemon):
    u"""`template` should be a string.Template object.

    Uses safe_substitute to inject some fields from the Pokémon into the
    template.

    This cheerfully returns a literal, so be sure to escape the original format
    string BEFORE passing it to Template!
    """

    d = dict(
        icon=pokemon_sprite(pokemon, prefix=u'icons'),
        id=pokemon.normal_form.id,
        name=pokemon.full_name,

        height=format_height_imperial(pokemon.height),
        height_ft=format_height_imperial(pokemon.height),
        height_m=format_height_metric(pokemon.height),
        weight=format_weight_imperial(pokemon.weight),
        weight_lb=format_weight_imperial(pokemon.weight),
        weight_kg=format_weight_metric(pokemon.weight),

        gender=gender_rate_label[pokemon.gender_rate],
        species=pokemon.species,
        base_experience=pokemon.base_experience,
        capture_rate=pokemon.capture_rate,
        base_happiness=pokemon.base_happiness,
    )

    # "Lazy" loading, to avoid hitting other tables if unnecessary.  This is
    # very chumpy and doesn't distinguish between literal text and fields (e.g.
    # '$type' vs 'type'), but that's very unlikely to happen, and it's not a
    # big deal if it does
    if 'type' in template.template:
        types = pokemon.types
        d['type'] = u'/'.join(_.name for _ in types)
        d['type1'] = types[0].name
        d['type2'] = types[1].name if len(types) > 1 else u''

    if 'egg_group' in template.template:
        egg_groups = pokemon.egg_groups
        d['egg_group'] = u'/'.join(_.name for _ in egg_groups)
        d['egg_group1'] = egg_groups[0].name
        d['egg_group2'] = egg_groups[1].name if len(egg_groups) > 1 else u''

    if 'ability' in template.template:
        abilities = pokemon.abilities
        d['ability'] = u'/'.join(_.name for _ in abilities)
        d['ability1'] = abilities[0].name
        d['ability2'] = abilities[1].name if len(abilities) > 1 else u''
        if pokemon.dream_ability:
            d['dream_ability'] = pokemon.dream_ability.name
        else:
            d['dream_ability'] = u''

    if 'color' in template.template:
        d['color'] = pokemon.color

    if 'habitat' in template.template:
        d['habitat'] = pokemon.habitat

    if 'shape' in template.template:
        if pokemon.shape:
            d['shape'] = pokemon.shape.name
        else:
            d['shape'] = ''

    if 'hatch_counter' in template.template:
        d['hatch_counter'] = pokemon.hatch_counter

    if 'steps_to_hatch' in template.template:
        d['steps_to_hatch'] = (pokemon.hatch_counter + 1) * 255

    if 'stat' in template.template or \
       'hp' in template.template or \
       'attack' in template.template or \
       'defense' in template.template or \
       'speed' in template.template or \
       'effort' in template.template:
        d['effort'] = u', '.join("{0} {1}".format(_.effort, _.stat.name)
                                 for _ in pokemon.stats if _.effort)

        d['stats'] = u'/'.join(str(_.base_stat) for _ in pokemon.stats)

        for pokemon_stat in pokemon.stats:
            key = pokemon_stat.stat.name.lower().replace(' ', '_')
            d[key] = pokemon_stat.base_stat

    return h.literal(template.safe_substitute(d))

def apply_move_template(template, move):
    u"""`template` should be a string.Template object.

    Uses safe_substitute to inject some fields from the move into the template,
    just like the above.
    """

    d = dict(
        id=move.id,
        name=move.name,
        type=move.type.name,
        damage_class=move.damage_class.name,
        pp=move.pp,
        power=move.power,
        accuracy=move.accuracy,

        priority=move.priority,
        effect_chance=move.effect_chance,
        effect=move.move_effect.short_effect,
    )

    return h.literal(template.safe_substitute(d))
