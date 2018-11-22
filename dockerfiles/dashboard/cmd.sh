#!/bin/bash

mkdir -p $DJANGO_STATIC_ROOT
chown -R archivematica:archivematica $DJANGO_STATIC_ROOT

# /src/dashboard/src/manage.py collectstatic --noinput --clear

su archivematica
sleep infinity
