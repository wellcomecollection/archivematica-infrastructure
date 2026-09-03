---
description: What does it look like from the outside?
---

# High-level design

Archivists upload packages containing born-digital files to an S3 bucket (the "transfer source bucket").

These packages are then processed by Archivematica. It does various processing steps and analysis, and creates [a METS file](https://en.wikipedia.org/wiki/Metadata\_Encoding\_and\_Transmission\_Standard) which describes the contents of the archive. The files and the metadata get packaged in a BagIt bag, which is uploaded to the Wellcome storage service for permanent storage.

When a bag is stored in the `born-digital` space, the born-digital listener publishes a notification for the IIIF Builder workflow.
IIIF Builder uses the identifier to retrieve the stored METS and file information, register the material with DLCS, and build IIIF Presentation resources for material which can be made publicly available.
The listener does not forward notifications for the `born-digital-accessions` or `testing` spaces.
