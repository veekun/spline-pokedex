# encoding: utf8
"""Small library of bits and pieces useful to the Web interface that don't
really belong in the pokedex core.
"""

from __future__ import absolute_import

import pokedex.db
import pokedex.db.tables as tables

# DB session for everyone to use
session = pokedex.db.connect('mysql://perl@localhost/pydex')

# List of generations, so we can go generation[1]
generations = {}
for generation in session.query(tables.Generation).all():
    generations[generation.id] = generation

# Gender rates, translated from -1..8 to useful text
gender_rates = {
    -1: u'genderless',
    0: u'always male',
    1: u'⅞ male, ⅛ female',
    2: u'¾ male, ¼ female',
    3: u'⅝ male, ⅜ female',
    4: u'½ male, ½ female',
    5: u'⅜ male, ⅝ female',
    6: u'¼ male, ¾ female',
    7: u'⅛ male, ⅞ female',
    8: u'always female',
}
