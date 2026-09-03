# Troubleshooting known errors

These pages describe errors we have seen in our Archivematica deployment and the steps which helped us investigate or recover from them.

Before changing a service or a file on the container host, confirm that you are working in the intended environment and check whether any transfers or ingests are running.
Some recovery actions interrupt in-flight work and may cause a task to run twice.

If the error is not listed here, start by checking [the application logs](../where-to-find-application-logs.md) and the stopped-task or service events in ECS.
