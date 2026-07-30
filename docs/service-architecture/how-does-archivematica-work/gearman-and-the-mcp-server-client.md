# Gearman and the MCP server/client

Archivematica also has microservices in the sense we use them in the rest of the platform: independent containers running in ECS.

![](../../images/mcp\_architecture.svg)

The _MCP server_ is a scheduler written as part of Archivematica. It decides what tasks (in the sense described above) need to be run. It tells the _Gearman server_ about these tasks.

_Gearman_ is [an open-source framework](http://gearman.org/) for distributing tasks between machines. Our Gearman server uses its built-in, in-memory queue. Archivematica submits MCP work as foreground Gearman jobs, so these jobs are not recovered from a persistent queue after a Gearman restart. An interrupted transfer or ingest may fail and need to be retried.

The _MCP client_ picks up tasks from Gearman, and actually does the work -- for example, moving a file from A to B. It then reports the results back to Gearman. You can have multiple instances of the MCP client, and the computational resources available to each client are a dominant factor in the speed of processing in Archivematica.

So the lifecycle of a task is as follows:

* The MCP server schedules a task, and sends it to Gearman
* Gearman forwards the task to an MCP client
* The MCP client performs the task, and reports the result back to Gearman
* Gearman forwards the result to the MCP server, which then displays the result in the dashboard, and decides what task to run next

These services write the result of their processing to a MySQL database, which uses RDS.
