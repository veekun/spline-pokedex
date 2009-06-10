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
    25: u'¼',
    50: u'½',
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

def romaji(kana):
    """Converts a string of kana to romaji."""

    vowels = ['a', 'e', 'i', 'o', 'u', 'y']

    characters = []
    last_kana = None  # Used for ー; っ or ッ; ん or ン
    for char in kana:
        if ord(char) >= 0xff11 and ord(char) <= 0xff5e:
            # Full-width Latin
            if last_kana == 'sokuon':
                raise ValueError("Sokuon cannot precede Latin characters.")

            char = chr(ord(char) - 0xff11 + 0x31)
            characters.append(char)

            last_kana = None

        elif char in (u'っ', u'ッ'):
            # Sokuon
            last_kana = 'sokuon'

        elif char == u'ー':
            # Extended vowel or n
            if last_kana[-1] not in vowels:
                raise ValueError(u"'ー' must follow by a vowel.")
            characters.append(last_kana[-1])

            last_kana = None

        elif char in _romaji_kana:
            # Regular ol' kana
            kana = _romaji_kana[char]

            if last_kana == 'sokuon':
                if kana[0] in vowels:
                    raise ValueError("Sokuon cannot precede a vowel.")

                characters.append(kana[0])
            elif last_kana == 'n' and kana[0] in vowels:
                characters.append("'")

            characters.append(kana)

            last_kana = kana

        else:
            # Not Japanese
            if last_kana == 'sokuon':
                raise ValueError("Sokuon must be followed by another kana.")

            characters.append(char)

            last_kana = None

    if last_kana == 'sokuon':
        raise ValueError("Sokuon cannot be the last character.")

    return ''.join(characters)

# Data used by romaji function above
_romaji_kana = {
    u'ア': 'a',     u'イ': 'i',     u'ウ': 'u',     u'エ': 'e',     u'オ': 'o',
    u'カ': 'ka',    u'キ': 'ki',    u'ク': 'ku',    u'ケ': 'ke',    u'コ': 'ko',
    u'サ': 'sa',    u'シ': 'shi',   u'ス': 'su',    u'セ': 'se',    u'ソ': 'so',
    u'タ': 'ta',    u'チ': 'chi',   u'ツ': 'tsu',   u'テ': 'te',    u'ト': 'to',
    u'ナ': 'na',    u'ニ': 'ni',    u'ヌ': 'nu',    u'ネ': 'ne',    u'ノ': 'no',
    u'ハ': 'ha',    u'ヒ': 'hi',    u'フ': 'fu',    u'ヘ': 'he',    u'ホ': 'ho',
    u'マ': 'ma',    u'ミ': 'mi',    u'ム': 'mu',    u'メ': 'me',    u'モ': 'mo',
    u'ヤ': 'ya',                    u'ユ': 'yu',                    u'ヨ': 'yo',
    u'ラ': 'ra',    u'リ': 'ri',    u'ル': 'ru',    u'レ': 're',    u'ロ': 'ro',
    u'ワ': 'wa',    u'ヰ': 'wi',                    u'ヱ': 'we',    u'ヲ': 'wo',
                                                                    u'ン': 'n',
    u'ガ': 'ga',    u'ギ': 'gi',    u'グ': 'gu',    u'ゲ': 'ge',    u'ゴ': 'go',
    u'ザ': 'za',    u'ジ': 'ji',    u'ズ': 'zu',    u'ゼ': 'ze',    u'ゾ': 'zo',
    u'ダ': 'da',    u'ヂ': 'ji',    u'ヅ': 'dzu',   u'デ': 'de',    u'ド': 'do',
    u'バ': 'ba',    u'ビ': 'bi',    u'ブ': 'bu',    u'ベ': 'be',    u'ボ': 'bo',
    u'パ': 'pa',    u'ピ': 'pi',    u'プ': 'pu',    u'ペ': 'pe',    u'ポ': 'po',
}
