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

class TextField(fields.TextField):
    """Represents a regular ol' text field, with the slight change that the
    default value is empty string rather than None.  This actually matches what
    the client will send by default, and allows for deciding whether something
    was actually typed by comparing the client value to the default.
    """
    def __init__(self, *args, **kwargs):
        if 'default' not in kwargs:
            kwargs['default'] = u''
        super(TextField, self).__init__(*args, **kwargs)

class PokemonSearchForm(Form):
    name = TextField('Name')


class PokedexSearchController(BaseController):

    def pokemon_search(self):
        c.form = PokemonSearchForm(request.params)
        if not c.form.validate():
            # Either blank, or errortastic.  Skip the logic and just send the
            # form back
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
