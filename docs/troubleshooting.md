# Troubleshooting

This document has some notes on errors seen in our Archivematica deployment, and how to fix them:

*   [Timeout waiting for network interface provisioning to complete](#timeout_provisioning)
*   [401 Unauthorized when the s3_start_transfer Lambda tries to run](#401_lambda)



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
