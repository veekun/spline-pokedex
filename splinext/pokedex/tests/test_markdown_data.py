# encoding: utf8
from __future__ import unicode_literals

from markupsafe import escape
from nose.tools import ok_
import pylons.test

from spline.tests import *
import splinext.pokedex.db

from pokedex.db import markdown
from pokedex.db.tables import metadata, MoveEffect

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

        # Move effects have their own special wrappers, so they aren't actually
        # marked as MarkdownColumns.  Explicitly test them separately
        yield self.check_markdown_column, MoveEffect.prose_table.__table__.c.short_effect
        yield self.check_markdown_column, MoveEffect.prose_table.__table__.c.effect

    def check_markdown_column(self, column):
        """Implementation for the above"""
        # Well this is a bit roundabout
        session = splinext.pokedex.db.pokedex_session

        table = column.table
        columns = (column,) + tuple(table.primary_key.columns)
        for data in session.query(*columns).all():
            mdtext = data[0]
            if not isinstance(column.type, markdown.MarkdownColumn):
                # For move effect columns
                mdtext = markdown.MarkdownString(mdtext)

            assert mdtext, "row %r in table %s has no %s" % (
                data[1:], table.name, column.name)

            key = "{0} / {1}".format(table.name, data[1:])

            # Test 1: HTML conversion shouldn't crash!
            html = escape(mdtext)

            # Test 2: It almost certainly shouldn't have brackets or braces;
            # those are going to be junk left over from mistyped markup
            ok_(not any(char in html for char in '[]{}'),
                """Markdown in ({0}) leaves syntax cruft:\n{1}""".format(key, html))
