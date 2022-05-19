# Troubleshooting

This document has some notes on errors seen in our Archivematica deployment, and how to fix them:

*   [Timeout waiting for network interface provisioning to complete](#timeout_provisioning)
*   [401 Unauthorized when the s3_start_transfer Lambda tries to run](#401_lambda)
*   ["pull access denied" when trying to run containers](#ecs_ec2_state_issues)
*   [Unable to log in because "Unauthorized for url"](#unauthorized_azure)



<h2 id="timeout_provisioning">
  Timeout waiting for network interface provisioning to complete
</h2>

You may see this error in the ECS console as the reason a task stopped (or rather, failed to stop):

![](provisioning_timeout.png)

This means that when the EC2 container host tries to place a new task, something goes wrong when it sets up the networking.
This can happen if the same task has been stopped and restarted repeatedly.

The easiest fix is to terminate the EC2 container hosts, and wait for them to be restarted by the autoscaling group.



<h2 id="401_lambda">
  401 Unauthorized when the s3_start_transfer Lambda tries to run
</h2>

We have an s3_start_transfer Lambda which is meant to notice uploads to the transfer_soure bucket, and trigger a new transfer process in Archivematica.
If that's not working, and you see this in the CloudWatch logs:

> Response: <Response [401]>

it might be a sign that the Lambda has bad credentials for the Archivematica API.

These are kept in Parameter Store, then injected into the Lambda by Terraform (see `transfer_lambda.tf`).



<h2 id="ecs_ec2_state_issues">
  EC2/ECS issues
</h2>

It is possible for the ECS agent running on an EC2 host to get into a bad state that prevents containers from starting on the host.

An error we have seen resulting from this is:

> CannotPullContainerError: Error response from daemon: pull access denied

Although permissions are correctly configured. Restarting the ECS agent on the EC2 host machine resolved that issue.

There may be other issues which arise from having a long running EC2 instance as a cluster host. Out of date or broken ECS agent, or exhausting file system space are potential issues. Restarting the EC2 instance may result in having to perform step 8 of the [bootstrapping.md](bootstrapping procedure.

An EC2 host can be manually inspected by SSHing to that instance using the SSH key available in AWS SecretsManager at `ssh/wellcomedigitalworkflow` in the `platform` account. You will need to SSH via the "bastion host" to gain access.

```sh
ssh -A -i ~/.ssh/wellcomedigitalworkflow ec2-user@bastion-host.in.aws
ssh -i ~/.ssh/wellcomedigitalworkflow ec2-user@cluster-host.in.aws
```

You can then inspect running containers on the cluster host using standard `docker` commands. The ECS agent runs as a container on the EC2 host and will be automatically restarted if it is killed.



<h2 id="unauthorized_azure">
  Unauthorized for logging in to Azure
</h2>

In October 2021, we saw issues logging into Archivematica.
Logged-in users would see an internal server error in the dashboard, and we saw this error in the logs:

> HTTPError: 401 Client Error: Unauthorized for url: https://login.microsoftonline.com/3b7a675a-1fc8-4983-a100-cc52b7647737/oauth2/v2.0/token

This means the Archivematica client secret in Azure AD has expired.
You can tell this is the case when you log into the [Azure portal](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/Overview/appId/8dccdaeb-e67e-417f-bebc-7aab4abade28/isMSAApp/) and see this screen:

<img src="images/expired_secret.png">

If so, follow the instructions [to regenerate the Azure AD secrets](../azure_ad_login).
