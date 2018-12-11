#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

apt-get update

# Install the storage service package.
# The DEBIAN_FRONTEND variable tells 'apt-get' that we're can't give input;
# otherwise it tries to ask the user for a MySQL root password.
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-storage-service

# Configure the storage service.
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/storage /etc/nginx/sites-enabled/storage

apt-get clean
