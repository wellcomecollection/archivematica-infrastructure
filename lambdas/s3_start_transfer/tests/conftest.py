# -*- encoding: utf-8

import pathlib
import secrets
import sys

import boto3
from moto import mock_dynamodb2
import pytest

sys.path.append(str(pathlib.Path(__file__).parent.parent / "src"))


@pytest.fixture
def bucket_name():
    return f"bucket-{secrets.token_hex(5)}"


@pytest.fixture
def idempotency_table(monkeypatch):
    table_name = f"events-{secrets.token_hex(5)}"
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("IDEMPOTENCY_TABLE_NAME", table_name)

    with mock_dynamodb2():
        table = boto3.resource("dynamodb").create_table(
            TableName=table_name,
            KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
            ProvisionedThroughput={
                "ReadCapacityUnits": 5,
                "WriteCapacityUnits": 5,
            },
        )
        yield table
