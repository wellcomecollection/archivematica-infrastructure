#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

apt-get update

# Install the mcp server packages.  We set DEBIAN_FRONTEND so we don't get asked
# for mail configuration.
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-client

apt-get clean
