# ECS containers on EC2, not Fargate

Most of our services run as Docker containers in ECS, on Fargate.

We do package the Archivematica apps as Docker containers, but they run on a single EC2 instance with [a shared EBS volume](../../about-our-deployment/working-storage-mysql-redis-and-ebs.md#shared-file-system-ebs), not in Fargate.

This mimics how Archivematica expects to be run: all the services on the same server. We still package the services as Docker containers, orchestrated by ECS, so things behave similar to our other services -- but we're mounting a persistent EBS volume inside the containers to provide the shared file system.

As much as possible, these Docker images look similar to our other services, e.g. they're published by Buildkite, stored in ECR, managed by ECS.

We use EBS rather than EFS because Archivematica expects the file system to be synchronous. We did try using EFS, but we couldn't get it to behave reliably.
