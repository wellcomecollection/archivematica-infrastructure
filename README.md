# Archivematica Infrastructure on ECS

[![Build Status](https://travis-ci.org/wellcometrust/archivematica-infra.svg?branch=development)](https://travis-ci.org/wellcometrust/archivematica-infra)

Dockerfiles & Terraform required to run Archivematica on AWS ECS.

## Getting credentials

This assumes you already have credentials for the `wellcomedigitalplatform` account.

You need credentials for the workflow account.

1.  Download the script for issuing temporary credentials: <https://github.com/alexwlchan/junkdrawer/blob/master/aws/issue_temporary_credentials.py>

2.  Run the script to set up credentials:

    ```console
    $ python issue_temporary_credentials.py --account_id=299497370133 --role_name=platform-team-assume-role --account_name=wellcomedigitalworkflow
    ```

You can then run `make tf-plan` and `make tf-apply` like normal.

The credentials will expire after 60 minutes; re-run the script to get a fresh set.

Note: we cannot use AssumeRole in the Terraform provider because we also need it when retrieving the Terraform vars file from the S3 bucket in the workflow account.
Later we might consider pushing this inside our wrapper.

## Lambda development

The `s3_start_transfer` lambda initiates an Archivematica transfer when a file is uploaded to the watched Archivematica bucket (set up as an S3 transfer source in the Archivematica storage service).

If changes need to be made to the lambda, it can be tested with `make lambda-test` and then republished to s3 as a zipfile with `make lambda-publish`. A redeployment will be necessary so that Terraform can pick up the newly published lambda zipfile and upload it to the lambda service.
