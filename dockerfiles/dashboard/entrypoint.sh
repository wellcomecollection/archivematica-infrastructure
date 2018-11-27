#!/bin/bash

mkdir -p $DJANGO_STATIC_ROOT
chown -R archivematica:archivematica $DJANGO_STATIC_ROOT

# /src/dashboard/src/manage.py collectstatic --noinput --clear

su archivematica
/src/dashboard/src/manage.py migrate
/src/dashboard/src/manage.py runserver 0.0.0.0:$DJANGO_PORT
