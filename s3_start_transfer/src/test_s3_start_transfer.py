# -*- encoding: utf-8 -*-

import json
import sys
from unittest.mock import call, patch

import pytest

import s3_start_transfer


class TestStartTransfer:
    @patch.object(s3_start_transfer, "ss_api_get")
    def test_get_target_path(self, mock_ss_get):
        mock_ss_get.side_effect = [
            {
                "objects": [
                    {
                        "relative_path": "/path-a/",
                        "space": "/api/v2/space/1",
                        "uuid": "space1-uuid",
                    },
                    {
                        "relative_path": "/path-b/",
                        "space": "/api/v2/space/2",
                        "uuid": "space2-uuid",
                    },
                ]
            },
            {"s3_bucket": "bucket01"},
            {"s3_bucket": "bucket02"},
        ]
        assert (
            s3_start_transfer.get_target_path("bucket01", "path-a", "test1.zip")
            == b"space1-uuid:/test1.zip"
        )

        mock_ss_get.assert_has_calls(
            [
                call(
                    "/api/v2/location/",
                    {"space__access_protocol": "S3", "purpose": "TS"},
                ),
                call("/api/v2/space/1"),
                call("/api/v2/space/2"),
            ]
        )

    def test_find_matching_path(self):
        locations = [
            {
                "relative_path": "/path-a/",
                "s3_bucket": "bucket01",
                "uuid": "space1-uuid",
            },
            {
                "relative_path": "/path-b/",
                "s3_bucket": "bucket02",
                "uuid": "space2-uuid",
            },
        ]

        assert (
            s3_start_transfer.find_matching_path(
                locations, "bucket01", "path-a", "test1.zip"
            )
            == b"space1-uuid:/test1.zip"
        )

    def test_find_matching_path_no_path_match(self):
        locations = [
            {
                "relative_path": "/path-a/",
                "s3_bucket": "bucket01",
                "uuid": "space1-uuid",
            }
        ]

        with pytest.raises(s3_start_transfer.StoragePathException):
            s3_start_transfer.find_matching_path(
                locations, "bucket01", "path-x", "test1.zip"
            )

    def test_find_matching_path_no_bucket_match(self):
        locations = [
            {
                "relative_path": "/path-a/",
                "s3_bucket": "bucket01",
                "uuid": "space1-uuid",
            }
        ]

        with pytest.raises(s3_start_transfer.StoragePathException):
            s3_start_transfer.find_matching_path(
                locations, "bucket02", "path-a", "test1.zip"
            )

    @patch.object(s3_start_transfer, "am_api_post_json")
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

    @patch.object(s3_start_transfer, "am_api_post_json")
    def test_start_transfer_raises_upon_error(self, mock_am_post):
        mock_am_post.return_value = {"error": True, "message": "An error occurred"}

        with pytest.raises(s3_start_transfer.StartTransferException):
            s3_start_transfer.start_transfer(
                "test1.zip", b"space1-uuid:/test1.zip", "born-digital"
            )

    @patch.object(s3_start_transfer.requests, "get")
    def test_ss_api_get(self, mock_get, monkeypatch):
        monkeypatch.setenv(
            "ARCHIVEMATICA_SS_URL", "http://archivematica-ss.example.com"
        )
        monkeypatch.setenv("ARCHIVEMATICA_SS_USERNAME", "ss_username")
        monkeypatch.setenv("ARCHIVEMATICA_SS_API_KEY", "ss_api_key")
        mock_get.return_value.json.return_value = {"c": "d"}

        response = s3_start_transfer.ss_api_get("/api/v2/path", {"a": "b"})

        assert response == {"c": "d"}
        mock_get.assert_called_with(
            "http://archivematica-ss.example.com/api/v2/path",
            params={"a": "b"},
            headers={"Authorization": "ApiKey ss_username:ss_api_key"},
        )

    @patch.object(s3_start_transfer.requests, "post")
    def test_am_api_post_json(self, mock_post, monkeypatch):
        monkeypatch.setenv("ARCHIVEMATICA_URL", "http://archivematica.example.com")
        monkeypatch.setenv("ARCHIVEMATICA_USERNAME", "am_username")
        monkeypatch.setenv("ARCHIVEMATICA_API_KEY", "am_api_key")
        mock_post.return_value.json.return_value = {"c": "d"}

        s3_start_transfer.am_api_post_json("/api/v2/path", {"a": "b"})

        mock_post.assert_called_with(
            "http://archivematica.example.com/api/v2/path",
            json={"a": "b"},
            headers={"Authorization": "ApiKey am_username:am_api_key"},
        )

    @patch.object(s3_start_transfer, "start_transfer")
    @patch.object(s3_start_transfer, "get_target_path")
    def test_main(self, mock_get_target_path, mock_start_transfer):
        events = {
            "Records": [
                {
                    "s3": {
                        "bucket": {"name": "upload-bucket"},
                        "object": {"key": "born-digital/test-key"},
                    }
                }
            ]
        }

        s3_start_transfer.main(events)

        mock_get_target_path.assert_called_with(
            "upload-bucket", "born-digital", "test-key"
        )
        mock_start_transfer.assert_called_with(
            name="test-key",
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
