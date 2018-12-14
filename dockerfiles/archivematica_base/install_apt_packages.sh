#!/usr/bin/env bash
# Install the dashboard package.

set -o errexit
set -o nounset
set -o verbose

apt-get update

if [[ "${APT_INSTALL_DASHBOARD:-no}" == "yes" ]]
then
  # We don't want to be asked about geographic area or tzdata.
  apt-get install --yes libmysqlclient-dev
  DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-dashboard
fi

if [[ "${APT_INSTALL_MCP_CLIENT:-no}" == "yes" ]]
then
  # We set DEBIAN_FRONTEND so we don't get asked for a MySQL root password.
  DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-client
fi

if [[ "${APT_INSTALL_MCP_SERVER:-no}" == "yes" ]]
then
  # We set DEBIAN_FRONTEND so we don't get asked for a MySQL root password.
  DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-server
fi

if [[ "${APT_INSTALL_STORAGE_SERVICE:-no}" == "yes" ]]
then
  # We set DEBIAN_FRONTEND so we don't get asked for a MySQL root password.
  DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-storage-service
fi

apt autoremove --yes
apt-get clean
