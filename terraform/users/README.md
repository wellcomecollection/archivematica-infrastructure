# users

This stack creates the IAM users for archivists to use with FileZilla Pro and Archivematica, which allows them to:

*   Upload transfer packages to the Archivematica uploads bucket
*   Download files from the storage service buckets

Because staff names are personal information, they aren't encoded here -- instead, there's a list of users in [a Parameter Store value][pms].

Each person gets a different IAM user, so we can remove IAM keys when somebody leaves Wellcome.

[pms]: https://eu-west-1.console.aws.amazon.com/systems-manager/parameters/archivists_s3_upload-usernames/description?region=eu-west-1&tab=Table

## How to create a new access/secret key pair

1.  Edit the Parameter Store entry to add the new person's name.
2.  Run a `terraform plan` / `terraform apply` to create the new IAM user.
3.  In the IAM console, create an access key pair.

## Older users

Some staff still have keys for the shared `archivists_s3_upload` user; ideally we should migrate everyone to individual IAM users/keys.
