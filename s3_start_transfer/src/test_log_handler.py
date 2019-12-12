# -*- encoding: utf-8

import datetime as dt
import re
import secrets

import boto3
import moto
import pytest

from log_handler import Logger, s3_logger


class TestLogger:
    def test_can_write(self):
        logger = Logger()
        logger.write("Hello!")
        logger.write("My favourite colour is red")

        assert re.match(
            r"@@ Logging starts at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@\n"
            r"Hello!\n"
            r"My favourite colour is red\n"
            r"@@ Logging ends at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@",
            logger.text()
        )

        logger.write("I will write some more text")
        assert re.match(
            r"@@ Logging starts at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@\n"
            r"Hello!\n"
            r"My favourite colour is red\n"
            r"I will write some more text\n"
            r"@@ Logging ends at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@",
            logger.text()
        )

    def test_timestamp_is_recent(self):
        logger = Logger()
        logger.write("Hello!")

        text = logger.text()
        timestamp, *_ = text.splitlines()
        parsed_datetime = dt.datetime.strptime(
            timestamp, "@@ Logging starts at %Y-%m-%d %H:%M:%S @@"
        )
        assert (dt.datetime.now() - parsed_datetime).seconds < 5


@pytest.fixture
def bucket_name():
    return f"bucket-{secrets.token_hex(5)}"


class TestLoggingContext:
    def _get_log_file(self, s3, *, bucket):
        s3_objects = s3.list_objects_v2(Bucket=bucket)

        assert len(s3_objects["Contents"]) == 1
        log_file = next(
            s3_obj
            for s3_obj in s3_objects["Contents"]
            if s3_obj["Key"].endswith(".log")
        )  # pragma: no cover

        return log_file

    def _get_log_file_contents(self, s3, *, bucket):
        log_file = self._get_log_file(s3, bucket=bucket)
        return s3.get_object(Bucket=bucket, Key=log_file["Key"])["Body"].read()

    @moto.mock_s3
    def test_can_use_logging_context(self, bucket_name):
        s3 = boto3.client("s3")
        s3.create_bucket(Bucket=bucket_name)

        with s3_logger(bucket=bucket_name, prefix="transfer.zip") as logger:
            logger.write("Something happened")
            logger.write("Something else happened")

        log_file = self._get_log_file(s3, bucket=bucket_name)

        # e.g. transfer.zip.2019-12-12_11-10-44.log
        assert re.match(
            r"^transfer\.zip.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_file["Key"]
        )

        contents = self._get_log_file_contents(s3, bucket=bucket_name)

        assert re.match(
            r"@@ Logging starts at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@\n"
            r"Something happened\n"
            r"Something else happened\n"
            r"@@ Logging ends at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@",
            contents.decode("utf8")
        )

    @moto.mock_s3
    def test_uses_recent_timestamp_in_log_key(self, bucket_name):
        s3 = boto3.client("s3")
        s3.create_bucket(Bucket=bucket_name)

        with s3_logger(bucket=bucket_name, prefix="transfer.zip") as logger:
            logger.write("Something happened")
            logger.write("Something else happened")

        log_file = self._get_log_file(s3, bucket=bucket_name)

        parsed_datetime = dt.datetime.strptime(
            log_file["Key"], "transfer.zip.%Y-%m-%d_%H-%M-%S.log"
        )
        assert (dt.datetime.now() - parsed_datetime).seconds < 5

    @moto.mock_s3
    def test_handles_exception_in_logging_context(self, bucket_name):
        s3 = boto3.client("s3")
        s3.create_bucket(Bucket=bucket_name)

        with s3_logger(bucket=bucket_name, prefix="transfer.zip") as logger:
            logger.write("Something happened")
            logger.write("Something else happened")
            raise ValueError("BOOM!")

        log_file = self._get_log_file(s3, bucket=bucket_name)

        contents = self._get_log_file_contents(s3, bucket=bucket_name)

        assert re.match(
            r"@@ Logging starts at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@\n"
            r"Something happened\n"
            r"Something else happened\n"
            r"!!! Something went wrong!\n"
            r"!!! Please ask an AWS admin to check the CloudWatch logs\.\n"
            r"!!! Exception message: BOOM!\n"
            r"@@ Logging ends at \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} @@",
            contents.decode("utf8")
        )
