import csv
import datetime as dt
import io
import os
import os.path
import traceback
import urllib.parse
import zipfile

import boto3

import archivematica
from archivematica import choose_processing_config
from big_s3 import S3File
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


def _write_log(sess, logger, bucket, key, result, tags=None):
    s3 = sess.client("s3")

    timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    log_key = ".".join([key, result, timestamp, "log"])

    print(f"Writing user log to s3://{bucket}/{log_key}")

    s3.put_object(
        Bucket=bucket,
        Key=log_key,
        Body=logger.text(),
        Tagging={"TagSet":[
            {"Key": key, "Value": value}
            for key, value in tags.items()
            if value is not None
        ]},
        # The object is uploaded by a Lambda running in the workflow account,
        # but the transfer bucket is owned by the digitisation bucket.
        #
        # Give full control to the digitisation account, so people in that
        # account (e.g. archivists) can download/clean up the files.
        ACL="bucket-owner-full-control",
    )


def verify_s3_package(*, s3, logger, bucket, key):
    print(f"Running verifications on s3://{bucket}/{key}")
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
            _write_log(logger, bucket=bucket, key=key, result="failed")
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


def run_transfer(sess, *, bucket, key):
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
                s3=sess.resource("s3"), logger=logger, bucket=bucket, key=key
            )
        except VerificationFailure:
            print(f"Verification error in s3://{bucket}/{key}")
            return

        identifiers = get_identifiers(
            s3=sess.resource("s3"), logger=logger, bucket=bucket, key=key
        )
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

    # Now try to start a transfer in Archivematica.
    try:
        processing_config = choose_processing_config(key)

        directory, key_path = key.strip("/").split("/", 1)

        # Identify the file's location on the AM storage service
        target_path = archivematica.get_target_path(
            bucket=bucket, directory=directory, key=key_path
        )

        target_name = os.path.basename(key)
        transfer_id = archivematica.start_transfer(
            name=target_name,
            path=target_path,
            processing_config=processing_config,
            accession_number=identifiers["accession_number"],
        )

        tags = {
            "Archivematica-TransferId": transfer_id,
            "Archivematica-ProcessingConfig": processing_config,
            "Archivematica-AccessionNumber": identifiers["accession_number"],
            "Archivematica-CatalogueIdentifier": identifiers["dc.identifier"],
            "Archivematica-TransferStartedAt": dt.datetime.now().isoformat(),
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
    except Exception as err:
        logger.write(f"Error starting transfer: {err}")
        logger.write("Ask somebody to check the CloudWatch logs for more info")
        _write_log(sess, logger, bucket=bucket, key=key, result="failed")

        print(f"Error starting transfer for s3://{bucket}/{key}")
    else:
        logger.write("Started successful transfer!")
        logger.write(f"Archivematica transfer ID is {transfer_id}")
        _write_log(sess, logger, bucket=bucket, key=key, result="success", tags=tags)

        print("Started transfer {}".format(transfer_id))


def main(event, context=None):
    sess = boto3.Session()

    for record in event["Records"]:
        # Get the object from the event and show its content type
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"], encoding="utf-8")

        try:
            run_transfer(sess, bucket=bucket, key=key)
        except Exception:
            print(traceback.format_exc())
            print("Error thrown, skipping to next record...")
            continue


if __name__ == "__main__":  # pragma: no cover
    s3 = boto3.resource("s3")

    run_transfer(
        s3,
        bucket="wellcomecollection-archivematica-transfer-source",
        key="born-digital-accessions/WT_B_9_2_2.zip",
    )
