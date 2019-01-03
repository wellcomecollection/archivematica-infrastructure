#!/usr/bin/env bash

set -o errexit
set -o nounset

while true; do
  curl -v 'https://workflow.wellcomecollection.org/archivematica/dashboard/administration/'
  echo (date)
  echo "~~~"
  sleep 5
done
