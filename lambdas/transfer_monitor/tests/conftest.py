# -*- encoding: utf-8

import json
import pathlib
import sys
import urllib.request

import boto3
import pytest
from moto import mock_aws

sys.path.append(str(pathlib.Path(__file__).parent.parent / "src"))

REPORTING_SECRET = "archivematica/transfer_monitor/reporting_credentials"
SLACK_SECRET = "archivematica/transfer_monitor/slack_webhook"

ES_ENDPOINT = "https://es.example"
SLACK_WEBHOOK = "https://hooks.slack.example/services/T000/B000/XXX"


class RecordingSession:
    """A boto3 Session that records every AWS API call made through it."""

    def __init__(self, calls):
        self._session = boto3.Session()
        self._calls = calls

    def client(self, name, **kwargs):
        client = self._session.client(name, **kwargs)
        client.meta.events.register("before-call", self._record)
        return client

    def _record(self, model, **kwargs):
        self._calls.append(f"{model.service_model.service_name}.{model.name}")


class FakeResponse:
    def __init__(self, payload):
        self._payload = json.dumps(payload).encode("utf8")

    def read(self):
        return self._payload

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


class FakeUrlopen:
    """
    Stands in for urllib.request.urlopen, recording each call so tests can
    count Elasticsearch queries and check every request had a timeout.
    """

    def __init__(self, stored_names=()):
        self.calls = []
        self.stored_names = list(stored_names)

    def __call__(self, req, timeout=None):
        self.calls.append({"url": req.full_url, "timeout": timeout})

        if req.full_url.startswith(ES_ENDPOINT):
            body = json.loads(req.data)
            identifier = body["query"]["bool"]["filter"][0]["term"][
                "externalIdentifier"
            ]
            hits = [
                {"_source": {"name": name}}
                for name in self.stored_names
                if name.startswith(f"{identifier}/")
            ]
            return FakeResponse({"hits": {"hits": hits}})

        return FakeResponse({})

    @property
    def es_calls(self):
        return [c for c in self.calls if c["url"].startswith(ES_ENDPOINT)]


@pytest.fixture(autouse=True)
def aws_environment(monkeypatch):
    monkeypatch.delenv("AWS_PROFILE", raising=False)
    monkeypatch.delenv("AWS_DEFAULT_PROFILE", raising=False)
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_SECURITY_TOKEN", "testing")
    monkeypatch.setenv("AWS_SESSION_TOKEN", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")


# Depends on aws_environment: transfer_monitor builds a boto3 Session at module
# scope, so the env must be clean before the first import.
@pytest.fixture
def monitor(aws_environment):
    """
    transfer_monitor with both caches cleared.

    The caches are module scope, so without this a cached secret or file
    listing would leak between tests and hide the call counts under test.
    """
    import transfer_monitor

    transfer_monitor.get_secret_string.cache_clear()
    transfer_monitor.get_stored_xml_file_names.cache_clear()

    yield transfer_monitor

    transfer_monitor.get_secret_string.cache_clear()
    transfer_monitor.get_stored_xml_file_names.cache_clear()


@pytest.fixture
def aws(monitor, monkeypatch):
    """Runs the lambda against moto, recording the AWS calls it makes."""
    with mock_aws():
        calls = []
        monkeypatch.setattr(monitor, "sess", RecordingSession(calls))

        secrets = boto3.client("secretsmanager")
        secrets.create_secret(
            Name=REPORTING_SECRET,
            SecretString=json.dumps(
                {"endpoint": ES_ENDPOINT, "api_key": "api-key-123"}
            ),
        )
        secrets.create_secret(Name=SLACK_SECRET, SecretString=SLACK_WEBHOOK)

        yield calls


@pytest.fixture
def bucket_name():
    return "transfer-source-test"


@pytest.fixture
def transfer_bucket(aws, bucket_name, monkeypatch):
    boto3.client("s3").create_bucket(Bucket=bucket_name)

    monkeypatch.setenv("TRANSFER_BUCKET", bucket_name)
    monkeypatch.setenv("REPORTING_FILES_INDEX", "files-index")
    monkeypatch.setenv("DAYS_TO_CHECK", "7")
    monkeypatch.setenv("ENVIRONMENT", "staging")

    return bucket_name


@pytest.fixture
def upload_package(transfer_bucket):
    """Puts a tagged .zip in the transfer bucket, as s3_start_transfer would."""
    s3 = boto3.client("s3")

    def _upload(key, *, transfer_id, external_identifier):
        s3.put_object(Bucket=transfer_bucket, Key=key, Body=b"zip")
        s3.put_object_tagging(
            Bucket=transfer_bucket,
            Key=key,
            Tagging={
                "TagSet": [
                    {"Key": "Archivematica-TransferId", "Value": transfer_id},
                    {
                        "Key": "Archivematica-CatalogueIdentifier",
                        "Value": external_identifier,
                    },
                ]
            },
        )

    return _upload


@pytest.fixture
def urlopen(monkeypatch):
    """Replaces urlopen, so no test reaches Elasticsearch or Slack."""

    def _install(stored_names=()):
        fake = FakeUrlopen(stored_names)
        monkeypatch.setattr(urllib.request, "urlopen", fake)
        return fake

    return _install
