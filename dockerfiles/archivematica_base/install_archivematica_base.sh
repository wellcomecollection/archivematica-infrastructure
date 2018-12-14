#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

# This installation process is based on the instructions from
# https://www.archivematica.org/en/docs/archivematica-1.8/admin-manual/installation-setup/installation/install-ubuntu/#install-pkg-ubuntu,
# as retrieved on 11 December 2018.


# 0. Install some dependencies that are implicitly assumed, but not present in
#    a base Ubuntu 18.04 Docker image.
#
apt-get update
apt-get install --yes curl gnupg python


# 1. Add Archivematica package sources.
curl -Ls https://packages.archivematica.org/1.8.x/key.asc | apt-key add -
sh -c 'echo "deb [arch=amd64] http://packages.archivematica.org/1.8.x/ubuntu bionic main" >> /etc/apt/sources.list'
sh -c 'echo "deb [arch=amd64] http://packages.archivematica.org/1.8.x/ubuntu-externals bionic main" >> /etc/apt/sources.list'


# 7. Upgrade pip.
curl -Ls https://bootstrap.pypa.io/get-pip.py | python -


# The remaining steps are specific to particular services -- for example, the dashboard
# or the client, so we'll run them in other Docker images.  We clear out the
# package cache to keep the build size down, but that's it.
apt-get remove --yes curl gnupg
apt autoremove --yes
apt-get clean
