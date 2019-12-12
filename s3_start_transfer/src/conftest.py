# -*- encoding: utf-8

import secrets

import pytest


@pytest.fixture
def bucket_name():
    return f"bucket-{secrets.token_hex(5)}"
