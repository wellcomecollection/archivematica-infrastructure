# Introduction

**We use Archivematica to process and store our born-digital archives.**

This processing includes:

* Analysing files in the archive, like virus scanning, file format identification, and fixity checking
* Creating a metadata description of the archive that can be read by downstream applications
* Uploading the archive to our permanent cloud storage

Archivematica is an open-source application created by [Artefactual](https://www.artefactual.com/).

## Requirements

* Allow archivists to manage our born-digital collections
* Ensure our born-digital collections are processed consistently and stored safely
* Provide metadata in a consistent format that we can (eventually) use to display born-digital archives on wellcomecollection.org
* Avoid "reinventing the wheel" when processing born-digital archives

## Documentation

This GitBook space is meant for staff at Wellcome Collection to understand how our Archivematica deployment works, so they can use it, debug issues, and administer our deployment.

This includes:

* How-to guides explaining how to do common operations, e.g. create a new transfer package
* Reference material explaining how Archivematica works
* Notes for developers who want to administer or debug our Archivematica deployment

It should be read in conjunction with [the first-party Archivematica docs](https://www.archivematica.org/en/), because those docs mostly contain information specific to Wellcome.

## Repo

All our Archivematica-related code is in [https://github.com/wellcomecollection/archivematica-infrastructure](https://github.com/wellcomecollection/archivematica-infrastructure)

The READMEs in the repo have instructions for specific procedures, e.g. how to create new Docker images. This GitBook is meant to be a bit higher-level.
