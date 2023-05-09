# gearman.errors.ExceededConnectionAttempts: Exceeded 1 connection attempt(s)

We have seen errors like this from MCP server, alongside packages stalling at the "Extract zipped transfer" job:

> gearman.errors.ExceededConnectionAttempts: Exceeded 1 connection attempt(s)

This can be fixed by restarting the MCP server task.

My hypothesis: the MCP server relies on Gearman, and I think it might struggle when it can't connect to it – that is, when there aren't any Gearman tasks running.
Even when Gearman comes back, it can't regain its connection.

The Gearman service should persist through a blue-green deployment, but there may be times when it goes down properly – for example, if we restart all the ECS tasks by hand.
If so, it's important to ensure that the MCP server task starts *after* Gearman.
