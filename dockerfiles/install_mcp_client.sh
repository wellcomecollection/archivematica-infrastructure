#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

apt-get update

# Install the mcp server packages.  We set DEBIAN_FRONTEND so we don't get asked
# for mail configuration.
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-client

# If you don't install the dashboard, the server complains about not being
# able to find the 'components' module.
apt-get install --yes libmysqlclient-dev
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-dashboard

apt autoremove --yes
apt-get clean
