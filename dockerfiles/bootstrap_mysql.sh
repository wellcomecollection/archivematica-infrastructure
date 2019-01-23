#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o verbose

until mysql --host=mysql --port=3306 --user=root --password="$MYSQL_ROOT_PASSWORD"; do
  >&2 echo "MySQL is unavailable - sleeping"
  sleep 5
done

>&2 echo "MySQL is available - running commands"
exec mysql --host=mysql --port=3306 --user=root --password="$MYSQL_ROOT_PASSWORD" --execute "\
		DROP DATABASE IF EXISTS SS;
		CREATE DATABASE SS;
		GRANT ALL ON SS.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';
    DROP DATABASE IF EXISTS MCP;
    CREATE DATABASE MCP;
    GRANT ALL ON MCP.* TO 'archivematica'@'%' IDENTIFIED BY 'demo';"
