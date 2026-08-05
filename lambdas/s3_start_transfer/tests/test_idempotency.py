from idempotency import S3EventIdentity


def _event(*, sequencer="0001", version_id=None):
    return S3EventIdentity(
        bucket="transfer-bucket",
        object_key="born-digital/package name.zip",
        event_name="ObjectCreated:Put",
        sequencer=sequencer,
        version_id=version_id,
        event_time="2026-07-31T08:00:00.000Z",
    )


def test_s3_event_identity_preserves_event_fields():
    event = S3EventIdentity.from_record(
        {
            "eventName": "ObjectCreated:CompleteMultipartUpload",
            "eventTime": "2026-07-31T08:00:00.000Z",
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
        event_time="2026-07-31T08:00:00.000Z",
    )


def test_sequencer_and_version_id_are_part_of_event_identity():
    original = _event()

    assert _event(sequencer="0002").event_id != original.event_id
    assert _event(version_id="version-1").event_id != original.event_id
    assert (
        _event(version_id="version-2").event_id
        != _event(version_id="version-1").event_id
    )
