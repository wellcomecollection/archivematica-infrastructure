import json
import base64
import logging
import os
import os.path
import time
from collections import OrderedDict

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
    :returns: dict of json data returned by request
    """
    am_url = os.environ["ARCHIVEMATICA_URL"]
    am_user = os.environ["ARCHIVEMATICA_USERNAME"]
    am_api_key = os.environ["ARCHIVEMATICA_API_KEY"]
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
    :returns: dict of json data returned by request
    """
    ss_url = os.environ["ARCHIVEMATICA_SS_URL"]
    ss_user = os.environ["ARCHIVEMATICA_SS_USERNAME"]
    ss_api_key = os.environ["ARCHIVEMATICA_SS_API_KEY"]
    ss_headers = {"Authorization": "ApiKey {0}:{1}".format(ss_user, ss_api_key)}

    params = params or {}
    url = "{0}{1}".format(ss_url, api_path)
    print("URL: %s; Params: %s" % (url, params))
    response = requests.get(url, params=params, headers=ss_headers)
    print("Response: %s" % response)
    response_json = response.json()
    print("Response JSON: %s" % response_json)
    return response_json


def get_target_path(bucket, key):
    """
    Get the uploaded file's path on the Archivematica storage service,
    as a `<location_uuid>:<target_path>` bytestring returned by `find_matching_path`

    :param bucket: Name of s3 bucket
    :param key: Name of s3 key
    :returns: bytestring identifying the path
    """

    # Get s3 location matching bucket and key
    # Look for an S3 transfer source that matches the bucket name and prefix
    # and take the transfer ID of that location
    """
    Example of relevant fields in Location API return json:
    {
        "meta": ...
        "objects": [{
            "description": "S3 Transfer Source",
            "purpose": "TS",
            "relative_path": "/test-uploads/",
            "space": "/api/v2/space/6710c8dd-00ad-4614-8f1c-d9be23052179/",
            "uuid": "017fcad6-fb5c-434e-818a-14b812ef6427"
            ...
            }]
    }
    """
    s3_sources = ss_api_get(
        "/api/v2/location/", {"space__access_protocol": "S3", "purpose": "TS"}
    )

    """
    Example of relevant fields in Space API json:
    {
        "access_protocol": "S3",
        "s3_bucket": "wellcomecollection-archivematica-transfer-source",
        "uuid": "6710c8dd-00ad-4614-8f1c-d9be23052179",
        ...
    }
    """
    all_spaces = OrderedDict(
        (location["space"], None) for location in s3_sources["objects"]
    )
    buckets = {space: ss_api_get(space)["s3_bucket"] for space in all_spaces}
    for location in s3_sources["objects"]:
        location["s3_bucket"] = buckets[location["space"]]

    return find_matching_path(s3_sources["objects"], bucket, key)


def find_matching_path(locations, bucket, key):
    """
    Match the given bucket and key to a location and return a path on the
    Archivematica storage service

    This takes the form `<location_uuid>:<target_path>` where:
        `location_uuid` is the UUID of an S3 transfer source `Location` on the
        Archivematica storage service which is configured with the same
        bucket name and (optionally) a relative path that is a parent of the key
        `target_path` is the path of the key within the relative path

    e.g. a Location with bucket `test-bucket`, relative path '/test/path' and uuid 123 will match for
    bucket='test-bucket' and key='/test/path/subdir/file.zip'
    The return value will be '123:/subdir/file.zip'

    :param locations: Iterable of location dicts,
            each with `relative_path`, `s3_bucket` and `uuid` fields
    :param bucket: Name of s3 bucket
    :param key: Name of s3 key
    :returns: bytestring identifying the path
    """

    for location in locations:
        relative_path = location["relative_path"].strip(os.sep)

        if key.startswith(relative_path) and location["s3_bucket"] == bucket:
            target_path = key.split(relative_path, 1)[-1]
            return b"%s:%s" % (fsencode(location["uuid"]), fsencode(target_path))


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
    return response_json["id"]


def main(event, context=None):
    # Get the object from the event and show its content type
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = urllib.parse.unquote_plus(
        event["Records"][0]["s3"]["object"]["key"], encoding="utf-8"
    )
    target_name = os.path.basename(key)

    target_path = get_target_path(bucket, key)

    # Start the transfer
    if target_path:
        transfer_id = start_transfer(target_name, target_path)

        print("Started transfer {}".format(transfer_id))
    else:
        print("Cannot find S3 transfer source for {} in bucket {}".format(bucket, key))


if __name__ == "__main__":
    key = "test-uploads/PPTHW_2466.zip"
    main(
        {
            "Records": [
                {
                    "s3": {
                        "bucket": {
                            "name": "wellcomecollection-archivematica-transfer-source"
                        },
                        "object": {"key": key},
                    }
                }
            ]
        },
        None,
    )
