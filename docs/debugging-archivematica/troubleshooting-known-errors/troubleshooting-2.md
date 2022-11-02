# "pull access denied" when running containers (and other ECS agent issues)

It is possible for the ECS agent running on an EC2 host to get into a bad state that prevents containers from starting on the host.

An error we have seen resulting from this is:

> CannotPullContainerError: Error response from daemon: pull access denied

Although permissions are correctly configured. Restarting the ECS agent on the EC2 host machine resolved that issue.

There may be other issues which arise from having a long running EC2 instance as a cluster host. Out of date or broken ECS agent, or exhausting file system space are potential issues. Restarting the EC2 instance may result in having to perform step 8 of the [bootstrapping procedure](../../administering-archivematica/bootstrapping.md).

It may also be useful to [SSH into the container host](../ssh-into-container-hosts.md) and poke around inside the containers.
