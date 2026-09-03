# Restarting services if a task is stuck

Sometimes a task will get stuck in the Archivematica dashboard. Restarting services may help, but it can also fail in-flight transfers or cause completed work to run twice.

Before restarting a service, confirm that you are working in the intended environment, record the affected transfer or ingest UUID and its current state, and check whether any other work is in progress.
Restart the smallest possible set of services, then wait for the ECS service to return to its expected task count and check its logs before retrying the transfer.

The MCP Client/Server tasks can get stuck if there's an issue with the MySQL database, e.g. if the database server has been rebooted:

```
OperationalError: (2006, 'MySQL server has gone away')
```

If you don't want to restart all the services, here are some notes on restarting individual services and the potential impact:

* Restarting an MCP client is less disruptive than restarting the MCP server, but not all tasks tolerate being run twice. A restarted task may fail the entire transfer or ingest.
* Restarting the MCP server can interrupt every in-flight transfer or ingest, so only restart it when the impact is understood.
* Restarting Gearman interrupts foreground jobs held in its in-memory queue. After Gearman returns, restart the MCP clients and wait for the service to reach its expected task count. Confirm in the logs that the workers have registered and connected to Gearman before restarting the MCP server. This is the recovery sequence recorded for this deployment, but it does not prevent new work from arriving unless transfer intake has been paused separately.

After any restart, verify the affected transfer in the dashboard rather than assuming it resumed successfully.
