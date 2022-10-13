# born_digital_listener

The **born digital listener** sends SNS notifications about new born-digital bags that have been stored in Archivematica, which tell DLCS to build a IIIF manifest.

For ease of implementation, we're going to listen to the [SNS notifications of new bags][storage_firehose] and filter the output, rather than modify Archivematica.

[storage_firehose]: https://github.com/wellcomecollection/storage-service/blob/main/docs/howto/get-notifications-of-stored-bags.md
