# How to upload a transfer package to S3

Once you have [created your transfer package](./create-a-transfer-package.md) as a zip file, you need to upload it to S3 for processing.

Where you upload it depends on what sort of package this is:

*   Does this contain real files, or is it just for testing?

    -   If real files, then use the bucket **wellcomecollection-archivematica-transfer-source**
    -   If you're just testing, then use the bucket **wellcomecollection-archivematica-staging-transfer-source**

*   Does this contain catalogued data, or is it an uncatalogued accession?

    -   If catalogued, then upload into the prefix **born-digital**
    -   If uncatalogued, then upload into the prefix **born-digital-accessions**

Pick a descriptive name for your transfer package, then upload it to S3.

For example, if you were using the AWS CLI and you had an uncatalogued accession to upload in prod:

```
aws s3 cp 1234.zip s3://wellcomecollection-archivematica-transfer-source/born-digital-accessions/1234.zip
```

A few seconds after you upload, you should see a log file appear in the bucket, with either "success" or "failed" in the name.

*   If it says "success" – your package has been accepted and is being sent to Archivematica
*   If it says "failed" – your package has not been accepted; it's structured incorrectly.
    Download the log file for instructions on how to fix it.
