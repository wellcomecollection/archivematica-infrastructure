# Working storage: MySQL, Redis, and EBS

Archivematica has two forms of working storage.

## MySQL database: RDS

The MySQL database includes:

* the processing config – what steps to run when
* a record of all the tasks that Archivematica has performed
* the Archivematica users and other settings

We use Amazon RDS as our MySQL database.

## Task manager: Redis/ElastiCache

Archivematica uses a Redis instance to manage in-flight tasks (see [Gearman, ElastiCache, and the MCP server/client](../service-architecture/how-does-archivematica-work/gearman-elasticache-and-the-mcp-server-client.md) for more details).

We use Amazon ElastiCache as our Redis instance.

## Shared file system: EBS

Archivematica uses a shared file system to pass files between tasks. All the services have access to the same volume, so a service can say _"get the file from path A"_ and another service can pick that up.

We use an EBS volume, which is mounted on the EC2 instance and shared between all the containers.
