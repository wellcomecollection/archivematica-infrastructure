#!/usr/bin/env bash

set -o errexit
set -o nounset

docker run -e ARCHIVEMATICA_DASHBOARD_CLIENT_HOST=139.162.244.147 \
  -e DJANGO_SECRET_KEY=12345 \
    -e DJANGO_SETTINGS_MODULE=settings.local \
      -e ARCHIVEMATICA_DASHBOARD_CLIENT_USER=archivematica \
        -e ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD=demo \
          -e ARCHIVEMATICA_DASHBOARD_CLIENT_DATABASE=MCP \
            -e ARCHIVEMATICA_DASHBOARD_SEARCH_ENABLED=true \
              archivematica_dashboard