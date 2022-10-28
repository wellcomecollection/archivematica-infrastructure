# -*- encoding: utf-8

import io
import secrets

import boto3
from moto import mock_s3
import pytest

from big_s3 import S3File


class TestS3File:
    def _create_s3_file(self, s3, *, body=None):
        bucket_name = f"bucket-{secrets.token_hex(5)}"

        key = secrets.token_hex()
        bucket = s3.Bucket(bucket_name)
        bucket.create()

        if body is None:
            body = secrets.token_hex().encode("utf8")

        bucket.put_object(Key=key, Body=body)

        s3_object = bucket.Object(key)
        return S3File(s3_object)

    @mock_s3
    def test_can_read_whole_file(self):
        s3 = boto3.resource("s3")

        body = b"Hello world, this is a message"

        s3_file = self._create_s3_file(s3, body=body)
        assert s3_file.read() == body

    def test_repr(self, bucket_name):
        s3 = boto3.resource("s3")
        s3_object = s3.Object("bukkit", "example.txt")
        s3_file = S3File(s3_object)
        assert repr(s3_file) == f"<S3File s3_object={s3_object!r}>"

    @mock_s3
    def test_can_tell_file(self):
        s3 = boto3.resource("s3")
        s3_file = self._create_s3_file(s3)

        assert s3_file.tell() == 0
        s3_file.read(size=5)
        assert s3_file.tell() == 5
        s3_file.read(size=5)
        assert s3_file.tell() == 10

    @mock_s3
    def test_can_seek_to_start_of_file(self):
        s3 = boto3.resource("s3")
        s3_file = self._create_s3_file(s3, body="Hello, this is my message")

        s3_file.seek(offset=7, whence=io.SEEK_SET)
        assert s3_file.read(size=4) == b"this"

    @mock_s3
    def test_is_seekable(self):
        s3 = boto3.resource("s3")
        s3_file = self._create_s3_file(s3)

        assert s3_file.seekable()

    @mock_s3
    def test_is_readable(self):
        s3 = boto3.resource("s3")
        s3_file = self._create_s3_file(s3)

        assert s3_file.readable()

    @mock_s3
    def test_invalid_whence_is_error(self):
        s3 = boto3.resource("s3")
        s3_file = self._create_s3_file(s3)

        with pytest.raises(ValueError, match="invalid whence"):
            s3_file.seek(offset=0, whence=io.SEEK_SET + io.SEEK_CUR + io.SEEK_END + 1)

    @mock_s3
    def test_reading_more_than_file_reads_to_end(self):
        s3 = boto3.resource("s3")
        s3_file = self._create_s3_file(s3, body="Hello")

        assert s3_file.read(size=10) == b"Hello"
