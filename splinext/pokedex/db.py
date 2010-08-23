# encoding: utf8
"""Small wrapper for access to the pokedex library's database."""
from __future__ import absolute_import

import os.path

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
    pokedex_session = pokedex.db.connect(
        config['spline-pokedex.database_url'],
        engine_args={'proxy': SQLATimerProxy()},
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
    """Finds a single row in the given table by name, ignoring case.

    Don't use this for Pokémon!  Use `pokemon()`, as it knows about forms.
    """
    q = pokedex_session.query(table).filter(func.lower(table.name)
                                            == name.lower())

    return q

def get_by_name(table, name):
    """Same as above, except actally performs the query, which is lame.

    Use the above if at all possible.
    """
    return get_by_name_query(table, name).one()

def pokemon_query(name, form=None):
    """Returns a query that will look for the named Pokémon."""

    # Force case-insensitive matching the heavy-handed way
    q = pokedex_session.query(tables.Pokemon) \
                       .filter(func.lower(tables.Pokemon.name) == name.lower())

    # Some Pokémon have a "default" form with no real name, like Deoxys.
    # Some Pokémon have names for all their forms, e.g., Grass Wormadam.
    # We have to accept wormadam/None and do the right thing.  So.
    if form:
        # If there's a form, it must match exactly
        q = q.filter_by(forme_name=form)
    else:
        # If there's NOT a form, just make sure we get a normal-form
        # Pokémon, whether or not it has a name
        q = q.filter_by(forme_base_pokemon_id=None)

    return q

def pokemon(name, form=None):
    # TODO: make this go away

    # If this raises because the data is bogus, it's the caller's fault
    return pokemon_query(name, form).one()

def generation(id):
    return pokedex_session.query(tables.Generation).get(id)
def version(name):
    return pokedex_session.query(tables.Version).filter_by(name=name).one()
