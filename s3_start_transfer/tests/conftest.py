# -*- encoding: utf-8

import pathlib
import secrets
import sys

import pytest

sys.path.append(str(pathlib.Path(__file__).parent.parent / "src"))


@pytest.fixture
def bucket_name():
    return f"bucket-{secrets.token_hex(5)}"
