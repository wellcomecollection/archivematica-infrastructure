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
logger = logging.getLogger("archivematica.mcp.server")
level = os.environ.get("LOG_LEVEL", "INFO")

handler = logging.StreamHandler(sys.stdout)
handler.setLevel(level)
formatter = logging.Formatter("%(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)
