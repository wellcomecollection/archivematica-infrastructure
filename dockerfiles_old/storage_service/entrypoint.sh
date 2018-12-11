#!/bin/bash

if [ ! -d "/home/archivematica/archivematica-sampledata" ]; then
    cp -rf /src/archivematica-sampledata/ /home/archivematica/archivematica-sampledata/
fi

su archivematica
/src/storage_service/manage.py migrate
/src/storage_service/manage.py runserver 0.0.0.0:$DJANGO_PORT