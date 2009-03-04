# encoding: utf8
"""Small library of bits and pieces useful to the Web interface that don't
really belong in the pokedex core.
"""

from __future__ import absolute_import

import pokedex.db
import pokedex.db.tables as tables

# DB session for everyone to use
session = pokedex.db.connect('mysql://perl@localhost/pydex')

# Qick access to generations and versions
def generation(id):
    return session.query(tables.Generation).get(id)
def version(name):
    return session.query(tables.Version).filter_by(name=name).one()

# Type efficacy, from percents to Unicode fractions
type_efficacy_label = {
    0: '0',
    25: '¼',
    50: '½',
    100: '1',
    200: '2',
    400: '4',
}

# Gender rates, translated from -1..8 to useful text
gender_rate_label = {
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
