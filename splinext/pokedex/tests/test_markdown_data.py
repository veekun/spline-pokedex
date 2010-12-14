# encoding: utf8
from __future__ import unicode_literals

from nose.tools import ok_
import pylons.test

from spline.tests import *

from pokedex.db import connect, markdown
from pokedex.db.tables import metadata

class TestMarkdownData(SplineTest):

    def test_markdown(self):
        """Scans the database schema for Markdown columns, runs through every value
        in each, and ensures that it's valid Markdown.
        """
        for table in metadata.tables.values():  # dict of name => table
            for column in table.c:
                if not isinstance(column.type, markdown.MarkdownColumn):
                    continue

                yield self.check_markdown_column, column

    def check_markdown_column(self, column):
        """Implementation for the above"""
        # Well this is a bit roundabout
        session = connect(
            pylons.test.pylonsapp.config['spline-pokedex.database_url'])

        table = column.table
        columns = (column,) + tuple(table.primary_key.columns)
        for data in session.query(*columns).all():
            mdtext = data[0]
            key = "{0} / {1}".format(table.name, data[1:])

            # Test 1: HTML conversion shouldn't crash!
            exc = None
            try:
                html = mdtext.as_html
            except Exception as exc:
                # Catch it so we can wrap it in a useful message
                pass

            ok_(exc is None,
                """Markdown in ({0}) crashes while translating with {1}:\n{2}"""
                .format(key, exc, mdtext.source_text))

            # Test 2: It almost certainly shouldn't have brackets or braces;
            # those are going to be junk left over from mistyped markup
            ok_(not any(char in html for char in '[]{}'),
                """Markdown in ({0}) leaves syntax cruft:\n{1}""".format(key, html))
