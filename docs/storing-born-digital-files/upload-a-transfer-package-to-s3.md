# Upload a transfer package to S3

Once you have [created your transfer package](creating-a-transfer-package.md) as a zip file, you need to upload it to S3 for processing.

Where you upload it depends on what sort of package this is:

* Does this contain real files, or is it just for testing?
  * If real files, then use the bucket **wellcomecollection-archivematica-transfer-source**
  * If you're just testing, then use the bucket **wellcomecollection-archivematica-staging-transfer-source**
* Does this contain catalogued data, or is it an uncatalogued accession?
  * If catalogued, then upload into the prefix **born-digital**
  * If uncatalogued, then upload into the prefix **born-digital-accessions**

Pick a descriptive name for your transfer package, then upload it to S3.

For example, if you were using the AWS CLI and you had an uncatalogued accession to upload in prod:

```
aws s3 cp 1234.zip s3://wellcomecollection-archivematica-transfer-source/born-digital-accessions/1234.zip
```

The `s3_start_transfer` Lambda runs as soon as a zip file is uploaded.
The staging container host is scheduled to run from 07:00 to 19:00 UTC, Monday to Friday.
If the host is stopped, Lambda retries a failed invocation twice and then sends the event to its dead-letter queue; it does not wait for staging to start again.

If no feedback log appears, do not upload another copy until a developer has checked the `s3_start_transfer` Lambda logs and dead-letter queue.

* If it says "success" – your package has been accepted and is being sent to Archivematica
* If it says "failed" – your package has not been accepted. Download the log to see whether the package needs correcting or a developer needs to investigate.
