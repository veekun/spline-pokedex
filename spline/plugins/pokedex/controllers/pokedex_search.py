# encoding: utf8
from __future__ import absolute_import, division

import logging

from wtforms import Form, ValidationError, fields, widgets
from wtforms.ext.sqlalchemy.fields import QuerySelectField

import pokedex.db.tables as tables
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect_to
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func, and_, or_

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

    name = fields.TextField('Name', default=u'')
    ability = QueryTextField('Ability',
        query_factory=
            lambda value: pokedex_session.query(tables.Ability)
                .filter( func.lower(tables.Ability.name) == value.lower() ),
        label_attr='name',
    )
    color = QuerySelectField('Color',
        query_factory=lambda: pokedex_session.query(tables.PokemonColor),
        label_attr='name',
        allow_blank=True,
        pk_attr='name',
    )
    habitat = QuerySelectField('Habitat',
        query_factory=lambda: pokedex_session.query(tables.PokemonHabitat),
        label_attr='name',
        allow_blank=True,
        pk_attr='name',
    )

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
        query = pokedex_session.query(tables.Pokemon)

        # Name
        if c.form.name.data:
            name_like = u"%{0}%".format(c.form.name.data.lower())
            query = query.filter( func.lower(tables.Pokemon.name).like(name_like) )

        # Color
        if c.form.color.data:
            query = query.filter( tables.Pokemon.color_id == c.form.color.data.id )

        # Habitat
        if c.form.habitat.data:
            query = query.filter( tables.Pokemon.habitat_id == c.form.habitat.data.id )

        # Ability
        if c.form.ability.data:
            query = query.filter( tables.Pokemon.abilities.any(
                                    tables.Ability.id == c.form.ability.data.id
                                  )
                                )

        # Gender distribution
        if c.form.gender_rate.data:
            gender_rate = int(c.form.gender_rate.data)
            gender_rate_op = c.form.gender_rate_operator.data

            # Genderless ignores the operator
            if gender_rate == -1 or gender_rate_op == 'equal':
                clause = tables.Pokemon.gender_rate == gender_rate
            elif gender_rate_op == 'less_equal':
                clause = tables.Pokemon.gender_rate <= gender_rate
            elif gender_rate_op == 'more_equal':
                clause = tables.Pokemon.gender_rate >= gender_rate

            if gender_rate != -1:
                # No amount of math should make "<= 1/4 female" include
                # genderless
                clause = and_(clause, tables.Pokemon.gender_rate != -1)

            query = query.filter(clause)

        # Egg groups
        if any(c.form.egg_group.data):
            clauses = []
            for egg_group in c.form.egg_group.data:
                if not egg_group:
                    continue
                subclause = tables.Pokemon.egg_groups.any(
                    tables.EggGroup.id == egg_group.id
                )
                clauses.append(subclause)

            if c.form.egg_group_operator.data == 'any':
                clause = or_(*clauses)
            elif c.form.egg_group_operator.data == 'all':
                clause = and_(*clauses)

            query = query.filter(clause)


        c.results = query.all()

        return render('/pokedex/search/pokemon.mako')
