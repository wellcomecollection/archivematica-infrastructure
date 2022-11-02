# Restarting services if a task is stuck

Sometimes a task will get stuck in the Archivematica dashboard. A common debugging technique is to restart all the services, usually using the ECS console.

The MCP Client/Server tasks can get stuck if there's an issue with the MySQL database, e.g. if the database server has been rebooted:

```
OperationalError: (2006, 'MySQL server has gone away')
```

If you don't want to restart all the services, here are some notes on restarting individual services and the potential impact:

* Restarting the MCP client tends to be okay. Not all tasks cope with being restarted – if the task doesn't expect to be run twice, you may fail the entire transfer/ingest; if so, you just have to retry the whole thing, sorry.
* Restarting the MCP server is more disruptive, and seems to cause all in-flight transfers/ingests to be dropped. I've seen it get stuck once or twice, but it's unusual.
* Restarting the Gearman server is probably fine (all the data should be in Redis), but I've never tried it. Gearman has been pretty robust and never been the source of issues.
