# encoding: utf8
from __future__ import absolute_import, division

import logging
import re
from string import Template

from wtforms import Form, ValidationError, fields, widgets
from wtforms.ext.sqlalchemy.fields import QuerySelectField

import pokedex.db.tables as tables
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from sqlalchemy.orm import aliased, eagerload, eagerload_all, joinedload
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import exists, func, and_, not_, or_
from sqlalchemy.sql.operators import asc_op

from spline.lib import helpers as h
from spline.lib.base import render
from spline.lib.forms import DuplicateField, MultiCheckboxField, QueryCheckboxSelectMultipleField, QueryTextField

from splinext.pokedex import helpers as pokedex_helpers, PokedexBaseController
import splinext.pokedex.db as db
from splinext.pokedex.forms import PokedexLookupField, RangeTextField, StatField
from splinext.pokedex.magnitude import parse_size

log = logging.getLogger(__name__)

# XXX probably needs to live elsewhere
default_pokemon_table_columns = [
    'icon',
    'name',
    'type',
    'ability',
    'gender',
    'egg_group',
    'stat_hp',
    'stat_attack',
    'stat_defense',
    'stat_special_attack',
    'stat_special_defense',
    'stat_speed',
    'stat_total',
]
default_move_table_columns = [
    'name',
    'type',
    'class',
    'pp',
    'power',
    'accuracy',
    'priority',
    'effect',
]

def ilike(column, string):
    string = string.lower()

    # If there are no wildcards, assume it's a partial match
    if '*' not in string and '?' not in string:
        string = u"*{0}*".format(string)

    # LIKE wildcards should be escaped: % -> ^%, _ -> ^_, ^ -> ^^
    # Our wildcards should be changed: * -> %, ? -> _
    # And all at once.
    translations = {
        '%': u'^%',     '_': u'^_',     '^': u'^^',
        '*': u'%',      '?': u'_',
    }
    string = re.sub(ur'([%_*?^])',
                    lambda match: translations[match.group(0)],
                    string)

    return func.lower(column).like(string, escape='^')


def in_pokedex_label(pokedex):
    """[ IV ] Sinnoh"""

    return """{gen_icon} {name}""".format(
        gen_icon=pokedex_helpers.generation_icon(pokedex.region.generation),
        name=pokedex.name,
    )

class BaseSearchForm(Form):
    # Defaults are set to match what the client will actually send if the field
    # is left blank
    shorten = fields.HiddenField(default=u'')
    compound_field_names = []

    def __init__(self, formdata=None, *args, **kwargs):
        """Saves a copy of the passed form data, with default values removed,
        in the `formdata` property.
        """

        super(BaseSearchForm, self).__init__(formdata, *args, **kwargs)

        # Two factoids we need to remember about this form: was it submitted at
        # all, and is it valid?
        self.is_valid = None
        self.was_submitted = None
        self.needs_shortening = bool(formdata.get('shorten', False))
        self.cleansed_data = dict()

        # Need to make a copy and delete items, rather than creating a new
        # dict, because formdata is some variant of a multi-dict
        if self.needs_shortening and formdata:
            self.was_submitted = True
            self.cleansed_data = formdata.copy()
            del self.cleansed_data['shorten']

            for stat_field_name in self.compound_field_names:
                stat_field = self[stat_field_name]
                for field in stat_field:
                    if field.data == field.default:
                        self.cleansed_data.pop(field.name, None)

            for name, field in self._fields.iteritems():
                # Shorten: nuke anything that's a default
                if field.data == field.default and name in self.cleansed_data:
                    del self.cleansed_data[name]

        elif not self.needs_shortening:
            # Only count the form as submitted if there are any actual
            # searching fields
            self.was_submitted = not all(
                key in (u'sort', u'display', u'column', u'format')
                for key in formdata.keys()
            )

            # Unshortening.  Fields that are missing entirely from the form
            # data need to be FILLED IN with their defaults.
            # (XXX What? Surely wtforms takes care of this.)
            # Note that this will cheerfully fill in a multi-select field where
            # nothing was selected; it's assumed that a multi-select field with
            # a default makes no sense with nothing selected
            for name, field in self._fields.iteritems():
                if field.default and name not in formdata:
                    field.data = field.default

    def validate(self):
        # XXX this works around a wtforms bug; QueryMultiSelectField (or
        # whatever it's called) lazily checks or errors when field.data is
        # accessed, but that's not likely to happen before validating!  Ping
        # all the field data
        for name, field in self._fields.iteritems():
            field.data

        self.is_valid = super(BaseSearchForm, self).validate()

        return self.is_valid


class PokemonSearchForm(BaseSearchForm):
    id = RangeTextField('National ID', inflator=int)

    # Core stuff
    name = fields.TextField('Name', default=u'')
    ability = PokedexLookupField('Ability', valid_type='ability', allow_blank=True)
    held_item = PokedexLookupField('Held item', valid_type='item', allow_blank=True)
    growth_rate = QuerySelectField('Growth rate',
        query_factory=lambda: db.pokedex_session.query(tables.GrowthRate) \
            .options(eagerload('max_experience_obj')),
        get_pk=lambda _: _.max_experience,
        get_label=lambda _: """{0} ({1:n} EXP)""".format(_.name, _.max_experience),
        allow_blank=True,
    )

    # Type
    type_operator = fields.SelectField(
        choices=[
            (u'any',   'at least one of these types'),
            (u'exact', 'exactly these types'),
            (u'only',  'only these types'),
        ],
        default=u'any',
    )
    type = QueryCheckboxSelectMultipleField(
        'Type',
        query_factory=lambda: db.pokedex_session.query(tables.Type),
        get_label=lambda _: _.name,
        get_pk=lambda table: table.identifier,
        allow_blank=True,
    )

    # Breeding
    gender_rate_operator = fields.SelectField(
        choices=[
            (u'more_equal', u'at least'),
            (u'equal',      u'exactly'),
            (u'less_equal', u'at most'),
        ],
        default=u'equal',
    )
    gender_rate = fields.SelectField('Gender distribution',
        choices=[
            (u'',   u''),
            (u'0',  u'Never female'),
            (u'1',  u'1/8 female'),
            (u'2',  u'1/4 female'),
            (u'3',  u'3/8 female'),
            (u'4',  u'1/2 female'),
            (u'5',  u'5/8 female'),
            (u'6',  u'3/4 female'),
            (u'7',  u'7/8 female'),
            (u'8',  u'Always female'),
            (u'-1', u'Genderless'),
        ],
        default=u'',
    )

    egg_group_operator = fields.SelectField(
        choices=[ ('any', 'any of'), ('all', 'all of') ],
        default='all',
    )
    egg_group = DuplicateField(
        QuerySelectField(
            'Egg group',
            query_factory=lambda: db.pokedex_session.query(tables.EggGroup),
            get_label=lambda _: _.name,
            allow_blank=True,
        ),
        min_entries=2,
        max_entries=2,
    )

    # Evolution
    evolution_stage = MultiCheckboxField('Stage',
        choices=[
            (u'baby',   u'baby'),
            (u'basic',  u'basic'),
            (u'stage1', u'stage 1'),
            (u'stage2', u'stage 2'),
        ],
    )
    evolution_position = MultiCheckboxField('Position',
        choices=[
            (u'first',  u'First evolution'),
            (u'middle', u'Middle evolution'),
            (u'last',   u'Final evolution'),
            (u'only',   u'Only evolution'),
        ],
    )
    evolution_special = MultiCheckboxField('Special',
        choices=[
            (u'branching', u'Branching evolution (e.g., Tyrogue)'),
            (u'branched',  u'Branched evolution (e.g., Shedinja)'),
        ],
    )

    # Generation
    introduced_in = QueryCheckboxSelectMultipleField(
        'Introduced in',
        query_factory=lambda: db.pokedex_session.query(tables.Generation),
        get_label=lambda _: pokedex_helpers.generation_icon(_),
        get_pk=lambda table: table.id,
        allow_blank=True,
    )
    in_pokedex = QueryCheckboxSelectMultipleField(
        u'In regional Pokédex',
        query_factory=lambda: db.pokedex_session.query(tables.Pokedex) \
                                  .filter(tables.Pokedex.region_id != None) \
                                  .options(eagerload_all('region.generation')),
        get_label=in_pokedex_label,
        get_pk=lambda table: table.id,
        allow_blank=True,
    )

    # Moves
    move = DuplicateField(
        PokedexLookupField(u'Move', valid_type='move', allow_blank=True),
        min_entries=4,
        max_entries=4,
    )
    # XXX tests claim this will also do "similar moves", but I don't know what
    # that means.  same categories..?
    move_fuzz = fields.SelectField('Accept',
        choices=[
            (u'exact-move', 'Only these moves'),
            (u'same-effect', 'Any moves with the same effect'),
        ],
        default=u'exact-move',
    )
    move_method = QueryCheckboxSelectMultipleField(
        'Learned by',
        query_factory=lambda: db.pokedex_session.query(tables.PokemonMoveMethod)
            # XXX move methods need to identify themselves as "common"
            .filter(tables.PokemonMoveMethod.id <= 4),
        get_label=lambda row: row.name,
        get_pk=lambda table: table.identifier,
        allow_blank=True,
    )
    move_version_group = QueryCheckboxSelectMultipleField(
        'Versions',
        query_factory=lambda: db.pokedex_session.query(tables.VersionGroup) \
                                             .options(eagerload('versions')),
        get_label=lambda row: pokedex_helpers.version_icons(*row.versions),
        get_pk=lambda table: table.id,
        allow_blank=True,
    )

    # Numbers
    # Effort and stats are pulled from the database, so those fields are added
    # dynamically
    hatch_counter = RangeTextField('Initial hatch counter', inflator=int)
    base_experience = RangeTextField('Base EXP', inflator=int)
    capture_rate = RangeTextField('Capture rate', inflator=int)
    base_happiness = RangeTextField('Base happiness', inflator=int)

    height = RangeTextField('Height', inflator=lambda _: parse_size(_, 'height'))
    weight = RangeTextField('Weight', inflator=lambda _: parse_size(_, 'weight'))

    stat_total = RangeTextField('Total', inflator=int)
    effort_total = RangeTextField('Total', inflator=int)

    # Flavor
    genus = fields.TextField('Species', default=u'')
    color = QuerySelectField('Color',
        query_factory=lambda: db.pokedex_session.query(tables.PokemonColor),
        get_label=lambda _: _.name,
        allow_blank=True,
        get_pk=lambda table: table.identifier,
    )
    habitat = QuerySelectField('Habitat',
        query_factory=lambda: db.pokedex_session.query(tables.PokemonHabitat),
        get_label=lambda _: _.name,
        allow_blank=True,
        get_pk=lambda table: table.identifier,
    )
    shape = QuerySelectField('Shape',
        query_factory=lambda: db.pokedex_session.query(tables.PokemonShape)
            .order_by(tables.PokemonShape.identifier.asc()),
        get_label=lambda _: _.name,
        get_pk=lambda _: _.identifier,
        allow_blank=True,
    )


    # Order and display
    # XXX mention fallback sort?  have a sort2?
    sort = fields.SelectField('Sort by',
        choices=[
            ('id', 'National dex number'),
            ('evolution-chain', 'Evolution family'),
            ('name', 'Name'),
            ('type', 'Type'),
            ('growth-rate', 'Growth rate'),
            ('hatch-counter', 'Hatch counter/steps'),
            ('base-experience', 'Base EXP'),
            ('capture-rate', 'Capture rate'),
            ('base-happiness', 'Base happiness'),
            ('height', 'Height'),
            ('weight', 'Weight'),
            ('gender', 'Gender rate'),
            ('genus', 'Species'),
            ('color', 'Color'),
            ('habitat', 'Habitat'),
            ('shape', 'Shape'),
            ('stat-hp', 'HP'),
            ('stat-attack', 'Attack'),
            ('stat-defense', 'Defense'),
            ('stat-special-attack', 'Special Attack'),
            ('stat-special-defense', 'Special Defense'),
            ('stat-speed', 'Speed'),
            ('stat-total', 'Stat total'),
        ],
        default='name',
    )
    sort_backwards = fields.BooleanField('Sort backwards')

    display = fields.SelectField('Display',
        choices=[
            ('smart-table', 'Smart table'),
            ('custom-table', 'Custom table'),
            ('custom-list', 'Custom list'),
            ('icons', 'Icons'),
            ('sprites', 'Sprites'),
        ],
        default='smart-table',
    )

    column = MultiCheckboxField(
        'Custom table columns',
        choices=[
            ('id', 'National ID'),
            ('icon', 'Icon'),
            ('name', 'Name'),
            ('type', 'Types'),
            ('growth_rate', 'EXP to level 100'),
            ('ability', 'Abilities'),
            ('hidden_ability', 'Hidden ability'),
            ('gender', 'Gender rate'),
            ('egg_group', 'Egg groups'),

            ('height', 'Height'),
            ('height_metric', 'Height (in metric)'),
            ('weight', 'Weight'),
            ('weight_metric', 'Weight (in metric)'),
            ('genus', 'Species'),
            ('color', 'Color'),
            ('habitat', 'Habitat'),
            ('shape', 'Shape'),
            ('hatch_counter', 'Initial hatch counter'),
            ('steps_to_hatch', 'Steps to hatch'),
            ('base_experience', 'Base EXP'),
            ('capture_rate', 'Capture rate'),
            ('base_happiness', 'Base happiness'),

            ('stat_hp', 'HP'),
            ('stat_attack', 'Attack'),
            ('stat_defense', 'Defense'),
            ('stat_special_attack', 'Special Attack'),
            ('stat_special_defense', 'Special Defense'),
            ('stat_speed', 'Speed'),
            ('stat_total', 'Stat total'),
            ('effort', 'Effort given'),
        ],
        default=default_pokemon_table_columns,
    )
    format = fields.TextField('Custom list format', default=u'$icon $name')

class MoveSearchForm(BaseSearchForm):
    compound_field_names = ['stat_change']

    id = RangeTextField('ID', inflator=int)

    # Core stuff
    name = fields.TextField('Name', default=u'')
    damage_class = QueryCheckboxSelectMultipleField(
        'Damage class',
        query_factory=lambda: db.pokedex_session.query(tables.MoveDamageClass),
        get_label=lambda _: _.name.capitalize(),
        get_pk=lambda table: table.identifier,
        allow_blank=True,
    )
    introduced_in = QueryCheckboxSelectMultipleField(
        'Generation',
        query_factory=lambda: db.pokedex_session.query(tables.Generation),
        get_label=lambda _: _.name,
        get_pk=lambda table: table.id,
        allow_blank=True,
    )

    target = QuerySelectField('Target',
        query_factory=lambda: (db.pokedex_session.query(tables.MoveTarget)
            .filter(tables.MoveTarget.identifier != 'selected-pokemon-me-first')),
        get_pk=lambda _: _.id,
        get_label=lambda _: _.name,
        allow_blank=True,
    )

    similar_to = PokedexLookupField('Same effect as', valid_type='move', allow_blank=True)

    type = QueryCheckboxSelectMultipleField(
        'Type',
        query_factory=lambda: db.pokedex_session.query(tables.Type)
                              .filter(tables.Type.id != 10002),  # Shadow
        get_label=lambda _: _.name,
        get_pk=lambda table: table.identifier,
        allow_blank=True,
    )

    shadow_moves = fields.BooleanField('Include Colosseum/XD Shadow moves')

    category = QueryCheckboxSelectMultipleField(
        'Category',
        query_factory=lambda: db.pokedex_session.query(tables.MoveMetaCategory)
            .options(joinedload(tables.MoveMetaCategory.prose_local)),
        get_label=lambda _: _.description,
        get_pk=lambda _: _.identifier,
        allow_blank=True,
    )
    ailment = QueryCheckboxSelectMultipleField(
        'Status ailment',
        query_factory=lambda: db.pokedex_session.query(tables.MoveMetaAilment)
            .options(joinedload(tables.MoveMetaAilment.names_local)),
        get_label=lambda _: _.name,
        get_pk=lambda _: _.identifier,
        allow_blank=True,
    )

    # Pokémon
    pokemon = DuplicateField(
        PokedexLookupField(u'Pokémon', valid_type='pokemon', allow_blank=True),
        min_entries=6,
        max_entries=6,
    )
    # XXX perhaps share this stuff with the definitions above
    pokemon_method = QueryCheckboxSelectMultipleField(
        'Learned by',
        query_factory=lambda: db.pokedex_session.query(tables.PokemonMoveMethod)
            # XXX move methods need to identify themselves as "common"
            .filter(tables.PokemonMoveMethod.id <= 4),
        get_label=lambda row: row.name,
        get_pk=lambda table: table.identifier,
        allow_blank=True,
    )
    pokemon_version_group = QueryCheckboxSelectMultipleField(
        'Versions',
        query_factory=lambda: db.pokedex_session.query(tables.VersionGroup) \
                                             .options(eagerload('versions')),
        get_label=lambda row: pokedex_helpers.version_icons(*row.versions),
        get_pk=lambda table: table.id,
        allow_blank=True,
    )

    # Numbers
    accuracy = RangeTextField('Accuracy', inflator=int)
    pp = RangeTextField('PP', inflator=int)
    power = RangeTextField('Power', inflator=int)
    priority = RangeTextField('Priority', inflator=int, signed=True)

    recoil = RangeTextField('% damage absorbed/recoiled', inflator=int, signed=True)
    healing = RangeTextField('% max HP healed', inflator=int, signed=True)
    ailment_chance = RangeTextField('Ailment chance', inflator=int)
    flinch_chance = RangeTextField('Flinch chance', inflator=int)
    stat_chance = RangeTextField('Stat chance', inflator=int)

    crit_rate = fields.BooleanField('Increased crit rate')
    multi_hit = fields.BooleanField('Hits multiple times')
    multi_turn = fields.BooleanField('Effect lasts multiple (but finite) turns')

    # Order and display
    sort = fields.SelectField('Sort by',
        choices=[
            ('id', 'Internal ID'),
            ('name', 'Name'),
            ('type', 'Type'),
            ('class', 'Damage class'),
            ('pp', 'PP'),
            ('power', 'Power'),
            ('accuracy', 'Accuracy'),
            ('priority', 'Priority'),
            ('effect_chance', 'Effect chance'),
            ('effect', 'Effect'),
        ],
        default='name',
    )
    sort_backwards = fields.BooleanField('Sort backwards')

    display = fields.SelectField('Display',
        choices=[
            ('smart-table', 'Smart table'),
            ('custom-table', 'Custom table'),
            ('custom-list', 'Custom list'),
        ],
        default='smart-table',
    )

    column = MultiCheckboxField(
        'Custom table columns',
        choices=[
            ('id', 'Internal ID'),
            ('name', 'Name'),
            ('type', 'Type'),
            ('class', 'Damage class'),
            ('pp', 'PP'),
            ('power', 'Power'),
            ('accuracy', 'Accuracy'),
            ('priority', 'Priority'),
            ('effect_chance', 'Effect chance'),
            ('effect', 'Effect'),
        ],
        default=default_move_table_columns,
    )
    format = fields.TextField('Custom list format', default=u'$name')


class PokedexSearchController(PokedexBaseController):
    def __before__(self, action, **params):
        super(PokedexSearchController, self).__before__(action, **params)

        c.javascripts.append(('pokedex', 'pokedex'))

    def pokemon_search(self):
        class F(PokemonSearchForm):
            pass

        # Add stat-based fields dynamically
        c.stat_fields = []
        for stat in db.pokedex_session.query(tables.Stat) \
                                   .filter(~tables.Stat.is_battle_only) \
                                   .order_by(tables.Stat.id):
            field_name = stat.identifier.replace(u'-', u'_')

            stat_field = RangeTextField(stat.name, inflator=int)
            effort_field = RangeTextField(stat.name, inflator=int)

            c.stat_fields.append((stat.id, field_name))

            setattr(F, 'stat_' + field_name, stat_field)
            setattr(F, 'effort_' + field_name, effort_field)


        ### Parse form, etc etc
        c.form = F(request.params)
        c.form.validate()

        # Rendering needs to know which version groups go with which
        # generations for the move-version-group list
        c.generations = db.pokedex_session.query(tables.Generation) \
            .options(eagerload('version_groups')) \
            .order_by(tables.Generation.id.asc())

        # Rendering also needs an example Pokémon, to make the custom list docs
        # reliable
        c.eevee = db.pokedex_session.query(tables.Pokemon).get(133)

        # If this is the first time the form was submitted, redirect to a URL
        # with only non-default values
        if c.form.is_valid and c.form.was_submitted and c.form.needs_shortening:
            redirect(url.current(**c.form.cleansed_data.mixed()))

        if not c.form.was_submitted or not c.form.is_valid:
            # Either blank, or errortastic.  Skip the logic and just send the
            # form back
            return render('/pokedex/search/pokemon.mako')


        ### Do the searching!
        me = tables.Pokemon
        my_species = tables.PokemonSpecies
        query = db.pokedex_session.query(me).join((my_species, me.species))
        query = query.join(my_species.names_local)

        # Several joins need to know the default form
        default_form = tables.PokemonForm
        query = query.outerjoin((default_form, me.default_form))

        # Sorting and filtering by stat both need to join to the stat table for
        # the specific stat in question.  Keep track of these joins to avoid
        # doing them multiple times
        stat_aliases = {}
        def join_to_stat(stat):
            # stat can be an id, object, or identifier
            if isinstance(stat, basestring):
                stat = db.pokedex_session.query(tables.Stat) \
                    .filter_by(identifier=stat).one()
            elif isinstance(stat, int):
                stat = db.pokedex_session.query(tables.Stat).get(stat)

            if stat not in stat_aliases:
                stat_alias = aliased(tables.PokemonStat)
                new_query = query.join(stat_alias)
                new_query = new_query.filter(stat_alias.stat_id == stat.id)
                stat_aliases[stat] = stat_alias
            else:
                new_query = query

            return new_query, stat_aliases[stat]

        stat_total_subquery = None
        def join_to_stat_total():
            new_query = query
            subquery = stat_total_subquery

            if subquery is None:
                alias = aliased(tables.PokemonStat)
                subquery = db.pokedex_session.query(
                    alias.pokemon_id,
                    func.sum(alias.base_stat).label('stat_total'),
                    func.sum(alias.effort).label('effort_total')
                ).group_by(alias.pokemon_id).subquery()
                    
                new_query = new_query.outerjoin(subquery,
                    me.id == subquery.c.pokemon_id)

            return new_query, subquery

        # Same applies to a couple other tables...
        joins = []
        def join_once(relation):
            if relation in joins:
                return query

            new_query = query.join(relation)
            joins.append(relation)
            return new_query

        # ID
        if c.form.id.data:
            query = query.filter(c.form.id.data(my_species.id))

        # Name
        if c.form.name.data:
            name = c.form.name.data.strip().lower()

            query = query.join(default_form.names_local)
            query = query.filter(
                or_(
                    # Either it was a form name...
                    ilike(default_form.names_table.pokemon_name, name),
                    # ...or not.
                    ilike(my_species.names_table.name, name),
                )
            )

        # Ability
        if c.form.ability.data:
            query = query.filter(
                me.all_abilities.any(
                    tables.Ability.id == c.form.ability.data.id
                )
            )

        # Held item
        if c.form.held_item.data:
            item_subquery = db.pokedex_session.query(
                    tables.PokemonItem.pokemon_id
                ) \
                .filter_by(item_id=c.form.held_item.data.id) \
                .subquery()

            query = query.join((item_subquery,
                me.id == item_subquery.c.pokemon_id))

        # Growth rate
        if c.form.growth_rate.data:
            query = query.filter(my_species.growth_rate == c.form.growth_rate.data)

        # Type
        if c.form.type.data:
            type_ids = [_.id for _ in c.form.type.data]

            if c.form.type_operator.data == u'any':
                # Well, this is easy; be lazy and use EXISTS
                query = query.filter(
                    me.types.any( tables.Type.id.in_(type_ids) )
                )

            elif c.form.type_operator.data == u'only':
                # None of this Pokémon's types can be not selected.  Right.
                query = query.filter(
                    ~ me.types.any( ~ tables.Type.id.in_(type_ids) )
                )

            elif c.form.type_operator.data == u'exact':
                # This one is interesting, and not quite so easy to express
                # with set operations.  It's like 'only', except every selected
                # type also must be one of the Pokémon's types.  Thus we
                # combine the above two approaches:
                query = query.filter(
                    ~ me.types.any( ~ tables.Type.id.in_(type_ids) )
                )

                for type_id in type_ids:
                    query = query.filter(
                        me.types.any( tables.Type.id == type_id )
                    )

        # Gender distribution
        if c.form.gender_rate.data:
            gender_rate = int(c.form.gender_rate.data)
            gender_rate_op = c.form.gender_rate_operator.data

            # Genderless ignores the operator
            if gender_rate == -1 or gender_rate_op == 'equal':
                clause = my_species.gender_rate == gender_rate
            elif gender_rate_op == 'less_equal':
                clause = my_species.gender_rate <= gender_rate
            elif gender_rate_op == 'more_equal':
                clause = my_species.gender_rate >= gender_rate

            if gender_rate != -1:
                # No amount of math should make "<= 1/4 female" include
                # genderless
                clause = and_(clause, my_species.gender_rate != -1)

            query = query.filter(clause)

        # Egg groups
        if any(c.form.egg_group.data):
            clauses = []
            for egg_group in c.form.egg_group.data:
                if not egg_group:
                    continue
                subclause = my_species.egg_groups.any(
                    tables.EggGroup.id == egg_group.id
                )
                clauses.append(subclause)

            if c.form.egg_group_operator.data == 'any':
                clause = or_(*clauses)
            elif c.form.egg_group_operator.data == 'all':
                clause = and_(*clauses)

            query = query.filter(clause)

        # Evolution stuff
        # Try to limit our joins without duplicating too much code
        # Stage and position generally need to know parents:
        if c.form.evolution_stage.data or c.form.evolution_position.data or \
           c.form.evolution_special.data:
            # NOTE: This makes the assumption that evolution chains are never
            # more than three Pokémon long.  So far, this is pretty safe, as in
            # 10+ years no Pokémon has ever been able to evolve more than
            # twice.  If this changes, then either this query will need a
            # greatgrandparent, or (likely) the table structure will change
            parent_species = aliased(tables.PokemonSpecies)
            grandparent_species = aliased(tables.PokemonSpecies)

            query = query.outerjoin(
                # If we're a specific form, check the base form, too
                (tables.PokemonEvolution,
                    tables.PokemonEvolution.evolved_species_id == my_species.id),
                (parent_species, my_species.parent_species),

                # No Pokémon ever evolve, gain forms, then evolve again
                (grandparent_species, parent_species.parent_species)
            )

        # ...whereas position and special tend to need children
        if c.form.evolution_position.data or c.form.evolution_special.data:
            child_species = aliased(tables.PokemonSpecies)
            child_subquery = db.pokedex_session.query(
                    child_species.evolves_from_species_id.label('parent_id'),
                    func.count('*').label('child_count'),
                ) \
                .group_by(child_species.evolves_from_species_id) \
                .subquery()

            query = query.outerjoin((child_subquery,
                my_species.id == child_subquery.c.parent_id))

        if c.form.evolution_stage.data:
            # Collect clauses for the requested stages and add to the query
            clauses = []
            if u'baby' in c.form.evolution_stage.data:
                # Baby form: is_baby.  Cool, easy.
                clauses.append( my_species.is_baby == True )

            if u'basic' in c.form.evolution_stage.data:
                # Basic: this is not a baby.  Either there's no parent, or
                # parent is a baby
                clauses.append(
                    and_(
                        my_species.is_baby == False,
                        or_(
                            parent_species.id == None,
                            parent_species.is_baby == True,
                        )
                    )
                )

            if u'stage1' in c.form.evolution_stage.data:
                # Stage 1: parent exists and is not a baby.  Grandparent either
                # doesn't exist or is a baby
                clauses.append(
                    and_(
                        parent_species.id != None,
                        parent_species.is_baby == False,
                        or_(
                            grandparent_species.id == None,
                            grandparent_species.is_baby == True,
                        ),
                    )
                )

            if u'stage2' in c.form.evolution_stage.data:
                # Stage 2: grandparent exists and is not a baby
                clauses.append(
                    and_(
                        grandparent_species.id != None,
                        grandparent_species.is_baby == False,
                    )
                )

            query = query.filter(or_(*clauses))

        if c.form.evolution_position.data:
            # Same story
            clauses = []

            if u'first' in c.form.evolution_position.data:
                # No parent; at least one child
                clauses.append(
                    and_(
                        parent_species.id == None,
                        child_subquery.c.child_count != None,
                    )
                )

            if u'middle' in c.form.evolution_position.data:
                # Has a parent AND a child
                clauses.append(
                    and_(
                        parent_species.id != None,
                        child_subquery.c.child_count != None,
                    )
                )

            if u'last' in c.form.evolution_position.data:
                # Has a parent but no children
                clauses.append(
                    and_(
                        parent_species.id != None,
                        child_subquery.c.child_count == None
                    )
                )

            if u'only' in c.form.evolution_position.data:
                # No parent or children
                clauses.append(
                    and_(
                        parent_species.id == None,
                        child_subquery.c.child_count == None,
                    )
                )

            query = query.filter(or_(*clauses))

        if c.form.evolution_special.data:
            clauses = []

            if u'branching' in c.form.evolution_special.data:
                # Branching means: multiple children.  Easy!
                clauses.append( child_subquery.c.child_count > 1 )

            if u'branched' in c.form.evolution_special.data:
                # Need to join to..  siblings.  Ugh.
                sibling_species = aliased(tables.PokemonSpecies)
                sibling_subquery = db.pokedex_session.query(
                    sibling_species.evolves_from_species_id.label('parent_id'),
                    func.count('*').label('sibling_count'),
                ) \
                    .group_by(sibling_species.evolves_from_species_id) \
                    .subquery()

                query = query.outerjoin((
                    sibling_subquery,
                    parent_species.id == sibling_subquery.c.parent_id
                ))

                clauses.append( sibling_subquery.c.sibling_count > 1 )

            query = query.filter(or_(*clauses))

        # Generation
        if c.form.introduced_in.data:
            query = query.filter(
                my_species.generation_id.in_(data.id for data in c.form.introduced_in.data)
            )

        # Regional dex inclusion
        if c.form.in_pokedex.data:
            pokedex_query = db.pokedex_session.query(
                    tables.PokemonDexNumber.species_id) \
                .filter(tables.PokemonDexNumber.pokedex_id.in_(
                    data.id for data in c.form.in_pokedex.data))

            query = query.filter(my_species.id.in_(pokedex_query.subquery()))

        # Moves
        # To avoid stupid group-by-having-count tricks, each move needs to
        # check a separate subquery of Pokémon that learn the given move
        # under the given conditions.
        pokemoves_filter = []
        if c.form.move_version_group.data:
            pokemoves_filter.append(tables.PokemonMove.version_group_id.in_(
                [_.id for _ in c.form.move_version_group.data]))
        if c.form.move_method.data:
            pokemoves_filter.append(
                tables.PokemonMove.pokemon_move_method_id.in_(
                    [_.id for _ in c.form.move_method.data])
            )
        for move in c.form.move.data:
            # Apply fuzzing
            if c.form.move_fuzz.data == 'same-effect':
                move_effect_query = db.pokedex_session.query(tables.Move) \
                    .filter_by(effect_id=move.effect_id)
                move_ids = [id for (id,) in
                    move_effect_query.values(tables.Move.id)]
            else:
                move_ids = [move.id]

            query = query.filter(me.pokemon_moves.any(
                and_(tables.PokemonMove.move_id.in_(move_ids),
                    *pokemoves_filter)
            ))

        # Numbers
        for stat_id, field_name in c.stat_fields:
            stat_field = c.form['stat_' + field_name]
            effort_field = c.form['effort_' + field_name]

            if stat_field.data or effort_field.data:
                query, stat_alias = join_to_stat(stat_id)

                if stat_field.data:
                    query = query.filter(stat_field.data(stat_alias.base_stat))

                if effort_field.data:
                    query = query.filter(effort_field.data(stat_alias.effort))

        if c.form.stat_total.data:
            query, stat_total_subquery = join_to_stat_total()
            query = query.filter(c.form.stat_total.data(
                stat_total_subquery.c.stat_total))

        if c.form.effort_total.data:
            query, stat_total_subquery = join_to_stat_total()
            query = query.filter(c.form.effort_total.data(
                stat_total_subquery.c.effort_total))

        if c.form.hatch_counter.data:
            query = query.filter(c.form.hatch_counter.data(my_species.hatch_counter))

        if c.form.base_experience.data:
            query = query.filter(c.form.base_experience.data(me.base_experience))

        if c.form.capture_rate.data:
            query = query.filter(c.form.capture_rate.data(my_species.capture_rate))

        if c.form.base_happiness.data:
            query = query.filter(c.form.base_happiness.data(my_species.base_happiness))

        if c.form.height.data:
            query = query.filter(c.form.height.data(me.height))

        if c.form.weight.data:
            query = query.filter(c.form.weight.data(me.weight))

        # Genus string
        if c.form.genus.data:
            query = query.filter(ilike(my_species.names_table.genus, c.form.genus.data))

        # Color
        if c.form.color.data:
            query = query.filter( my_species.color_id == c.form.color.data.id )

        # Habitat
        if c.form.habitat.data:
            query = query.filter( my_species.habitat_id == c.form.habitat.data.id )

        # Shape
        if c.form.shape.data:
            query = query.filter( my_species.shape_id == c.form.shape.data.id )


        ### Display
        c.display_mode = c.form.display.data
        c.display_columns = []
        c.original_results = None  # evolution chain thing
        c.species_count = None
        c.total_count = None

        if c.display_mode == 'smart-table':
            # Based on the standard table, but a little more clever.  For
            # example: searching by moves will show how the move is learned by
            # each resulting Pokémon.
            # TODO actually do that.
            c.display_mode = 'custom-table'
            c.display_columns = default_pokemon_table_columns

        elif c.display_mode == 'custom-table':
            # User can pick whatever columns, in any order.  Woo!
            c.display_columns = c.form.column.data
            if not c.display_columns:
                # Hmm.  Show name, at least.
                c.display_columns = ['name']

        elif c.display_mode == 'custom-list':
            # Use whatever they asked for; it'll get pumped through
            # safe_substitute anyway.  This uses apply_pokemon_template from
            # the pokedex helpers
            list_format = c.form.format.data.strip()

            # Asterisk at the beginning is secret code to make this a
            # traditional list
            if list_format and list_format[0] == u'*':
                c.display_mode = 'custom-list-bullets'
                list_format = list_format[1:]

            # Need to escape funny characters in the actual format, but the
            # h.literal() stuff in the helper functions infects the entire
            # format and allows user HTML, and using h.escape() here likewise
            # escapes even legitimate $icon's.  Solution is to use h.escape,
            # then cast back to a string to remove infectious magic
            c.display_template = Template( unicode(h.escape(list_format)) )

        else:
            # icons and sprites don't need any special behavior
            pass

        # "Name" is the field that actually links to the page.  If it's
        # missing, add a little link column
        if c.display_mode == 'custom-table' and 'name' not in c.display_columns:
            c.display_columns.append('link')

        ### Sorting
        # nb: the below sort ascending for words (a->z) and descending for
        # numbers (9->1), because that's how it should be, okay
        # Default fallback sort is by name, then by form
        # XXX: Use name, not identifier
        sort_clauses = [my_species.identifier.asc(), default_form.order.asc(),
                        default_form.form_identifier.asc()]

        if c.form.sort.data == 'id':
            # Sorting by both name and national ID is redundant, since both are
            # the same for two species.
            sort_clauses[0] = my_species.id.asc()

        elif c.form.sort.data == 'evolution-chain':
            # This one is very special!  It affects sorting, but if the display
            # is a table, sorting by chain will also show other Pokémon from
            # each family, even if they don't match the search criteria.
            # E.g., a search that produces Bulbasaur will display Bulbasaur,
            # followed by Ivysaur and Venusaur dimmed.
            # XXX doing this for lists would be nice, too, but would sort of
            # break copy/paste, which is what lists are designed for

            # DO NOT allow sorting backwards!  It breaks the template's
            # indenting magic.  XXX fix me!
            c.form.sort_backwards.data = False

            # Grab the results first; needed for sorting even if the query is
            # otherwise left alone, boo
            pokemon_ids = {}
            species_ids = set()  # For result count
            evolution_chain_ids = set()
            for id, chain_id, species_id in query.values(me.id,
              my_species.evolution_chain_id, my_species.id):
                evolution_chain_ids.add(chain_id)
                species_ids.add(species_id)
                pokemon_ids[id] = None

            c.species_count = len(species_ids)
            c.total_count = len(pokemon_ids.keys())

            # Rebuild the query
            if c.display_mode in ('custom-table',):
                query = db.pokedex_session.query(me).filter(
                    my_species.evolution_chain_id.in_( list(evolution_chain_ids) )
                )
            else:
                query = db.pokedex_session.query(me) \
                    .filter(me.id.in_(pokemon_ids.keys()))

            # Join the new query to pokemon & forms again; needed for sorting
            query = query.join((me, my_species.pokemon))
            query = query.outerjoin((default_form, me.default_form))

            # Let the template know which Pokémon are actually in the original
            # result set
            c.original_results = pokemon_ids

            # Pokémon should be sorted by the id number of the first form of
            # their chain to actually appear in the results.  This is wonky,
            # but makes sure that fake results don't affect sorting
            chain_sorting_alias = aliased(tables.Pokemon)
            chain_sorting_species = aliased(tables.PokemonSpecies)
            chain_sorting_forms = aliased(tables.PokemonForm)
            chain_sorting_subquery = db.pokedex_session.query(
                    chain_sorting_species.evolution_chain_id,
                    func.min(chain_sorting_species.id).label('chain_position')
                ).select_from(chain_sorting_alias) \
                .filter(chain_sorting_species.id.in_(pokemon_ids)) \
                .outerjoin((chain_sorting_species, chain_sorting_alias.species)) \
                .outerjoin((chain_sorting_forms, chain_sorting_alias.default_form)) \
                .group_by(chain_sorting_species.evolution_chain_id) \
                .subquery()

            query = query.join((
                chain_sorting_subquery,
                chain_sorting_subquery.c.evolution_chain_id
                    == my_species.evolution_chain_id
            ))

            # Sort by ID instead of name within families
            sort_clauses[0] = my_species.order

            sort_clauses = [
                chain_sorting_subquery.c.chain_position,
                my_species.is_baby.desc()
            ] + sort_clauses

        elif c.form.sort.data == 'name':
            # Name is fallback, so don't do anything
            pass

        elif c.form.sort.data == 'type':
            # Sort by type1, then type2.  Unfortunately, need to left-join
            # independently for each type to make this work right
            type_sort_clauses = []
            for type_slot in [1, 2]:
                pokemon_type_alias = aliased(tables.PokemonType)
                type_alias = aliased(tables.Type)

                query = query \
                    .outerjoin((pokemon_type_alias,
                        and_(pokemon_type_alias.pokemon_id == me.id,
                             pokemon_type_alias.slot == type_slot))) \
                    .outerjoin((type_alias,
                        pokemon_type_alias.type_id == type_alias.id))

                # Single-type should come first; i.e., sorting by type2 asc
                # means NULL should come first.  This isn't the default in
                # postgres (and elsewhere?), so do it explicitly
                if type_slot == 2:
                    # Booleans sort by false, true -- so this should be desc to
                    # put NULL first
                    type_sort_clauses.append((type_alias.id == None).desc())

                type_sort_clauses.append(type_alias.identifier.asc())

            sort_clauses = type_sort_clauses + sort_clauses

        elif c.form.sort.data == 'growth-rate':
            query = query.outerjoin(my_species.growth_rate)
            query = query.outerjoin(tables.Experience, tables.GrowthRate.max_experience_obj)
            sort_clauses.insert(0, tables.Experience.experience.desc())

        elif c.form.sort.data == 'height':
            sort_clauses.insert(0, me.height.desc())

        elif c.form.sort.data == 'weight':
            sort_clauses.insert(0, me.weight.desc())

        elif c.form.sort.data == 'gender':
            sort_clauses.insert(0, my_species.gender_rate.asc())

        elif c.form.sort.data == 'genus':
            sort_clauses.insert(0, my_species.names_table.genus.asc())

        elif c.form.sort.data == 'color':
            query = query.outerjoin(my_species.color)
            sort_clauses.insert(0, tables.PokemonColor.identifier.asc())

        elif c.form.sort.data == 'habitat':
            query = query.outerjoin(my_species.habitat)
            sort_clauses.insert(0, tables.PokemonHabitat.identifier.asc())

        elif c.form.sort.data == 'hatch-counter':
            sort_clauses.insert(0, my_species.hatch_counter.asc())

        elif c.form.sort.data == 'base-experience':
            sort_clauses.insert(0, me.base_experience.desc())

        elif c.form.sort.data == 'capture-rate':
            sort_clauses.insert(0, my_species.capture_rate.desc())

        elif c.form.sort.data == 'base-happiness':
            sort_clauses.insert(0, my_species.base_happiness.desc())

        elif c.form.sort.data == 'stat-total':
            query, stat_total_subquery = join_to_stat_total()
            sort_clauses.insert(0, stat_total_subquery.c.stat_total.desc())

        elif c.form.sort.data.startswith('stat-'):
            stat_ident = c.form.sort.data[5:]
            query, stat_alias = join_to_stat(stat_ident)
            sort_clauses.insert(0, stat_alias.base_stat.desc())

        # Reverse sort
        if c.form.sort_backwards.data:
            for i, clause in enumerate(sort_clauses):
                # This is some semi-black SQLA magic...
                if clause.modifier == asc_op:
                    sort_clauses[i] = clause.element.desc()
                else:
                    sort_clauses[i] = clause.element.asc()

        query = query.order_by(*sort_clauses)

        # We always want the species
        query = query.options(eagerload('species'))

        ### Run the query!
        c.results = query.all()

        # Count the results (which we've already done if we're family-sorting)
        if c.species_count is None:
            c.species_count = len(set(result.species_id for result in c.results))
            c.total_count = len(c.results)

        ### Eagerloading
        # SQLAlchemy is guaranteed to only have one copy of a particular object
        # around at a time.  So if I run queries with the same results several
        # times, but eagerload something different each time, I'll only have
        # one set of obects with all of the eagerloads present on each.
        # For simplicity, and because all of the conditional eagerloads are
        # has-manies, this code abuses the above property to eagerload
        # everything after-the-fact, based on which table columns are visible.
        # TODO doesn't apply so much to lists at the moment...
        if c.results and c.display_mode == 'custom-table':
            eagerloads = []

            if 'icon' in c.display_columns:
                eagerloads.append('default_form')

            if 'type' in c.display_columns:
                eagerloads.append('types')

            if 'ability' in c.display_columns:
                eagerloads.append('abilities')

            if 'hidden_ability' in c.display_columns:
                eagerloads.append('hidden_ability')

            if 'egg_group' in c.display_columns:
                eagerloads.append('species.egg_groups')

            if any(column[0:5] == 'stat_' for column in c.display_columns) \
                or 'effort' in c.display_columns:

                eagerloads.append('stats.stat')

            if c.form.sort.data == 'evolution-chain':
                # Gotta know the chain itself and the parent Pokémon to make
                # the cool indented tree work
                eagerloads.append('species.parent_species')


            ids = [_.id for _ in c.results]
            for relation in eagerloads:
                # Run the query again, selecting only by id this time, but
                # eagerloading some relation
                (db.pokedex_session.query(tables.Pokemon) \
                    .filter(tables.Pokemon.id.in_(ids)) \
                    .options(eagerload_all(relation)) \
                    .all())

        ### Done.
        return render('/pokedex/search/pokemon.mako')

    def move_search(self):
        ### First tack some database-driven fields onto the form
        c.stats = db.pokedex_session.query(tables.Stat).all()

        class F(MoveSearchForm):
            stat_change = StatField(c.stats, RangeTextField('', inflator=int, signed=True))

        # Add flag fields dynamically
        c.flag_fields = []
        c.flags = db.pokedex_session.query(tables.MoveFlag) \
            .order_by(tables.MoveFlag.id)
        for flag in c.flags:
            field_name = 'flag_' + flag.identifier
            field = fields.SelectField(flag.name,
                choices=[
                    (u'any',    u''),
                    (u'yes',    u'Yes'),
                    (u'no',     u'No'),
                ],
                default=u'any',
            )

            c.flag_fields.append((field_name, flag.id))
            setattr(F, field_name, field)


        ### Parse form, etc etc
        c.form = F(request.params)
        c.form.validate()

        # Rendering needs to know which version groups go with which
        # generations for the move-version-group list
        c.generations = db.pokedex_session.query(tables.Generation) \
            .order_by(tables.Generation.id.asc())

        # Rendering also needs an example move, to make the custom list docs
        # reliable
        c.surf = db.pokedex_session.query(tables.Move).get(57)

        # If this is the first time the form was submitted, redirect to a URL
        # with only non-default values
        if c.form.is_valid and c.form.was_submitted and c.form.needs_shortening:
            redirect(url.current(**c.form.cleansed_data.mixed()))

        if not c.form.was_submitted or not c.form.is_valid:
            # Either blank, or errortastic.  Skip the logic and just send the
            # form back
            return render('/pokedex/search/moves.mako')


        ### Do the searching!
        me = tables.Move
        query = db.pokedex_session.query(me) \
            .join(me.names_local) \
            .join(tables.MoveEffect) \
            .outerjoin(tables.MoveMeta)

        # Name
        if c.form.name.data:
            query = query.filter( ilike(me.names_table.name, c.form.name.data) )

        # Damage class
        if c.form.damage_class.data:
            query = query.filter(
                me.damage_class_id.in_(_.id for _ in c.form.damage_class.data)
            )

        # Generation
        if c.form.introduced_in.data:
            query = query.filter(
                me.generation_id.in_(_.id for _ in c.form.introduced_in.data)
            )

        # Target
        if c.form.target.data:
            query = query.filter(me.target_id == c.form.target.data.id)

        # Effect
        if c.form.similar_to.data:
            query = query.filter(me.effect_id == c.form.similar_to.data.effect_id)

        # Type
        if c.form.type.data:
            type_ids = [_.id for _ in c.form.type.data]
            query = query.filter( me.type_id.in_(type_ids) )

        if not c.form.shadow_moves.data:
            query = query.filter(me.type_id != 10002)

        # Flags
        for field, flag_id in c.flag_fields:
            if c.form[field].data != u'any':
                # Join to a move-flag table that's cut down to just this flag
                flag_alias = aliased(tables.MoveFlagMap)
                subq = db.pokedex_session.query(flag_alias) \
                    .filter(flag_alias.move_flag_id == flag_id) \
                    .subquery()

                # Then join or nega-join against it
                if c.form[field].data == u'yes':
                    query = query.join((subq, me.id == subq.c.move_id))
                else:
                    query = query.outerjoin((subq, me.id == subq.c.move_id)) \
                        .filter(subq.c.move_id == None)

        # Meta stuff
        if c.form.category.data:
            query = query.filter(tables.MoveMeta.meta_category_id.in_(
                row.id for row in c.form.category.data))

        if c.form.ailment.data:
            query = query.filter(tables.MoveMeta.meta_ailment_id.in_(
                row.id for row in c.form.ailment.data))

        if c.form.crit_rate.data:
            query = query.filter(tables.MoveMeta.crit_rate > 0)

        if c.form.multi_hit.data:
            query = query.filter(tables.MoveMeta.min_hits != None)

        if c.form.multi_turn.data:
            query = query.filter(tables.MoveMeta.min_turns != None)

        for stat_field in c.form.stat_change:
            if not stat_field.data:
                continue

            query = query.filter(me.meta_stat_changes.any(and_(
                tables.MoveMetaStatChange.stat == stat_field.stat,
                stat_field.data(tables.MoveMetaStatChange.change),
            )))

        ### Numbers
        # These are all ranges:
        for form_field, column in [
            (c.form.accuracy,           me.accuracy),
            (c.form.pp,                 me.pp),
            (c.form.power,              me.power),
            (c.form.priority,           me.priority),
            (c.form.recoil,             tables.MoveMeta.recoil),
            (c.form.healing,            tables.MoveMeta.healing),
            (c.form.ailment_chance,     tables.MoveMeta.ailment_chance),
            (c.form.flinch_chance,      tables.MoveMeta.flinch_chance),
            (c.form.stat_chance,        tables.MoveMeta.stat_chance),
        ]:
            if not form_field.data:
                continue
            query = query.filter(form_field.data(column))

        # Pokémon -- they're ORed, so only one subquery is necessary
        #for pokemon in c.form.pokemon.data:
        if c.form.pokemon.data:
            pokemoves_alias = aliased(tables.PokemonMove)

            ids = [_.id for _ in c.form.pokemon.data]
            pokemoves_subq = db.pokedex_session.query(pokemoves_alias.move_id) \
                .filter(pokemoves_alias.pokemon_id.in_(ids))

            if c.form.pokemon_method.data:
                ids = [_.id for _ in c.form.pokemon_method.data]
                pokemoves_subq = pokemoves_subq.filter(
                    pokemoves_alias.pokemon_move_method_id.in_(ids))

            if c.form.pokemon_version_group.data:
                ids = [_.id for _ in c.form.pokemon_version_group.data]
                pokemoves_subq = pokemoves_subq.filter(
                    pokemoves_alias.version_group_id.in_(ids))

            pokemoves_subq = pokemoves_subq.subquery()

            query = query.filter(me.id.in_(pokemoves_subq))


        ### Display
        c.display_mode = c.form.display.data
        c.display_columns = []

        if c.display_mode == 'smart-table':
            # Based on the standard table, but a little more clever.  For
            # example: searching by moves will show how the move is learned by
            # each resulting Pokémon.
            # TODO actually do that.
            c.display_mode = 'custom-table'
            c.display_columns = default_move_table_columns

        elif c.display_mode == 'custom-table':
            # User can pick whatever columns, in any order.  Woo!
            c.display_columns = c.form.column.data
            if not c.display_columns:
                # Hmm.  Show name, at least.
                c.display_columns = ['name']

        elif c.display_mode == 'custom-list':
            # Use whatever they asked for; it'll get pumped through
            # safe_substitute anyway.  This uses apply_pokemon_template from
            # the pokedex helpers
            list_format = c.form.format.data.strip()

            # Asterisk at the beginning is secret code to make this a
            # traditional list
            if list_format[0] == u'*':
                c.display_mode = 'custom-list-bullets'
                list_format = list_format[1:]

            # See super-duper long comment for Pokémon search.  Doesn't matter
            # so much for moves, which have no literal() template things, but
            # avoids bugs in the future.
            c.display_template = Template( unicode(h.escape(list_format)) )

        # "Name" is the field that actually links to the page.  If it's
        # missing, add a little link column
        if c.display_mode == 'custom-table' and 'name' not in c.display_columns:
            c.display_columns.append('link')

        ### Sorting
        # nb: the below sort ascending for words (a->z) and descending for
        # numbers (9->1), because that's how it should be, okay
        # Default fallback sort is by name, then by id (in case of form)
        sort_clauses = [ me.names_table.name.asc(), me.id.asc() ]
        if c.form.sort.data == 'id':
            sort_clauses.insert(0,
                me.id.asc()
            )

        elif c.form.sort.data == 'name':
            # Name is fallback, so don't do anything
            pass

        elif c.form.sort.data == 'type':
            # Sort by type name
            query = query.join(me.type)
            sort_clauses.insert(0, tables.Type.identifier.asc())

        elif c.form.sort.data == 'class':
            sort_clauses.insert(0, me.damage_class_id.asc())

        elif c.form.sort.data == 'pp':
            sort_clauses.insert(0, me.pp.desc())

        elif c.form.sort.data == 'power':
            sort_clauses.insert(0, me.power.desc())

        elif c.form.sort.data == 'accuracy':
            sort_clauses.insert(0, me.accuracy.desc())

        elif c.form.sort.data == 'priority':
            sort_clauses.insert(0, tables.Move.priority.desc())

        elif c.form.sort.data == 'effect':
            query = query.join(tables.MoveEffect.prose)
            sort_clauses.insert(0, tables.MoveEffect.prose_table.effect.desc())

        # Reverse sort
        if c.form.sort_backwards.data:
            for i, clause in enumerate(sort_clauses):
                # This is some semi-black SQLA magic...
                if clause.modifier == asc_op:
                    sort_clauses[i] = clause.element.desc()
                else:
                    sort_clauses[i] = clause.element.asc()

        query = query.order_by(*sort_clauses)

        # Eagerload the obvious stuff: type and damage class
        query = query.options(
            eagerload('type'),
            eagerload('damage_class'),
            eagerload('move_effect'),
            eagerload('move_effect.prose_local'),
        )

        c.results = query.all()

        ### Done.
        return render('/pokedex/search/moves.mako')
