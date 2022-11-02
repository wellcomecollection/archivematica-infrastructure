# Unusual aspects of our deployment



Archivematica predates a lot of technologies and techniques we now take for granted, e.g. managed cloud services, containers as a way to run services. This means it's deployed a little differently to our other services.

### **Archivematica uses the file system and a Redis cache to manage tasks**

Most of our services manage work using SQS queues, but Archivematica uses a different approach:

* Tasks are passed as files on a shared file system. When a process is done, the file is written to a particular directory. Another process is watching that directory, and starts when it sees a file be written.
* The MCP server/client and Gearman services manage their tasks in Redis, which we run as Elasticache.

### **We run all our tasks on a single EC2 instance with a shared EBS volume**

This mimics how Archivematica expects to be run: all the services on the same server. We still package the services as Docker containers, orchestrated by ECS, so things behave similar to our other services -- but we're mounting a persistent EBS volume inside the containers to provide the shared file system.

As much as possible, these Docker images look similar to our other services, e.g. they're published by Buildkite, stored in ECR, managed by ECS.

We use EBS rather than EFS because Archivematica expects the file system to be synchronous. We did try using EFS, but we couldn't get it to behave reliably.
