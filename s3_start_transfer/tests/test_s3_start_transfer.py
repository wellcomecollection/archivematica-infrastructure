# -*- encoding: utf-8 -*-

from unittest.mock import call, patch

import boto3
from moto import mock_s3
import requests
import pytest

import archivematica
import s3_start_transfer


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
    def test_main(self, mock_get_target_path, mock_start_transfer, bucket_name):
        s3 = boto3.resource("s3")

        bucket = s3.Bucket(bucket_name)
        bucket.create()

        key = "born-digital/transfer_package.zip"
        bucket.upload_file(Key=key, Filename="tests/files/valid_transfer_package.zip")

        events = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": bucket_name},
                        "object": {"key": key},
                    }
                }
            ]
        }

        s3_start_transfer.main(events)

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
