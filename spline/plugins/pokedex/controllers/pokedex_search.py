# encoding: utf8
from __future__ import absolute_import, division

import logging

from wtforms import Form, ValidationError, fields, widgets
from wtforms.ext.sqlalchemy.fields import QuerySelectField

import pokedex.db
import pokedex.db.tables as tables
from pokedex.db.tables import Ability, EggGroup, Generation, Item, Language, Machine, Move, MoveFlagType, Pokemon, PokemonEggGroup, PokemonFormSprite, PokemonMove, PokemonStat, Type, VersionGroup, PokemonType
import pokedex.lookup
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect_to
from pylons.decorators import jsonify
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased, join
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render
from spline.lib import helpers

from spline.plugins.pokedex import db, helpers as pokedex_helpers
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

    def cleanse_data(self, data):
        """Returns a copy of the given form data, with any default values
        removed.
        """
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
            redirect_to(url.current(**cleansed_data))

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

        # Ability
        if c.form.ability.data:
            query = query.filter( tables.Pokemon.abilities.any(
                                    tables.Ability.id == c.form.ability.data.id
                                  )
                                )

        c.results = query.all()

        return render('/pokedex/search/pokemon.mako')
