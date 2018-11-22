#!/bin/bash

if [ ! -d "/home/archivematica/archivematica-sampledata" ]; then
    cp -rf /src/archivematica-sampledata/ /home/archivematica/archivematica-sampledata/
fi

su archivematica
#sleep infinity
/src/dashboard/src/manage.py runserver 0.0.0.0:$DJANGO_PORT