# What are our extra services?

We've written several of our own services which sit around Archivematica.

<figure><img src="../.gitbook/assets/Untitled 2.png" alt=""><figcaption></figcaption></figure>

The [**s3\_start\_transfer Lambda**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/s3\_start\_transfer) watches for uploads to the S3 transfer bucket. It checks that new transfer packages are correctly formatted, and if so, it sends them to Archivematica for processing. It uploads a feedback log explaining if the package was accepted.

* For archivists, this means they can start processing a transfer package by uploading it to S3, rather than using the Archivematica dashboard.
* For the platform team, this means we can do some checks on packages before they're sent to Archivematica (e.g. that the metadata has been supplied correctly).

The [**start\_test**_**\_**_**transfer Lambda**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/start\_test\_transfer) gives us a way to do end-to-end testing of Archivematica. When you run it, it creates and uploads a new transfer package to the S3 bucket. This simulates the behaviour of an archivists.

We can then monitor that package being processed by Archivematica.

Any packages created this way are stored in a special `testing` space in the storage service, so they can be distinguished from real content.

The [**born-digital listener**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/born\_digital\_listener) **** sends notifications of newly-stored born-digital bags to an SNS topic. This tells iiif-builder about new born-digital content, and allows it to create a IIIF Presentation manifest for this archive.

The [**transfer monitor**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/transfer\_monitor) monitors the state of transfer packages in Archivematica. In particular, once a week it scans for new transfer packages in the transfer source bucket, and checks if they're in the storage service.

* If a package has been successfully stored, it deletes the copy in the source bucket
* If a package hasn't been successfully stored, it leaves the package as-is and logs a warning

It posts its results to the #wc-preservation channel in Slack, so we're alerted of any packages that didn't store correctly.
