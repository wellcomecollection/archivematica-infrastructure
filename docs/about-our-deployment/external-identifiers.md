# Using Wellcome catalogue identifiers

We use the External-Identifier from the BagIt bag to store bags in the storage service (see [notes on identifiers](https://github.com/wellcomecollection/storage-service/blob/main/docs/explanations/identifiers.md)). By default, Archivematica uses the ingest UUID as the External-Identifier for the AIPs it creates, but this UUID has no meaning outside Archivematica. We want to use our own identifiers (i.e. references from CALM) to store bags in the storage service.

We achieve this in two steps:

1.  When users upload bags, they include a `metadata.csv` file that includes our reference number as the Dublin Core identifier. e.g.

    ```
    filename,dc.identifier
    objects/,archivematica-dev/TEST/1
    ```

    would use the reference `archivematica-dev/TEST/1`. This identifier gets written to the Archivematica METS file.
2.  In our fork of Archivematica, before we store the AIP, we unpack the bag, extract the reference from the METS file, and write it as the External-Identifier. We move the Archivematica UUID to the Internal-Identifier field.

    We record this reference in the Archivematica database so that Archivematica can retrieve the bag later (although we don't actually retrieve bags in Archivematica).

    You can see the code for this in [storage\_service/locations/models/wellcome.py](../../../archivematica-apps/archivematica-storage-service/overlay/storage\_service/locations/models/wellcome.wellcome.py).
