# encoding: utf8
"""Small library of bits and pieces useful to the Web interface that don't
really belong in the pokedex core.
"""

from __future__ import absolute_import, division

import math
import re

from pylons import url

import pokedex.db.tables as tables
import pokedex.formulae as formulae
from pokedex.roomaji import romanize

import spline.lib.helpers as h


def make_thingy_url(thingy):
    u"""Given a thingy (Pokémon, move, type, whatever), returns a URL to it.
    """
    # Using the table name as an action directly looks kinda gross, but I can't
    # think of anywhere I've ever broken this convention, and making a
    # dictionary to get data I already have is just silly
    args = {}

    # Pokémon with forms need the form attached to the URL
    if getattr(thingy, 'forme_base_pokemon_id', None):
        args['form'] = thingy.forme_name

    # Items are split up by pocket
    if isinstance(thingy, tables.Item):
        args['pocket'] = thingy.pocket.identifier

    return url(controller='dex',
               action=thingy.__tablename__,
               name=thingy.name.lower(),
               **args)

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

def filename_from_name(name):
    """Shorten the name of a whatever to something suitable as a filename.

    e.g. Water's Edge -> waters-edge
    """
    name = unicode(name)
    name = name.lower()
    name = re.sub(u'[ _]+', u'-', name)
    name = re.sub(u'[\']', u'', name)
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
                       alt="Generation %d" % generation)

def version_icons(*versions):
    """Returns some version icons, given a list of version names."""
    version_icons = ''
    for version in versions:
        # Convert version to string if necessary
        if not isinstance(version, basestring):
            version = version.name

        version_filename = filename_from_name(version)
        version_icons += pokedex_img(u'versions/%s.png' % version_filename,
                                     alt=version)

    return version_icons


def pokemon_sprite(pokemon, prefix='heartgold-soulsilver', **attr):
    """Returns an <img> tag for a Pokémon sprite."""

    # Kinda gross, but it's entirely valid to pass None as a form
    form = attr.pop('form', pokemon.forme_name)

    if 'crystal' in prefix or 'animated' in prefix:
        ext = 'gif'
    else:
        ext = 'png'

    if form:
        # Use the overridden form name
        alt_text = "{0} {1}".format(form.title(), pokemon.name)
    else:
        # Use the Pokémon's default full-name
        alt_text = pokemon.full_name

    attr.setdefault('alt', alt_text)
    attr.setdefault('title', alt_text)

    if form:
        filename = '%d-%s.%s' % (pokemon.national_id, form, ext)
    else:
        filename = '%d.%s' % (pokemon.national_id, ext)

    return pokedex_img("%s/%s" % (prefix, filename), **attr)

def pokemon_link(pokemon, content=None, to_flavor=False, **attr):
    """Returns a link to a Pokémon page.

    `pokemon`
        A name or a Pokémon object.

    `content`
        Link text (or image, or whatever).

    `form`
        An alternate form to link to.  If the form is only a sprite, the link
        will be to the flavor page.

    `to_flavor`
        If True, the link will always be to the flavor page, regardless of
        form.
    """

    # Kinda gross, but it's entirely valid to pass None as a form
    form = attr.pop('form', pokemon.forme_name)
    if form == pokemon.forme_name and not pokemon.forme_base_pokemon_id:
        # Don't use default form's name as part of the link
        form = None

    # Content defaults to the name of the Pokémon
    if not content:
        if form:
            content = "%s %s" % (form.title(), pokemon.name)
        else:
            content = pokemon.name

    url_kwargs = {}
    if form:
        # Don't want a ?form=None, so just only pass a form at all if there's
        # one to pass
        url_kwargs['form'] = form

    action = 'pokemon'
    if form and pokemon.normal_form.form_group \
            and not pokemon.normal_form.formes:
        # If a Pokémon does not have real (different species) forms, e.g.
        # Unown and its letters, then a form link only makes sense if it's to a
        # flavor page.
        action = 'pokemon_flavor'
    elif to_flavor:
        action = 'pokemon_flavor'

    return h.HTML.a(
        content,
        href=url(controller='dex', action=action,
                       name=pokemon.name.lower(), **url_kwargs),
        **attr
        )


def damage_class_icon(damage_class):
    return pokedex_img(
        "chrome/damage-classes/%s.png" % damage_class.name.lower(),
        alt=damage_class.name,
        title="%s: %s" % (damage_class.name, damage_class.description),
    )


def type_icon(type):
    if not isinstance(type, basestring):
        type = type.name
    return pokedex_img('chrome/types/%s.png' % type, alt=type)

def type_link(type):
    return h.HTML.a(
        type_icon(type),
        href=url(controller='dex', action='types', name=type.name.lower()),
    )


def item_link(item):
    """Returns a link to the requested item."""
    item_name = item.name

    filename = filename_from_name(item_name)
    return h.HTML.a(
        pokedex_img("items/%s.png" % filename,
                   alt=item_name, title=item_name) + item_name,
        href=url(controller='dex', action='items',
                 pocket=item.pocket.identifier, name=item_name.lower()),
    )


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
        id=pokemon.national_id,
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

    if 'color' in template.template:
        d['color'] = pokemon.color

    if 'habitat' in template.template:
        d['habitat'] = pokemon.habitat

    if 'shape' in template.template:
        d['shape'] = pokemon.shape.name

    if 'steps_to_hatch' in template.template:
        d['steps_to_hatch'] = pokemon.evolution_chain.steps_to_hatch

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
