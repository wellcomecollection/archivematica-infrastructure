# How we handle external identifiers in Archivematica

We use the External-Identifier from the BagIt bag to store bags in the storage service (see [notes on identifiers][identifiers]).
By default, Archivematica uses the ingest UUID as the External-Identifier for the AIPs it creates, but this UUID has no meaning outside Archivematica.
We want to use our own identifiers (i.e. references from CALM) to store bags in the storage service.

We achieve this in two steps:

1.  When users upload bags, they include a `metadata.csv` file that includes our reference number as the Dublin Core identifier.
    e.g.

    ```
    filename,dc.identifier
    objects/,archivematica-dev/TEST/1
    ```

    would use the reference `archivematica-dev/TEST/1`.

2.  In our fork of Archivematica, before we store the AIP, we unpack the bag and write this reference as the External-Identifier.
    We move the Archivematica UUID to the Internal-Identifier field.

    You can see the code for this in [storage_service/locations/models/wellcome.py][wellcome.py].

[identifiers]: https://github.com/wellcomecollection/storage-service/blob/main/docs/explanations/identifiers.md
[wellcome.py]: https://github.com/wellcomecollection/archivematica-storage-service/blob/wellcome-storage-service/storage_service/locations/models/wellcome.py#L139-L288
