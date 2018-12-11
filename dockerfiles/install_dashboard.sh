#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

apt-get update

# We don't want to be asked about geographic area or tzdata.
apt-get install --yes libmysqlclient-dev
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-dashboard

apt-get clean
