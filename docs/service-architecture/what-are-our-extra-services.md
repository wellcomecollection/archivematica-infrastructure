# What are our extra services?

We've written several of our own services which sit around Archivematica.

<figure><img src="../.gitbook/assets/Untitled 2.png" alt=""><figcaption></figcaption></figure>

The [**s3\_start\_transfer Lambda**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/s3\_start\_transfer) **** watches for uploads to the S3 transfer bucket. It checks that new transfer packages are correctly formatted, and if so, it sends them to Archivematica for processing. It uploads a feedback log explaining if the package was accepted.

* For archivists, this means they can start processing a transfer package by uploading it to S3, rather than using the Archivematica dashboard.
* For the platform team, this means we can do some checks on packages before they're sent to Archivematica (e.g. that the metadata has been supplied correctly).

The [**start\_test**_**\_**_**transfer Lambda**](https://github.com/wellcomecollection/archivematica-infrastructure/tree/main/lambdas/start_test_transfer) gives us a&#x20;

\
\
