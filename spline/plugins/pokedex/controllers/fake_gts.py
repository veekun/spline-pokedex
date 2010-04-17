# encoding: utf8
from __future__ import absolute_import, division

from collections import namedtuple
import logging
from random import sample
from string import uppercase, lowercase, digits

import pokedex.db
import pokedex.db.tables as tables
import pokedex.formulae
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect_to
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased, contains_eager, eagerload, eagerload_all, join
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func

from spline import model
from spline.model import meta
from spline.lib.base import BaseController, render
from spline.lib import helpers as h

from spline.plugins.pokedex import db, helpers as pokedex_helpers
from spline.plugins.pokedex.db import pokedex_session

log = logging.getLogger(__name__)

class FakeGTSController(BaseController):

    def dispatch(self, page):
        """We do our own dispatching for two reasons:

        1. All requests do challenge/response before anything, and it's easier
        to do that and then dispatch than copy/paste some block of code to
        every action.

        2. Easier to dump stuff if desired.
        """

        print request

        # Always return binary!
        response.headers['Content-type'] = 'application/octet-stream'

        if 'hash' in request.params:
            # Okay, already done the response.  Dispatch!
            method = 'page_' + page
            try:
                res = getattr(self, method)(request.params['pid'],
                                             request.params['data'])
                print "RESPONDING WITH ", type(res), len(res), repr(res)
                return res
            except AttributeError:
                # Page doesn't exist...  yet?
                abort(404)

        # No hash.  Need to issue a challenge.  It's random, so whatever
        return ''.join(sample( uppercase + lowercase + digits, 32 ))

    ### Actual pages

    def page_info(self, pid, data):
        """info.asp

        Apparently always returns 0x0001.  Probably just a ping to see if the
        server is up.
        """

        return '\x01\x00'

    def page_setProfile(self, pid, data):
        """setProfile.asp

        Only Pt and later check this page.  Don't know why.  It returns eight
        NULs, every time.
        """

        return '\x00' * 8

    def page_result(self, pid, data):
        u"""result.asp

        The good part!

        This checks the game's status on the GTS.  If there's nothing
        interesting to report, it returns 0x0005.  If the game has a Pokémon up
        on the GTS, it returns 0x0004.

        However...  if the game has a Pokémon waiting to come to it, it returns
        that entire Pokémon struct!  No header, no encryption.  Just a regular
        ol' Pokémon blob.
        """

        # This is just some Combee I got off the internets for now
        return '\xfc\x1bH\x86\x00\x00)\x98\xccFi\xa1=\xe7\xa6\xca\x1d\x0fR\xa5\xdcB\xe0l/\x04\xd9\x12\xf8\xc7\x95?|\xd4\xd4~C\xab\xa6B\xae\x90\xa8H\x05;\xba[#\xc0\xfc\xf3\xd5\tzsI\xdaB3\x94\xd8\x8a\xe4a\xd8\xbb\x02\xf4\xce\x98\xc32\xba\xe7I\x0e\xb9Av\xbf!\xb7\x00\xbc\xb7kR-\xe5\xd2W\xcb\xac\xb8)B\xdf-\x9e\xec\xee\xd8\xfd+G\x0b0\xb2\xe9w~\x1bfZ\xd4\x1c\xd4\xf5\x95\xa4N\xda\xb4c\xb4\xb4l\xbeCEE\x0e\x1d\xee\xde#\xc6_\x0b\r\xe2Z\xd2\xd5\xc2\x0f\xc1|\x0f\x05t\x96\x1f\x8b\x99\xb86\x06w\r?\x17\xd1\xb6\x82\\\xb4\x9fI\xa0\xec\xa9\xee\xe6c\x8b\xbb\xdb\xb5:\xfa\xed\x12\xe2\xfbk\xa6\xad\xa8R%\xe8P\xb9\x87U?\xf7D\x9f\xc5\xf7JIw]c\x9d\xd4a]W\x16\x8e1&\xec\xc6\xfc9#=2v\x1fFP\x06)*\xca]\x99]I\x9f\x01\x01\x0b\x01\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x002\x01S\x01W\x01L\x01M\x01\xff\xff\x00\x00\x00\x00\xa2i\x00\x00\x00\x00\x00\x00'

    def page_delete(self, pid, data):
        u"""delete.asp

        If a Pokémon is received from result.asp, the game requests this page
        to confirm that the incoming Pokémon may be deleted.

        Returns 0x0001.
        """

        return '\x01\x00'

