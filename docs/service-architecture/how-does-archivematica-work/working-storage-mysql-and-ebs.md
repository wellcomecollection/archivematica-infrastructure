# Working storage: MySQL and EBS

Archivematica has two forms of working storage.

## MySQL database: RDS

The MySQL database includes:

* the processing config – what steps to run when
* a record of all the tasks that Archivematica has performed
* the Archivematica users and other settings

We use Amazon RDS as our MySQL database.

## Shared file system: EBS

Archivematica uses a shared file system to pass files between tasks. The dashboard, Storage Service, MCP server, and MCP clients have access to the same volume, so one service can say _"get the file from path A"_ and another service can pick it up.

We use an EBS volume, which is mounted on the EC2 instance and shared between those containers.
Gearman does not use the shared volume, and ClamAV runs in Fargate and receives file contents as a stream.
