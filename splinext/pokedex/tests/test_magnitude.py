# encoding: utf8
from math import floor, log10

from unittest import TestCase

from splinext.pokedex.magnitude import parse_size

class TestSizeParsing(TestCase):
    u"""Provides `assert_same` to the height and weight test classes.  Each
    must implement a `height_or_weight` property.
    """

    def assert_same(self, a, b):
        u"""Asserts that `a` and `b` parse to the same size.  Makes tests
        easier to understand and maintain, as the results don't all have to be
        written as decimeters or hectograms.

        `b` may also just be a number, in which case it's assumed to be the
        Pokémon base unit.

        To account for the nature of floats, some slight deviation is allowed.
        """
        a_value = parse_size(a, self.height_or_weight)

        if isinstance(b, basestring):
            b_value = parse_size(b, self.height_or_weight)
        else:
            b_value = float(b)

        # log10(n) gives the position of the first sigdigit in n.
        # Find the most precise such value of a and b, negate it to get what
        # assertAlmostEqual expects, and allow three places of fudging
        print a_value, b_value
        places = min(log10(a_value), log10(b_value))
        places = int(floor(places))
        places = -places
        places -= 3

        self.assertAlmostEquals(
            a_value, b_value,
            places=places,
            msg="{0} ({1}) ~~ {2} ({3})".format(a, a_value, b, b_value),
        )

class TestHeightParsing(TestSizeParsing):
    height_or_weight = 'height'

    def test_simple(self):
        u"""Simple, one-part, not-abbreviated heights"""

        self.assert_same('1 meter', 10)
        self.assert_same('.1 meter', 1)
        self.assert_same('0.01 meter', 0.1)
        self.assert_same('meter', 10)
        self.assert_same('1 Meter', 10)
        self.assert_same('1 METER', 10)

        self.assert_same('1 inch', '0.0254 meter')
        self.assert_same('1 cubit', '0.45 meter')
        self.assert_same('1 light year', '5878630000000 mile')

    def test_plurals(self):
        u"""Heights with plural unit names"""

        self.assert_same('3 meters', 30)
        self.assert_same('5280 feet', '1 miles')
        self.assert_same('16 inches', '16 inch')

    def test_si_prefixes(self):
        u"""Heights with SI prefixes attached"""

        self.assert_same('kilometer', '1000 meters')
        self.assert_same('1 microlightyear', '5878630 miles')
        self.assert_same('1 femtoparsec', '30.857 meters')

    def test_abbreviations(self):
        u"""Heights with abbreviated unit names"""

        self.assert_same('1m', '1 meter')
        self.assert_same('1in', '1 inch')
        self.assert_same('3cm', '3 centimeters')
        self.assert_same('1km.', '1000 meters')
        self.assert_same('1mm', '0.001 meters')
        self.assert_same('1Mm', '1000000 meters')

    def test_combinations(self):
        u"""Heights with multiple units combined"""

        self.assert_same('1 meter 1 inch', '1.0254 meters')
        self.assert_same('3 kilometers 2 meters 1 centimeter', '3002.01 meters')
        self.assert_same('3 feet 2 inches', '38 inches')

    def test_special_cases(self):
        u"""Heights like 1'3" or 1m20"""

        self.assert_same('1\'6"', '1 foot 6 inches')
        self.assert_same('1\'6', '1 foot 6 inches')
        self.assert_same('1m20', '1 meter 20 centimeters')

    def test_pokemon(self):
        u"""Heights with critter names as units"""

        self.assert_same('1 natu', '0.2 m')
        self.assert_same('1 meganatu', '200 km')
        self.assert_same('1 eevee', '11.8"')
        self.assert_same('20 decieevee', '0.6 meters')

    def test_contrived(self):
        u"""Height-ish garbage that hopefully nobody actually types"""

        self.assert_same('3ft.2in0.5m..3km', '501.4652 meters')

class TestWeightParsing(TestSizeParsing):
    height_or_weight = 'weight'

    def test_simple(self):
        u"""Simple, one-part, not-abbreviated weights"""

        self.assert_same('1 gram', 0.01)
        self.assert_same('.1 gram', 0.001)
        self.assert_same('0.01 gram', 0.0001)
        self.assert_same('gram', 0.01)
        self.assert_same('1 Gram', 0.01)
        self.assert_same('1 GRAM', 0.01)

        self.assert_same('1 pound', '453.59237 gram')
        self.assert_same('1 bushel', '27216 gram')
        self.assert_same('1 longton', '1016046.9088 gram')

    def test_plurals(self):
        u"""Weights with plural unit names"""

        self.assert_same('3 grams', 0.03)
        self.assert_same('16 ounces', '1 pounds')

    def test_si_prefixes(self):
        u"""Weights with SI prefixes attached"""

        self.assert_same('kilogram', '1000 grams')
        self.assert_same('1 millimetricton', '1 kilogram')
        self.assert_same('gigaplanckmass', '21.764411 kilograms')

    def test_abbreviations(self):
        u"""Weights with abbreviated unit names"""

        self.assert_same('1g', '1 gram')
        self.assert_same('1oz', '1 ounce')
        self.assert_same('3lb', '3 pounds')
        self.assert_same('1kg.', '1000 grams')
        self.assert_same('1mg', '0.001 grams')
        self.assert_same('1Mg', '1000000 grams')

    def test_combinations(self):
        u"""Weights with multiple units combined"""

        self.assert_same('1 kilogram 1 metric ton', '1001000 grams')
        self.assert_same('3 kilograms 2 grams 1 centigram', '3002.01 grams')
        self.assert_same('3 pounds 2 ounces', '38 ounces')

    def test_special_cases(self):
        u"""Weights like 1lb4"""

        self.assert_same('1lb4', '1 pound 4 ounces')

    def test_pokemon(self):
        u"""Weights with critter names as units"""

        self.assert_same('1 natu', '2 kg')
        self.assert_same('1 meganatu', '2000000 kg')
        self.assert_same('1 eevee', '14.3 lb')
        self.assert_same('20 decieevee', '13 kilograms')
