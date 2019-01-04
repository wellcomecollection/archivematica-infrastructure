#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

# The Archivematica management scripts assume this database exists when
# they try to run a migration, and fail if it's not present.  You get the
# following error:
#
#     django.db.utils.OperationalError: (1049, "Unknown database 'MCP'")
#
# This command hangs if we can't connect to RDS, hence the explicit
# (and short!) timeout.
#
mysql --connect-timeout=5 --verbose \
  --host="$ARCHIVEMATICA_DASHBOARD_CLIENT_HOST" \
  --port="$ARCHIVEMATICA_DASHBOARD_CLIENT_PORT" \
  --user="$ARCHIVEMATICA_DASHBOARD_CLIENT_USER" \
  --password="$ARCHIVEMATICA_DASHBOARD_CLIENT_PASSWORD" --execute "\
		CREATE DATABASE IF NOT EXISTS MCP;"

/usr/share/archivematica/virtualenvs/archivematica-dashboard/bin/python \
  /usr/share/archivematica/dashboard/manage.py \
    migrate --noinput

/usr/share/archivematica/virtualenvs/archivematica-dashboard/bin/python \
  /usr/share/archivematica/dashboard/manage.py \
    install \
      --username="test" \
      --password="test" \
      --email="test@test.com" \
      --org-name="test" \
      --org-id="test" \
      --api-key="test" \
      --ss-url="$WELLCOME_SS_URL" \
      --ss-user="test" \
      --ss-api-key="test" \
      --site-url="$WELLCOME_SITE_URL"

/usr/share/archivematica/virtualenvs/archivematica-dashboard/bin/gunicorn \
  --config /etc/archivematica/dashboard.gunicorn-config.py \
  wsgi:application
