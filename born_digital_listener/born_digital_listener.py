#!/usr/bin/env python3

import datetime
import json
import os

import boto3


def handler(event, context):
    sess = boto3.Session()

    sns = sess.client("sns")
    topic_arn = os.environ["SNS_TOPIC"]

    for ev in event["Records"]:
        sns_message = json.loads(ev["Sns"]["Message"])

        if sns_message["space"] != "born-digital":
            continue

        message = {
            "identifier": sns_message["externalIdentifier"],
            "space": sns_message["space"],
            "version": sns_message["version"],
            "origin": "archivematica",
            "timeSent": datetime.datetime.now().isoformat(),
        }

        sns.publish(TopicArn=topic_arn, Message=json.dumps(message))
