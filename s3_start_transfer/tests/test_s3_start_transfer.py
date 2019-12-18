# -*- encoding: utf-8 -*-

import re
from unittest.mock import call, patch

import boto3
from moto import mock_s3
import requests
import pytest

import archivematica
import s3_start_transfer


def _write_transfer_package(
    s3, *, bucket_name, filename, key="born-digital/transfer_package.zip"
):
    bucket = s3.Bucket(bucket_name)
    bucket.create()

    bucket.upload_file(Key=key, Filename=f"tests/files/{filename}")

    return key


def _find_log_object(s3, *, bucket_name):
    bucket = s3.Bucket(bucket_name)

    bucket_objects = list(bucket.objects.all())
    assert len(bucket_objects) == 2

    log_objects = [
        s3_obj
        for s3_obj in bucket_objects
        if s3_obj.key.endswith(".log")
    ]
    assert len(log_objects) == 1
    log_key = log_objects[0].key

    return bucket.Object(log_key)


class TestStartTransfer:
    @patch.object(archivematica, "am_api_post_json")
    def test_start_transfer(self, mock_am_post):
        mock_am_post.return_value = {"id": "my-transfer-id"}

        assert (
            s3_start_transfer.start_transfer(
                "test1.zip", b"space1-uuid:/test1.zip", "born-digital"
            )
            == "my-transfer-id"
        )

        mock_am_post.assert_called_once_with(
            "/api/v2beta/package",
            {
                "name": "test1.zip",
                "type": "zipfile",
                "path": "c3BhY2UxLXV1aWQ6L3Rlc3QxLnppcA==",
                "processing_config": "born_digital",
                "auto_approve": True,
            },
        )

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_valid_transfer_is_started(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        s3 = boto3.resource("s3")

        key = _write_transfer_package(
            s3, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        s3_start_transfer.run_transfer(s3, bucket=bucket_name, key=key)

        mock_get_target_path.assert_called_with(
            bucket=bucket_name,
            directory="born-digital",
            key="transfer_package.zip"
        )
        mock_start_transfer.assert_called_with(
            name="transfer_package.zip",
            path=mock_get_target_path.return_value,
            processing_config="born_digital"
        )

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_valid_transfer_creates_success_log(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        s3 = boto3.resource("s3")

        key = _write_transfer_package(
            s3, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        s3_start_transfer.run_transfer(s3, bucket=bucket_name, key=key)

        log_object = _find_log_object(s3, bucket_name=bucket_name)

        # Example: born-digital/transfer_package.zip.success.2019-12-13_14-46-09.log
        assert re.match(
            r"^born-digital/transfer_package\.zip\.success\.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_object.key
        )

        log_text = log_object.get()["Body"].read()
        assert b"All checks complete!\nStarted successful transfer!" in log_text

    @mock_s3
    def test_verification_failure_writes_failed_log(self, bucket_name):
        s3 = boto3.resource("s3")
        key = _write_transfer_package(
            s3, bucket_name=bucket_name, filename="no_metadata_csv.zip"
        )

        s3_start_transfer.run_transfer(s3, bucket=bucket_name, key=key)

        log_object = _find_log_object(s3, bucket_name=bucket_name)

        # Example: born-digital/transfer_package.zip.failed.2019-12-13_14-46-09.log
        assert re.match(
            r"^born-digital/transfer_package\.zip\.failed\.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_object.key
        )

        log_text = log_object.get()["Body"].read()
        assert b"== Check 3: verify_has_a_metadata_csv ==\nCheck failed:" in log_text

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_verification_failure_does_not_start_transfer(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        s3 = boto3.resource("s3")
        key = _write_transfer_package(
            s3, bucket_name=bucket_name, filename="no_metadata_csv.zip"
        )

        s3_start_transfer.run_transfer(s3, bucket=bucket_name, key=key)

        mock_get_target_path.assert_not_called()
        mock_start_transfer.assert_not_called()

    @mock_s3
    def test_error_while_calling_archivematica_writes_failure_log(self, bucket_name):
        s3 = boto3.resource("s3")
        key = _write_transfer_package(
            s3, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        def boom(*args, **kwargs):
            raise ValueError("BOOM!")

        with patch.object(archivematica, "get_target_path", boom):
            s3_start_transfer.run_transfer(s3, bucket=bucket_name, key=key)

        log_object = _find_log_object(s3, bucket_name=bucket_name)

        # Example: born-digital/transfer_package.zip.failed.2019-12-13_14-46-09.log
        assert re.match(
            r"^born-digital/transfer_package\.zip\.failed\.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_object.key
        )

        log_text = log_object.get()["Body"].read()
        assert b"Error starting transfer: BOOM!" in log_text


@mock_s3
def test_main_runs_all_events(bucket_name):
    s3 = boto3.resource("s3")

    _write_transfer_package(
        s3,
        bucket_name=bucket_name,
        filename="valid_transfer_package.zip",
        key="born-digital/transfer_package1.zip"
    )

    _write_transfer_package(
        s3,
        bucket_name=bucket_name,
        filename="valid_transfer_package.zip",
        key="born-digital/transfer_package2.zip"
    )

    event = {"Records": [
        {
            "s3": {
                "bucket": {"name": bucket_name},
                "object": {"key": "born-digital%2Ftransfer_package1.zip"},
            }
        },
        {
            "s3": {
                "bucket": {"name": bucket_name},
                "object": {"key": "born-digital%2Ftransfer_package2.zip"},
            }
        },
    ]}

    with patch.object(archivematica, "get_target_path") as mock_get_target_path:
        with patch.object(archivematica, "start_transfer") as mock_start_transfer:
            s3_start_transfer.main(event=event)

            assert mock_start_transfer.call_count == 2


@pytest.mark.parametrize("s3_key, processing_config", [
    ("born-digital/PPABC1.zip", "born_digital"),
    ("born-digital/lexie/PPABC1.zip", "born_digital"),
    ("born-digital-accessions/WT1234.zip", "accessions"),
])
def test_choose_processing_config(s3_key, processing_config):
    assert s3_start_transfer.choose_processing_config(s3_key) == processing_config


@pytest.mark.parametrize("s3_key", [
    "digitised/b12345678.zip",
])
def test_unrecognised_key_is_not_processing_config(s3_key):
    with pytest.raises(ValueError, match="Unable to determine processing config"):
        s3_start_transfer.choose_processing_config(s3_key)
