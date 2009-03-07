# encoding: utf8
"""Small library of bits and pieces useful to the Web interface that don't
really belong in the pokedex core.
"""

from __future__ import absolute_import

import math
import re

import pokedex.db
import pokedex.db.tables as tables

# DB session for everyone to use
session = pokedex.db.connect('mysql://perl@localhost/pydex')

def filename_from_name(name):
    """Shorten the name of a whatever to something suitable as a filename.

    e.g. Water's Edge -> waters-edge
    """
    name = name.lower()
    name = re.sub('[ _]+', '-', name)
    name = re.sub('[^-a-z0-9]', '', name)
    return name

# Quick access to generations and versions
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

def scale_sizes(size_dict, dimensions=1):
    """Normalizes a list of sizes so the largest is 1.0.

    Use `dimensions` if the sizes are non-linear, i.e. 2 for scaling area.
    """

    # x -> (x/max)^(1/dimensions)
    max_size = float(max(size_dict.values()))
    scaled_sizes = dict()
    for k, v in size_dict.items():
        scaled_sizes[k] = math.pow(v / max_size, 1.0 / dimensions)
    return scaled_sizes
