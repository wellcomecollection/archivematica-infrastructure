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



def am_api_post_json(url, data):
    """
    POST json to the Archivematica API
    :param api_path: URL path to request (without hostname, e.g. /api/v2/location/)
    :param data: Dict of data to post
    :returns dict of json data returned by request:
    """
    am_url = os.environ['ARCHIVEMATICA_URL']
    am_user = os.environ['ARCHIVEMATICA_USERNAME']
    am_api_key = os.environ['ARCHIVEMATICA_API_KEY']
    am_headers = {"Authorization": "ApiKey {0}:{1}".format(am_user, am_api_key)}

    url = "{0}{1}".format(am_url, url)
    print("URL: %s; Data: %s" % (url, data))
    response = requests.post(url, json=data, headers=am_headers)
    print("Response: %s" % response)
    response_json = response.json()
    print("Response JSON: %s" % response_json)
    return response_json


def ss_api_get(api_path, params=None):
    """
    GET request to the Archivematica storage service API
    :param api_path: URL path to request (without hostname, e.g. /api/v2/location/)
    :param params: Dict of params to include in the request
    :returns dict of json data returned by request:
    """
    ss_url = os.environ['ARCHIVEMATICA_SS_URL']
    ss_user = os.environ['ARCHIVEMATICA_SS_USERNAME']
    ss_api_key = os.environ['ARCHIVEMATICA_SS_API_KEY']
    ss_headers = {"Authorization": "ApiKey {0}:{1}".format(ss_user, ss_api_key)}

    params = params or {}
    url = "{0}{1}".format(ss_url, api_path)
    print("URL: %s; Params: %s" % (url, params))
    response = requests.get(url, params=params, headers=ss_headers)
    print("Response: %s" % response)
    response_json = response.json()
    print("Response JSON: %s" % response_json)
    return response_json


def get_target_location(bucket, key):
    """
    Get an S3 location from the Archivematica storage service
    to match the given bucket and key

    :param bucket: Name of s2 bucket
    :param key: Name of s3 key
    :returns: bytestring identifying location, of the form
        b'<location_uuid>:<target_path>'
    """
    # Get s3 location matching bucket and key
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

                return fsencode(ts_location_uuid) + b":" + fsencode(target_path)

def start_transfer(name, path):
    """
    Start an Archivematica transfer using the automated workflow

    :param name: Name of transfer
    :param key: Path of transfer, of the form b'<location_uuid>:<target_path>'

    :returns: transfer uuid
    """
    data = {
        "name": name,
        "type": "zipfile",
        "path": base64.b64encode(path).decode(),
        "processing_config": "automated",
        "auto_approve": True,
    }
    response_json = am_api_post_json("/api/v2beta/package", data)
    return response_json['id']


def main(event, context=None):
    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    target_name = os.path.basename(key)

    target_path = get_target_location(bucket, key)

    # Start the transfer
    if target_path:
        transfer_id = start_transfer(target_name, target_path)

        print("Started transfer {}".format(transfer_id))
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
