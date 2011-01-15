# encoding: utf8
"""Small wrapper for access to the pokedex library's database."""
from __future__ import absolute_import

import os.path
import re

import pokedex.db
from pokedex.db import tables
from sqlalchemy.sql import func

from spline.lib.base import SQLATimerProxy


pokedex_session = None
pokedex_lookup = None

def connect(config):
    """Instantiates the `pokedex_session` and `pokedex_lookup` objects."""
    # DB session for everyone to use.
    # This uses the same timer proxy as the main engine, so Pokédex queries are
    # counted towards the db time in the footer
    global pokedex_session
    prefix = 'spline-pokedex.sqlalchemy.'
    config[prefix + 'proxy'] = config['spline._sqlalchemy_proxy']
    pokedex_session = pokedex.db.connect(
        engine_args=config, engine_prefix=prefix,
    )

    # Lookup object
    global pokedex_lookup
    pokedex_lookup = pokedex.lookup.PokedexLookup(
        # Keep our own whoosh index in the /data dir
        directory=os.path.join(config['pylons.cache_dir'],
                              'pokedex-index'),
        session=pokedex_session,
    )
    if not pokedex_lookup.index:
        pokedex_lookup.rebuild_index()


# Quick access to a few database objects
def get_by_name_query(table, name):
    """Returns a query to find a single row in the given table by name,
    ignoring case.

    Don't use this for Pokémon!  Use `pokemon_query()`, as it knows about
    forms.
    """
    # XXX: Use the name, not identifier

    name = name.lower()
    name = re.sub(u'[ _]+', u'-', name)
    name = re.sub(u'[\'.]', u'', name)

    q = pokedex_session.query(table).filter(func.lower(table.identifier)
                                            == name)

    return q

def pokemon_query(name, form=None):
    """Returns a query that will look for the named Pokémon."""

    # Force case-insensitive matching the heavy-handed way
    # XXX: Use the name, not identifier
    q = pokedex_session.query(tables.Pokemon) \
                       .filter(func.lower(tables.Pokemon.identifier) == name.lower())

    if form:
        # If a form has been specified, it must match
        q = q.join('unique_form')
        q = q.filter(func.lower(tables.PokemonForm.name) == form.lower())
    else:
        # If there's NOT a form, just make sure we get a form base Pokémon
        q = q.filter(tables.Pokemon.forms.any())

    return q

def pokemon_form_query(name, form=None):
    """Returns a query that will look for the specified Pokémon form, or the
    default form of the named Pokémon.
    """

    q = pokedex_session.query(tables.PokemonForm) \
                       .join('form_base_pokemon') \
                       .filter(func.lower(tables.Pokemon.name) == name.lower())

    if form:
        # If a form has been specified, it must match
        q = q.filter(func.lower(tables.PokemonForm.name) == form.lower())
    else:
        # If there's NOT a form, just get the default form
        q = q.filter(tables.PokemonForm.is_default == True)

    return q

def generation(id):
    return pokedex_session.query(tables.Generation).get(id)
def version(name):
    return pokedex_session.query(tables.Version).filter_by(name=name).one()
