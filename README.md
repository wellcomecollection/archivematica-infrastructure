# Archivematica Infrastructure on ECS

[![Build Status](https://travis-ci.org/wellcomecollection/archivematica-infra.svg?branch=development)](https://travis-ci.org/wellcomecollection/archivematica-infra)

Dockerfiles & Terraform required to run Archivematica on AWS ECS.

You might find these docs helpful:

*   [Troubleshooting](docs/troubleshooting.md) -- notes on problems we've seen in our deployment, and how to fix them.

*   [Bootstrapping a stack](docs/bootstrapping.md) -- how we set up a fresh instance of Archivematica.


## Lambda development

The `s3_start_transfer` lambda initiates an Archivematica transfer when a file is uploaded to the watched Archivematica bucket (set up as an S3 transfer source in the Archivematica storage service).

If changes need to be made to the lambda, it can be tested with `make lambda-test` and then republished to s3 as a zipfile with `make lambda-publish`. A redeployment will be necessary so that Terraform can pick up the newly published lambda zipfile and upload it to the lambda service.

## Testing your changes to Archivematica

Once you've deployed a new version of Archivematica, you may want to test your changes by running a transfer package.

1.  In the workflow account, find the Lambda **archivematica-start_test_transfer-staging** (or prod).
2.  Run this Lambda.
    This will upload a new package to the Archivematica hot folder.
3.  Follow the progress of the package on the dashboard at <https://archivematica.wellcomecollection.org/transfer/>
