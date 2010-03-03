# encoding: utf8
from __future__ import absolute_import, division

import logging

from wtforms import Form, fields

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

class PokemonSearchForm(Form):
    # Defaults are set to match what the client will actually send if the field
    # is left blank
    shorten = fields.HiddenField(default=u'')

    name = fields.TextField('Name', default=u'')

    @property
    def cleansed_data(self):
        """Returns a dictionary of form data, with any blank values removed.
        That is, fields whose values are equal to their defaults are omitted.
        """
        data = dict()
        for name, field in self._fields:
            if field.data == field._default:
                continue

            data[name] = field.data

        return data


class PokedexSearchController(BaseController):

    def pokemon_search(self):
        c.form = PokemonSearchForm(request.params)
        validates = c.form.validate()
        data = c.form.cleansed_data

        # If this is the first time the form was submitted, redirect to a URL
        # with only non-default values
        if validates and data and data.get('shorten', None):
            del data['shorten']
            redirect_to(url.current(**data))

        if not validates or not data:
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

        c.results = query.all()

        return render('/pokedex/search/pokemon.mako')
