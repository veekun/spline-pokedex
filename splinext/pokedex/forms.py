# encoding: utf8
"""Useful form fields of my own devising."""

import re

from sqlalchemy.sql import and_, or_
from wtforms import ValidationError, fields, widgets
from wtforms.ext.sqlalchemy.fields import QuerySelectMultipleField

try:
    from wtforms.fields.core import UnboundField
except ImportError:
    from wtforms.fields import UnboundField

import splinext.pokedex.db as db


class FakeMultiDict(dict):
    def getlist(self, key):
        return self[key]

class DuplicateField(fields.Field):
    """
    Wraps a field that must be rendered several times.  Similar to FieldList,
    except the fields are identical -- names are unchanged.

    Do NOT use this for multi-select fields, compound fields, or subforms!
    """
    widget = widgets.ListWidget()

    def __init__(self, unbound_field, label=None, validators=None, min_entries=0,
                 max_entries=None, default=[], **kwargs):
        super(DuplicateField, self).__init__(label, validators, default=default, **kwargs)
        if self.filters:
            raise TypeError('DuplicateField does not accept any filters. Instead, define them on the enclosed field.')
        if validators:
            raise TypeError('DuplicateField does not accept any validators. Instead, define them on the enclosed field.')
        assert isinstance(unbound_field, UnboundField), 'Field must be unbound, not a field class'

        self.unbound_field = unbound_field
        self.min_entries = min_entries
        self.max_entries = max_entries
        self._prefix = kwargs.get('_prefix', '')
        self._form = kwargs.get('_form', None)

    def process(self, formdata, data=fields._unset_value):
        if data is fields._unset_value or not data:
            try:
                data = self.default()
            except TypeError:
                data = self.default
        else:
            assert not self.max_entries or len(data) < self.max_entries, \
                'You cannot have more than max_entries entries in this DuplicateField'

        # Grab data from the incoming form
        if formdata:
            valuelist = formdata.getlist(self.name)
            if self.max_entries:
                valuelist = valuelist[0:self.max_entries]
        else:
            valuelist = []

        # Create the subfields
        self.entries = []
        self.data = []

        num_entries = max(self.min_entries, len(valuelist), len(data))
        subsubfields = []
        for i in range(num_entries):
            subfield = self.unbound_field.bind(form=self._form, prefix=self._prefix,
                                               name=self.short_name, id="{0}-{1}".format(self.id, i))

            if i == 0:
                if formdata and hasattr(subfield, 'subfield_names'):
                    subsubfields = list(subfield.subfield_names)

            # See if there's any form data to give the field
            fakedata = FakeMultiDict()
            if i < len(valuelist):
                fakedata[subfield.name] = [valuelist[i]]
            for name in subsubfields:
                subvaluelist = formdata.getlist(name)
                if i < len(subvaluelist):
                    fakedata[name] = [subvaluelist[i]]

            if i < len(data):
                subfield.process(fakedata, data[i])
            else:
                subfield.process(fakedata)

            if subfield.default or subfield.data != subfield.default:
                self.data.append(subfield.data)

            self.entries.append(subfield)

    def validate(self, form, extra_validators=[]):
        self.errors = []
        success = True
        for subfield in self.entries:
            if not subfield.validate(form):
                success = False
                self.errors.append(subfield.errors)
        return success

    def __iter__(self):
        return iter(self.entries)

    def __len__(self):
        return len(self.entries)

    def __getitem__(self, index):
        return self.entries[index]


class MultiCheckboxField(fields.SelectMultipleField):
    """ A multiple-select, except displays a list of checkboxes.

    Iterating the field will produce subfields, allowing custom rendering of
    the enclosed checkbox fields.
    """
    widget = widgets.ListWidget(prefix_label=False)
    option_widget = widgets.CheckboxInput()


class QueryCheckboxSelectMultipleField(QuerySelectMultipleField):
    """
    Works the same as a QuerySelectMultipleField, except using checkboxes
    rather than a selectbox.

    Iterating over the field yields the checkbox subfields.
    """
    widget = widgets.ListWidget(prefix_label=False)
    option_widget = widgets.CheckboxInput()


class PokedexLookupField(fields.StringField):
    u"""Provides a lookup box for naming something in the Pokédex."""

    def __init__(self, label=None, validators=None,
                 valid_type='pokemon', allow_blank=False, **kwargs):
        """`valid_type` is the type prefix to pass to lookup."""
        super(PokedexLookupField, self).__init__(label, validators, **kwargs)

        self.raw_data = None
        self.valid_type = valid_type
        self.allow_blank = allow_blank

    def __call__(self, *args, **kwargs):
        """Adds the appropriate classes to make lookup suggestions work."""
        extra_class = "js-dex-suggest js-dex-suggest-{0}" \
                      .format(self.valid_type)

        if 'class_' in kwargs:
            kwargs['class_'] += ' ' + extra_class
        else:
            kwargs['class_'] = extra_class

        return super(PokedexLookupField, self).__call__(*args, **kwargs)

    def process_formdata(self, valuelist):
        """Load the value from the incoming form."""
        if not valuelist or not valuelist[0]:
            if self.allow_blank:
                self.data = None
                return
            else:
                raise ValidationError('Gotta pick something')

        self.raw_data = valuelist

        valid_types = [self.valid_type]
        if self.valid_type == 'pokemon':
            valid_types = ['pokemon_species', 'pokemon_form']

        results = db.pokedex_lookup.lookup(
            valuelist[0],
            valid_types=valid_types,
        )

        all_data = set()
        for result in results:
            obj = result.object
            if obj.__tablename__ == 'pokemon_forms':
                all_data.add(obj.pokemon)
            elif obj.__tablename__ == 'pokemon_species':
                all_data.add(obj.default_pokemon)
            else:
                all_data.add(obj)

        if not all_data:
            raise ValidationError('Nothing found')
        if len(all_data) > 1:
            # XXX fix this to offer alternatives somehow
            raise ValidationError('Too vague')

        self.data = all_data.pop()

    def _value(self):
        """Converts Python value back to a form value."""
        if self.data is None:
            return self.raw_data[0] if self.raw_data else u''
        elif self.valid_type == 'pokemon':
            # Pokémon need form names
            return self.data.default_form.name
        else:
            return self.data.name


class StatField(fields.Field):
    """Compound field that contains one subfield for each of the six main
    statistics, which need to be passed in on creation since they're db
    objects.

    Can be iterated to get the individual fields in stat id order, or used as a
    dictionary.
    """
    def __init__(self, stats, unbound_field, **kwargs):
        self._stats = stats
        self._unbound_field = unbound_field
        self._form = kwargs.get('_form', None)

        super(StatField, self).__init__(**kwargs)

    def process(self, formdata, data=None):
        self.process_errors = []
        self._fields = {}

        short_data = {}
        if self.short_name in formdata:
            # Must be a shortened field; unshorten it and clobber the actual
            # formdata
            values = re.split(u'[|,]', formdata.getlist(self.short_name)[0])
            try:
                int_values = [int(value) for value in values]
                short_data = dict(zip(self._stats, int_values))
            except ValueError:
                # Something isn't an integer.  Shortening fucked up.  ABORT
                pass

        for stat, name in zip(self._stats, self.subfield_names):
            field = self._fields[stat] = self._unbound_field.bind(form=self._form, name=name)
            field.stat = stat
            if stat in short_data:
                field.process({}, short_data[stat])
            else:
                field.process(formdata)

    def validate(self, form, extra_validators=()):
        self.errors = []
        success = True
        for field in self:
            if not field.validate(form):
                success = False
                self.errors.append(field.errors)
        return success

    def populate_obj(self, obj, name): raise NotImplementedError

    @property
    def subfield_names(self):
        for stat in self._stats:
            yield '_'.join((self.short_name, stat.name.lower().replace(' ', '_')))

    def __iter__(self):
        return (self._fields[stat] for stat in self._stats)

    def __getitem__(self, stat):
        return self._fields[stat]

    @property
    def data(self):
        return dict((stat, self._fields[stat].data) for stat in self._stats)

    @property
    def short_data(self):
        return u','.join(str(field.data) for field in self)


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

class RangeTextField(fields.StringField):
    """Parses a string of the form 'a, b, c-e'.

    `inflator` converts each chunk (a, b, c, and e) to a number.  If it dies,
    the range is taken to be invalid.

    If `signed` is true, then input of "-foo" won't be taken to mean "0-foo",
    and "--foo" will be allowed.
    """
    def __init__(self, label=None, validators=None, inflator=None, signed=False,
        **kwargs):

        super(RangeTextField, self).__init__(label, validators, **kwargs)

        if not inflator:
            raise ValueError('RangeTextField requires an inflator')

        self.inflator = inflator
        self.signed = signed
        self._original_data = u''

    def __call__(self, *args, **kwargs):
        """Size ought to be a bit smaller."""
        if 'size' not in kwargs:
            kwargs['size'] = u'6'

        return super(RangeTextField, self).__call__(*args, **kwargs)

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
            # For signed ranges, - in front of a digit is interpreted as part
            # of that digit
            if self.signed:
                endpoints = re.split(ur'([.]{2}|[–+~±]|[<>]=?|-(?!\d))', phrase, 1)
            else:
                endpoints = re.split(ur'([.]{2}|[-–+~±]|[<>]=?)', phrase, 1)

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

            if (a is None and b is None) or \
                (a is not None and delimiter in ('<', '<=', '>', '>=')):

                # Either there are no numbers, or someone typed "1<4"
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

            elif delimiter == '<':
                partitions.append((None, b - 0.01))

            elif delimiter == '<=':
                partitions.append((None, b))

            elif delimiter == '>':
                partitions.append((b + 0.01, None))

            elif delimiter == '>=':
                partitions.append((b, None))

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
