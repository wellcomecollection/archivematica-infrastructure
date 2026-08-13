# s3_start_transfer

This Lambda tells Archivematica to process transfer packages which are uploaded to a "transfer source" S3 bucket.
A transfer package is a zip file containing the files, plus some metadata (including our catalogue reference and/or accession number).

*   For archivists, this means they can start processing a transfer package by uploading it to S3, rather than using the Archivematica dashboard.

*   For the platform team, this means we can do some checks on packages before they're sent to Archivematica (e.g. that the metadata has been supplied correctly).



## How it works

```mermaid
graph TD
    A[User uploads package<br/>to S3] -->|S3 PutObject notification| L{Lambda checks package<br/>has correct structure<br/>and metadata}
    L -->|passes checks| K[derive idempotency key<br/>from the S3 event]
    K --> S[trigger Archivematica transfer<br/>with Idempotency-Key]
    S --> C[tag S3 object and upload<br/>a stable 'success' log]
    S -->|temporary failure| R[fail the invocation so<br/>Lambda retries the event]
    C -->|temporary failure| R
    R --> L
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

## Rights CSV validation

The supported Wellcome transfer-package contract is documented in [Creating a transfer package](../../docs/storing-born-digital-files/creating-a-transfer-package.md).
The Lambda validates that contract locally before submitting a transfer; it does not call Archivematica's validation API.

The upstream reference for this contract is Archivematica's `qa/1.x` branch:

*   Archivematica's [`RightsValidator`](https://github.com/artefactual/archivematica/blob/qa/1.x/src/archivematica/dashboard/components/api/validators.py) defines the intended CSV schema, including allowed columns, basis-specific fields, documentation identifiers, and grant restrictions.
*   Archivematica's [`rights_from_csv.py`](https://github.com/artefactual/archivematica/blob/qa/1.x/src/archivematica/MCPClient/clientScripts/rights_from_csv.py) is the actual importer and therefore determines which values are persisted or cause an import failure.

These source links intentionally follow `qa/1.x`, while [the current image build](../../archivematica-apps/archivematica/build_and_publish_image.sh) pins a commit selected from that branch for reproducible future images.
An environment may still run an image produced by an earlier version of the build script.
The final upstream and Wellcome overlay revisions can vary as images are updated or environments are rolled independently.
To identify the exact revisions selected for deployment, inspect the `ecr_image_tags` variables in the [staging locals](../../terraform/stack_staging/locals.tf) or [production locals](../../terraform/stack_prod/locals.tf).
Each Archivematica image tag contains an upstream revision, which may be a commit SHA or a release tag, followed by the overlay commit.
For a release-tagged image, inspect the build script at the overlay commit and resolve the release tag in the upstream Archivematica repository.

These upstream implementations are not completely consistent, so the Lambda deliberately adds stricter checks where accepting a row would cause an unhandled import failure or silently discard metadata:

*   Every `objects/` path must resolve to a real, non-metadata file in the transfer package.
*   A populated basis-specific field is accepted only when `rights_from_csv.py` persists that field for the selected basis.
*   Any grant information requires both `grant_act` and `grant_restriction`, because the importer only persists a grant when `grant_act` has a value.
*   Any documentation identifier requires both `doc_id_type` and `doc_id_value`, following the upstream validator's stated requirement rather than its more permissive conditional.
*   Each normalized file, basis, and grant-act combination may appear only once, because the importer silently skips later duplicates.
*   Copyright rows cannot use `open` as their `end_date`, because the importer version selected from `qa/1.x` does not set the open-ended flag correctly for that basis.
*   Duplicate headings, malformed row widths, non-UTF-8 input, UTF-8 byte-order marks, and empty files are rejected with depositor-facing messages.

When `qa/1.x` or a deployed image revision changes, compare both upstream files with `verify_rights_csv_is_valid`, its tests, and the transfer-package documentation.
If the upstream validator and importer disagree, preserve importer compatibility first and document any intentionally stricter Wellcome rule.

## Idempotency

S3 and Lambda can deliver the same notification more than once.
The Lambda derives a SHA-256 identity from the notification's bucket, decoded object key, event type, sequencer, and version ID when present.
It sends that identity to Archivematica in the `Idempotency-Key` header on every attempt.

Archivematica returns the original Transfer UUID when the same request and key are replayed, including when an earlier response was lost after the Transfer was accepted.
A genuine replacement upload has a new S3 sequencer or version ID, so it receives a new key and starts a new Transfer.

Archivematica transport errors, server errors, and retryable HTTP responses fail the invocation, as do failures writing S3 success feedback.
Lambda can then redeliver the event without creating another Transfer.
Permanent submission errors write a failed user log and do not retry.
Package tags include the stable S3 event time, and user log names include a readable event timestamp and an event identity suffix so a retry overwrites the same log instead of creating a duplicate.
Invalid packages and permanent transfer-source configuration errors also write a failed user log and do not retry.

The header is optional and ignored by older Archivematica versions, but deploying this retry behaviour with those versions is unsafe because an uncertain submission can create duplicate Transfers.
Deploy idempotency-aware Dashboard and MCPServer images before deploying this Lambda version in an environment.
Safe replay guarantees apply only when the request is handled by Dashboard and MCPServer versions which support idempotent package submission.
During a mixed-version rollout, attempts handled by an older instance can still create duplicate Transfers.
Newer Archivematica versions retain keys for 90 days, which covers Lambda retries and events retained in the Lambda dead-letter queue.



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
