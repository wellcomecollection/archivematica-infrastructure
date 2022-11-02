# Different environments

We run two instances of Archivematica at Wellcome:

* A ["prod" environment](https://en.wikipedia.org/wiki/Deployment\_environment#Production) that holds our real collections
* A ["staging" environment](https://en.wikipedia.org/wiki/Deployment\_environment#Staging) that we use for testing and development

Each instance of the Archivematica is completely separate, and talks to a [separate instance of the storage service](https://github.com/wellcomecollection/storage-service#usage). They don't share any files or storage.

We distinguish between two categories of born-digital archive:

* Catalogued collections, which have been appraised by an archivist and have a catalogue reference (e.g. PP/MDM/A/3/1a). These go in the `born-digital` space in the storage service.
* Accessions, which is an uncatalogued collection of files received from a donor. These have an [accession number](https://en.wikipedia.org/wiki/Accession\_number\_\(cultural\_property\)) (e.g. 1234), and go in the `born-digital-accessions` space in the storage service.
