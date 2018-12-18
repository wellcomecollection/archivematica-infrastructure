#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

# This is a proxy for whether the storage service has started yet (and applied
# the database migrations that the MCP server requires).
sleep 20
# for i in 1 2 3 4 5 6 7 8 9 10
# do
#   if curl "http://localhost:9000/"
#   then
#     echo "Dashboard is up!  Starting"
#     break
#   else
#     echo "Dashboard not up yet; sleeping"
#     sleep 20
#   fi
# done
#
# if curl "http://localhost:9000/"
# then
#   echo "Dashboard has not started successfully!"
#   exit 1
# fi


/usr/share/archivematica/virtualenvs/archivematica-mcp-server/bin/python /usr/lib/archivematica/MCPServer/archivematicaMCP.py
