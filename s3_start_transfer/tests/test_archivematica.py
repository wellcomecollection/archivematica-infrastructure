# -*- encoding: utf-8

from unittest.mock import call, patch

import pytest
import requests

import archivematica


@patch.object(requests, "post")
def test_am_api_post_json(mock_post, monkeypatch):
    monkeypatch.setenv("ARCHIVEMATICA_URL", "http://archivematica.example.com")
    monkeypatch.setenv("ARCHIVEMATICA_USERNAME", "am_username")
    monkeypatch.setenv("ARCHIVEMATICA_API_KEY", "am_api_key")
    mock_post.return_value.json.return_value = {"c": "d"}

    archivematica.am_api_post_json("/api/v2/path", {"a": "b"})

    mock_post.assert_called_with(
        "http://archivematica.example.com/api/v2/path",
        json={"a": "b"},
        headers={"Authorization": "ApiKey am_username:am_api_key"},
    )


@patch.object(requests, "get")
def test_ss_api_get(mock_get, monkeypatch):
    monkeypatch.setenv(
        "ARCHIVEMATICA_SS_URL", "http://archivematica-ss.example.com"
    )
    monkeypatch.setenv("ARCHIVEMATICA_SS_USERNAME", "ss_username")
    monkeypatch.setenv("ARCHIVEMATICA_SS_API_KEY", "ss_api_key")
    mock_get.return_value.json.return_value = {"c": "d"}

    response = archivematica.ss_api_get("/api/v2/path", {"a": "b"})

    assert response == {"c": "d"}
    mock_get.assert_called_with(
        "http://archivematica-ss.example.com/api/v2/path",
        params={"a": "b"},
        headers={"Authorization": "ApiKey ss_username:ss_api_key"},
    )


@patch.object(archivematica, "ss_api_get")
def test_get_target_path(mock_ss_get):
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
        archivematica.get_target_path("bucket01", "path-a", "test1.zip")
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


def test_find_matching_path():
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
        archivematica.find_matching_path(locations, "bucket01", "path-a", "test1.zip")
        == b"space1-uuid:/test1.zip"
    )


def test_find_matching_path_no_path_match():
    locations = [
        {
            "relative_path": "/path-a/",
            "s3_bucket": "bucket01",
            "uuid": "space1-uuid",
        }
    ]

    with pytest.raises(archivematica.StoragePathException):
        archivematica.find_matching_path(locations, "bucket01", "path-x", "test1.zip")


def test_find_matching_path_no_bucket_match():
    locations = [
        {
            "relative_path": "/path-a/",
            "s3_bucket": "bucket01",
            "uuid": "space1-uuid",
        }
    ]

    with pytest.raises(archivematica.StoragePathException):
        archivematica.find_matching_path(locations, "bucket02", "path-a", "test1.zip")


@patch.object(archivematica, "am_api_post_json")
def test_start_transfer_raises_upon_error(mock_am_post):
    mock_am_post.return_value = {"error": True, "message": "An error occurred"}

    with pytest.raises(archivematica.StartTransferException):
        archivematica.start_transfer(
            "test1.zip", b"space1-uuid:/test1.zip", "born-digital"
        )
