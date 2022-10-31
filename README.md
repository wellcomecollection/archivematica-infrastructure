# archivematica-infrastructure

[![Build status](https://badge.buildkite.com/110c72015ef5319e8fbec009b7f3e477ccc7ccab1a732e5194.svg)](https://buildkite.com/wellcomecollection/archivematica-infrastructure)

This is the configuration for our Archivematica deployment.

Archivematica is an open-source service for processing born-digital archives, which we use to:

*   Analyse files in the archive – including virus scanning, file format identification, and fixity checking
*   Create a metadata description of the archive that can be read by downstream applications
*   Upload the archive to our permanent cloud storage

The original application was created by [Artefactual], and we run a lightly modified fork.

[Artefactual]: https://www.artefactual.com/



## Requirements

Our deployment is designed to:

*   Allow archivists to manage our born-digital collections
*   Ensure our born-digital collections are processed consistently and stored safely
*   Avoid "reinventing the wheel" when processing born-digital archives



## High-level design

```mermaid
graph LR
    S[(S3)] -->|transfer package| Ar{Archivematica}
    Ar -->|BagIt bag| WSS[(Wellcome<br/>storage service)]
    WSS --> I{IIIF builder}

    classDef archivematicaNode fill:#e9702e,stroke:#e9702e,fill-opacity:0.15
    class Ar archivematicaNode

    classDef genericNode fill:#e8e8e8,stroke:#8f8f8f
    class S,WSS,I genericNode
```

The user uploads a "transfer package" to an S3 bucket.
This contains the born-digital files, plus some metadata.

Anything that gets uploaded to this bucket is sent to Archivematica for processing.
It does its checking and analysis, and creates a [METS file] which describes the contents of the archive.
This becomes part of the BagIt bag, which is uploaded to [our storage service].

Successfully stored archives are then sent to iiif-builder, which uses the METS file to construct a IIIF Presentation manifest to describe this archive.
(If we can make the archive publicly available.)

[our storage service]: https://github.com/wellcomecollection/storage-service
[METS file]: https://en.wikipedia.org/wiki/Metadata_Encoding_and_Transmission_Standard



## Documentation

We have [documentation](./docs) about our Archivematica deployment, which includes:

*   How-to guides explaining how to do common operations, e.g. create a new transfer package
Reference material explaining how the storage service works
Notes for developers who want to modify or extend the storage service



## Usage

We run two instances of Archivematica at Wellcome:

*   A ["prod" environment][prod] that holds our real collections
*   A ["staging" environment][staging] that we use for testing and development

Each instance of the Archivematica is completely separate, and talks to a [separate instance of the storage service][storage_environments].
They don't share any files or storage.

We distinguish between two categories of born-digital archive:

*   Catalogued collections, which have been appraised by an archivist and have a catalogue reference (e.g. PP/MDM/A/3/1a).
    These go in the `born-digital` space in the storage service.
*   Accessions, which is an uncatalogued collection of files received from a donor.
    These have an [accession number][accno] (e.g. 1234), and go in the `born-digital-accessions` space in the storage service.

[prod]: https://en.wikipedia.org/wiki/Deployment_environment#Production
[staging]: https://en.wikipedia.org/wiki/Deployment_environment#Staging
[storage_environments]: https://github.com/wellcomecollection/storage-service#usage
[accno]: https://en.wikipedia.org/wiki/Accession_number_(cultural_property)



## License

This repository includes some code from the Archivematica repository, which is licensed from Artefactual under AGPL v3.0.
There are separate LICENSE files in the root of trees that contain AGPL code.

The remainder of the repository is released under the MIT license.




## How-to

see also SharePoint docs

*   create a transfer package
*   Upload a transfer package
*   Check a package is stored
*   Download a package from storage service

archivematica dashboard:

*   log in to AM dashboard
*   following a package
*   add/remove users

## developer information

design principles:

*   why do we have forks? how do forks work? contribute upstream where possible
*   diff to other applications

reference material:

*   what are the services?
*   external identifiers
*   repo layout

how to:

*   How to deploy new images?
*   how do forks work?
*   troubleshooting
*   setting up SSO
*   bootstrapping
*   end-to-end testing

---


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
*   [Authentication with Azure AD](docs/authentication.md) -- notes on how staff log in to Archivematica.
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
