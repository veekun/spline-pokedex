# encoding: utf8
"""Useful form fields of my own devising."""

import re

from sqlalchemy.sql import and_, or_
from wtforms import ValidationError, fields

from spline.plugins.pokedex.db import pokedex_lookup

class PokedexLookupField(fields.TextField):
    u"""Provides a lookup box for naming something in the Pokédex."""

    def __init__(self, label=u'', validators=[],
                 valid_type='pokemon', **kwargs):
        """`valid_type` is the type prefix to pass to lookup."""
        super(fields.TextField, self).__init__(label, validators, **kwargs)

        self._original_value = u''
        self.valid_type = valid_type

    def __call__(self, *args, **kwargs):
        """Adds the appropriate classes to make lookup suggestions work."""
        extra_class = "js-dex-suggest js-dex-suggest-{0}" \
                      .format(self.valid_type)

        if 'class_' in kwargs:
            kwargs['class_'] += ' ' + extra_class
        else:
            kwargs['class_'] = extra_class

        return super(fields.TextField, self).__call__(*args, **kwargs)

    def process_formdata(self, valuelist):
        """Load the value from the incoming form."""
        if valuelist:
            self._original_value = valuelist[0]

            if not valuelist[0]:
                raise ValidationError('Gotta pick something')

            results = pokedex_lookup.lookup(
                valuelist[0],
                valid_types=[self.valid_type],
            )

            if not results:
                raise ValidationError('Nothing found')
            elif len(results) > 1:
                # XXX fix this to offer alternatives somehow
                raise ValidationError('Too vague')
            else:
                self.data = results[0].object

    def _value(self):
        """Converts Python value back to a form value."""
        if self.data is None:
            return self._original_value
        elif self.valid_type == 'pokemon':
            # Pokémon need form names
            return self.data.full_name
        else:
            return self.data.name


class RangeQueryEvaluator(object):
    """Turns a list of values and (min, max) tuples into a query filter
    statement.
    """
    def __init__(self, partitions):
        self.partitions = partitions

    def __call__(self, column):
        clauses = []
        for thing in self.partitions:
            if isinstance(thing, tuple):
                a, b = thing
                if a is None:
                    # -b
                    clauses.append(column <= b)
                elif b is None:
                    # a+
                    clauses.append(column >= a)
                else:
                    # a-b
                    clauses.append(column.between(a, b))
            else:
                # a
                clauses.append(column == thing)

        return or_(*clauses)

class RangeTextField(fields.TextField):
    """Parses a string of the form 'a, b, c-e'.

    `inflator` converts each chunk (a, b, c, and e) to a number.  If it dies,
    the range is taken to be invalid.
    """
    def __init__(self, label=u'', validators=[], inflator=None, **kwargs):
        super(fields.TextField, self).__init__(label, validators, **kwargs)

        if not inflator:
            raise ValueError('RangeTextField requires an inflator')

        self.inflator = inflator
        self._original_data = u''

    def __call__(self, *args, **kwargs):
        """Size ought to be a bit smaller."""
        if 'size' not in kwargs:
            kwargs['size'] = u'6'

        return super(fields.TextField, self).__call__(*args, **kwargs)

    def _make_number(self, n):
        if n == u'':
            return None

        try:
            return self.inflator(n)
        except:
            raise ValidationError("Don't know what '{0}' is".format(n))

    def process_formdata(self, valuelist):
        if not valuelist or not valuelist[0]:
            self._original_data = u''
            return

        self._original_data = valuelist[0]
        partitions = []

        sentence = valuelist[0].strip()
        for phrase in re.split(r'\s*,\s*', sentence):
            # Allowed separators: - – .. + ~ ±
            endpoints = re.split(ur'([.]{2}|[-–+~±])', phrase, 1)

            if len(endpoints) > 3:
                # Can't handle this yet.  TODO: try it each way
                raise ValidationError('Invalid range')

            if len(endpoints) == 1:
                # Not a range; just a single item.  Use the same logic as below
                # so the error fudging still works
                endpoints = [ endpoints[0], '-', endpoints[0] ]

            # The split captured, so endpoints is [a, '-', b]
            delimiter = endpoints.pop(1)

            # Note; either of these can be None
            a = self._make_number(endpoints[0])
            b = self._make_number(endpoints[1])

            if a is None and b is None:
                raise ValidationError("'{0}' is not a valid range".format(delimiter))

            error = 0
            if isinstance(a, float) or isinstance(b, float):
                # Allow +/- 0.5.  All the numbers in the db are integers,
                # and unit conversions can introduce rounding error
                error = 0.5

            if delimiter in ('~', u'±'):
                # 10~3 means 7-13.
                # It's possible for a or b to be None here
                if a is None:
                    # If a is None ("~b"), take that to mean "about b", and
                    # auto-approximate.  Half the square root seems reasonable;
                    # ~100 becomes 95-105, and ~50 becomes 46-54.
                    a = b
                    b = a ** 0.5 / 2
                elif b is None:
                    # If b is None ("a~"), just make b zero.
                    b = 0.0

                partitions.append((a - b - error, a + b + error))

            else:
                # Force them to be in the right order
                if a is not None and b is not None:
                    a, b = sorted((a, b))

                if a is not None:
                    a -= error
                if b is not None:
                    b += error
                partitions.append((a, b))

        self.data = RangeQueryEvaluator(partitions)

    def _value(self):
        # XXX Improve me
        return self._original_data
