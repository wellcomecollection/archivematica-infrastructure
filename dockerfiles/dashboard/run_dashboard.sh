#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

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
      --ss-url="http://localhost:8000" \
      --ss-user="test" \
      --ss-api-key="test" \
      --site-url="http://localhost:9000"

/usr/share/archivematica/virtualenvs/archivematica-dashboard/bin/gunicorn --config /etc/archivematica/dashboard.gunicorn-config.py wsgi:application