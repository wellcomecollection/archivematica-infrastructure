import json
import base64
import logging
import os
import os.path
import time
try:
    from botocore.vendored import requests
except ImportError:
    import requests
from os import fsencode
import urllib.parse

print('Loading function')

am_url = os.environ['ARCHIVEMATICA_URL']
am_user = os.environ['ARCHIVEMATICA_USERNAME']
am_api_key = os.environ['ARCHIVEMATICA_API_KEY']
ss_url = os.environ['ARCHIVEMATICA_SS_URL']
ss_user = os.environ['ARCHIVEMATICA_SS_USERNAME']
ss_api_key = os.environ['ARCHIVEMATICA_SS_API_KEY']

transfer_type = 'zipfile'

am_headers = {"Authorization": "ApiKey {0}:{1}".format(am_user, am_api_key)}
ss_headers = {"Authorization": "ApiKey {0}:{1}".format(ss_user, ss_api_key)}


def am_api_post_json(url, data):
    url = "{0}{1}".format(am_url, url)
    print("URL: %s; Data: %s" % (url, data))
    response = requests.post(url, json=data, headers=am_headers)
    print("Response: %s" % response)
    response_json = response.json()
    print("Response JSON: %s" % response_json)
    return response_json


def ss_api_get(url, params=None):
    params = params or {}
    url = "{0}{1}".format(ss_url, url)
    print("URL: %s; Params: %s" % (url, params))
    response = requests.get(url, params=params, headers=ss_headers)
    print("Response: %s" % response)
    response_json = response.json()
    print("Response JSON: %s" % response_json)
    return response_json


def main(event, context):
    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    target_name = os.path.basename(key)

    # Look for an S3 transfer source that matches the bucket name and prefix
    # and take the transfer ID of that location
    relative_path = ''
    target_path = ''
    ts_location_uuid = None
    s3_sources = ss_api_get(
        '/api/v2/location/',
        {
            'space__access_protocol': 'S3',
            'purpose': 'TS'
        }
    )
    for location in s3_sources['objects']:
        relative_path = location['relative_path'].strip(os.sep)
        if key.startswith(relative_path):
            space_bucket = ss_api_get(location['space'])['s3_bucket']
            if space_bucket == bucket:
                ts_location_uuid = location['uuid']
                target_path = key.split(relative_path, 1)[-1]
                break

    # Start the transfer
    if ts_location_uuid:
        path = fsencode(ts_location_uuid) + b":" + fsencode(target_path)
        data = {
            "name": target_name,
            "type": transfer_type,
            "path": base64.b64encode(path).decode(),
            "processing_config": "automated",
            "auto_approve": True,
        }
        response_json = am_api_post_json("/api/v2beta/package", data)

        print("Started transfer {}".format(response_json['id']))
    else:
        print("Cannot find S3 transfer source for {} in bucket {}".format(bucket, key))


if __name__ == '__main__':
    key = 'test-uploads/PPTHW_2466.zip'
    main({
        'Records': [
            {
                's3': {
                    'bucket': { 'name': 'wellcomecollection-archivematica-transfer-source' },
                    'object': { 'key': key },
                }
            }
        ]
    }, None)
