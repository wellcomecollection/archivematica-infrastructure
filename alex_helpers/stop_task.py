#!/usr/bin/env python
# -*- encoding: utf-8

from pprint import pprint

import boto3

ecs = boto3.client("ecs")

resp = ecs.list_tasks(cluster="archivematica")

for task in resp["taskArns"]:
    print(task)
    ecs.stop_task(cluster="archivematica", task=task)
