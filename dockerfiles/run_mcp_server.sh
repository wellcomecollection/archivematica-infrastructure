#!/usr/bin/env bash

set -o errexit
set -o nounset

# This is a proxy for whether the storage service has started yet (and applied
# the database migrations that the MCP server requires).
for i in 1 2 3 4 5
do
  if curl http://archivematica-dashboard:8000/
  then
    echo "Dashboard is up!  Starting"
    break
  else
    echo "Dashboard not up yet; sleeping"
    sleep 10
  fi
done

/usr/share/archivematica/virtualenvs/archivematica-mcp-server/bin/python /usr/lib/archivematica/MCPServer/archivematicaMCP.py
