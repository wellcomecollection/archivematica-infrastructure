# -*- encoding: utf-8

import datetime as dt
import os
import os.path
import urllib.parse
import zipfile

import boto3

from archivematica import (
    choose_processing_config,
    get_target_path,
    start_transfer
)
from big_s3 import S3File
from log_handler import Logger
from verify_transfer_packages import verify_package


def _write_log(logger, bucket, key, result):
    s3 = boto3.client("s3")

    timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    log_key = ".".join([key, result, timestamp, "log"])

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
        ACL="bucket-owner-full-control"
    )


def main(event, context=None):
    s3 = boto3.resource("s3")

    for record in event["Records"]:
        # Get the object from the event and show its content type
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"], encoding="utf-8")

        logger = Logger()

        # Run some verifications on the object before we sent it to Archivematica.
        print(f"Running verifications on s3://{bucket}/{key}")
        s3_object = s3.Object(bucket, key)
        s3_file = S3File(s3_object=s3_object)

        with zipfile.ZipFile(s3_file) as zf:
            if not verify_package(logger=logger, zip_file=zf):
                _write_log(logger, bucket=bucket, key=key, result="failed")
                print(f"Verification error in s3://{bucket}/{key}")
                continue

        # Now try to start a transfer in Archivematica.
        try:
            processing_config = choose_processing_config(key)

            directory, key_path = key.strip("/").split("/", 1)

            # Identify the file's location on the AM storage service
            target_path = get_target_path(bucket, directory, key_path)

            target_name = os.path.basename(key)
            transfer_id = start_transfer(
                name=target_name,
                path=target_path,
                processing_config=processing_config
            )
        except Exception as err:
            logger.write(f"Error starting transfer: {err}")
            logger.write("Ask somebody to check the CloudWatch logs for more info")
            _write_log(logger, bucket=bucket, key=key, result="failed")

            print(f"Error starting transfer for s3://{bucket}/{key}")
        else:
            logger.write("Started successful transfer!")
            _write_log(logger, bucket=bucket, key=key, result="success")

            print("Started transfer {}".format(transfer_id))


if __name__ == "__main__":
    key = "born-digital-accessions/WT_B_9_2_2.zip"
    main(
        {
            "Records": [
                {
                    "s3": {
                        "bucket": {
                            "name": "wellcomecollection-archivematica-transfer-source"
                        },
                        "object": {"key": key},
                    }
                }
            ]
        },
        None,
    )
