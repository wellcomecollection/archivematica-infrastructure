# -*- encoding: utf-8

from __future__ import absolute_import

import logging

from .production import *


# This setting allows anybody to view static assets, whether or not they're
# logged in.  The practical effect is that the login page looks a bit nicer.
LOGIN_EXEMPT_URLS += [
    r"^media/"
]


# Normally the dashboard sends its logs to a file on disk, which can be found at:
#
#     /var/log/archivematica/dashboard
#
# See https://wiki.archivematica.org/MCPServer#Parsing_Logs
#
# This config adds a logging handler that copies all messages to stdout as
# well as to the file, so they show up in CloudWatch.
#
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "detailed": {
            "format": "[%(levelname)s] %(name)s:%(module)s:%(funcName)s:%(lineno)d: %(message)s"
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "detailed",
        },
    },
    "loggers": {
        "archivematica": {
            "handlers": ["console"],
            "level": os.getenv("LOG_LEVEL", "INFO"),
        },
        "archivematica.dashboard": {
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
            "console",
        ],
        "level": os.getenv("LOG_LEVEL", "INFO"),
    },
}

logging.config.dictConfig(LOGGING)
