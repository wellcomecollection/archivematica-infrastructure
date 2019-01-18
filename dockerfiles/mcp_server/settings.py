# -*- encoding: utf-8

import logging
import os
import sys

from .common import *


# Normally MCPServer sends its logs to a file on disk, which can be found at:
#
#     /var/log/archivematica/MCPServer
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
        },
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
    },
    "root": {
        "handlers": ["console"],
        "level": os.getenv("LOG_LEVEL", "INFO"),
    },
}

logging.config.dictConfig(LOGGING)
