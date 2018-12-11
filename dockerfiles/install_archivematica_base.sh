#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

# This installation process is based on the instructions from
# archivematica.org/en/docs/archivematica-1.8/admin-manual/installation/installation/,
# as retrieved on 11 December 2018.


# 0. Install git and wget.  The instructions presume they're both present (for Git,
#    it's implicit in a 'pip install' command as part of 'apt-get' installation),
#    but neither are present in a base Ubuntu 16.04 Docker image.
#
apt-get update
apt-get install --yes git wget

# You also need this package, or you get the following error when running
# 'apt-get update' against the Archivematica package repos:
#
#     The method driver /usr/lib/apt/methods/https could not be found
#
# See https://askubuntu.com/q/104160/265738
apt-get install --yes apt-transport-https


# 1. Add Archivematica package sources.
wget -O - http://jenkins-ci.archivematica.org/repos/devel.key | apt-key add -
wget -O - https://packages.archivematica.org/1.8.x/key.asc | apt-key add -
echo "deb [arch=amd64] http://jenkins-ci.archivematica.org/repos/apt/dev-1.8.x-xenial/ ./"    >> /etc/apt/sources.list
echo "deb [arch=amd64] http://jenkins-ci.archivematica.org/repos/apt/release-0.11-xenial/ ./" >> /etc/apt/sources.list
echo "deb [arch=amd64] http://packages.archivematica.org/1.8.x/ubuntu-externals xenial main"  >> /etc/apt/sources.list


# 2. Add Elasticsearch.
#    We're using hosted Elasticsearch so we don't need this.  Also following the
#    docs fails here; see https://github.com/archivematica/Issues/issues/376


# 3. Update your system.
#    Although we ran 'update' once in step 0, we need to run it again here to
#    pick up the new package sources.
apt-get update


# 4. Install Elasticsearch.   See step 2.


# 5. Install the storage service package.
#    The DEBIAN_FRONTEND variable tells 'apt-get' that we're can't give input;
#    otherwise it tries to ask the user for a MySQL root password.
#
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-storage-service


# 6. Configure the storage service.
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/storage /etc/nginx/sites-enabled/storage


# 7. Upgrade pip.
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py


# 8. Install the Archivematica packages.
#    We set DEBIAN_FRONTEND so we don't get asked for a MySQL root password when
#    installing MCP server, and mail configuratin in MCP client.  (See also: step 5.)
#
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-server
apt-get install --yes archivematica-dashboard
DEBIAN_FRONTEND=noninteractive apt-get install --yes archivematica-mcp-client


# 9. Configure the dashboard.
ln -s /etc/nginx/sites-available/dashboard.conf /etc/nginx/sites-enabled/dashboard.conf


# 10. Start Elasticsearch.  We're using hosted Elasticsearch so we don't need this.


# 11. Start the remaining services
service clamav-freshclam restart
service clamav-daemon start
service gearman-job-server restart
service archivematica-mcp-server start
service archivematica-mcp-client start
service archivematica-storage-service start
service archivematica-dashboard start
service nginx restart
systemctl enable fits
service fits start
