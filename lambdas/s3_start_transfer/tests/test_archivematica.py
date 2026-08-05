# -*- encoding: utf-8

from unittest.mock import call, patch
import uuid

import pytest

import archivematica


@patch.object(archivematica.urllib.request, "urlopen")
def test_am_api_post_json(mock_urlopen, monkeypatch):
    monkeypatch.setenv("ARCHIVEMATICA_URL", "https://archivematica.example.com")
    monkeypatch.setenv("ARCHIVEMATICA_USERNAME", "am_username")
    monkeypatch.setenv("ARCHIVEMATICA_API_KEY", "am_api_key")
    mock_urlopen.return_value.read.return_value = b'{"c": "d"}'

    response = archivematica.am_api_post_json("/api/v2/path", {"a": "b"})

    assert response == {"c": "d"}
    request = mock_urlopen.call_args.args[0]
    assert request.full_url == "https://archivematica.example.com/api/v2/path"
    assert request.data == b'{"a": "b"}'
    assert request.method == "POST"
    assert request.get_header("Authorization") == "ApiKey am_username:am_api_key"
    assert request.get_header("Content-type") == "application/json"


@patch.object(archivematica.urllib.request, "urlopen")
def test_ss_api_get(mock_urlopen, monkeypatch):
    monkeypatch.setenv("ARCHIVEMATICA_SS_URL", "https://storage.example.com")
    monkeypatch.setenv("ARCHIVEMATICA_SS_USERNAME", "ss_username")
    monkeypatch.setenv("ARCHIVEMATICA_SS_API_KEY", "ss_api_key")
    mock_urlopen.return_value.read.return_value = b'{"c": "d"}'

    assert archivematica.ss_api_get("/api/v2/path", {"a": "b"}) == {"c": "d"}
    assert archivematica.ss_api_get("/api/v2/path") == {"c": "d"}

    requests = [urlopen_call.args[0] for urlopen_call in mock_urlopen.call_args_list]
    assert requests[0].full_url == "https://storage.example.com/api/v2/path?a=b"
    assert requests[1].full_url == "https://storage.example.com/api/v2/path?"
    assert all(
        request.get_header("Authorization") == "ApiKey ss_username:ss_api_key"
        for request in requests
    )


@patch.object(archivematica.urllib.request, "urlopen")
def test_am_api_post_json_includes_additional_headers(mock_urlopen, monkeypatch):
    monkeypatch.setenv("ARCHIVEMATICA_URL", "https://archivematica.example")
    monkeypatch.setenv("ARCHIVEMATICA_USERNAME", "test-user")
    monkeypatch.setenv("ARCHIVEMATICA_API_KEY", "test-key")
    mock_urlopen.return_value.read.return_value = b'{"id": "transfer-uuid"}'

    result = archivematica.am_api_post_json(
        "/api/v2beta/package",
        {"name": "test1.zip"},
        headers={"Idempotency-Key": "event-id"},
    )

    assert result == {"id": "transfer-uuid"}
    request = mock_urlopen.call_args.args[0]
    headers = {key.lower(): value for key, value in request.header_items()}
    assert headers == {
        "authorization": "ApiKey test-user:test-key",
        "content-type": "application/json",
        "idempotency-key": "event-id",
    }


@patch.object(archivematica, "am_api_post_json")
def test_start_transfer(mock_am_post):
    transfer_uuid = str(uuid.uuid4())
    mock_am_post.return_value = {"id": transfer_uuid}

    actual_transfer_uuid = archivematica.start_transfer(
        name="test1.zip",
        path=b"space1-uuid:/test1.zip",
        processing_config="born-digital",
        idempotency_key="event-id",
    )

    assert actual_transfer_uuid == transfer_uuid

    mock_am_post.assert_called_once_with(
        "/api/v2beta/package",
        {
            "name": "test1.zip",
            "type": "zipfile",
            "path": "c3BhY2UxLXV1aWQ6L3Rlc3QxLnppcA==",
            "processing_config": "born_digital",
            "auto_approve": True,
        },
        headers={"Idempotency-Key": "event-id"},
    )


@patch.object(archivematica, "am_api_post_json")
def test_start_transfer_with_accession(mock_am_post):
    transfer_uuid = str(uuid.uuid4())
    mock_am_post.return_value = {"id": transfer_uuid}

    actual_transfer_uuid = archivematica.start_transfer(
        name="test1.zip",
        path=b"space1-uuid:/test1.zip",
        processing_config="b_dig_accessions",
        idempotency_key="event-id",
        accession_number="1234",
    )

    assert actual_transfer_uuid == transfer_uuid

    mock_am_post.assert_called_once_with(
        "/api/v2beta/package",
        {
            "name": "test1.zip",
            "type": "zipfile",
            "path": "c3BhY2UxLXV1aWQ6L3Rlc3QxLnppcA==",
            "processing_config": "b_dig_accessions",
            "auto_approve": True,
            "accession": "1234",
        },
        headers={"Idempotency-Key": "event-id"},
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
                "/api/v2/location/", {"space__access_protocol": "S3", "purpose": "TS"}
            ),
            call("/api/v2/space/1"),
            call("/api/v2/space/2"),
        ]
    )


def test_find_matching_path():
    locations = [
        {"relative_path": "/path-a/", "s3_bucket": "bucket01", "uuid": "space1-uuid"},
        {"relative_path": "/path-b/", "s3_bucket": "bucket02", "uuid": "space2-uuid"},
    ]

    assert (
        archivematica.find_matching_path(locations, "bucket01", "path-a", "test1.zip")
        == b"space1-uuid:/test1.zip"
    )


def test_find_matching_path_no_path_match():
    locations = [
        {"relative_path": "/path-a/", "s3_bucket": "bucket01", "uuid": "space1-uuid"}
    ]

    with pytest.raises(archivematica.StoragePathException):
        archivematica.find_matching_path(locations, "bucket01", "path-x", "test1.zip")


def test_find_matching_path_no_bucket_match():
    locations = [
        {"relative_path": "/path-a/", "s3_bucket": "bucket01", "uuid": "space1-uuid"}
    ]

    with pytest.raises(archivematica.StoragePathException):
        archivematica.find_matching_path(locations, "bucket02", "path-a", "test1.zip")


@patch.object(archivematica, "am_api_post_json")
def test_start_transfer_raises_upon_error(mock_am_post):
    mock_am_post.return_value = {"error": True, "message": "An error occurred"}

    with pytest.raises(archivematica.StartTransferException):
        archivematica.start_transfer(
            "test1.zip",
            b"space1-uuid:/test1.zip",
            "born-digital",
            idempotency_key="event-id",
        )


@pytest.mark.parametrize(
    "s3_key, processing_config",
    [
        ("born-digital/PPABC1.zip", "born_digital"),
        ("born-digital/lexie/PPABC1.zip", "born_digital"),
        ("born-digital-accessions/WT1234.zip", "b_dig_accessions"),
    ],
)
def test_choose_processing_config(s3_key, processing_config):
    assert archivematica.choose_processing_config(s3_key) == processing_config
