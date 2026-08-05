import dataclasses
import hashlib
import json
import urllib.parse


@dataclasses.dataclass(frozen=True)
class S3EventIdentity:
    bucket: str
    object_key: str
    event_name: str
    sequencer: str
    event_time: str
    version_id: str | None = None

    @classmethod
    def from_record(cls, record):
        s3_object = record["s3"]["object"]

        return cls(
            bucket=record["s3"]["bucket"]["name"],
            object_key=urllib.parse.unquote_plus(s3_object["key"], encoding="utf-8"),
            event_name=record["eventName"],
            sequencer=s3_object["sequencer"],
            event_time=record["eventTime"],
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
