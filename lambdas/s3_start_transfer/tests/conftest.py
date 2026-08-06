# -*- encoding: utf-8

import pathlib
import secrets
import sys

import pytest

sys.path.append(str(pathlib.Path(__file__).parent.parent / "src"))


@pytest.fixture(autouse=True)
def aws_environment(monkeypatch):
    monkeypatch.delenv("AWS_PROFILE", raising=False)
    monkeypatch.delenv("AWS_DEFAULT_PROFILE", raising=False)
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_SECURITY_TOKEN", "testing")
    monkeypatch.setenv("AWS_SESSION_TOKEN", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")


@pytest.fixture
def bucket_name():
    return f"bucket-{secrets.token_hex(5)}"
