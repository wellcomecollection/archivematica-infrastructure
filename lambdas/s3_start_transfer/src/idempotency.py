import dataclasses
import datetime as dt
import hashlib
import json
import os
import urllib.parse

from botocore.exceptions import ClientError


SUBMITTING = "SUBMITTING"
SUBMITTED = "SUBMITTED"
UNKNOWN = "UNKNOWN"
SUBMITTED_RETENTION = dt.timedelta(days=90)


@dataclasses.dataclass(frozen=True)
class S3EventIdentity:
    bucket: str
    object_key: str
    event_name: str
    sequencer: str
    version_id: str = None

    @classmethod
    def from_record(cls, record):
        s3_object = record["s3"]["object"]

        return cls(
            bucket=record["s3"]["bucket"]["name"],
            object_key=urllib.parse.unquote_plus(s3_object["key"], encoding="utf-8"),
            event_name=record["eventName"],
            sequencer=s3_object["sequencer"],
            version_id=s3_object.get("versionId"),
        )

    @property
    def event_id(self):
        identity = {
            "bucket": self.bucket,
            "event_name": self.event_name,
            "object_key": self.object_key,
            "sequencer": self.sequencer,
            "version_id": self.version_id,
        }
        encoded_identity = json.dumps(
            identity, ensure_ascii=False, separators=(",", ":"), sort_keys=True
        ).encode("utf-8")

        return hashlib.sha256(encoded_identity).hexdigest()


def _utc_now():
    return dt.datetime.now(dt.timezone.utc)


def _format_timestamp(timestamp):
    return timestamp.isoformat().replace("+00:00", "Z")


class EventLedger:
    def __init__(self, table):
        self._table = table

    @classmethod
    def from_session(cls, sess):
        table_name = os.environ["IDEMPOTENCY_TABLE_NAME"]
        table = sess.resource("dynamodb").Table(table_name)
        return cls(table)

    def claim(self, event, *, now=None):
        now = now or _utc_now()
        timestamp = _format_timestamp(now)
        item = {
            "event_id": event.event_id,
            "bucket": event.bucket,
            "object_key": event.object_key,
            "event_name": event.event_name,
            "sequencer": event.sequencer,
            "state": SUBMITTING,
            "created_at": timestamp,
            "updated_at": timestamp,
        }
        if event.version_id is not None:
            item["version_id"] = event.version_id

        try:
            self._table.put_item(
                Item=item,
                ConditionExpression="attribute_not_exists(event_id)",
            )
        except ClientError as err:
            if err.response["Error"]["Code"] == "ConditionalCheckFailedException":
                return False
            raise

        return True

    def mark_submitted(self, event, transfer_uuid, *, now=None):
        now = now or _utc_now()
        submitted_at = _format_timestamp(now)
        expires_at = int((now + SUBMITTED_RETENTION).timestamp())

        self._table.update_item(
            Key={"event_id": event.event_id},
            UpdateExpression=(
                "SET #state = :submitted, transfer_uuid = :transfer_uuid, "
                "submitted_at = :submitted_at, updated_at = :updated_at, "
                "expires_at = :expires_at"
            ),
            ConditionExpression="#state = :submitting",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={
                ":submitting": SUBMITTING,
                ":submitted": SUBMITTED,
                ":transfer_uuid": transfer_uuid,
                ":submitted_at": submitted_at,
                ":updated_at": submitted_at,
                ":expires_at": expires_at,
            },
        )

    def mark_unknown(self, event, *, now=None):
        now = now or _utc_now()
        updated_at = _format_timestamp(now)

        self._table.update_item(
            Key={"event_id": event.event_id},
            UpdateExpression="SET #state = :unknown, updated_at = :updated_at",
            ConditionExpression="#state = :submitting",
            ExpressionAttributeNames={"#state": "state"},
            ExpressionAttributeValues={
                ":submitting": SUBMITTING,
                ":unknown": UNKNOWN,
                ":updated_at": updated_at,
            },
        )
