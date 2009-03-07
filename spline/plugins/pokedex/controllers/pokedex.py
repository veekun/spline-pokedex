from __future__ import absolute_import

import collections
import logging
import mimetypes

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

    def media(self, path):
        (mimetype, whatever) = mimetypes.guess_type(path)
        response.headers['content-type'] = mimetype
        pkg_path = "data/media/%s" % path
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

        # Sizing
        # Note that these are totally hardcoded average sizes in Pokemon units:
        # Male: 17.5 dm, 860 hg
        # Female: 16 dm, 720 hg
        heights = dict(pokemon=c.pokemon.height, male=17.5, female=16)
        c.heights = c.dexlib.scale_sizes(heights)
        weights = dict(pokemon=c.pokemon.weight, male=860, female=720)
        # Strictly speaking, weight takes three dimensions.  But the real
        # measurement here is just "space taken up", and these are sprites, so
        # the space they actually take up is two-dimensional.
        c.weights = c.dexlib.scale_sizes(weights, dimensions=2)

        # Flavor text
        c.flavor_text = {}
        for pokemon_flavor_text in c.pokemon.flavor_text:
            c.flavor_text[pokemon_flavor_text.version.name] = pokemon_flavor_text.flavor_text

        return render('/pokedex/pokemon.mako')

    def pokemon_flavor(self, name=None):
        try:
            c.pokemon = dexlib.session.query(Pokemon).filter_by(name=name).one()
        except NoResultFound:
            return self._not_found()
        return render('/pokedex/pokemon_flavor.mako')
