# -*- encoding: utf-8

from __future__ import absolute_import

from .production import *


# This setting is a workaround for some slightly dodgy behaviour in Archivematica.
# Specifically, when a user tries to hit a page while not logged in, they get
# redirected to this hard-coded login URL.  This bypasses any other URL prefixes
# or rewriting, in particular it doesn't work when served behind a path
# (/archivematica/dashboard/).
#
# https://github.com/artefactual/archivematica/blob/174736794b96a504f782978bca935d5697f03703/src/dashboard/src/installer/middleware.py#L39-L43
#
# You can see the settings being overridden here:
# https://github.com/artefactual/archivematica/blob/2ffe3e8e5485dc038a3fb4fafe3723a1e4a45974/src/dashboard/src/settings/base.py#L397

LOGIN_URL = "/archivematica/dashboard/administration/accounts/login/"


# Changing this setting ensures that after a successful login, the user
# remains in the dashboard and isn't booted to the root path of workflow.wc.org.
#
# https://github.com/artefactual/archivematica/blob/2ffe3e8e5485dc038a3fb4fafe3723a1e4a45974/src/dashboard/src/settings/base.py#L398

LOGIN_REDIRECT_URL = "/archivematica/dashboard/"


# This tells the app that it should point to static assets at
# /archivematica/dashboard/media, which is a path actually served by nginx.
#
# TODO: It would be nicer if Django served these assets and the dashboard
# didn't have to know about nginx, but this was the easiest fix to get working
# as a non-expert with Django URL handling.

STATIC_URL = "/archivematica/dashboard/media/"
