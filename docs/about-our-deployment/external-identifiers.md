# Using catalogue references and accession numbers

We use the External-Identifier from the BagIt bag to store bags in the Wellcome storage service (see [notes on identifiers](https://github.com/wellcomecollection/storage-service/blob/main/docs/explanations/identifiers.md)). By default, Archivematica uses the ingest UUID as the External-Identifier for the AIPs it creates, but this UUID has no meaning outside Archivematica. We use a catalogue reference or accession number instead.

The S3 prefix determines which automated workflow and metadata schema are used.
Packages uploaded under `born-digital/` use the `born_digital` workflow and include their catalogue reference as the Dublin Core identifier, e.g.

```
filename,dc.identifier
objects/,PP/MDM/A/3/1a
```

Packages uploaded under `born-digital-accessions/` use the `b_dig_accessions` workflow and include their collection reference and accession number, e.g.

```
filename,collection_reference,accession_number
objects/,SA/TIH,2314_2
```

Before storing the AIP, our Archivematica Storage Service overlay unpacks the bag and derives a slash-delimited common prefix from all the Dublin Core identifiers in the AIP METS file.
If it does not find one, it uses the accession number from the transfer METS file and routes the bag to the corresponding `-accessions` space.
Accession metadata should not include `dc.identifier`, because a Dublin Core identifier takes precedence over the accession number and prevents routing to the `-accessions` space.
A package whose identifier starts with `archivematica-dev/TEST` is routed to the `testing` space instead.

The overlay writes the selected reference to the BagIt External-Identifier and writes the Archivematica UUID to the Internal-Sender-Identifier field.
It records the selected reference and space on the Archivematica Storage Service package record.
Fetching stored packages back through Archivematica is not implemented.

You can see this behaviour in [the Wellcome storage model](https://github.com/wellcomecollection/archivematica-infrastructure/blob/main/archivematica-apps/archivematica-storage-service/overlay/src/archivematica/storage_service/locations/models/wellcome.wellcome.py).
