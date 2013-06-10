# encoding: utf8
"""Small wrapper for access to the pokedex library's database."""
from __future__ import absolute_import

import os.path
import re

import pokedex.db
from pokedex.db import tables
import spline.lib.base
from sqlalchemy.sql import func
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import lazyload
from pylons import tmpl_context as c


pokedex_session = None
pokedex_lookup = None

def connect(config):
    """Instantiates the `pokedex_session` and `pokedex_lookup` objects."""
    # DB session for everyone to use.
    global pokedex_session
    prefix = 'spline-pokedex.sqlalchemy.'
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
def get_by_identifier_query(table, identifier):
    """Returns a query to find a single row in the given table by identifier.

    Don't use this for Pokémon!  Use `pokemon_identifier_query()`,
    as it knows about forms.
    """

    identifier = identifier.lower()
    identifier = re.sub(u'[ _]+', u'-', identifier)
    identifier = re.sub(u'[\'.]', u'', identifier)

    query = pokedex_session.query(table).filter(
                table.identifier == identifier)

    return query

def pokemon_form_identifier_query(identifier, form_identifier=None):
    """Returns a query that will look for the Pokémon with the given identifier.
    """

    q = get_by_identifier_query(tables.PokemonForm, form_identifier)
    q = q.join(tables.PokemonForm.species)
    q = q.filter(tables.Pokemon.forms.any())

    if form:
        # If a form has been specified, it must match
        q = q.join(tables.Pokemon.unique_form) \
            .filter(tables.PokemonForm.identifier == form)
    else:
        # If there's NOT a form, just make sure we get a form base Pokémon
        # TODO wtf is this any() for?
        q = q.filter(tables.Pokemon.forms.any())

    return q

def get_by_name_query(table, name, query=None):
    """Returns a query to find a single row in the given table by name,
    ignoring case.

    Don't use this for Pokémon!  Use `pokemon_query()`, as it knows about
    forms.

    If query is given, it will be extended joined with table.name_table,
    otherwise table will be queried.
    """

    name = name.lower()

    if query is None:
        query = pokedex_session.query(table)

    query = query.join(table.names_local) \
        .filter(func.lower(table.names_table.name) == name)

    return query

def pokemon_query(name, form=None):
    """Returns a query that will look for the named Pokémon.

    form, if given, is a form identifier.
    """

    query = pokedex_session.query(tables.Pokemon)
    query = query.join(tables.Pokemon.species)
    query = query.join(tables.PokemonSpecies.names_local)
    query = query.filter(func.lower(tables.PokemonSpecies.names_table.name) == name.lower())

    if form:
        # If a form has been specified, it must match
        query = query.join(tables.Pokemon.forms) \
            .filter(tables.PokemonForm.form_identifier == form)
    else:
        # If there's NOT a form, just make sure we get a default Pokémon
        query = query.filter(tables.Pokemon.is_default == True)

    return query

def pokemon_form_query(name, form=None):
    """Returns a query that will look for the specified Pokémon form, or the
    default form of the named Pokémon.
    """

    q = pokedex_session.query(tables.PokemonForm)
    q = q.join(tables.PokemonForm.pokemon)
    q = q.join(tables.Pokemon.species)
    q = q.join(tables.PokemonSpecies.names_local) \
        .filter(func.lower(tables.PokemonSpecies.names_table.name) == name.lower())

    if form:
        # If a form has been specified, it must match
        q = q.filter(tables.PokemonForm.form_identifier == form)
    else:
        # If there's NOT a form, just get the default form
        q = q.filter(tables.Pokemon.is_default == True)
        q = q.filter(tables.PokemonForm.is_default == True)

    return q

def generation(id):
    return pokedex_session.query(tables.Generation).get(id)
def version(name):
    return pokedex_session.query(tables.Version).filter_by(name=name).one()
