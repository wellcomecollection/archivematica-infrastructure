# gearman.errors.ExceededConnectionAttempts: Exceeded 1 connection attempt(s)

We have seen errors like this from MCP server, alongside packages stalling at the "Extract zipped transfer" job:

> gearman.errors.ExceededConnectionAttempts: Exceeded 1 connection attempt(s)

This can be fixed by restarting the MCP client tasks, followed by the MCP server task.

My hypothesis: the MCP server relies on Gearman, and I think it might struggle when it can't connect to it – that is, when there aren't any Gearman tasks running.
Even when Gearman comes back, it can't regain its connection.

## Restarting or replacing Gearman

Gearman is a singleton with stop-before-start deployments. Replacing it interrupts its in-memory queue and existing MCP connections, so prevent new uploads or submissions and plan the replacement while no transfers or ingests are running.

Use this sequence whenever Gearman is restarted or replaced:

1. Confirm in the dashboard that no transfers or ingests are running and that new transfer intake has been paused.
2. Stop the current Gearman task and allow its ECS service to replace it, or force a new deployment of the Gearman service.
3. Wait for the new Gearman task to be `RUNNING` on the EC2 container host and registered in service discovery, then check its logs for a successful start.
4. Restart the MCP client service. Wait for it to reach its expected task count and confirm in its logs that the workers have registered with Gearman.
5. Restart the MCP server service, wait for it to reach its expected task count, and confirm in its logs that it has connected to Gearman.
6. While normal transfer intake remains paused, run a controlled end-to-end transfer and check that it completes successfully.
7. Restore transfer intake.

To roll back a Gearman change, revert the Terraform configuration to a known-compatible version, review the plan, and apply it using the same idle-window and readiness checks.
