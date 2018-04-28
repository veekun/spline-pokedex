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
import os.path
import warnings

from pylons import config, tmpl_context as c, url

import pokedex.db.tables as t
import spline.lib.helpers as h
from splinext.pokedex.i18n import NullTranslator

# Re-exported
import pokedex.formulae as formulae
from pokedex.roomaji import romanize

# We can't translate at import time, but _ will mark strings as translatable
# Functions that need translation will take a "_" parameter, which defaults
# to this:
_ = NullTranslator()

def make_thingy_url(thingy, subpage=None, controller='dex'):
    u"""Given a thingy (Pokémon, move, type, whatever), returns a URL to it.
    """
    # Using the table name as an action directly looks kinda gross, but I can't
    # think of anywhere I've ever broken this convention, and making a
    # dictionary to get data I already have is just silly
    args = {}

    # Pokémon with forms need the form attached to the URL
    if isinstance(thingy, t.PokemonForm):
        action = 'pokemon'
        args['form'] = thingy.form_identifier.lower()
        args['name'] = thingy.pokemon.species.name.lower()

        if not thingy.is_default:
            subpage = 'flavor'
    elif isinstance(thingy, t.PokemonSpecies):
        action = 'pokemon'
        args['name'] = thingy.name.lower()
    else:
        action = thingy.__tablename__
        args['name'] = thingy.name.lower()


    # Items are split up by pocket
    if isinstance(thingy, t.Item):
        args['pocket'] = thingy.pocket.identifier

    if (thingy.__tablename__.startswith('conquest_')
       or (isinstance(thingy, t.Ability) and not thingy.is_main_series)
       or subpage == 'conquest'):
        # Conquest stuff needs to go to the Conquest controller
        if action == 'conquest_warrior_skills':
            action = 'skills'
        else:
            action = action.replace('conquest_', '')

        controller = 'dex_conquest'
    elif subpage:
        action += '_' + subpage

    return url(controller=controller,
               action=action,
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

        # Collapse adjacent spaces and strip trailing whitespace.
        html = u' '.join(html.split())

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

# XXX only used by version_icons()
def filename_from_name(name):
    """Shorten the name of a whatever to something suitable as a filename.

    e.g. Water's Edge -> waters-edge
    """
    name = unicode(name)
    name = name.lower()

    name = re.sub(u'[ _]+', u'-', name)
    name = re.sub(u'[\'.()]', u'', name)
    return name

def pokedex_img(src, **attr):
    return h.HTML.img(src=url(controller='dex', action='media', path=src), **attr)

def chrome_img(src, **attr):
    return h.HTML.img(src=h.static_uri('pokedex', 'images/' + src), **attr)

# XXX Should these be able to promote to db objects, rather than demoting to
# strings and integers?  If so, how to do that without requiring db access
# from here?
def generation_icon(generation, _=_):
    """Returns a generation icon, given a generation number."""
    # Convert generation to int if necessary
    if not isinstance(generation, int):
        generation = generation.id


    return chrome_img('versions/generation-%s.png' % generation,
            alt=_(u"Generation %d") % generation,
            title=_(u"Generation %d") % generation)

def version_icons(*versions, **kwargs):
    """Returns some version icons, given a list of version names.

    Keyword arguments:
    _: translator for i18n
    """
    # python's argument_list syntax is kind of limited here
    _ = kwargs.get('_', globals()['_'])
    version_icons = u''
    comma = chain([u''], repeat(u', '))
    for version in versions:
        # Convert version to string if necessary
        if isinstance(version, basestring):
            identifier = filename_from_name(version)
            name = version
        else:
            identifier = version.identifier
            name = version.name

        version_icons += h.HTML.img(
                src=h.static_uri('pokedex', 'images/versions/%s.png' % identifier),
                alt=comma.next() + name,
                title=name)

    return version_icons

def version_group_icon(version_group):
    return version_icons(*version_group.versions)
    # XXX this is for the combined pixely version group icons i made
    names = ', '.join(version.name for version in version_group.versions)
    return h.HTML.img(
        src=h.static_uri('pokedex', 'images/versions/%s.png' % (
            '-'.join(version.identifier for version in version_group.versions))),
        alt=names,
        title=names)


def pokemon_has_media(pokemon_form, prefix, ext, use_form=True):
    """Determine whether a file exists in the specified directory for the
    specified Pokémon form.
    """
    # TODO share this somewhere
    media_dir = config.get('spline-pokedex.media_directory', None)
    if not media_dir:
        warnings.warn(
            "No media_directory found; "
            "you may want to clone pokedex-media.git")
        return False

    if use_form:
        kwargs = dict(form=pokemon_form)
    else:
        kwargs = dict()

    return os.path.exists(os.path.join(media_dir,
        pokemon_media_path(pokemon_form.species, prefix, ext, **kwargs)))

def pokemon_media_path(pokemon_species, prefix, ext, form=None):
    """Returns a path to a Pokémon media file.

    form is not None if the form should be in the filename; it should be False
    if the form should be ignored, e.g. for footprints.
    """

    if form:
        form_identifier = form.form_identifier
    else:
        form_identifier = None

    if form_identifier:
        filename = '{id}-{form}.{ext}'
    else:
        filename = '{id}.{ext}'

    filename = filename.format(
        id=pokemon_species.id,
        form=form_identifier,
        ext=ext
    )

    return '/'.join(('pokemon', prefix, filename))

def species_image(pokemon_species, prefix='main-sprites/black-white', **attr):
    u"""Returns an <img> tag for a Pokémon species image."""

    default_text = pokemon_species.name

    if 'animated' in prefix:
        ext = 'gif'
    else:
        ext = 'png'

    attr.setdefault('alt', default_text)
    attr.setdefault('title', default_text)

    return pokedex_img(pokemon_media_path(pokemon_species, prefix, ext),
                       **attr)

def pokemon_form_image(pokemon_form, prefix=None, **attr):
    """Returns an <img> tag for a Pokémon form image."""

    if prefix is None:
        prefix = 'main-sprites/ultra-sun-ultra-moon'
        # FIXME what the hell is going on here
        if not pokemon_has_media(pokemon_form, prefix, 'png'):
            prefix = 'main-sprites/black-white'

        # Deal with Spiky-eared Pichu and ??? Arceus
        if pokemon_form.pokemon_form_generations:
            last_gen = pokemon_form.pokemon_form_generations[-1].generation_id
            if last_gen == 4:
                prefix = 'main-sprites/heartgold-soulsilver'

    default_text = pokemon_form.name

    if 'animated' in prefix:
        ext = 'gif'
    elif 'dream-world' in prefix:
        ext = 'svg'
    else:
        ext = 'png'

    attr.setdefault('alt', default_text)
    attr.setdefault('title', default_text)

    return pokedex_img(pokemon_media_path(pokemon_form.species, prefix, ext, form=pokemon_form),
                       **attr)

def pokemon_icon(pokemon, alt=True):
    if pokemon.is_default:
        return h.literal('<span class="sprite-icon sprite-icon-%d"></span>' % pokemon.species.id)

    alt_text = pokemon.name if alt else u''
    if pokemon_has_media(pokemon.default_form, 'icons', 'png'):
        return pokemon_form_image(pokemon.default_form, prefix='icons', alt=alt_text)

    return pokedex_img('pokemon/icons/0.png', title=pokemon.species.name, alt=alt_text)

def pokemon_link(pokemon, content=None, **attr):
    """Returns a link to a Pokémon page.

    `pokemon`
        A Pokemon object.

    `content`
        Link text (or image, or whatever).
    """

    # Content defaults to the name of the Pokémon
    if not content:
        content = pokemon.name

    url_kwargs = {}
    if pokemon.default_form.form_identifier:
        # Don't want a ?form=None, or a ?form=default
        url_kwargs['form'] = pokemon.default_form.form_identifier

    return h.HTML.a(
        content,
        href=url(controller='dex', action='pokemon',
                       name=pokemon.species.name.lower(), **url_kwargs),
        **attr
        )

def form_flavor_link(form, content=None, **attr):
    """Returns a link to a pokemon form's flavor page.

    `form`
        A PokemonForm object.

    `content`
        Link text (or image, or whatever).
    """
    if not content:
        content = form.name

    url_kwargs = {}
    if form.form_identifier:
        # Don't want a ?form=None, or a ?form=default
        url_kwargs['form'] = form.form_identifier

    return h.HTML.a(
        content,
        href=url(controller='dex', action='pokemon_flavor',
                       name=form.species.name.lower(), **url_kwargs),
        **attr
        )

def damage_class_icon(damage_class, _=_):
    return pokedex_img(
        "damage-classes/%s.png" % damage_class.identifier,
        alt=damage_class.name,
        title=_("%s: %s", context="damage class: description") % (
                damage_class.name.capitalize(),
                damage_class.description,
            )
    )


def type_icon(type):
    if isinstance(type, basestring):
        if type == '???':
            identifier = 'unknown'
        else:
            identifier = type.lower()
        name = type
    else:
        name = type.name
        identifier = type.identifier
    return pokedex_img('types/{1}/{0}.png'.format(identifier, c.game_language.identifier),
            alt=name, title=name)

def type_link(type):
    return h.HTML.a(
        type_icon(type),
        href=url(controller='dex', action='types', name=type.identifier),
    )

def item_filename(item):
    if item.pocket.identifier == u'machines':
        machines = item.machines
        prefix = u'hm' if machines[-1].is_hm else u'tm'
        filename = prefix + u'-' + machines[-1].move.type.identifier
    elif item.identifier.startswith(u'data-card-'):
        filename = u'data-card'
    else:
        filename = item.identifier

    return filename

def item_link(item, include_icon=True, _=_):
    """Returns a link to the requested item."""

    item_name = item.name

    if include_icon:
        label = pokedex_img("items/%s.png" % item_filename(item),
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
    -1: _(u'genderless'),
    0: _(u'always male'),
    1: _(u'⅞ male, ⅛ female'),
    2: _(u'¾ male, ¼ female'),
    3: _(u'⅝ male, ⅜ female'),
    4: _(u'½ male, ½ female'),
    5: _(u'⅜ male, ⅝ female'),
    6: _(u'¼ male, ¾ female'),
    7: _(u'⅛ male, ⅞ female'),
    8: _(u'always female'),
}

conquest_rank_label = {
    1: 'I',
    2: 'II',
    3: 'III'
}

def article(noun, _=_):
    """Returns 'a' or 'an', as appropriate."""
    if noun[0].lower() in u'aeiou':
        return _(u'an')
    return _(u'a')

def evolution_description(evolution, _=_):
    """Crafts a human-readable description from a `pokemon_evolution` row
    object.
    """
    chunks = []

    # Trigger
    if evolution.trigger.identifier == u'level-up':
        chunks.append(_(u'Level up'))
    elif evolution.trigger.identifier == u'trade':
        chunks.append(_(u'Trade'))
    elif evolution.trigger.identifier == u'use-item':
        chunks.append(h.literal(_(u"Use {article} {item}")).format(
            article=article(evolution.trigger_item.name, _=_),
            item=item_link(evolution.trigger_item, include_icon=False)))
    elif evolution.trigger.identifier == u'shed':
        chunks.append(
            _(u"Evolve {from_pokemon} ({to_pokemon} will consume "
            u"a Poké Ball and appear in a free party slot)").format(
                from_pokemon=evolution.evolved_species.parent_species.name,
                to_pokemon=evolution.evolved_species.name))
    else:
        chunks.append(_(u'Do something'))

    # Conditions
    if evolution.gender_id:
        chunks.append(_(u"{0}s only").format(evolution.gender.identifier))
    if evolution.time_of_day:
        chunks.append(_(u"during the {0}").format(evolution.time_of_day))
    if evolution.minimum_level:
        chunks.append(_(u"starting at level {0}").format(evolution.minimum_level))
    if evolution.location_id:
        chunks.append(h.literal(_(u"around {0} ({1})")).format(
            h.HTML.a(evolution.location.name,
                href=url(controller='dex', action='locations',
                         name=evolution.location.name.lower())),
            evolution.location.region.name))
    if evolution.held_item_id:
        chunks.append(h.literal(_(u"while holding {article} {item}")).format(
            article=article(evolution.held_item.name),
            item=item_link(evolution.held_item, include_icon=False)))
    if evolution.known_move_id:
        chunks.append(h.literal(_(u"knowing {0}")).format(
            h.HTML.a(evolution.known_move.name,
                href=url(controller='dex', action='moves',
                         name=evolution.known_move.name.lower()))))
    if evolution.known_move_type_id:
        chunks.append(h.literal(_(u'knowing a {0}-type move')).format(
            h.HTML.a(evolution.known_move_type.name,
                href=url(controller='dex', action='types',
                    name=evolution.known_move_type.name.lower()))))
    if evolution.minimum_happiness:
        chunks.append(_(u"with at least {0} happiness").format(
            evolution.minimum_happiness))
    if evolution.minimum_beauty:
        chunks.append(_(u"with at least {0} beauty").format(
            evolution.minimum_beauty))
    if evolution.minimum_affection:
        chunks.append(_(u'with at least {0} affection in Pokémon-Amie').format(
            evolution.minimum_affection))
    if evolution.relative_physical_stats is not None:
        if evolution.relative_physical_stats < 0:
            op = _(u'<')
        elif evolution.relative_physical_stats > 0:
            op = _(u'>')
        else:
            op = _(u'=')
        chunks.append(_(u"when Attack {0} Defense").format(op))
    if evolution.party_species_id:
        chunks.append(h.literal(_(u"with {0} in the party")).format(
            pokemon_link(evolution.party_species.default_pokemon, include_icon=False)))
    if evolution.party_type_id:
        chunks.append(h.literal(_(u"with a {0}-type Pokémon in the party")).format(
            h.HTML.a(evolution.party_type.name,
                href=url(controller='dex', action='types',
                    name=evolution.party_type.name.lower()))))
    if evolution.trade_species_id:
        chunks.append(h.literal(_(u"in exchange for {0}")).format(
            pokemon_link(evolution.trade_species.default_pokemon, include_icon=False)))
    if evolution.needs_overworld_rain:
        chunks.append(_(u'while it is raining outside of battle'))
    if evolution.turn_upside_down:
        chunks.append(_(u'with the 3DS turned upside-down'))

    return h.literal(u', ').join(chunks)


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


def apply_pokemon_template(template, pokemon, _=_):
    u"""`template` should be a string.Template object.

    Uses safe_substitute to inject some fields from the Pokémon into the
    template.

    This cheerfully returns a literal, so be sure to escape the original format
    string BEFORE passing it to Template!
    """

    d = dict(
        icon=pokemon_form_image(pokemon.default_form, prefix=u'icons'),
        id=pokemon.species.id,
        name=pokemon.default_form.name,

        height=format_height_imperial(pokemon.height),
        height_ft=format_height_imperial(pokemon.height),
        height_m=format_height_metric(pokemon.height),
        weight=format_weight_imperial(pokemon.weight),
        weight_lb=format_weight_imperial(pokemon.weight),
        weight_kg=format_weight_metric(pokemon.weight),

        gender=_(gender_rate_label[pokemon.species.gender_rate]),
        genus=pokemon.species.genus,
        base_experience=pokemon.base_experience,
        capture_rate=pokemon.species.capture_rate,
        base_happiness=pokemon.species.base_happiness,
    )

    # "Lazy" loading, to avoid hitting other tables if unnecessary.  This is
    # very chumpy and doesn't distinguish between literal text and fields (e.g.
    # '$type' vs 'type'), but that's very unlikely to happen, and it's not a
    # big deal if it does
    if 'type' in template.template:
        types = pokemon.types
        d['type'] = u'/'.join(type_.name for type_ in types)
        d['type1'] = types[0].name
        d['type2'] = types[1].name if len(types) > 1 else u''

    if 'egg_group' in template.template:
        egg_groups = pokemon.species.egg_groups
        d['egg_group'] = u'/'.join(group.name for group in egg_groups)
        d['egg_group1'] = egg_groups[0].name
        d['egg_group2'] = egg_groups[1].name if len(egg_groups) > 1 else u''

    if 'ability' in template.template:
        abilities = pokemon.abilities
        d['ability'] = u'/'.join(ability.name for ability in abilities)
        d['ability1'] = abilities[0].name
        d['ability2'] = abilities[1].name if len(abilities) > 1 else u''
        if pokemon.hidden_ability:
            d['hidden_ability'] = pokemon.hidden_ability.name
        else:
            d['hidden_ability'] = u''

    if 'color' in template.template:
        d['color'] = pokemon.species.color.name

    if 'habitat' in template.template:
        if pokemon.species.habitat:
            d['habitat'] = pokemon.species.habitat.name
        else:
            d['habitat'] = ''

    if 'shape' in template.template:
        if pokemon.species.shape:
            d['shape'] = pokemon.species.shape.name
        else:
            d['shape'] = ''

    if 'hatch_counter' in template.template:
        d['hatch_counter'] = pokemon.species.hatch_counter

    if 'steps_to_hatch' in template.template:
        d['steps_to_hatch'] = (pokemon.species.hatch_counter + 1) * 255

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


class DownloadSizer(object):
    file_size_units = 'B KB MB GB TB'.split()

    def __init__(self):
        self.seen = set()

    def compute(self, path):
        if path in self.seen:
            # Two download links for the same thing on one page
            # Remove the "seen" stuff if this is ever legitimate
            raise AssertionError('Copy/paste oversight! Two equal download links on one page')
        self.seen.add(path)
        root, me = os.path.split(__file__)
        path = os.path.join(root, 'public', path)
        try:
            size = os.stat(path).st_size
        except EnvironmentError:
            raise EnvironmentError("Could not stat %s. Make sure to run spline-pokedex's bin/create-downloads.py script." % path)
        def str_no_trailing_zero(num):
            s = str(num)
            if s.endswith('.0'):
                s = s[:-2]
            return s
        for unit in self.file_size_units:
            if size < 1024:
                if size >= 100:
                    return str(int(round(size))) + unit
                elif size >= 10:
                    return str_no_trailing_zero(round(size, 1)) + unit
                else:
                    return str_no_trailing_zero(round(size, 2)) + unit
            else:
                size = size / 1024.
        else:
            raise AssertionError('Serving a file of %s petabytes', size)
