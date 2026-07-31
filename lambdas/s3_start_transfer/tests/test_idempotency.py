import concurrent.futures
import datetime as dt
import threading
from unittest.mock import patch

from botocore.exceptions import ClientError
import pytest

from idempotency import (
    EventLedger,
    S3EventIdentity,
    SUBMITTED,
    SUBMITTING,
    UNKNOWN,
)


def _event(*, sequencer="0001", version_id=None):
    return S3EventIdentity(
        bucket="transfer-bucket",
        object_key="born-digital/package name.zip",
        event_name="ObjectCreated:Put",
        sequencer=sequencer,
        version_id=version_id,
    )


def test_s3_event_identity_preserves_event_fields():
    event = S3EventIdentity.from_record(
        {
            "eventName": "ObjectCreated:CompleteMultipartUpload",
            "s3": {
                "bucket": {"name": "transfer-bucket"},
                "object": {
                    "key": "born-digital%2Fpackage+name.zip",
                    "sequencer": "00ABC123",
                    "versionId": "version-1",
                },
            },
        }
    )

    assert event == S3EventIdentity(
        bucket="transfer-bucket",
        object_key="born-digital/package name.zip",
        event_name="ObjectCreated:CompleteMultipartUpload",
        sequencer="00ABC123",
        version_id="version-1",
    )


def test_sequencer_and_version_id_are_part_of_event_identity():
    original = _event()

    assert _event(sequencer="0002").event_id != original.event_id
    assert _event(version_id="version-1").event_id != original.event_id
    assert (
        _event(version_id="version-2").event_id
        != _event(version_id="version-1").event_id
    )


def test_sequential_claim_of_same_event_has_one_winner(idempotency_table):
    ledger = EventLedger(idempotency_table)
    event = _event()

    assert ledger.claim(event)
    assert not ledger.claim(event)

    item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
    assert item["state"] == SUBMITTING
    assert item["bucket"] == event.bucket
    assert item["object_key"] == event.object_key
    assert item["event_name"] == event.event_name
    assert item["sequencer"] == event.sequencer
    assert "expires_at" not in item


def test_concurrent_claim_of_same_event_has_one_winner(idempotency_table):
    ledger = EventLedger(idempotency_table)
    event = _event()
    barrier = threading.Barrier(2)

    def claim():
        barrier.wait()
        return ledger.claim(event)

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        results = list(executor.map(lambda _: claim(), range(2)))

    assert sorted(results) == [False, True]
    assert idempotency_table.scan()["Count"] == 1


def test_claim_propagates_dynamodb_failure(idempotency_table):
    ledger = EventLedger(idempotency_table)
    dynamodb_error = ClientError(
        {"Error": {"Code": "InternalServerError", "Message": "unavailable"}},
        "PutItem",
    )

    with patch.object(
        idempotency_table, "put_item", side_effect=dynamodb_error
    ), pytest.raises(ClientError, match="InternalServerError"):
        ledger.claim(_event())


def test_submitting_event_is_marked_submitted_with_uuid_and_ttl(
    idempotency_table,
):
    ledger = EventLedger(idempotency_table)
    event = _event(version_id="version-1")
    claimed_at = dt.datetime(2026, 7, 31, 8, 0, tzinfo=dt.timezone.utc)
    submitted_at = claimed_at + dt.timedelta(minutes=1)

    ledger.claim(event, now=claimed_at)
    ledger.mark_submitted(event, "transfer-uuid", now=submitted_at)

    item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
    assert item["state"] == SUBMITTED
    assert item["transfer_uuid"] == "transfer-uuid"
    assert item["version_id"] == "version-1"
    assert item["submitted_at"] == "2026-07-31T08:01:00Z"
    assert item["expires_at"] == int((submitted_at + dt.timedelta(days=90)).timestamp())


def test_unknown_event_does_not_have_ttl(idempotency_table):
    ledger = EventLedger(idempotency_table)
    event = _event()

    ledger.claim(event)
    ledger.mark_unknown(event)

    item = idempotency_table.get_item(Key={"event_id": event.event_id})["Item"]
    assert item["state"] == UNKNOWN
    assert "transfer_uuid" not in item
    assert "expires_at" not in item
