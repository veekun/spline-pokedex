# encoding: utf8
from __future__ import absolute_import, division

import json
import logging

import pokedex.db
import pokedex.db.tables as tables
import pokedex.formulae
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from spline.lib.base import BaseController, render
import spline.lib.helpers as h

import splinext.pokedex.db as db
import splinext.pokedex.helpers as pokedex_helpers

log = logging.getLogger(__name__)


class PokedexAPIController(BaseController):
    u"""All of these actions return JSON representing some kinda Pokédex data.
    """

    def pokemon(self):
        u"""Returns an array of all Pokémon."""
        # XXX should this handle formes oh no
        # TODO document these!
        # TODO cache me!
        pokemon = []
        for row in db.pokedex_session.query(tables.Pokemon):
            pokemon.append(dict(
                id=row.id,
                name=row.name,
            ))

        response.headers['Content-Type'] = 'application/json; charset=UTF-8'
        return json.dumps(pokemon)
