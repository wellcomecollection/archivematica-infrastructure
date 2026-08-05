import csv
import datetime as dt
import io
import os
import os.path
import traceback
import urllib.error
import zipfile

import boto3

import archivematica
from archivematica import choose_processing_config
from big_s3 import S3File
from idempotency import S3EventIdentity
from log_handler import Logger
from verify_transfer_packages import (
    VerificationFailure,
    verify_has_a_metadata_csv,
    verify_only_metadata_and_rights_csv_in_metadata_dir,
    verify_metadata_csv_has_accession_fields,
    verify_metadata_csv_has_dc_identifier,
    verify_package,
    extract_metadata,
)


_RETRYABLE_HTTP_STATUS_CODES = {408, 409, 425, 429}


def _write_log(sess, logger, bucket, key, result, log_id, event_time, tags=None):
    s3 = sess.client("s3")

    log_key = ".".join([key, result, event_time, log_id[:12], "log"])

    print(f"Writing user log to s3://{bucket}/{log_key}")

    s3.put_object(
        Bucket=bucket,
        Key=log_key,
        Body=logger.text(),
        # The object is uploaded by a Lambda running in the workflow account,
        # but the transfer bucket is owned by the digitisation bucket.
        #
        # Give full control to the digitisation account, so people in that
        # account (e.g. archivists) can download/clean up the files.
        ACL="bucket-owner-full-control",
    )

    if tags:
        s3.put_object_tagging(
            Bucket=bucket,
            Key=log_key,
            Tagging={
                "TagSet": [
                    {"Key": key, "Value": value}
                    for key, value in tags.items()
                    if value is not None
                ]
            },
        )


def verify_s3_package(sess, *, logger, bucket, key, log_id, event_time):
    print(f"Running verifications on s3://{bucket}/{key}")
    s3 = sess.resource("s3")
    s3_object = s3.Object(bucket, key)
    s3_file = S3File(s3_object=s3_object)

    verifications = [
        # These checks require us to build the entire list, which takes a long
        # time and times out on big transfers, so for now we skip them.
        # verify_all_files_not_under_single_dir,
        # verify_all_files_not_under_objects_dir,
        verify_has_a_metadata_csv,
        verify_only_metadata_and_rights_csv_in_metadata_dir,
    ]

    if key.startswith("born-digital-accessions/"):
        verifications.append(verify_metadata_csv_has_accession_fields)
    else:
        verifications.append(verify_metadata_csv_has_dc_identifier)

    with zipfile.ZipFile(s3_file) as zf:
        if not verify_package(logger=logger, zip_file=zf, verifications=verifications):
            _write_log(
                sess,
                logger,
                bucket=bucket,
                key=key,
                result="failed",
                log_id=log_id,
                event_time=event_time,
            )
            raise VerificationFailure("One of the verifications failed!")


def get_identifiers(*, s3, logger, bucket, key):
    print(f"Extracting accession number and dc.identifier from s3://{bucket}/{key}")
    s3_object = s3.Object(bucket, key)
    s3_file = S3File(s3_object=s3_object)

    with zipfile.ZipFile(s3_file) as zf:
        metadata = extract_metadata(zf)
        assert metadata is not None

        reader = io.StringIO(metadata)

        csv_reader = csv.DictReader(reader)
        rows = list(csv_reader)

        assert len(rows) == 1
        return {
            "accession_number": rows[0].get("accession_number"),
            "dc.identifier": rows[0].get("dc.identifier"),
        }


def _record_start_failure(sess, logger, *, bucket, key, err, log_id, event_time):
    logger.write(f"Error starting transfer: {err}")
    logger.write("Ask somebody to check the CloudWatch logs for more info")
    _write_log(
        sess,
        logger,
        bucket=bucket,
        key=key,
        result="failed",
        log_id=log_id,
        event_time=event_time,
    )

    print(f"Error starting transfer for s3://{bucket}/{key}")


def _record_package_failure(sess, logger, *, bucket, key, err, log_id, event_time):
    logger.write(f"Unable to read transfer package: {err}")
    _write_log(
        sess,
        logger,
        bucket=bucket,
        key=key,
        result="failed",
        log_id=log_id,
        event_time=event_time,
    )

    print(f"Invalid transfer package in s3://{bucket}/{key}")


def run_transfer(sess, *, event):
    bucket = event.bucket
    key = event.object_key
    logger = Logger()

    # Run some verifications on the object before we sent it to Archivematica.
    #
    # If the ZIP package is using deflate64, we can't uncompress it with Python.
    # For now, try to guess the accession number if it's an accession, or error
    # out if not.
    #
    # See https://github.com/wellcomecollection/platform/issues/4614
    try:
        try:
            verify_s3_package(
                sess,
                logger=logger,
                bucket=bucket,
                key=key,
                log_id=event.event_id,
                event_time=event.event_time,
            )
        except VerificationFailure:
            print(f"Verification error in s3://{bucket}/{key}")
            return

        identifiers = get_identifiers(
            s3=sess.resource("s3"), logger=logger, bucket=bucket, key=key
        )
    except (zipfile.BadZipFile, UnicodeDecodeError) as err:
        _record_package_failure(
            sess,
            logger,
            bucket=bucket,
            key=key,
            err=err,
            log_id=event.event_id,
            event_time=event.event_time,
        )
        return
    except NotImplementedError as err:
        if str(err) in {
            "compression type 9 (deflate64)",
            "That compression method is not supported",
        } and key.startswith("born-digital-accessions/"):
            print(
                f"Skipping verification for s3://{bucket}/{key}, deflate64-compressed ZIP"
            )
            identifiers = {
                "accession_number": os.path.basename(os.path.splitext(key)[0]),
                "dc.identifier": None,
            }
        else:
            print(f"Unable to decompress s3://{bucket}/{key}: {err}")
            return

    # Finish the work which can safely be repeated before submitting the transfer.
    try:
        processing_config = choose_processing_config(key)

        directory, key_path = key.strip("/").split("/", 1)
    except ValueError as err:
        _record_start_failure(
            sess,
            logger,
            bucket=bucket,
            key=key,
            err=err,
            log_id=event.event_id,
            event_time=event.event_time,
        )
        return

    # Identify the file's location on the AM storage service. A missing matching
    # path is a permanent configuration error; transport and service errors are
    # allowed to fail the invocation so Lambda can retry them.
    try:
        target_path = archivematica.get_target_path(
            bucket=bucket, directory=directory, key=key_path
        )
    except archivematica.StoragePathException as err:
        _record_start_failure(
            sess,
            logger,
            bucket=bucket,
            key=key,
            err=err,
            log_id=event.event_id,
            event_time=event.event_time,
        )
        return

    target_name = os.path.basename(key)
    try:
        transfer_id = archivematica.start_transfer(
            name=target_name,
            path=target_path,
            processing_config=processing_config,
            accession_number=identifiers["accession_number"],
            idempotency_key=event.event_id,
        )
    except archivematica.StartTransferException as err:
        _record_start_failure(
            sess,
            logger,
            bucket=bucket,
            key=key,
            err=err,
            log_id=event.event_id,
            event_time=event.event_time,
        )
        return
    except urllib.error.HTTPError as err:
        if not 400 <= err.code < 500 or err.code in _RETRYABLE_HTTP_STATUS_CODES:
            raise
        _record_start_failure(
            sess,
            logger,
            bucket=bucket,
            key=key,
            err=err,
            log_id=event.event_id,
            event_time=event.event_time,
        )
        return

    tags = {
        "Archivematica-TransferId": transfer_id,
        "Archivematica-ProcessingConfig": processing_config,
        "Archivematica-AccessionNumber": identifiers["accession_number"],
        "Archivematica-CatalogueIdentifier": identifiers["dc.identifier"],
        "Archivematica-S3EventTime": event.event_time,
    }

    sess.client("s3").put_object_tagging(
        Bucket=bucket,
        Key=key,
        Tagging={
            "TagSet": [
                {"Key": key, "Value": value}
                for (key, value) in tags.items()
                if value is not None
            ]
        },
    )

    logger.write("Started successful transfer!")
    logger.write(f"Archivematica transfer ID is {transfer_id}")
    _write_log(
        sess,
        logger,
        bucket=bucket,
        key=key,
        result="success",
        tags=tags,
        log_id=event.event_id,
        event_time=event.event_time,
    )

    print("Started transfer {}".format(transfer_id))


def main(event, context=None):
    sess = boto3.Session()
    first_failure = None

    for record in event["Records"]:
        try:
            run_transfer(sess, event=S3EventIdentity.from_record(record))
        except Exception as err:
            print(traceback.format_exc())
            print("Error thrown, skipping to next record...")
            if first_failure is None:
                first_failure = err

    if first_failure is not None:
        raise first_failure


if __name__ == "__main__":  # pragma: no cover
    sess = boto3.Session()

    run_transfer(
        sess,
        event=S3EventIdentity(
            bucket="wellcomecollection-archivematica-transfer-source",
            object_key="born-digital-accessions/WT_B_9_2_2.zip",
            event_name="ObjectCreated:Put",
            sequencer="manual",
            event_time=dt.datetime.now(dt.timezone.utc).isoformat(),
        ),
    )
