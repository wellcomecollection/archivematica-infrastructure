# -*- encoding: utf-8

from __future__ import absolute_import

from .production import *


# This setting allows anybody to view static assets, whether or not they're
# logged in.  The practical effect is that the login page looks a bit nicer.
LOGIN_EXEMPT_URLS += [
    r"^media/"
]
