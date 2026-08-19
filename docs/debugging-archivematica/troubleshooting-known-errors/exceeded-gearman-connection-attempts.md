# gearman.errors.ExceededConnectionAttempts: Exceeded 1 connection attempt(s)

We have seen errors like this from MCP server, alongside packages stalling at the "Extract zipped transfer" job:

> gearman.errors.ExceededConnectionAttempts: Exceeded 1 connection attempt(s)

This can be fixed by restarting the MCP client tasks, followed by the MCP server task.

My hypothesis: the MCP server relies on Gearman, and I think it might struggle when it can't connect to it – that is, when there aren't any Gearman tasks running.
Even when Gearman comes back, it can't regain its connection.

## Rolling out a Gearman replacement

Gearman is a singleton with stop-before-start deployments. Replacing it interrupts its in-memory queue and existing MCP connections, so plan the replacement while no transfers or ingests are running.

Use this sequence to roll the change from staging to production:

1. Review the Terraform plan and confirm that the target image is `artefactual/gearmand:2.0.0-alpine` and that the ECS service will be replaced. The production rollout intentionally combines any pending image upgrade with the move to EC2.
2. Apply the staging stack from the pull request.
3. Wait for the new Gearman task to be `RUNNING` on EC2 and registered in service discovery. Terraform does not wait for the ECS service to reach steady state.
4. Restart the MCP client service, then restart the MCP server service. This lets the workers register with Gearman before the server schedules new work.
5. Run an end-to-end transfer in staging.
6. Merge the pull request only after the staging checks pass, then repeat the sequence for production during an idle maintenance window.

Rollback also replaces Gearman and must follow the same idle-window and MCP restart sequence. Reverting the EC2 migration returns Gearman to version 2.0.0 on Fargate; it does not restore an older image that may still have been running in production before the rollout.
