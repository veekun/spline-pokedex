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
    """Parses a string of the form 'a, b, c-e'."""
    def __init__(self, label=u'', validators=[], **kwargs):
        super(fields.TextField, self).__init__(label, validators, **kwargs)
        self._original_data = u''

    def __call__(self, *args, **kwargs):
        """Size ought to be a bit smaller."""
        if 'size' not in kwargs:
            kwargs['size'] = u'6'

        return super(fields.TextField, self).__call__(*args, **kwargs)

    def _make_float(self, n):
        try:
            if n == u'':
                return None
            else:
                return float(n)
        except ValueError:
            raise ValidationError('Invalid range')

    def process_formdata(self, valuelist):
        if not valuelist or not valuelist[0]:
            self._original_data = u''
            return

        self._original_data = valuelist[0]
        partitions = []

        sentence = valuelist[0].strip()
        for phrase in re.split(r'\s*,\s*', sentence):
            endpoints = re.split(ur'\s*(?:-|–|[.][.]|[+])\s*', phrase, 1)

            if len(endpoints) == 1:
                # Not a range; just a single item
                partitions.append(self._make_float(endpoints[0]))
            else:
                # a-b
                endpoints[0] = self._make_float(endpoints[0])
                endpoints[1] = self._make_float(endpoints[1])

                partitions.append(tuple(endpoints))

        self.data = RangeQueryEvaluator(partitions)

    def _value(self):
        # XXX Improve me
        return self._original_data
