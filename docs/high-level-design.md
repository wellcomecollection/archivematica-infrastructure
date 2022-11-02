---
description: What does it look like from the outside?
---

# High-level design

Archivists upload packages containing born-digital files to an S3 bucket (the "transfer source bucket").

These packages are then processed by Archivematica. It does various processing steps and analysis, and creates [a METS file](https://en.wikipedia.org/wiki/Metadata\_Encoding\_and\_Transmission\_Standard) which describes the contents of the archive. The files and the metadata get packaged in a BagIt bag, which is uploaded to the Wellcome storage service for permanent storage.

Successfully stored archives are then sent to iiif-builder, which uses the METS file to construct a IIIF Presentation manifest to describe this archive. (If we can make the archive publicly available.)
