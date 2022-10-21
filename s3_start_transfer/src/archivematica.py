"""
Code for talking to Archivematica.
"""

import base64
import collections
import json
import os
import urllib.parse
import urllib.request


class StartTransferException(Exception):
    pass


class StoragePathException(Exception):
    pass


def am_api_post_json(api_path, data):
    """
    POST json to the Archivematica API
    :param api_path: URL path to request (without hostname, e.g. /api/v2/location/)
    :param data: Dict of data to post
    :returns: dict of json data returned by request
    """
    am_url = os.environ["ARCHIVEMATICA_URL"]
    am_user = os.environ["ARCHIVEMATICA_USERNAME"]
    am_api_key = os.environ["ARCHIVEMATICA_API_KEY"]
    am_headers = {"Authorization": f"ApiKey {am_user}:{am_api_key}"}

    url = f"{am_url}{api_path}"
    data = json.dumps(data).encode("utf-8")
    print(f"URL: {url}; Data: {data}")

    request = urllib.request.Request(
        url,
        data=data,
        headers={**am_headers, "Content-Type": "application/json"},
        method="POST",
    )
    response = urllib.request.urlopen(request)
    print(f"Response: {response}")
    response_json = json.loads(response.read())
    print(f"Response JSON: {response_json}")
    return response_json


def ss_api_get(api_path, params=None):
    """
    GET request to the Archivematica storage service API
    :param api_path: URL path to request (without hostname, e.g. /api/v2/location/)
    :param params: Dict of params to include in the request
    :returns: dict of json data returned by request
    """
    params = params or {}

    ss_url = os.environ["ARCHIVEMATICA_SS_URL"]
    ss_user = os.environ["ARCHIVEMATICA_SS_USERNAME"]
    ss_api_key = os.environ["ARCHIVEMATICA_SS_API_KEY"]
    ss_headers = {"Authorization": f"ApiKey {ss_user}:{ss_api_key}"}

    query_string = urllib.parse.urlencode(params)

    url = f"{ss_url}{api_path}?{query_string}"
    print(f"URL: {url}; Params: {params}")

    request = urllib.request.Request(url, headers=ss_headers)
    response = urllib.request.urlopen(request)
    print(f"Response: {response}")
    response_json = json.loads(response.read())
    print(f"Response JSON: {response_json}")
    return response_json


def get_target_path(bucket, directory, key):
    """
    Get the uploaded file's path on the Archivematica storage service,
    as a `<location_uuid>:<target_path>` bytestring returned by `find_matching_path`

    :param bucket: Name of s3 bucket
    :param directory: Top level directory in which key is found
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
            "relative_path": "/uploads/",
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
    # We use an OrderedDict here to improve testability - as it stabilitses
    # the order of the API calls
    all_spaces = collections.OrderedDict(
        (location["space"], None) for location in s3_sources["objects"]
    )
    buckets = {space: ss_api_get(space)["s3_bucket"] for space in all_spaces}
    for location in s3_sources["objects"]:
        location["s3_bucket"] = buckets[location["space"]]

    return find_matching_path(s3_sources["objects"], bucket, directory, key)


def find_matching_path(locations, bucket, directory, key):
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
        relative_path = location["relative_path"].strip("/")

        if relative_path == directory and location["s3_bucket"] == bucket:
            target_path = "/" + key
            return b"%s:%s" % (os.fsencode(location["uuid"]), os.fsencode(target_path))

    raise StoragePathException("Unable to find location for %s:%s" % (bucket, key))


def start_transfer(name, path, processing_config, accession_number=None):
    """
    Start an Archivematica transfer using the automated workflow

    :param name: Name of transfer
    :param key: Path of transfer, of the form b'<location_uuid>:<target_path>'

    :returns: transfer uuid
    """
    # Archivematica processing configs don't support dashes, so replace with underscores
    # See https://wiki.archivematica.org/Archivematica_API#Package
    data = {
        "name": name,
        "type": "zipfile",
        "path": base64.b64encode(path).decode(),
        "processing_config": processing_config.replace("-", "_"),
        "auto_approve": True,
    }

    if accession_number is not None:
        data["accession"] = accession_number

    response_json = am_api_post_json("/api/v2beta/package", data)
    if "error" in response_json:
        raise StartTransferException(
            "Error starting transfer: %s" % response_json["message"]
        )
    return response_json["id"]


def choose_processing_config(key):
    if key.startswith("born-digital/"):
        return "born_digital"
    elif key.startswith("born-digital-accessions/"):
        return "b_dig_accessions"
    else:
        raise ValueError("Unable to determine processing config for key: %r" % key)
