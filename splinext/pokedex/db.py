# encoding: utf8
"""Small wrapper for access to the pokedex library's database."""
from __future__ import absolute_import

import os.path
import re

import pokedex.db
from pokedex.db import tables
from sqlalchemy.sql import func
from sqlalchemy import and_, or_, not_
from pylons import tmpl_context as c

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
def get_by_identifier_query(table, identifier, query=None):
    """Returns a query to find a single row in the given table by identifier.

    Don't use this for Pokémon!  Use `pokemon_query(use_identifier=True)`,
    as it knows about forms.
    """

    identifier = identifier.lower()
    identifier = re.sub(u'[ _]+', u'-', identifier)
    identifier = re.sub(u'[\'.]', u'', identifier)

    query = pokedex_session.query(table).filter(
                table.identifier == identifier)

    return query

def get_by_name_query(table, name, language=None, query=None):
    """Returns a query to find a single row in the given table by name,
    ignoring case.

    Don't use this for Pokémon!  Use `pokemon_query()`, as it knows about
    forms.

    If query is given, it will be extended joined with table.name_table,
    otherwise table will be queried.
    """

    if language is None:
        language = c.game_language

    name = name.lower()

    if query is None:
        query = pokedex_session.query(table)

    query = query.outerjoin(
            (table.name_table, and_(
                    table.name_table.object_id == table.id,
                    table.name_table.language == language,
                ))
        ).filter(or_(
                func.lower(table.name_table.name) == name,
                and_(table.name_table.name == None, table.identifier == name),
            )).order_by(table.name_table.name != None)

    return query

def pokemon_query(name, form=None, language=None, use_identifier=False):
    """Returns a query that will look for the named Pokémon."""

    if use_identifier:
        q = get_by_identifier_query(tables.Pokemon, name)
    else:
        if language is None:
            language = c.game_language

        q = get_by_name_query(tables.Pokemon, name, language=language)

    if form:
        # If a form has been specified, it must match
        q = q.join('unique_form')
        if use_identifier:
            q = q.filter(func.lower(tables.PokemonForm.identifier) == form.lower())
        else:
            q = get_by_name_query(tables.PokemonForm, form, language=language, query=q)
    else:
        # If there's NOT a form, just make sure we get a form base Pokémon
        q = q.filter(tables.Pokemon.forms.any())

    return q

def pokemon_form_query(name, form=None, language=None):
    """Returns a query that will look for the specified Pokémon form, or the
    default form of the named Pokémon.
    """

    if language is None:
        language = c.game_language

    q = get_by_name_query(
            tables.Pokemon,
            name,
            language=language,
            query=pokedex_session.query(tables.PokemonForm).join('form_base_pokemon')
        )

    if form:
        # If a form has been specified, it must match
        q = get_by_name_query(tables.PokemonForm, form, language=language, query=q)
    else:
        # If there's NOT a form, just get the default form
        q = q.filter(tables.PokemonForm.is_default == True)

    return q

def generation(id):
    return pokedex_session.query(tables.Generation).get(id)
def version(name):
    return pokedex_session.query(tables.Version).filter_by(name=name).one()

def alphabetize(query, name_table, sort_column=None, language=None, reverse=False):
    if language is None:
        language = c.game_language
    if sort_column is None:
        sort_column = 'name'
    if isinstance(sort_column, basestring):
        sort_column = getattr(name_table, sort_column)
    query = query.outerjoin((name_table, and_(
            name_table.object_id == name_table.object_table.id,
            name_table.language == language,
        )))
    identifier_column = getattr(name_table.object_table, 'identifier', None)
    if identifier_column:
        if reverse:
            query = query.order_by(identifier_column.desc())
        else:
            query = query.order_by(identifier_column.asc())
    if reverse:
        return query.order_by(sort_column.desc())
    else:
        return query.order_by(sort_column.asc())

def alphabetize_table(table, sort_column=None, language=None, reverse=False):
    return alphabetize(
            pokedex_session.query(table),
            table.name_table,
            sort_column=sort_column,
            language=language,
            reverse=reverse,
        )
