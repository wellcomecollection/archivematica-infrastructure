# Table of contents

* [Introduction](README.md)
* [High-level design](high-level-design.md)

## Storing born-digital files

* [Creating a transfer package](storing-born-digital-files/creating-a-transfer-package.md)
* [Upload a transfer package to S3](storing-born-digital-files/upload-a-transfer-package-to-s3.md)
* [Check a package was stored successfully](storing-born-digital-files/check-a-transfer-package-is-stored.md)
* [Downloading a package from the storage service](storing-born-digital-files/downloading-a-package-from-the-storage-service.md)
* [Following a package in the dashboard](storing-born-digital-files/following-a-package-in-the-dashboard.md)

## Service architecture

* [How does Archivematica work?](service-architecture/how-does-archivematica-work/README.md)
  * [The Archivematica apps](service-architecture/how-does-archivematica-work/archivematica-apps.md)
  * [Microservices, tasks and jobs](service-architecture/how-does-archivematica-work/microservices-tasks-and-jobs.md)
  * [Gearman, ElastiCache, and the MCP server/client](service-architecture/how-does-archivematica-work/gearman-elasticache-and-the-mcp-server-client.md)
* [How is our deployment unusual?](service-architecture/how-is-our-deployment-unusual/README.md)
  * [What are our extra services?](service-architecture/how-is-our-deployment-unusual/what-are-our-extra-services.md)
  * [ECS containers on EC2, not Fargate](service-architecture/how-is-our-deployment-unusual/unusual-aspects-of-our-deployment.md)
  * [Why we forked Archivematica](service-architecture/how-is-our-deployment-unusual/archivematica-forks.md)
* [How it fits into the wider platform](service-architecture/how-it-fits-into-the-wider-platform.md)

## About our deployment

* [Using Wellcome catalogue identifiers](about-our-deployment/external-identifiers.md)
* [Different environments](about-our-deployment/different-environments.md)
* [Working storage: MySQL, Redis, and EBS](about-our-deployment/working-storage-mysql-redis-and-ebs.md)

## Administering Archivematica

* [Bootstrapping a new Archivematica stack](administering-archivematica/bootstrapping.md)
* [User management](administering-archivematica/user-management/README.md)
  * [How to add or remove users](administering-archivematica/user-management/add-or-remove-users.md)
  * [Authentication with Azure AD](administering-archivematica/user-management/authentication.md)
* [Upgrading to a new version of Archivematica](administering-archivematica/upgrading-to-a-new-version-of-archivematica.md)
* [Running an end-to-end test](administering-archivematica/running-an-end-to-end-test.md)

## Debugging Archivematica

* [Troubleshooting known errors](debugging-archivematica/troubleshooting-known-errors/README.md)
  * [Timeout waiting for network interface provisioning to complete](debugging-archivematica/troubleshooting-known-errors/troubleshooting.md)
  * [401 Unauthorized when the s3\_start\_transfer Lambda tries to run](debugging-archivematica/troubleshooting-known-errors/troubleshooting-1.md)
  * ["pull access denied" when running containers (and other ECS agent issues)](debugging-archivematica/troubleshooting-known-errors/troubleshooting-2.md)
  * ["Unauthorized for url" when logging in](debugging-archivematica/troubleshooting-known-errors/troubleshooting-3.md)
* [Restarting services if a task is stuck](debugging-archivematica/restarting-services-if-a-task-is-stuck.md)
* [SSH into the Archivematica container hosts](debugging-archivematica/ssh-into-container-hosts.md)
