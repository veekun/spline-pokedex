from __future__ import absolute_import

import logging

import pokedex.db
from pokedex.db.tables import Pokemon
import pkg_resources
from pylons import config, request, response, session, tmpl_context as c
from pylons.controllers.util import abort, redirect_to
from routes import url_for, request_config
from sqlalchemy.orm.exc import NoResultFound

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render

log = logging.getLogger(__name__)

class PokedexController(BaseController):

    def index(self):
        return ''

    def images(self, image_path):
        response.headers['content-type'] = 'image/png'
        return pkg_resources.resource_string('pokedex', "data/images/%s" % image_path)

    def _not_found(self):
        # XXX make this do fuzzy search or whatever
        abort(404)

    def pokemon(self, name=None):
        session = pokedex.db.connect('mysql://perl@localhost/pydex')
        try:
            c.pokemon = session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon.mako')

    def pokemon_flavor(self, name=None):
        session = pokedex.db.connect('mysql://perl@localhost/pydex')
        try:
            c.pokemon = session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon_flavor.mako')
