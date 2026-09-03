# How it fits into the wider platform

Born-digital material which is processed by Archivematica is stored in the **Wellcome storage service**, which is the permanent storage for all our digital collections.

## Downstream notifications

The Wellcome storage service publishes a notification when it registers a new bag.
The born-digital listener receives these notifications and publishes events for the `born-digital` space to an SNS topic, which fans them out to subscribed queues.

The IIIF Builder WorkflowProcessor consumes one of these queues and uses the identifier to retrieve the stored METS and file information, register material with DLCS, and build IIIF Presentation resources.
The listener ignores events for accessions in `born-digital-accessions` and test packages in `testing`.
