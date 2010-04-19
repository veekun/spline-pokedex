# encoding: utf8
u"""Handles parsing and converting between height and weight.  Used by the
trainer size comparison on Pokémon pages and the Pokémon search.
"""

import re

from spline.plugins.pokedex import db

si_prefixes = {
    'yotta': 1e24,      'yocto': 1e-24,
    'zetta': 1e21,      'zepto': 1e-21,
    'exa'  : 1e18,      'atto' : 1e-18,
    'peta' : 1e15,      'femto': 1e-15,
    'tera' : 1e12,      'pico' : 1e-12,
    'giga' : 1e9,       'nano' : 1e-9,
    'mega' : 1e6,       'micro': 1e-6,
    'kilo' : 1000,      'milli': 0.001,
    'hecta': 100,       'centi': 0.01,
    'deca' : 10,        'deci' : 0.1,
}
si_abbrs = {
    'Y' : 'yotta',      'y' : 'yocto',
    'Z' : 'zetta',      'z' : 'zepto',
    'E' : 'exa',        'a' : 'atto',
    'P' : 'peta',       'f' : 'femto',
    'T' : 'tera',       'p' : 'pico',
    'G' : 'giga',       'n' : 'nano',
    'M' : 'mega',       'µ' : 'micro',
    'k' : 'kilo',       'm' : 'milli',
    'h' : 'hecta',      'c' : 'centi',
    'da': 'deca',       'd' : 'deci',
}

# 1 of each unit is X meters
height_units = {
    'meter':            1,
    'metre':            1,

    u'ångström':        1e-10,
    'angstrom':         1e-10,
    'thou':             0.0000254,
    'inch':             0.0254,
    'hand':             0.1016,
    'foot':             0.3048,
    'yard':             0.9144,
    'furlong':          201.168,
    'mile':             1609.344,
    'league':           4828.032,
    'link':             0.201168,
    'rod':              5.0292,
    'pole':             5.0292,
    'chain':            20.1168,

    # nautical
    'fathom':           1.853184,
    'cable':            185.3184,
    'nauticalmile':     1853.184,

    # astronomy and physics
    'astronomicalunit': 1.496e11,
    'lightyear':        9460730472580800,
    'lightsecond':      299792458,
    'lightminute':      17987547480,
    'lighthour':        1079252848800,
    'lightday':         2.59020684e13,
    'lightweek':        1.81314479e14,
    'lightfortnight':   3.62628958e14,
    'parsec':           3.0857e16,
    'plancklength':     1.61625281e-35,
    'lightplanck':      1.61625281e-35,

    # ancient
    'cubit':            0.45,
    'royalcubit':       0.525,
}
height_abbrs = {
    'Å'  : u'ångström',
    'm'  : 'meter',
    'in' : 'inch',
    'h'  : 'hand',
    'ft' : 'foot',
    'yd' : 'yard',
    'mi' : 'mile',
    'li' : 'link',
    'rd' : 'rod',
    'ch' : 'chain',
    'fur': 'furlong',
    'lea': 'league',
    'ftm': 'fathom',
    'cb' : 'cable',
    'NM' : 'nauticalmile',
    'au' : 'astronomicalunit',
    'ly' : 'lightyear',
    'pc' : 'parsec',
}


# 1 of these is X kilograms
weight_units = {
    'grain':            0.00006479891,
    'dram':             0.001771845,
    'ounce':            0.02834952,
    'pound':            0.45359237,
    'stone':            6.35029318,
    'quarter':          12.70058636,
    'hundredweight':    45.359237,
    'shortton':         907.18474,
    'ton':              907.18474,
    'longton':          1016.0469088,
    'metricton':        1000,
    'troyounce':        0.03110348,
    'troypound':        0.3732417,
    'pennyweight':      0.001555174,
    'gram':             0.001,
    'bushel':           27.216,  # i.e., of wheat

    'planckmass':       2.1764411e-8,
}
weight_abbrs = {
    'gr':   'grain',
    'dr':   'dram',
    'oz':   'ounce',
    'lb':   'pound',
    'st':   'stone',
    'qtr':  'quarter',
    'cwt':  'hundredweight',
    'ozt':  'troyounce',
    'lbt':  'troypound',
    'dwt':  'pennyweight',
    'g':    'gram',
}


def parse_size(size, height_or_weight):
    u"""Parses a string that looks remotely like a height or weight.

    Pokémon names may be used in lieu of unit strings.  SI prefixes are allowed
    on any unit.  Yes.  Any.

    `size` is the string to parse.  `height_or_weight` should be either
    'height' or 'weight'.

    Returns a number of meters or kilograms.
    XXX use Pokémon units  :T

    This function assumes the input is valid.  If it dies for any reason, the
    input is bogus.
    """

    # XXX commas should be handled better, in these two cases:
    # - 1,000,000 miles
    # - 5 feet, 6 inches

    if height_or_weight == 'height':
        units = height_units
        abbrs = height_abbrs
        pokemon_unit = 0.1
    elif height_or_weight == 'weight':
        units = weight_units
        abbrs = weight_abbrs
        pokemon_unit = 0.1

    # A size looks like:
    # [NUMBER] [SI PREFIX] [UNIT]
    # ...where the number is optional, the SI prefix is optional, the unit
    # might be a Pokémon, and there may or may not be spaces anywhere in here.
    # And there can be multiple parts, e.g. 5'10" or 6m12cm.
    # In the case of ambiguity, no SI prefix wins.

    # First thing to do is figure out where parts end.  A part must either
    # start with a number or be separated by a space from the previous part.
    # But "kilo meter" could then either be read as one kilometer, or one kilo
    # plus one meter.  The most flexible way to resolve this ambiguity is to
    # try the longest string first, then start breaking off pieces until
    # something valid is found.

    # So!  First, break into what absolutely must be parts: a non-number
    # followed by a number must be a new part.
    # This monstrosity breaks on things that look like numbers, BUT assumes
    # that dots not preceded by a space go on the end of the unit, not the
    # beginning of the number
    rough_parts = re.split(
        ur'(?x) ( (?: (?: [0-9]+ | (?<=[\s.]) ) [,.] )? [0-9]+ )',
        size
    )

    # The first element will be either an empty string or a lone unit name...
    if rough_parts[0]:
        # Lone unit; insert an implied 1
        rough_parts.insert(0, u'1')
    else:
        # Nothing; the string began with a number, so this is junk
        rough_parts.pop(0)

    # 1'3 and 1m20 are common abbreviations
    if rough_parts[-1] == '':
        if rough_parts[-3] == 'lb':
            rough_parts[-1] = 'ounce'
        if rough_parts[-3] == 'm':
            rough_parts[-1] = 'centimeter'
        elif rough_parts[-3] == '\'':
            rough_parts[-1] = 'inch'

    # Okay, now clean this up a bit.  Break into tuples of (num, unit, unit,
    # ...), remove whitespace everywhere, and turn the numbers into actual
    # numbers
    parts = []
    while rough_parts:
        number = rough_parts.pop(0)
        unit = rough_parts.pop(0)

        number = number.replace(',', '.')  # euro decimal point
        number = float(number)  # XXX support 0xff, why not

        # Divide '   mega  metre  ' into ('mega', 'metre')
        unit_chunks = unit.split()

        parts.append((number, unit_chunks))



    # Alright!  Got a list of individual units.  Awesome.
    # Now go through them and try to turn them into something intelligible.
    # Use a while loop, because the list might be modified in-flight
    result = 0.0
    while parts:
        done = False
        number, unit_chunks = parts.pop(0)

        if len(unit_chunks) == 0:
            # What?
            raise ValueError

        # There are several possibilities here:
        # - SI prefix might be part of the first chunk, the entire first chunk,
        #   or absent
        # - Unit name could be one or more chunks
        # - Entire first chunk could be an abbreviation
        # Run through each of these.  Remember, no-prefix and no-abbr win.

        possible_units = []  # (prefix, chunks) tuples

        # No prefix
        possible_units.append(( None, unit_chunks ))

        # Prefix in first chunk
        possible_prefix = unit_chunks[0].lower()
        if possible_prefix in si_prefixes:
            possible_units.append(( possible_prefix, unit_chunks[1:] ))

        # Prefix as part of first chunk
        for prefix_length in (3, 4, 5):
            possible_prefix = unit_chunks[0][0:prefix_length]
            possible_prefix = possible_prefix.lower()

            if possible_prefix in si_prefixes:
                chunks_sans_prefix = [ unit_chunks[0][prefix_length:] ] \
                                   + unit_chunks[1:]
                possible_units.append(( possible_prefix, chunks_sans_prefix ))

        # Abbreviations don't get spaces; "k m" is meaningless.
        # Also, abbreviations are the only place where case matters, and only
        # for the prefix
        if len(unit_chunks) == 1:
            unit = unit_chunks[0]
            if unit[-1] == '.':
                unit = unit[0:-1]

            for prefix_length in (0, 1, 2):
                prefix, abbr = unit[0:prefix_length], unit[prefix_length:]
                abbr = abbr.lower()

                if (not prefix or prefix in si_abbrs) \
                    and abbr in abbrs:

                    possible_units.append((
                        si_abbrs[prefix] if prefix else None,
                        [ abbrs[abbr] ]
                    ))

        # Prefix in possible_units is now guaranteed to be valid or None, so
        # part of the problem is solved.  
        # See if the rest of the unit of any of these possibilities is good
        for prefix, base_unit_chunks in possible_units:
            base_unit = u''.join(base_unit_chunks)  # unit names have no spaces
            base_unit = base_unit.lower()

            # Some slightly special munging for a few units:
            if base_unit in ('feet', '\''):
                base_unit = 'foot'
            elif base_unit in ('inches', '"'):
                base_unit = 'inch'

            # Chump fix for plural names.  Some units end in 's', and should
            # take precedence
            if base_unit not in units and base_unit[-1] == 's':
                base_unit = base_unit[0:-1]
            
            if base_unit in units:
                # Successful match!  Convert and we are DONE
                result += number * units[base_unit] \
                        * si_prefixes.get(prefix, 1.0) / pokemon_unit
                done = True
                break

        if done:
            continue

        # Now try again, assuming each unit might be a Pokémon name.
        # This is actually sort of an optimization; in violation of my own
        # rule, it will try "meganium" as a mega-nium before a Pokémon.  But it
        # avoids hitting the db for very common prefixed units, and I'm not
        # aware of any Pokémon that cause problems here
        for prefix, pokemon_name_chunks in possible_units:
            pokemon_name = u' '.join(pokemon_name_chunks)
            
            # TODO should this allow forms?
            try:
                pokemon = db.pokemon_query(pokemon_name).one()

                # Success again!
                result += number * getattr(pokemon, height_or_weight) \
                        * si_prefixes.get(prefix, 1.0)
                done = True
                break
            
            except:
                # Failure; just try next one
                pass

        if done:
            continue

        # XXX fallback: assume 'inch meter' is two parts

    return result
