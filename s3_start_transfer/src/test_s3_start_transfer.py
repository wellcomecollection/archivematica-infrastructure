# -*- encoding: utf-8 -*-

import json

import pytest
from unittest.mock import call, patch


import sys

import s3_start_transfer


class TestStartTransfer:
    @patch.object(s3_start_transfer, 'ss_api_get')
    def test_get_target_location(self, mock_ss_get):
        mock_ss_get.side_effect = [
            {
                'objects':  [
                    {'relative_path': '/path/a', 'space': '/api/v2/space/1', 'uuid': 'space1-uuid'},
                    {'relative_path': '/path/b', 'space': '/api/v2/space/1', 'uuid': 'space2-uuid'},
                ]
            },
            {'s3_bucket': 'bucket01'},
        ]
        assert s3_start_transfer.get_target_location('bucket01', 'path/a/test1.zip') == b'space1-uuid:/test1.zip'

        mock_ss_get.assert_has_calls([
            call('/api/v2/location/', {'space__access_protocol': 'S3', 'purpose': 'TS'}),
            call('/api/v2/space/1'),
        ])

    @patch.object(s3_start_transfer, 'ss_api_get')
    def test_get_target_location_no_path_match(self, mock_ss_get):
        mock_ss_get.return_value = {
            'objects':  [
                {'relative_path': '/path/a', 'space': '/api/v2/space/1', 'uuid': 'space1-uuid'},
            ]
        }

        assert s3_start_transfer.get_target_location('bucket02', 'path/x/test1.zip') is None

        mock_ss_get.assert_has_calls([
            call('/api/v2/location/', {'space__access_protocol': 'S3', 'purpose': 'TS'}),
        ])

    @patch.object(s3_start_transfer, 'ss_api_get')
    def test_get_target_location_no_bucket_match(self, mock_ss_get):
        mock_ss_get.side_effect = [
            {
                'objects':  [
                    {'relative_path': '/path/a', 'space': '/api/v2/space/1', 'uuid': 'space1-uuid'},
                ]
            },
            {'s3_bucket': 'bucket01'},
        ]

        assert s3_start_transfer.get_target_location('bucket03', 'path/a/test1.zip') is None

        mock_ss_get.assert_has_calls([
            call('/api/v2/location/', {'space__access_protocol': 'S3', 'purpose': 'TS'}),
            call('/api/v2/space/1'),
        ])

    @patch.object(s3_start_transfer, 'am_api_post_json')
    def test_start_transfer(self, mock_am_post):
        mock_am_post.return_value = {'id': 'my-transfer-id'}

        assert s3_start_transfer.start_transfer(
            'test1.zip', b'space1-uuid:/test1.zip') == 'my-transfer-id'

        mock_am_post.assert_called_once_with(
            "/api/v2beta/package", {
                "name": "test1.zip",
                "type": "zipfile",
                "path": "c3BhY2UxLXV1aWQ6L3Rlc3QxLnppcA==",
                "processing_config": "automated",
                "auto_approve": True,
            }
        )

    @patch.object(s3_start_transfer.requests, 'get')
    def test_ss_api_get(self, mock_get, monkeypatch):
        monkeypatch.setenv('ARCHIVEMATICA_SS_URL', 'http://archivematica-ss.example.com')
        monkeypatch.setenv('ARCHIVEMATICA_SS_USERNAME', 'ss_username')
        monkeypatch.setenv('ARCHIVEMATICA_SS_API_KEY', 'ss_api_key')
        mock_get.return_value.json.return_value = {'c': 'd'}

        response = s3_start_transfer.ss_api_get('/api/v2/path', {'a': 'b'})

        assert response == {'c': 'd'}
        mock_get.assert_called_with(
            'http://archivematica-ss.example.com/api/v2/path',
            params={'a': 'b'},
            headers={"Authorization": "ApiKey ss_username:ss_api_key"}
        )

    @patch.object(s3_start_transfer.requests, 'post')
    def test_am_api_post_json(self, mock_post, monkeypatch):
        monkeypatch.setenv('ARCHIVEMATICA_URL', 'http://archivematica.example.com')
        monkeypatch.setenv('ARCHIVEMATICA_USERNAME', 'am_username')
        monkeypatch.setenv('ARCHIVEMATICA_API_KEY', 'am_api_key')
        mock_post.return_value.json.return_value = {'c': 'd'}

        s3_start_transfer.am_api_post_json('/api/v2/path', {'a': 'b'})

        mock_post.assert_called_with(
            'http://archivematica.example.com/api/v2/path',
            json={'a': 'b'},
            headers={"Authorization": "ApiKey am_username:am_api_key"}
        )

    @patch.object(s3_start_transfer, 'start_transfer')
    @patch.object(s3_start_transfer, 'get_target_location')
    def test_main(self, mock_get_target_location, mock_start_transfer):
        events = {
            'Records': [
                {
                    's3': {
                        'bucket': {'name': 'test-bucket'},
                        'object': {'key': '/path/test-key'},
                    }
                }
            ]
        }

        s3_start_transfer.main(events)

        mock_get_target_location.assert_called_with('test-bucket', '/path/test-key')
        mock_start_transfer.assert_called_with('test-key', mock_get_target_location.return_value)
