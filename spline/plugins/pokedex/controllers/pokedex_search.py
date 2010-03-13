# encoding: utf8
from __future__ import absolute_import, division

import logging
import re

from wtforms import Form, ValidationError, fields, widgets
from wtforms.ext.sqlalchemy.fields import QuerySelectField, QueryCheckboxMultipleSelectField

import pokedex.db.tables as tables
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect_to
from sqlalchemy.orm import aliased
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func, and_, not_, or_

from spline.lib.base import BaseController, render

from spline.plugins.pokedex.db import pokedex_session

log = logging.getLogger(__name__)

class QueryTextField(fields.TextField):
    """Represents a database object entered in a freeform text field.

    Works similarly to QuerySelectField.  `query_factory` is still expected to
    return a query, but it takes a single argument: the incoming form value.
    `label_attr` is used to set the rendered field's value.
    """
    def __init__(self, label, query_factory, label_attr, *args, **kwargs):
        super(fields.TextField, self).__init__(label, *args, **kwargs)
        self.query_factory = query_factory
        self.label_attr = label_attr

    def process_formdata(self, valuelist):
        """Processes and loads the form value."""
        # Default of None
        if not valuelist or valuelist[0] == '':
            self.data = None
            return

        try:
            row = self.query_factory(valuelist[0]).one()
        except NoResultFound:
            raise ValidationError("No such {0}".format(self.label.text.lower()))

        if row:
            self.data = row
            return

    def _value(self):
        """Converts Python value back to a form value."""
        if self.data is None:
            return u''
        else:
            return getattr(self.data, self.label_attr)

# XXX clean this up a bit and propose it for inclusion?
class DuplicateField(fields.Field):
    """Wraps a field that must be rendered several times.  Similar to
    FieldList, except the fields are identical -- names are unchanged."""
    widget = widgets.ListWidget()

    def __init__(self, field, count=1, default=[], **kwargs):
        # XXX uhhh no.
        label = field.args[0]

        super(DuplicateField, self).__init__(label, default=default, **kwargs)

        self.inner_field = field
        self.count = count
        self._prefix = kwargs.get('_prefix', '')

    def process(self, formdata, data=None):
        # XXX handle data somehow?  it's a default I guess?

        # Grab data from the incoming form
        if self.name in formdata:
            valuelist = formdata.getlist(self.name)
        else:
            valuelist = []

        # Create the subfields
        self.subfields = []
        self.data = []

        for i in range(self.count):
            subfield = self.inner_field.bind(form=None, name=self.short_name, prefix=self._prefix, id="{0}-{1}".format(self.id, i))

            if i < len(valuelist):
                subfield.process_formdata([ valuelist[i] ])
            else:
                # nb: do NOT let subfield read the formdata.  subfields want to
                # see only their own values, and formdata contains values for
                # everyone
                subfield.process({})

            if subfield.data != subfield._default:
                self.data.append(subfield.data)

            self.subfields.append(subfield)

    def validate(self, form, extra_validators=[]):
        self.errors = []
        success = True
        for subfield in self.subfields:
            if not subfield.validate(form):
                success = False
                self.errors.append(subfield.errors)
        return success

    def __iter__(self):
        return iter(self.subfields)

    def __len__(self):
        return len(self.subfields)

    def __getitem__(self, index):
        return self.subfields[index]

class PokemonSearchForm(Form):
    # Defaults are set to match what the client will actually send if the field
    # is left blank
    shorten = fields.HiddenField(default=u'')

    # Core stuff
    name = fields.TextField('Name', default=u'')
    ability = QueryTextField('Ability',
        query_factory=
            lambda value: pokedex_session.query(tables.Ability)
                .filter( func.lower(tables.Ability.name) == value.lower() ),
        label_attr='name',
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
    type = QueryCheckboxMultipleSelectField(
        'Type',
        query_factory=lambda: pokedex_session.query(tables.Type),
        label_attr='name',
        get_pk=lambda table: table.name,
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
            query_factory=lambda: pokedex_session.query(tables.EggGroup),
            label_attr='name',
            allow_blank=True,
        ),
        count=2,
    )

    # Evolution
    evolution_stage = fields.CheckboxMultiSelectField('Stage',
        choices=[
            (u'baby',   u'baby'),
            (u'basic',  u'basic'),
            (u'stage1', u'stage 1'),
            (u'stage2', u'stage 2'),
        ],
    )
    evolution_position = fields.CheckboxMultiSelectField('Position',
        choices=[
            (u'first',  u'First evolution'),
            (u'middle', u'Middle evolution'),
            (u'last',   u'Final evolution'),
            (u'only',   u'Only evolution'),
        ],
    )
    evolution_special = fields.CheckboxMultiSelectField('Special',
        choices=[
            (u'branching', u'Branching evolution (e.g., Tyrogue)'),
            (u'branched',  u'Branched evolution (e.g., Shedinja)'),
        ],
    )

    # Flavor
    color = QuerySelectField('Color',
        query_factory=lambda: pokedex_session.query(tables.PokemonColor),
        label_attr='name',
        allow_blank=True,
        get_pk=lambda table: table.name,
    )
    habitat = QuerySelectField('Habitat',
        query_factory=lambda: pokedex_session.query(tables.PokemonHabitat),
        label_attr='name',
        allow_blank=True,
        get_pk=lambda table: table.name,
    )



    def cleanse_data(self, data):
        """Returns a copy of the given form data, with any default values
        removed.
        """
        # Making a copy and deleting items, rather than adding new items to a
        # new dictionary, allows data to not actually be a dictionary.  This is
        # important given that it probably isn't; getlist() is called on it by
        # wtforms code, and most frameworks have some multidict thing going on
        # XXX it would be nice if this didn't include duplicate field defaults
        newdata = data.copy()
        for name, field in self._fields.iteritems():
            if field.data == field._default and name in newdata:
                del newdata[name]

        return newdata


class PokedexSearchController(BaseController):

    def pokemon_search(self):
        c.form = PokemonSearchForm(request.params)
        validates = c.form.validate()
        cleansed_data = c.form.cleanse_data(request.params)

        # If this is the first time the form was submitted, redirect to a URL
        # with only non-default values
        if validates and cleansed_data and cleansed_data.get('shorten', None):
            del cleansed_data['shorten']
            redirect_to(url.current(**cleansed_data.mixed()))

        if not validates or not cleansed_data:
            # Either blank, or errortastic.  Skip the logic and just send the
            # form back
            c.search_performed = False

            return render('/pokedex/search/pokemon.mako')


        # Let the template know we're actually doing something
        c.search_performed = True

        ### Do the searching!
        me = tables.Pokemon
        query = pokedex_session.query(me)

        # Name
        if c.form.name.data:
            name = c.form.name.data.strip().lower()

            def ilike(column, string):
                # If there are no wildcards, assume it's a partial match
                if '*' not in string and '?' not in string:
                    string = "*{0}*".format(string)

                # LIKE wildcards should be escaped: % -> ^%, _ -> ^_, ^ -> ^^
                # Our wildcards should be changed: * -> %, ? -> _
                # And all at once.
                translations = {
                    '%': '^%',      '_': '^_',      '^': '^^',
                    '*': '%',       '?': '_',
                }
                string = re.sub(r'([%_*?^])',
                                lambda match: translations[match.group(0)],
                                string)

                return func.lower(column).like(string, escape='^')

            if ' ' in name:
                # Hmm.  If there's a space, it might be a form name
                form_name, name_sans_form = name.split(' ', 2)
                query = query.filter(
                    or_(
                        # Either it was a form name...
                        and_(
                            ilike( me.forme_name, form_name ),
                            ilike( me.name, name_sans_form ),
                        ),
                        # ...or not.
                        ilike( me.name, name ),
                    )
                )
            else:
                # Busines as usual
                query = query.filter( ilike(me.name, name) )

        # Ability
        if c.form.ability.data:
            query = query.filter( me.abilities.any(
                                    tables.Ability.id == c.form.ability.data.id
                                  )
                                )

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
                clause = me.gender_rate == gender_rate
            elif gender_rate_op == 'less_equal':
                clause = me.gender_rate <= gender_rate
            elif gender_rate_op == 'more_equal':
                clause = me.gender_rate >= gender_rate

            if gender_rate != -1:
                # No amount of math should make "<= 1/4 female" include
                # genderless
                clause = and_(clause, me.gender_rate != -1)

            query = query.filter(clause)

        # Egg groups
        if any(c.form.egg_group.data):
            clauses = []
            for egg_group in c.form.egg_group.data:
                if not egg_group:
                    continue
                subclause = me.egg_groups.any(
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
        if c.form.evolution_stage.data or c.form.evolution_position.data:
            # NOTE: This makes the assumption that evolution chains are never
            # more than three Pokémon long.  So far, this is pretty safe, as in
            # 10+ years no Pokémon has ever been able to evolve more than
            # twice.  If this changes, then either this query will need a
            # greatgrandparent, or (likely) the table structure will change
            parent_pokemon = aliased(tables.Pokemon)
            grandparent_pokemon = aliased(tables.Pokemon)

            # Make it an outer join; could be a search for e.g. 'baby', which
            # definitely doesn't want inner
            query = query.outerjoin((
                parent_pokemon,
                me.evolution_parent_pokemon_id == parent_pokemon.id
            )) \
            .outerjoin((
                grandparent_pokemon,
                parent_pokemon.evolution_parent_pokemon_id == grandparent_pokemon.id
            ))

        # ...whereas position and special tend to need children
        if c.form.evolution_position.data or c.form.evolution_special.data:
            child_pokemon = aliased(tables.Pokemon)
            child_subquery = pokedex_session.query(
                child_pokemon.evolution_parent_pokemon_id.label('parent_id'),
                func.count('*').label('child_count'),
            ) \
                .group_by(child_pokemon.evolution_parent_pokemon_id) \
                .subquery()

            query = query.outerjoin((
                child_subquery,
                me.id == child_subquery.c.parent_id
            ))

        if c.form.evolution_stage.data:
            # Collect clauses for the requested stages and add to the query
            clauses = []
            if u'baby' in c.form.evolution_stage.data:
                # Baby form: is_baby.  Cool, easy.
                clauses.append( me.is_baby == True )

            if u'basic' in c.form.evolution_stage.data:
                # Basic: this is not a baby.  Either there's no parent, or
                # parent is a baby
                clauses.append(
                    and_(
                        me.is_baby == False,
                        or_(
                            parent_pokemon.id == None,
                            parent_pokemon.is_baby == True,
                        )
                    )
                )

            if u'stage1' in c.form.evolution_stage.data:
                # Stage 1: parent exists and is not a baby.  Grandparent either
                # doesn't exist or is a baby
                clauses.append(
                    and_(
                        parent_pokemon.id != None,
                        parent_pokemon.is_baby == False,
                        or_(
                            grandparent_pokemon.id == None,
                            grandparent_pokemon.is_baby == True,
                        ),
                    )
                )

            if u'stage2' in c.form.evolution_stage.data:
                # Stage 2: grandparent exists and is not a baby
                clauses.append(
                    and_(
                        grandparent_pokemon.id != None,
                        grandparent_pokemon.is_baby == False,
                    )
                )

            query = query.filter(or_(*clauses))

        if c.form.evolution_position.data:
            # Same story
            clauses = []

            if u'first' in c.form.evolution_position.data:
                # No parent
                clauses.append( parent_pokemon.id == None )

            if u'middle' in c.form.evolution_position.data:
                # Has a parent AND a child
                clauses.append(
                    and_(
                        parent_pokemon.id != None,
                        child_subquery.c.child_count != None,
                    )
                )

            if u'last' in c.form.evolution_position.data:
                # No children
                clauses.append( child_subquery.c.child_count == None )

            if u'only' in c.form.evolution_position.data:
                # No parent; children
                clauses.append( 
                    and_(
                        parent_pokemon.id == None,
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
                sibling_pokemon = aliased(tables.Pokemon)
                sibling_subquery = pokedex_session.query(
                    sibling_pokemon.evolution_parent_pokemon_id.label('parent_id'),
                    func.count('*').label('sibling_count'),
                ) \
                    .group_by(sibling_pokemon.evolution_parent_pokemon_id) \
                    .subquery()

                query = query.outerjoin((
                    sibling_subquery,
                    me.evolution_parent_pokemon_id
                        == sibling_subquery.c.parent_id
                ))

                clauses.append( sibling_subquery.c.sibling_count > 1 )

            query = query.filter(or_(*clauses))

        # Color
        if c.form.color.data:
            query = query.filter( me.color_id == c.form.color.data.id )

        # Habitat
        if c.form.habitat.data:
            query = query.filter( me.habitat_id == c.form.habitat.data.id )


        ### Run the query!
        c.results = query.all()

        return render('/pokedex/search/pokemon.mako')
