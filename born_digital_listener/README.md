# born_digital_listener

The **born digital listener** sends SNS notifications about new born-digital bags that have been stored in Archivematica.
IIIF Builder consumes these notifications, registers the material with DLCS, and builds IIIF Presentation resources.

The listener subscribes to the [SNS notifications of new bags][storage_firehose] and filters the output rather than modifying Archivematica.

[storage_firehose]: https://github.com/wellcomecollection/storage-service/blob/main/docs/howto/get-notifications-of-stored-bags.md
