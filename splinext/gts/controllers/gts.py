# encoding: utf8
from __future__ import absolute_import, division

from base64 import urlsafe_b64decode
from collections import namedtuple
from itertools import izip
import logging
from random import sample
from string import uppercase, lowercase, digits
import struct

import pokedex.db
import pokedex.db.tables as tables
import pokedex.formulae
from pokedex.struct import SaveFilePokemon
from pylons import config, request, response, session, tmpl_context as c, url
from pylons.controllers.util import abort, redirect
from sqlalchemy import and_, or_, not_
from sqlalchemy.orm import aliased, contains_eager, eagerload, eagerload_all, join
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.sql import func
from sqlalchemy.exc import IntegrityError

from spline.model import meta
from spline.lib.base import BaseController, render
from spline.lib import helpers as h
from splinext.gts import model as gts_model

log = logging.getLogger(__name__)


### Utility functions

def gts_prng(seed):
    """Implements the GTS's linear congruential generator.

    I love typing that out.  It makes me sounds so smart.

    Yields magical numbers."""
    # 0xabcd => 0xabcdabcd
    seed = seed | (seed << 16)
    while True:
        seed = (seed * 0x45 + 0x1111) & 0x7fffffff  # signed dword!
        yield (seed >> 16) & 0xff

def stream_decipher(data, keystream):
    """Reverses a stream cipher, given iterable data and keystream.

    Yields decrypted bytes.
    """
    for c, key in izip(data, keystream):
        new_c = (ord(c) ^ key) & 0xff
        yield chr(new_c)


def decrypt_data(data):
    """Takes a binary blob uploaded from a game and returns the original binary
    blob.  Depending on your perspective, the returned value may be more
    intelligible.
    """
    # GTS encryption is a simple stream cipher.
    # The first four bytes of the data are a header containing an obfuscated
    # key; the rest is the message
    obf_key_blob, message = data[0:4], data[4:]
    obf_key, = struct.unpack('>I', obf_key_blob)
    key = obf_key ^ 0x4a3b2c1d

    # Data is XORed with the output of an LCG, like everything else in Pokémon
    return ''.join( stream_decipher(message, gts_prng(key)) )


### Controller!

def dbg(*args):
    #print ' '.join(args)
    pass

class GTSController(BaseController):

    def dispatch(self, page):
        """We do our own dispatching for two reasons:

        1. All requests do challenge/response before anything, and it's easier
        to do that and then dispatch than copy/paste some block of code to
        every action.

        2. Easier to dump stuff if desired.
        """

        dbg(request)

        # Always return binary!
        response.headers['Content-type'] = 'application/octet-stream'

        if 'hash' in request.params:
            # Okay, already done the response.  Decrypt, then dispatch!
            if request.params['data']:
                # Note: base64 doesn't like unicode.  Go figure.  It's binary
                # junk, anyway.
                encrypted_data = urlsafe_b64decode(str(request.params['data']))
                data = decrypt_data(encrypted_data)
                data = data[4:]  # data always starts with pid; we don't care
            else:
                data = ''

            method = 'page_' + page
            if not hasattr(self, method):
                dbg("NOT YET IMPLEMENTED?")
                abort(404)

            res = getattr(self, method)(request.params['pid'], data)
            dbg("RESPONDING WITH ", type(res), len(res), repr(res))
            return res

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

        # Check for an existing Pokémon
        # TODO support multiple!
        try:
            stored_pokemon = meta.Session.query(gts_model.GTSPokemon) \
                .filter_by(pid=pid) \
                .one()
            # We've got one!  Cool, send it back.  The game will ask us to
            # delete it after receiving successfully
            pokemon_save = SaveFilePokemon(stored_pokemon.pokemon_blob)
            return pokemon_save.as_encrypted

        except:
            # Nothing
            return '\x05\x00'

    def page_delete(self, pid, data):
        u"""delete.asp

        If a Pokémon is received from result.asp, the game requests this page
        to confirm that the incoming Pokémon may be deleted.

        Returns 0x0001.
        """

        meta.Session.query(gts_model.GTSPokemon).filter_by(pid=pid).delete()
        meta.Session.commit()

        return '\x01\x00'

    def page_post(self, pid, data):
        u"""post.asp

        Deposits a Pokémon in the GTS.  Returns 0x0001 on success, or 0x000c if
        the deposit is rejected.
        """

        try:
            # The uploaded Pokémon is encrypted, which is not very useful
            pokemon_save = SaveFilePokemon(data, encrypted=True)

            # Create a record...
            stored_pokemon = gts_model.GTSPokemon(
                pid=pid,
                pokemon_blob=pokemon_save.as_struct,
            )
            meta.Session.add(stored_pokemon)
            meta.Session.commit()
            return '\x01\x00'
        except IntegrityError:
            # If that failed due to unique key collision, we're already storing
            # something.  Reject!
            return '\x0c\x00'

    def page_post_finish(self, pid, data):
        u"""post_finish.asp

        Surely this does something, but for the life of me I can't figure out
        what.

        Returns 0x0001.
        """
        return '\x01\x00'
