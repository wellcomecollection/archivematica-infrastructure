# -*- encoding: utf-8 -*-

import io
import re
import zipfile
from types import SimpleNamespace
from unittest.mock import patch

import boto3
from botocore.exceptions import ClientError
from moto import mock_s3
import pytest

import archivematica
from idempotency import (
    EventLedger,
    S3EventIdentity,
    SUBMITTED,
    SUBMITTING,
    UNKNOWN,
)
import s3_start_transfer


def _write_transfer_package(
    sess, *, bucket_name, filename, key="born-digital/transfer_package.zip"
):
    s3 = sess.resource("s3")
    bucket = s3.Bucket(bucket_name)
    bucket.create()

    bucket.upload_file(Key=key, Filename=f"tests/files/{filename}")

    return key


def _write_accession_package(
    sess, *, bucket_name, key="born-digital-accessions/LEMON_1234.zip"
):
    archive = io.BytesIO()
    with zipfile.ZipFile(archive, "w") as zf:
        zf.writestr("record.txt", "test transfer")
        zf.writestr(
            "metadata/metadata.csv",
            (
                "filename,collection_reference,accession_number\n"
                "objects/,LEMON,1234\n"
            ),
        )

    bucket = sess.resource("s3").Bucket(bucket_name)
    bucket.create()
    bucket.put_object(Key=key, Body=archive.getvalue())

    return key


def _event(bucket, key, *, sequencer="0001", version_id=None):
    return S3EventIdentity(
        bucket=bucket,
        object_key=key,
        event_name="ObjectCreated:Put",
        sequencer=sequencer,
        version_id=version_id,
    )


def _find_log_object(sess, *, bucket_name):
    s3 = sess.resource("s3")
    bucket = s3.Bucket(bucket_name)

    bucket_objects = list(bucket.objects.all())
    assert len(bucket_objects) == 2

    log_objects = [s3_obj for s3_obj in bucket_objects if s3_obj.key.endswith(".log")]
    assert len(log_objects) == 1
    log_key = log_objects[0].key

    return bucket.Object(log_key)


@pytest.mark.usefixtures("idempotency_table")
class TestStartTransfer:
    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_valid_transfer_is_started(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        mock_start_transfer.return_value = "transfer-uuid"
        sess = boto3.Session()

        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        mock_get_target_path.assert_called_with(
            bucket=bucket_name, directory="born-digital", key="transfer_package.zip"
        )
        mock_start_transfer.assert_called_with(
            name="transfer_package.zip",
            path=mock_get_target_path.return_value,
            processing_config="born_digital",
            accession_number=None,
        )

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_valid_accession_transfer_is_started(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        mock_start_transfer.return_value = "transfer-uuid"
        sess = boto3.Session()

        key = _write_accession_package(sess, bucket_name=bucket_name)

        s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        mock_get_target_path.assert_called_with(
            bucket=bucket_name,
            directory="born-digital-accessions",
            key="LEMON_1234.zip",
        )
        mock_start_transfer.assert_called_with(
            name="LEMON_1234.zip",
            path=mock_get_target_path.return_value,
            processing_config="b_dig_accessions",
            accession_number="1234",
        )

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_valid_transfer_creates_success_log(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        mock_start_transfer.return_value = "transfer-uuid"
        sess = boto3.Session()

        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        log_object = _find_log_object(sess, bucket_name=bucket_name)

        # Example: born-digital/transfer_package.zip.success.2019-12-13_14-46-09.log
        assert re.match(
            r"^born-digital/transfer_package\.zip\.success\.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_object.key,
        )

        log_text = log_object.get()["Body"].read()
        assert b"All checks complete!\nStarted successful transfer!" in log_text

    @mock_s3
    def test_verification_failure_writes_failed_log(self, bucket_name):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="no_metadata_csv.zip"
        )

        s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        log_object = _find_log_object(sess, bucket_name=bucket_name)

        # Example: born-digital/transfer_package.zip.failed.2019-12-13_14-46-09.log
        assert re.match(
            r"^born-digital/transfer_package\.zip\.failed\.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_object.key,
        )

        log_text = log_object.get()["Body"].read()
        assert b"== Check 1: verify_has_a_metadata_csv ==\nCheck failed:" in log_text

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    @pytest.mark.parametrize(
        "filename, key",
        [
            ("no_metadata_csv.zip", "born-digital/LEMON_1234.zip"),
            ("no_metadata_csv.zip", "born-digital-accessions/LEMON_1234.zip"),
            ("valid_transfer_package.zip", "born-digital-accessions/LEMON_1234.zip"),
        ],
    )
    def test_verification_failure_does_not_start_transfer(
        self, mock_get_target_path, mock_start_transfer, bucket_name, filename, key
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename=filename, key=key
        )

        s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        mock_get_target_path.assert_not_called()
        mock_start_transfer.assert_not_called()

    @mock_s3
    def test_storage_service_error_writes_failure_log(
        self, bucket_name, idempotency_table
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        def boom(*args, **kwargs):
            raise ValueError("BOOM!")

        with patch.object(archivematica, "get_target_path", boom):
            s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        log_object = _find_log_object(sess, bucket_name=bucket_name)

        # Example: born-digital/transfer_package.zip.failed.2019-12-13_14-46-09.log
        assert re.match(
            r"^born-digital/transfer_package\.zip\.failed\.\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.log$",
            log_object.key,
        )

        log_text = log_object.get()["Body"].read()
        assert b"Error starting transfer: BOOM!" in log_text
        assert idempotency_table.scan()["Count"] == 0

    @mock_s3
    @patch.object(archivematica, "start_transfer", return_value="transfer-uuid")
    @patch.object(archivematica, "get_target_path")
    def test_sequential_delivery_starts_one_transfer(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        idempotency_table,
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)
        s3_start_transfer.run_transfer(sess, event=event)

        mock_start_transfer.assert_called_once()
        item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
        assert item["state"] == SUBMITTED
        assert item["transfer_uuid"] == "transfer-uuid"

    @mock_s3
    @patch.object(
        archivematica, "start_transfer", side_effect=["transfer-1", "transfer-2"]
    )
    @patch.object(archivematica, "get_target_path")
    def test_new_sequencer_starts_a_new_transfer(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        idempotency_table,
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        s3_start_transfer.run_transfer(
            sess, event=_event(bucket_name, key, sequencer="0001")
        )
        s3_start_transfer.run_transfer(
            sess, event=_event(bucket_name, key, sequencer="0002")
        )

        assert mock_start_transfer.call_count == 2
        items = idempotency_table.scan()["Items"]
        assert len(items) == 2
        assert {item["transfer_uuid"] for item in items} == {
            "transfer-1",
            "transfer-2",
        }

    @mock_s3
    @patch.object(archivematica, "get_target_path")
    def test_event_is_submitting_during_archivematica_call(
        self, mock_get_target_path, bucket_name, idempotency_table
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        def start_transfer(**kwargs):
            item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
            assert item["state"] == SUBMITTING
            assert "transfer_uuid" not in item
            return "transfer-uuid"

        with patch.object(archivematica, "start_transfer", start_transfer):
            s3_start_transfer.run_transfer(sess, event=event)

        item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
        assert item["state"] == SUBMITTED
        assert item["transfer_uuid"] == "transfer-uuid"

    @mock_s3
    @patch.object(archivematica, "start_transfer", return_value="transfer-uuid")
    @patch.object(archivematica, "get_target_path")
    def test_s3_feedback_failure_does_not_retry_submitted_transfer(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        idempotency_table,
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)
        s3_client = sess.client("s3")
        resource = sess.resource
        dynamodb = SimpleNamespace(Table=lambda _: idempotency_table)
        tagging_error = ClientError(
            {"Error": {"Code": "InternalError", "Message": "unavailable"}},
            "PutObjectTagging",
        )

        with patch.object(
            sess,
            "resource",
            side_effect=lambda service: (
                dynamodb if service == "dynamodb" else resource(service)
            ),
        ), patch.object(sess, "client", return_value=s3_client), patch.object(
            s3_client, "put_object_tagging", side_effect=tagging_error
        ) as mock_put_object_tagging:
            s3_start_transfer.run_transfer(sess, event=event)
            s3_start_transfer.run_transfer(sess, event=event)

        mock_start_transfer.assert_called_once()
        mock_put_object_tagging.assert_called_once()
        item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
        assert item["state"] == SUBMITTED
        assert item["transfer_uuid"] == "transfer-uuid"

    @mock_s3
    @patch.object(archivematica, "get_target_path")
    def test_unknown_submission_is_not_retried(
        self, mock_get_target_path, bucket_name, idempotency_table
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        with patch.object(
            archivematica, "start_transfer", side_effect=ValueError("BOOM!")
        ) as mock_start_transfer:
            s3_start_transfer.run_transfer(sess, event=event)
            s3_start_transfer.run_transfer(sess, event=event)

        mock_start_transfer.assert_called_once()
        item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
        assert item["state"] == UNKNOWN
        assert "expires_at" not in item

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_stale_submitting_event_is_not_retried(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        idempotency_table,
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)
        EventLedger(idempotency_table).claim(event)

        s3_start_transfer.run_transfer(sess, event=event)

        mock_start_transfer.assert_not_called()
        item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
        assert item["state"] == SUBMITTING
        assert "expires_at" not in item

    @mock_s3
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_dynamodb_claim_failure_prevents_archivematica_call(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        dynamodb_error = ClientError(
            {"Error": {"Code": "InternalServerError", "Message": "unavailable"}},
            "PutItem",
        )

        with patch.object(EventLedger, "claim", side_effect=dynamodb_error):
            with pytest.raises(ClientError, match="InternalServerError"):
                s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        mock_start_transfer.assert_not_called()

    @mock_s3
    @patch.object(archivematica, "start_transfer", return_value="transfer-uuid")
    @patch.object(archivematica, "get_target_path")
    def test_dynamodb_confirmation_failure_leaves_submitting_without_feedback(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        idempotency_table,
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)
        dynamodb_error = ClientError(
            {"Error": {"Code": "InternalServerError", "Message": "unavailable"}},
            "UpdateItem",
        )

        with patch.object(EventLedger, "mark_submitted", side_effect=dynamodb_error):
            with pytest.raises(ClientError, match="InternalServerError"):
                s3_start_transfer.run_transfer(sess, event=event)

        mock_start_transfer.assert_called_once()
        item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
        assert item["state"] == SUBMITTING
        assert "expires_at" not in item
        assert (
            sess.client("s3").get_object_tagging(Bucket=bucket_name, Key=key)["TagSet"]
            == []
        )
        assert len(list(sess.resource("s3").Bucket(bucket_name).objects.all())) == 1


@mock_s3
@pytest.mark.usefixtures("idempotency_table")
def test_main_runs_all_events(bucket_name):
    sess = boto3.Session()

    _write_transfer_package(
        sess,
        bucket_name=bucket_name,
        filename="valid_transfer_package.zip",
        key="born-digital/transfer_package1.zip",
    )

    _write_transfer_package(
        sess,
        bucket_name=bucket_name,
        filename="valid_transfer_package.zip",
        key="born-digital/transfer_package2.zip",
    )

    event = {
        "Records": [
            {
                "eventName": "ObjectCreated:Put",
                "s3": {
                    "bucket": {"name": bucket_name},
                    "object": {
                        "key": "born-digital%2Ftransfer_package1.zip",
                        "sequencer": "0001",
                    },
                },
            },
            {
                "eventName": "ObjectCreated:CompleteMultipartUpload",
                "s3": {
                    "bucket": {"name": bucket_name},
                    "object": {
                        "key": "born-digital%2Ftransfer_package2.zip",
                        "sequencer": "0002",
                    },
                },
            },
        ]
    }

    with patch.object(archivematica, "get_target_path"):
        with patch.object(archivematica, "start_transfer") as mock_start_transfer:
            mock_start_transfer.side_effect = ["transfer-1", "transfer-2"]
            s3_start_transfer.main(event=event)

            assert mock_start_transfer.call_count == 2


@pytest.mark.usefixtures("idempotency_table")
def test_main_reports_infrastructure_failure_after_processing_all_records():
    dynamodb_error = ClientError(
        {"Error": {"Code": "InternalServerError", "Message": "unavailable"}},
        "PutItem",
    )
    event = {
        "Records": [
            {
                "eventName": "ObjectCreated:Put",
                "s3": {
                    "bucket": {"name": "transfer-bucket"},
                    "object": {
                        "key": "born-digital%2Fpackage1.zip",
                        "sequencer": "0001",
                    },
                },
            },
            {
                "eventName": "ObjectCreated:Put",
                "s3": {
                    "bucket": {"name": "transfer-bucket"},
                    "object": {
                        "key": "born-digital%2Fpackage2.zip",
                        "sequencer": "0002",
                    },
                },
            },
        ]
    }

    with patch.object(
        s3_start_transfer,
        "run_transfer",
        side_effect=[dynamodb_error, None],
    ) as mock_run_transfer:
        with pytest.raises(ClientError, match="InternalServerError"):
            s3_start_transfer.main(event=event)

    assert mock_run_transfer.call_count == 2


@pytest.mark.parametrize("s3_key", ["digitised/b12345678.zip"])
def test_unrecognised_key_is_not_processing_config(s3_key):
    with pytest.raises(ValueError, match="Unable to determine processing config"):
        s3_start_transfer.choose_processing_config(s3_key)
