# -*- encoding: utf-8 -*-

import io
import urllib.error
import zipfile
from unittest.mock import patch

import boto3
from botocore.exceptions import ClientError
from moto import mock_aws
import pytest

import archivematica
from idempotency import S3EventIdentity
import s3_start_transfer


def _write_transfer_package(
    sess, *, bucket_name, filename, key="born-digital/transfer_package.zip"
):
    s3 = sess.resource("s3")
    bucket = s3.Bucket(bucket_name)
    bucket.create()

    if filename == "valid_accession_package.zip":
        package = io.BytesIO()
        with zipfile.ZipFile(package, mode="w") as zf:
            zf.writestr(
                "metadata/metadata.csv",
                "filename,collection_reference,accession_number,dc.title\n"
                "objects/,LEMON,1234,The Citrus Archives\n",
            )
            for object_name in ["apple.txt", "banana.txt", "cherry.txt"]:
                zf.writestr(object_name, b"")
        package.seek(0)
        bucket.upload_fileobj(Fileobj=package, Key=key)
    else:
        bucket.upload_file(Key=key, Filename=f"tests/files/{filename}")

    return key


def _write_package_bytes(
    sess, *, bucket_name, body, key="born-digital/transfer_package.zip"
):
    bucket = sess.resource("s3").Bucket(bucket_name)
    bucket.create()
    bucket.put_object(Key=key, Body=body)

    return key


def _package_with_metadata(metadata):
    archive = io.BytesIO()
    with zipfile.ZipFile(archive, "w") as zf:
        zf.writestr("record.txt", "test transfer")
        zf.writestr("metadata/metadata.csv", metadata)

    return archive.getvalue()


def _event(bucket, key, *, sequencer="0001", version_id=None):
    return S3EventIdentity(
        bucket=bucket,
        object_key=key,
        event_name="ObjectCreated:Put",
        sequencer=sequencer,
        version_id=version_id,
        event_time="2026-07-31T08:00:00.000Z",
    )


def _log_key(key, result, event):
    return ".".join([key, result, event.event_time, event.event_id[:12], "log"])


def _http_error(status):
    return urllib.error.HTTPError(
        "https://archivematica.example/api/v2beta/package",
        status,
        "request failed",
        hdrs=None,
        fp=None,
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


class TestStartTransfer:
    @mock_aws
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
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)

        mock_get_target_path.assert_called_with(
            bucket=bucket_name, directory="born-digital", key="transfer_package.zip"
        )
        mock_start_transfer.assert_called_with(
            name="transfer_package.zip",
            path=mock_get_target_path.return_value,
            processing_config="born_digital",
            accession_number=None,
            idempotency_key=event.event_id,
        )

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_valid_accession_transfer_is_started(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        mock_start_transfer.return_value = "transfer-uuid"
        sess = boto3.Session()

        key = _write_transfer_package(
            sess,
            bucket_name=bucket_name,
            filename="valid_accession_package.zip",
            key="born-digital-accessions/LEMON_1234.zip",
        )
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)

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
            idempotency_key=event.event_id,
        )

    @mock_aws
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
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)

        log_object = _find_log_object(sess, bucket_name=bucket_name)

        assert log_object.key == _log_key(key, "success", event)

        log_text = log_object.get()["Body"].read()
        assert b"All checks complete!\nStarted successful transfer!" in log_text

    @mock_aws
    def test_verification_failure_writes_failed_log(self, bucket_name):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="no_metadata_csv.zip"
        )
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)
        s3_start_transfer.run_transfer(sess, event=event)

        log_object = _find_log_object(sess, bucket_name=bucket_name)

        assert log_object.key == _log_key(key, "failed", event)

        log_text = log_object.get()["Body"].read()
        assert b"== Check 1: verify_has_a_metadata_csv ==\nCheck failed:" in log_text

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    @pytest.mark.parametrize(
        "filename, key",
        [
            ("no_metadata_csv.zip", "born-digital/LEMON_1234.zip"),
            ("no_metadata_csv.zip", "born-digital-accessions/LEMON_1234.zip"),
            ("valid_accession_package.zip", "born-digital/LEMON_1234.zip"),
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

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    @pytest.mark.parametrize(
        "body, expected_error",
        [
            (b"not a ZIP archive", b"File is not a zip file"),
            (
                _package_with_metadata(b"filename,dc.identifier\nobjects/,\xff\n"),
                b"codec can't decode byte 0xff",
            ),
        ],
    )
    def test_malformed_package_writes_failed_log_without_starting_transfer(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        body,
        expected_error,
    ):
        sess = boto3.Session()
        key = _write_package_bytes(sess, bucket_name=bucket_name, body=body)
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)

        mock_get_target_path.assert_not_called()
        mock_start_transfer.assert_not_called()

        log_object = _find_log_object(sess, bucket_name=bucket_name)
        assert log_object.key == _log_key(key, "failed", event)

        log_text = log_object.get()["Body"].read()
        assert b"Unable to read transfer package:" in log_text
        assert expected_error in log_text

    @mock_aws
    def test_missing_storage_service_path_writes_failure_log(self, bucket_name):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        def boom(*args, **kwargs):
            raise archivematica.StoragePathException("BOOM!")

        with patch.object(archivematica, "get_target_path", boom):
            s3_start_transfer.run_transfer(sess, event=event)

        log_object = _find_log_object(sess, bucket_name=bucket_name)

        assert log_object.key == _log_key(key, "failed", event)

        log_text = log_object.get()["Body"].read()
        assert b"Error starting transfer: BOOM!" in log_text

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_unknown_transfer_source_writes_failure_log(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess,
            bucket_name=bucket_name,
            filename="valid_transfer_package.zip",
            key="unknown/transfer_package.zip",
        )
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)

        mock_get_target_path.assert_not_called()
        mock_start_transfer.assert_not_called()

        log_object = _find_log_object(sess, bucket_name=bucket_name)
        assert log_object.key == _log_key(key, "failed", event)

        log_text = log_object.get()["Body"].read()
        assert b"Unable to determine processing config" in log_text

    @mock_aws
    @patch.object(archivematica, "start_transfer", return_value="transfer-uuid")
    @patch.object(archivematica, "get_target_path")
    def test_duplicate_delivery_reuses_idempotency_key_and_success_log(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)
        s3_start_transfer.run_transfer(sess, event=event)

        assert mock_start_transfer.call_count == 2
        assert [
            call.kwargs["idempotency_key"]
            for call in mock_start_transfer.call_args_list
        ] == [event.event_id, event.event_id]

        log_object = _find_log_object(sess, bucket_name=bucket_name)
        assert log_object.key == _log_key(key, "success", event)

        tags = {
            tag["Key"]: tag["Value"]
            for tag in sess.client("s3").get_object_tagging(
                Bucket=bucket_name, Key=key
            )["TagSet"]
        }
        assert tags["Archivematica-TransferId"] == "transfer-uuid"
        assert tags["Archivematica-S3EventTime"] == event.event_time

    @mock_aws
    @patch.object(
        archivematica, "start_transfer", side_effect=["transfer-1", "transfer-2"]
    )
    @patch.object(archivematica, "get_target_path")
    def test_new_sequencer_starts_a_new_transfer(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        first_event = _event(bucket_name, key, sequencer="0001")
        second_event = _event(bucket_name, key, sequencer="0002")

        s3_start_transfer.run_transfer(sess, event=first_event)
        s3_start_transfer.run_transfer(sess, event=second_event)

        assert mock_start_transfer.call_count == 2
        assert [
            call.kwargs["idempotency_key"]
            for call in mock_start_transfer.call_args_list
        ] == [first_event.event_id, second_event.event_id]
        assert first_event.event_id != second_event.event_id

    @mock_aws
    @patch.object(archivematica, "get_target_path")
    def test_uncertain_submission_is_retried_with_same_idempotency_key(
        self, mock_get_target_path, bucket_name
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        with patch.object(
            archivematica,
            "start_transfer",
            side_effect=[TimeoutError("response lost"), "transfer-uuid"],
        ) as mock_start_transfer:
            with pytest.raises(TimeoutError, match="response lost"):
                s3_start_transfer.run_transfer(sess, event=event)
            s3_start_transfer.run_transfer(sess, event=event)

        assert [
            call.kwargs["idempotency_key"]
            for call in mock_start_transfer.call_args_list
        ] == [event.event_id, event.event_id]
        _find_log_object(sess, bucket_name=bucket_name)

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    @pytest.mark.parametrize(
        "error",
        [
            pytest.param(
                archivematica.StartTransferException("invalid processing config"),
                id="error-response",
            ),
            pytest.param(_http_error(400), id="bad-request"),
            pytest.param(_http_error(422), id="idempotency-conflict"),
        ],
    )
    def test_permanent_submission_error_writes_failure_log(
        self, mock_get_target_path, mock_start_transfer, bucket_name, error
    ):
        mock_start_transfer.side_effect = error
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)

        s3_start_transfer.run_transfer(sess, event=event)

        log_object = _find_log_object(sess, bucket_name=bucket_name)
        assert log_object.key == _log_key(key, "failed", event)
        assert b"Error starting transfer:" in log_object.get()["Body"].read()

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    @pytest.mark.parametrize("status", [408, 409, 425, 429, 500])
    def test_retryable_http_submission_error_fails_invocation(
        self, mock_get_target_path, mock_start_transfer, bucket_name, status
    ):
        error = _http_error(status)
        mock_start_transfer.side_effect = error
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        with pytest.raises(urllib.error.HTTPError) as raised:
            s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        assert raised.value is error

    @mock_aws
    @patch.object(archivematica, "start_transfer", return_value="transfer-uuid")
    @patch.object(archivematica, "get_target_path")
    @pytest.mark.parametrize("failure_target", ["package", "success_log"])
    def test_s3_feedback_failure_is_safe_to_retry(
        self,
        mock_get_target_path,
        mock_start_transfer,
        bucket_name,
        failure_target,
    ):
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )
        event = _event(bucket_name, key)
        s3_client = sess.client("s3")
        success_log_key = _log_key(key, "success", event)
        failed_key = key if failure_target == "package" else success_log_key
        put_object_tagging = s3_client.put_object_tagging
        tagging_error = ClientError(
            {"Error": {"Code": "InternalError", "Message": "unavailable"}},
            "PutObjectTagging",
        )
        failed = False

        def fail_once(**kwargs):
            nonlocal failed
            if kwargs["Key"] == failed_key and not failed:
                failed = True
                raise tagging_error
            return put_object_tagging(**kwargs)

        with (
            patch.object(sess, "client", return_value=s3_client),
            patch.object(s3_client, "put_object_tagging", side_effect=fail_once),
        ):
            with pytest.raises(ClientError, match="InternalError"):
                s3_start_transfer.run_transfer(sess, event=event)
            s3_start_transfer.run_transfer(sess, event=event)

        assert mock_start_transfer.call_count == 2
        assert [
            call.kwargs["idempotency_key"]
            for call in mock_start_transfer.call_args_list
        ] == [event.event_id, event.event_id]
        log_object = _find_log_object(sess, bucket_name=bucket_name)
        assert log_object.key == success_log_key

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_storage_service_transport_error_is_retryable(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        mock_get_target_path.side_effect = OSError("service unavailable")
        sess = boto3.Session()
        key = _write_transfer_package(
            sess, bucket_name=bucket_name, filename="valid_transfer_package.zip"
        )

        with pytest.raises(OSError, match="service unavailable"):
            s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        mock_start_transfer.assert_not_called()

    @mock_aws
    @patch.object(archivematica, "start_transfer")
    @patch.object(archivematica, "get_target_path")
    def test_deflate64_accession_uses_filename_as_accession_number(
        self, mock_get_target_path, mock_start_transfer, bucket_name
    ):
        mock_start_transfer.return_value = "transfer-uuid"
        sess = boto3.Session()
        key = _write_transfer_package(
            sess,
            bucket_name=bucket_name,
            filename="valid_transfer_package.zip",
            key="born-digital-accessions/WT_B_9_2_2.zip",
        )
        event = _event(bucket_name, key)

        with patch.object(
            s3_start_transfer,
            "verify_s3_package",
            side_effect=NotImplementedError("That compression method is not supported"),
        ):
            s3_start_transfer.run_transfer(sess, event=event)

        mock_start_transfer.assert_called_once_with(
            name="WT_B_9_2_2.zip",
            path=mock_get_target_path.return_value,
            processing_config="b_dig_accessions",
            accession_number="WT_B_9_2_2",
            idempotency_key=event.event_id,
        )

    @mock_aws
    @pytest.mark.parametrize(
        "error, key",
        [
            (
                "That compression method is not supported",
                "born-digital/transfer_package.zip",
            ),
            (
                "unsupported compression type",
                "born-digital-accessions/transfer_package.zip",
            ),
        ],
    )
    def test_unsupported_compression_does_not_start_transfer(
        self, bucket_name, error, key
    ):
        sess = boto3.Session()
        with patch.object(
            s3_start_transfer,
            "verify_s3_package",
            side_effect=NotImplementedError(error),
        ):
            with patch.object(archivematica, "start_transfer") as mock_start_transfer:
                s3_start_transfer.run_transfer(sess, event=_event(bucket_name, key))

        mock_start_transfer.assert_not_called()


@mock_aws
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
                "eventTime": "2026-07-31T08:00:00.000Z",
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
                "eventTime": "2026-07-31T08:01:00.000Z",
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


def test_main_reports_infrastructure_failure_after_processing_all_records():
    first_error = ClientError(
        {"Error": {"Code": "InternalServerError", "Message": "unavailable"}},
        "PutObjectTagging",
    )
    second_error = TimeoutError("Archivematica unavailable")
    event = {
        "Records": [
            {
                "eventName": "ObjectCreated:Put",
                "eventTime": "2026-07-31T08:00:00.000Z",
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
                "eventTime": "2026-07-31T08:01:00.000Z",
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
        side_effect=[first_error, second_error],
    ) as mock_run_transfer:
        with pytest.raises(ClientError, match="InternalServerError"):
            s3_start_transfer.main(event=event)

    assert mock_run_transfer.call_count == 2


@pytest.mark.parametrize("s3_key", ["digitised/b12345678.zip"])
def test_unrecognised_key_is_not_processing_config(s3_key):
    with pytest.raises(ValueError, match="Unable to determine processing config"):
        s3_start_transfer.choose_processing_config(s3_key)
