# archivematica-infrastructure

[![Build Status](https://travis-ci.org/wellcomecollection/archivematica-infra.svg?branch=main)](https://travis-ci.org/wellcomecollection/archivematica-infra)

Archivematica is a service for processing born-digital archives.

Users upload a transfer package which contains their files (e.g. a set of catalogued files), which get processed by Archivematica.
The processing includes file format identification, virus scanning, and checksum creation – and eventually returns a BagIt bag which is uploaded to the [Wellcome storage service](https://github.com/wellcomecollection/storage-service).

<img src="docs/images/high_level_architecture.svg">

We run Archivematica in Docker containers in Amazon ECS.
This repo contains our Terraform configurations that define our Archivematica deployment.

## Environments

We run two instances of Archivematica:

*   A ["prod" environment][prod] that holds our real collections
*   A ["staging" environment][staging] that we use for testing and development

Each instance of the Archivematica is completely separate, and talks to a [separate instance of the storage service][storage_environments].
They don't share any files or storage.

[prod]: https://en.wikipedia.org/wiki/Deployment_environment#Production
[staging]: https://en.wikipedia.org/wiki/Deployment_environment#Staging
[storage_environments]: https://github.com/wellcomecollection/storage-service#usage

## Our Archivematica repositories

Our Archivematica code is split across three repositories:

*   This repo - infrastructure definitions in Terraform
*   [wellcomecollection/archivematica](https://github.com/wellcomecollection/archivematica) – a forked version of the Artefactual repo.
    Originally this fork diverged more substantially from the Artefactual repo when we were adding support for OpenID Connect; at this point the difference is slight and we'll probably switch to using code from upstream.
*   [wellcomecollection/archivematica-storage-service](https://github.com/wellcomecollection/archivematica-storage-service) – a forked version of the Artefactual repo.
    This fork adds support for the [Wellcome storage service](https://github.com/wellcomecollection/storage-service) to Archivematica.

## Other documentation

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
