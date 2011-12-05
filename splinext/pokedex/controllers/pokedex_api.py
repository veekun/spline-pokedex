# encoding: utf8
from __future__ import absolute_import, division

import json
import logging

import pokedex.db
import pokedex.db.tables as tables
import pokedex.formulae
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect

from spline.lib import helpers as h
from spline.lib.base import BaseController, render

from splinext.pokedex import helpers as pokedex_helpers
import splinext.pokedex.db as db

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
        import splinext.pokedex.api as api
        from collections import defaultdict

        api_query = api.APIQuery(api.pokemon_locus, db.pokedex_session)
        results = api_query.process_query(request.GET)
        response.headers['Content-Type'] = 'application/json; charset=UTF-8'
        return json.dumps(results)
