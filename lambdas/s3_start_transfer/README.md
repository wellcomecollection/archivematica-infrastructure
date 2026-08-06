# s3_start_transfer

This Lambda tells Archivematica to process transfer packages which are uploaded to a "transfer source" S3 bucket.
A transfer package is a zip file containing the files, plus some metadata (including our catalogue reference and/or accession number).

*   For archivists, this means they can start processing a transfer package by uploading it to S3, rather than using the Archivematica dashboard.

*   For the platform team, this means we can do some checks on packages before they're sent to Archivematica (e.g. that the metadata has been supplied correctly).



## How it works

```mermaid
graph TD
    A[User uploads package<br/>to S3] -->|S3 PutObject notification| L{Lambda checks package<br/>has correct structure<br/>and metadata}
    L -->|passes checks| S[trigger Archivematica transfer,<br/>upload 'success' log and<br/>tag S3 object]
    L -->|fails checks| F[upload 'failed' log]

    classDef failedNode fill:#e01b2f,stroke:#e01b2f,fill-opacity:0.15
    class F failedNode

    classDef successNode fill:#b0f7e2,stroke:#0b7051,fill-opacity:0.35
    class S successNode

    classDef genericNode fill:#e8e8e8,stroke:#8f8f8f
    class A,L genericNode
```

When a user uploads a package to the "transfer source" S3 bucket, this Lambda is triggered by a bucket notification.
It then runs a series of checks on the transfer package, e.g.:

*   does it have a `metadata.csv` in the right place?
*   does the `metadata.csv` have the right fields?
*   is the package structured correctly?

It records a success/fail result by uploading a small log file alongside the original file, which includes instructions if the transfer package is rejected -- so users can diagnose issues without leaving S3.

If it starts a transfer successfully, it tags the S3 object with the transfer ID.
The [transfer monitor Lambda](../transfer_monitor) uses these tags to report Archivematica successes and failures and remove successfully stored packages from the transfer bucket.



## Deployment

This Lambda is automatically deployed with the latest version whenever you apply Terraform in `stack_staging` or `stack_prod`.



## Running tests

The Lambda runs on Python 3.14. Install `uv`, then create a virtual environment
and install the locked test dependencies from this directory:

```console
$ uv venv --python 3.14
$ source .venv/bin/activate
$ uv pip sync test_requirements.txt
$ coverage run -m pytest
$ coverage report
```



## Maintaining test dependencies

`test_requirements.in` lists the direct test dependencies and
`test_requirements.txt` is the compiled lock file. Do not edit the lock file
directly. These dependencies are only used for local testing; Terraform does
not include them in the Lambda deployment package.

After changing `test_requirements.in`, or when upgrading all test dependencies,
regenerate the lock file for the Lambda's Python version:

```console
$ uv pip compile --python-version 3.14 --upgrade test_requirements.in --output-file test_requirements.txt
$ uv pip sync test_requirements.txt
$ coverage run -m pytest
```

To upgrade a single dependency while retaining the other locked versions, use
`--upgrade-package` instead:

```console
$ uv pip compile --python-version 3.14 --upgrade-package moto test_requirements.in --output-file test_requirements.txt
```



## Debugging notes

*   If you see a 401 Response from the Archivematica storage service in the CloudWatch Logs, check the API keys in the Lambda config are up-to-date.

*   If you get an "unable to find location" error, such as:

    ```
    Unable to find location for wellcomecollection-archivematica-staging-transfer-source:MS5520.zip: StoragePathException
    Traceback (most recent call last):
      File "/var/task/s3_start_transfer.py", line 200, in main
        target_path = get_target_path(bucket, directory, key_path)
      File "/var/task/s3_start_transfer.py", line 118, in get_target_path
        return find_matching_path(s3_sources["objects"], bucket, directory, key)
      File "/var/task/s3_start_transfer.py", line 150, in find_matching_path
        raise StoragePathException("Unable to find location for %s:%s" % (bucket, key))
    s3_start_transfer.StoragePathException: Unable to find location for wellcomecollection-archivematica-staging-transfer-source:MS5520.zip
    ```

    The Lambda may be trying to initiate a transfer from part of the bucket which isn't configured as a transfer source in Archivematica.

    We should have two top-level folders configured as transfer sources: `/born-digital` and `/born-digital-accessions`.
    To fix, set up these folders as transfer sources.

    See the bootstrapping docs elsewhere in this repo.
