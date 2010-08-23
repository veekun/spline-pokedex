# encoding: utf8
from __future__ import absolute_import, division

import logging

import pokedex.db
import pokedex.db.tables as tables
from pokedex.struct import SaveFilePokemon
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from sqlalchemy.orm.exc import NoResultFound

from spline.model import meta
from spline.lib.base import BaseController, render
from spline.lib import helpers as h
from splinext.gts import model as gts_model
import splinext.pokedex.db as db

log = logging.getLogger(__name__)

class GTSBrowseController(BaseController):

    def list(self):
        u"""Show a list of all Pokémon currently uploaded to the GTS."""

        gts_pokemons = meta.Session.query(gts_model.GTSPokemon).all()

        c.savefiles = []
        for gts_pokemon in gts_pokemons:
            savefile = SaveFilePokemon(gts_pokemon.pokemon_blob)
            savefile.use_database_session(db.pokedex_session)
            c.savefiles.append(savefile)

        return render('/gts/list.mako')
