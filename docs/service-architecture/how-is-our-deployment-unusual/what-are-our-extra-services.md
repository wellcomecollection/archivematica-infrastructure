# What are our extra services?

We've written several of our own services which sit around Archivematica.

<figure><img src="../../.gitbook/assets/Untitled 2 (1).png" alt=""><figcaption></figcaption></figure>

The [**s3\_start\_transfer Lambda**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/s3\_start\_transfer) watches for uploads to the S3 transfer bucket. It checks that new transfer packages are correctly formatted, and if so, it sends them to Archivematica for processing. It uploads a feedback log explaining if the package was accepted.

* For archivists, this means they can start processing a transfer package by uploading it to S3, rather than using the Archivematica dashboard.
* For the platform team, this means we can do some checks on packages before they're sent to Archivematica (e.g. that the metadata has been supplied correctly).

The [**start\_test\_transfer Lambda**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/start\_test\_transfer) gives us a way to do end-to-end testing of Archivematica. When you run it, it creates and uploads a new transfer package to the S3 bucket. This simulates the behaviour of an archivist.

We can then monitor that package being processed by Archivematica.

Any packages created this way are stored in a special `testing` space in the storage service, so they can be distinguished from real content.

The [**born-digital listener**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/born\_digital\_listener) sends notifications of newly-stored bags in the `born-digital` space to an SNS topic used by the IIIF Builder workflow.
It does not forward notifications for accessions or test packages, which are stored in different spaces.

The [**transfer monitor**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/transfer\_monitor) runs once a week and checks objects from the last 14 days which have an Archivematica Transfer ID tag.
For each tagged package, it looks for a matching METS file in the storage service.

* If a package has been successfully stored, it deletes the copy in the source bucket
* If it cannot find a matching stored package, it leaves the source package as-is and logs a warning

An object without a Transfer ID tag is not included in this report.
A reported failure means that no matching stored METS file was found during that check; it does not necessarily mean Archivematica has reached a terminal failure.

The monitor posts its results to Slack using the configured transfer-monitor webhook, so we're alerted to packages which need investigation.
