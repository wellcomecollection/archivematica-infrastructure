# Downloading a package from the storage service

If you store a package with Archivematica and you want to retrieve it later, you can download it from the storage service.

To do this, you need access to the underlying S3 buckets, e.g. using the `storage-developer` role or with AWS access keys configured in FileZilla Pro. If you don't have these, ask a developer in the #wc-platform-feedback channel in Slack.

## 1. Identify the correct bucket

* If you uploaded the package to **prod** Archivematica, then you want to look in the **wellcomecollection-storage** bucket.
* If you uploaded the package to **staging** Archivematica, then you want to look in the **wellcomecollection-storage-staging** bucket.

## 2. Identify the space

* If you uploaded a catalogued born-digital package, then the space is **born-digital**.
* If you uploaded a born-digital accession, then the space is **born-digital-accessions**.

## 3. Find the package in S3

Open the bucket; you should see a list of top-level folders, including **born-digital**, **born-digital-accessions** and **digitised**.

<figure><img src="../.gitbook/assets/Screenshot 2022-11-02 at 17.52.20.png" alt=""><figcaption></figcaption></figure>

Click on the space you identified in step 2. You should see a list of packages:

<figure><img src="../.gitbook/assets/Screenshot 2022-11-02 at 17.53.08.png" alt=""><figcaption></figcaption></figure>

Navigate to find the package you're looking for. If you have a hierarchical identifier like **PPCRI/1/a**, then you need to look in the corresponding folders – **PPCRI**, which should contain **1**, which should contain **a**.

You’ll get to a folder containing folders like **v1**, **v2**, **v3**, and so on. These are the individual versions of a package. Pick the latest version, and download all the files it contains.

**Note:** if a version doesn't contain any files, then it's a "shallow update" in the storage service – it updated the metadata, not the files. You can retrieve the files by downloading a previous version of the package.

