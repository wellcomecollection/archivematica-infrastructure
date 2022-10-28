# -*- encoding: utf-8

from unittest.mock import call, patch
import uuid

import pytest

import archivematica


@patch.object(archivematica, "am_api_post_json")
def test_start_transfer(mock_am_post):
    transfer_uuid = str(uuid.uuid4())
    mock_am_post.return_value = {"id": transfer_uuid}

    actual_transfer_uuid = archivematica.start_transfer(
        name="test1.zip",
        path=b"space1-uuid:/test1.zip",
        processing_config="born-digital",
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
    )


@patch.object(archivematica, "am_api_post_json")
def test_start_transfer_with_accession(mock_am_post):
    transfer_uuid = str(uuid.uuid4())

    actual_transfer_uuid = archivematica.start_transfer(
        name="test1.zip",
        path=b"space1-uuid:/test1.zip",
        processing_config="b_dig_accessions",
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
            "test1.zip", b"space1-uuid:/test1.zip", "born-digital"
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
