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

# This installs a virtualenv for every service, but we only need the one for
# this application.  This saves us several hundred MB in the final image.
if [[ ! -z "$APT_KEEP_VIRTUALENV" ]]
then
  for venv_name in dashboard mcp-client mcp-server storage-service
  do
    if [[ "$APT_KEEP_VIRTUALENV" != "$venv_name" ]]
    then
      rm -rf "/usr/share/archivematica/virtualenvs/archivematica-$venv_name"
    fi
  done
fi

apt autoremove --yes
apt-get clean
