# -*- encoding: utf-8

from __future__ import absolute_import

from .production import *


# This setting allows anybody to view static assets, whether or not they're
# logged in.  The practical effect is that the login page looks a bit nicer.
LOGIN_EXEMPT_URLS += [
    r"^media/"
]

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "detailed": {
            "datefmt": "%Y-%m-%d %H:%M:%S",
            "format": "%(levelname)-8s  %(asctime)s  %(name)s:%(module)s:%(funcName)s:%(lineno)d:  %(message)s"
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "loggers": {
        "archivematica": {
            "handlers": ["console"],
            "level": os.getenv("LOG_LEVEL", "INFO"),
        },
        "django": {
            "handlers": ["console"],
            "level": os.getenv("LOG_LEVEL", "INFO"),
        },
    },
    "root": {
        "handlers": [
            "archivematica",
            "django",
        ],
        "level": "WARNING"
    },
}
