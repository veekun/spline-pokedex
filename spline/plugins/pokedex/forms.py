# encoding: utf8
"""Useful form fields of my own devising."""

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
