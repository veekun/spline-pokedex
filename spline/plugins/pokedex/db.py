# encoding: utf8
"""Small wrapper for access to the pokedex library's database."""
from __future__ import absolute_import

import pokedex.db
from pokedex.db import tables
import pylons
from sqlalchemy.sql import func

# DB session for everyone to use
pokedex_session = pokedex.db.connect(pylons.config['pokedex_db_url'])

# Quick access to a few database objects
def pokemon(name, form=None):
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

    # If this raises because the data is bogus, it's the caller's fault
    return q.one()

def generation(id):
    return pokedex_session.query(tables.Generation).get(id)
def version(name):
    return pokedex_session.query(tables.Version).filter_by(name=name).one()
