from __future__ import absolute_import

import collections
import logging

import pokedex.db
from pokedex.db.tables import Generation, Pokemon, Type
import pkg_resources
from pylons import config, request, response, session, tmpl_context as c
from pylons.controllers.util import abort, redirect_to
from routes import url_for, request_config
from sqlalchemy.orm.exc import NoResultFound

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render
from spline.plugins.pokedex import lib as dexlib

log = logging.getLogger(__name__)

class PokedexController(BaseController):

    def __before__(self):
        c.dexlib = dexlib

    def index(self):
        return ''

    def images(self, image_path):
        response.headers['content-type'] = 'image/png'
        pkg_path = "data/images/%s" % image_path
        return pkg_resources.resource_string('pokedex', pkg_path)

    def _not_found(self):
        # XXX make this do fuzzy search or whatever
        abort(404)

    def pokemon(self, name=None):
        try:
            c.pokemon = dexlib.session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()

        # Type efficacy
        c.type_efficacies = collections.defaultdict(lambda: 100)
        for target_type in c.pokemon.types:
            for type_efficacy in target_type.target_efficacies:
                c.type_efficacies[type_efficacy.damage_type] *= \
                    type_efficacy.damage_factor

                # The defaultdict starts at 100, and every damage factor is
                # a percentage.  Dividing by 100 with every iteration turns the
                # damage factor into a decimal percentage taken of the starting
                # 100, without using floats and regardless of number of types
                c.type_efficacies[type_efficacy.damage_type] /= 100

        return render('/pokedex/pokemon.mako')

    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = dexlib.session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon_flavor.mako')
