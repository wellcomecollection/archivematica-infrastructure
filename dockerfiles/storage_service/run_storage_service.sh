#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

/usr/share/archivematica/virtualenvs/archivematica-storage-service/bin/python \
  /usr/share/archivematica/virtualenvs/archivematica-storage-service/lib/python2.7/site-packages/storage_service/manage.py \
    migrate --noinput

/usr/share/archivematica/virtualenvs/archivematica-storage-service/bin/python \
  /usr/share/archivematica/virtualenvs/archivematica-storage-service/lib/python2.7/site-packages/storage_service/manage.py \
		create_user \
			--username="test" \
			--password="test" \
			--email="test@test.com" \
			--api-key="test" \
			--superuser

/usr/share/archivematica/virtualenvs/archivematica-storage-service/bin/gunicorn --config /etc/archivematica/storage-service.gunicorn-config.py storage_service.wsgi:application
