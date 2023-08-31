import datetime
import functools
import json
import os
from urllib.error import HTTPError
import urllib.request

import boto3


@functools.lru_cache
def get_secret_string(sess, *, secret_id):
    """
    Look up the value of a SecretString in Secrets Manager.
    """
    secrets = sess.client("secretsmanager")
    return secrets.get_secret_value(SecretId=secret_id)["SecretString"]


@functools.lru_cache
def has_matching_bag(*, archivematica_transfer_id, external_identifier, files_index):
    """
    Is there a bag with this external identifier and transfer ID in
    the storage service?

    We rely on a bit of knowledge about how Archivematica structures the
    AIP: we know it's going to put a METS file at this location in the
    package:

        data/objects/submissionDocumentation/transfer-{package_name}-{transfer_id}/METS.xml

    so by looking for a matching file in the storage service, we know
    whether something was stored successfully.
    """
    sess = boto3.Session()
    es_credentials = json.loads(
        get_secret_string(
            sess, secret_id="archivematica/transfer_monitor/reporting_credentials"
        )
    )

    endpoint = es_credentials["endpoint"]
    api_key = es_credentials["api_key"]

    # This query looks for the most recently uploaded files that end
    # with '.xml'; unfortunately there's no way to query the index for
    # files by a name suffix.
    #
    # This may be possible in future, see
    # https://github.com/wellcomecollection/storage-service/issues/1028
    #
    # If a transfer package contains lots of XML files, this lookup may
    # fail because the METS file wasn't in the first 10,000 results.
    # If that occurs, we should consider scheduling the storage service
    # work in the ticket above, and
    query = {
        "query": {
            "bool": {
                "filter": [
                    {"term": {"externalIdentifier": external_identifier}},
                    {"term": {"suffix": "xml"}},
                ]
            }
        },
        "_source": ["name"],
        "sort": [{"createdDate": {"order": "desc"}}],
        "size": 10000,
    }

    req = urllib.request.Request(
        f"{endpoint}/{files_index}/_search",
        data=json.dumps(query).encode("utf-8"),
        headers={
            "Authorization": f"ApiKey {api_key}",
            "Content-Type": "application/json",
        },
    )

    resp = urllib.request.urlopen(req)
    es_resp = json.loads(resp.read())

    return any(
        h["_source"]["name"].endswith(f"-{archivematica_transfer_id}/METS.xml")
        for h in es_resp["hits"]["hits"]
    )


def get_recent_objects(sess, *, bucket, days):
    """
    Generates recent objects in the S3 bucket, and their tags.
    """
    s3 = sess.client("s3")
    paginator = s3.get_paginator("list_objects_v2")

    # TODO: Do we need to do a date restriction?  Could we look at
    # the entire bucket every time?
    last_modified_after = datetime.datetime.now() - datetime.timedelta(days=days)

    for page in paginator.paginate(Bucket=bucket):
        for s3_obj in page["Contents"]:
            # Vanilla Python can only create offset-naive datetimes, whereas
            # the S3 API returns a UTC datetime which is offset-aware.  Trying
            # to compare the two gives an error:
            #
            #       TypeError: can't compare offset-naive and
            #       offset-aware datetimes
            #
            # But this is only a loose heuristic, so it's okay to drop the
            # timezone info from S3.
            if s3_obj["LastModified"].replace(tzinfo=None) < last_modified_after:
                continue

            # Fetch the tags from S3 and attach them to the object.
            tagging = s3.get_object_tagging(Bucket=bucket, Key=s3_obj["Key"])
            s3_obj["Tags"] = {t["Key"]: t["Value"] for t in tagging["TagSet"]}

            yield s3_obj


def post_to_slack(*, webhook_url, results, days_to_check, environment):
    """
    Send a message to Slack about the results.  Here's an example of
    the sort of message is sends:

        Here’s what happened in Archivematica in the last 7 days:

        🚨 These packages didn’t get stored successfully:
        - born-digital/test_package.zip (d5669206-65bb-4e21-9689-d095b4a828c6)

        These packages were stored successfully:
        - born-digital/test_package2.zip

    """
    if environment == "staging":
        name = "Archivematica (staging)"
    else:
        name = "Archivematica"

    if results["failed"] or results["succeeded"]:
        summary = f"Here’s what happened in {name} in the last {days_to_check} day{'s' if days_to_check > 1 else ''}:"
    else:
        summary = f"Nothing happened in {name} in the last {days_to_check} day{'s' if days_to_check > 1 else ''}."

    blocks = [{"type": "section", "text": {"type": "mrkdwn", "text": summary}}]

    failed_packages = [p for p in results["failed"] if p["Key"].endswith(".zip")]

    if failed_packages:
        if environment == "staging":
            warning_emoji = "⚠️"
        else:
            warning_emoji = "🚨"

        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"{warning_emoji} *These packages didn’t get stored successfully:*\n"
                    + "\n".join(
                        f'- {p["Key"]} (`{p["Tags"]["Archivematica-TransferId"]}`)'
                        for p in failed_packages
                    ),
                },
            }
        )

    succeeded_packages = [p for p in results["succeeded"] if p["Key"].endswith(".zip")]

    if succeeded_packages:
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "These packages were stored successfully:\n"
                    + "\n".join(f'- {p["Key"]}' for p in succeeded_packages),
                },
            }
        )

    slack_payload = {"username": "Archivematica transfer report", "blocks": blocks}

    req = urllib.request.Request(
        webhook_url,
        data=json.dumps(slack_payload).encode("utf8"),
        headers={"Content-Type": "application/json"},
    )

    try:
        urllib.request.urlopen(req)
    except HTTPError as err:
        raise Exception(f"{err} - {err.read()}")


def run_transfer_lambda():
    sess = boto3.Session()

    transfer_bucket = os.environ["TRANSFER_BUCKET"]
    files_index = os.environ["REPORTING_FILES_INDEX"]
    days_to_check = int(os.environ["DAYS_TO_CHECK"])
    environment = os.environ["ENVIRONMENT"]

    # Categorise all the S3 objects that are tagged with a TransferId
    # as "succeeded" or "failed".
    results = {"succeeded": [], "failed": []}

    for s3_obj in get_recent_objects(sess, bucket=transfer_bucket, days=days_to_check):
        print(f"Inspecting {s3_obj['Key']}")
        if "Archivematica-TransferId" not in s3_obj["Tags"]:
            continue

        if has_matching_bag(
            archivematica_transfer_id=s3_obj["Tags"]["Archivematica-TransferId"],
            external_identifier=s3_obj["Tags"].get(
                "Archivematica-CatalogueIdentifier",
                s3_obj["Tags"].get("Archivematica-AccessionNumber"),
            ),
            files_index=files_index,
        ):
            results["succeeded"].append(s3_obj)
        else:
            results["failed"].append(s3_obj)

    # Send a message to Slack with a summary of the report.
    post_to_slack(
        webhook_url=get_secret_string(
            sess, secret_id="archivematica/transfer_monitor/slack_webhook"
        ),
        results=results,
        days_to_check=days_to_check,
        environment=environment,
    )

    # Once we've reported any successes in Slack, we can trust these were
    # successfully uploaded to the storage service.  Let's delete the objects
    # to keep the transfer bucket clean.
    for s3_obj in results["succeeded"]:
        kwargs = {"Bucket": transfer_bucket, "Key": s3_obj["Key"]}

        try:
            kwargs["VersionId"] = s3_obj["VersionId"]
        except KeyError:
            pass

        sess.client("s3").delete_object(**kwargs)


def main(event, _):
    run_transfer_lambda()


if __name__ == "__main__":
    run_transfer_lambda()
