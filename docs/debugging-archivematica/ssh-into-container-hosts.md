# Connect to the Archivematica container hosts

It can be useful to open a shell on an Archivematica container host for debugging.
The hosts are in private subnets and are accessed with AWS Systems Manager Session Manager; they do not need a bastion host or inbound SSH access.

## Using the helper script

Before starting, install the AWS CLI and the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html), and obtain AWS credentials for the workflow account (`299497370133`).

With the standard Wellcome profiles, log in once using the `weco` SSO profile.
Then run the helper from the repository root using the `workflow-developer` profile, which assumes the role in the workflow account:

```shell
aws sso login --profile weco
env AWS_PROFILE=workflow-developer scripts/ssh_to_archivematica <prod|staging>
```

Do not run the helper without `AWS_PROFILE` unless your default AWS profile already targets the workflow account.
Running `aws sso login` refreshes the cached SSO session, but it does not change the profile used by subsequent commands.
A second SSO login is not necessary.

The script finds the active container instance registered with the selected ECS cluster, resolves its underlying EC2 instance ID, and starts an SSM session.
The profile name is a local choice; use `workflow-dev` or another name if that is how your credentials are configured.
The script verifies the effective account before looking up the container instance.

The EC2 host must be running and connected to ECS before the session can start.
The staging host is normally stopped outside office hours; if the script finds no connected container instance, check the host state before trying again.

## Using the AWS CLI directly

First find the ECS container instance.
Replace `staging` with `prod` when needed:

```shell
CLUSTER_NAME=archivematica-staging

CONTAINER_INSTANCE_ARN=$(env AWS_PROFILE=workflow-developer aws ecs list-container-instances \
  --region eu-west-1 \
  --cluster "$CLUSTER_NAME" \
  --status ACTIVE \
  --filter 'agentConnected == true' \
  --query 'containerInstanceArns[0]' \
  --output text)

EC2_INSTANCE_ID=$(env AWS_PROFILE=workflow-developer aws ecs describe-container-instances \
  --region eu-west-1 \
  --cluster "$CLUSTER_NAME" \
  --container-instances "$CONTAINER_INSTANCE_ARN" \
  --query 'containerInstances[0].ec2InstanceId' \
  --output text)
```

Then start the session:

```shell
env AWS_PROFILE=workflow-developer aws ssm start-session \
  --region eu-west-1 \
  --target "$EC2_INSTANCE_ID"
```

## Interesting locations on the file system

If you are trying to fix an issue with failing ingests, you may wish to look at these locations:

- `/ebs/pipeline-data/`: The folders containing "processing storage" for archivematica (including `currentlyProcessing`)
- `/ebs/var/archivematica/storage_service/`: The archivematica-storage-service working storage
