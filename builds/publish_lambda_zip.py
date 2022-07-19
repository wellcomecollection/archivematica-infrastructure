#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""
Build a deployment ZIP for a Lambda, and upload it to Amazon S3.

Usage:
  publish_lambda_zip.py <PATH> --bucket=<BUCKET> --key=<KEY> [--sns-topic=<topic_arn>]
  publish_lambda_zip.py -h | --help

Options:
  <PATH>                Path to the source code for the Lambda
  --bucket=<BUCKET>     Name of the Amazon S3 bucket
  --key=<KEY>           Key for the upload ZIP file
  --sns-topic=<topic_arn>  If supplied, send a message about the push to this
                           SNS topic.

"""

import os
import shutil
import subprocess
import tempfile
import zipfile

import boto3
from botocore.exceptions import ClientError
import docopt

from tooling import compare_zip_files


def cmd(*args):
    return subprocess.check_output(list(args)).decode('utf8').strip()


def git(*args):
    return cmd('git', *args)


ROOT = git('rev-parse', '--show-toplevel')

ZIP_DIR = os.path.join(ROOT, '.lambda_zips')


def create_zip(src, dst):
    """
    Zip a source directory into a target directory.

    Based on https://stackoverflow.com/a/14569017/1558022
    """
    with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zf:
        abs_src = os.path.abspath(src)
        for dirname, subdirs, files in os.walk(src):
            for filename in files:
                if filename.startswith('.'):
                    continue
                absname = os.path.abspath(os.path.join(dirname, filename))
                arcname = absname[len(abs_src) + 1:]
                zf.write(absname, arcname)


def build_lambda_local(path, name):
    """
    Construct a Lambda ZIP bundle on the local disk.  Returns the path to
    the constructed ZIP bundle.

    :param path: Path to the Lambda source code.
    """
    print(f'*** Building Lambda ZIP for {name}')
    target = tempfile.mkdtemp()

    # Copy all the associated source files to the Lambda directory.
    src = os.path.join(path, "src")
    for f in os.listdir(src):
        if f.startswith((
            # Required for tests, but unneeded in our prod images
            'test_',
            '__pycache__',
            'docker-compose.yml',

            # Hidden files
            '.',

            # Required for installation, not for our prod Lambdas
            'requirements.in',
            'requirements.txt',
        )):
            continue

        try:
            shutil.copy(
                src=os.path.join(src, f),
                dst=os.path.join(target, os.path.basename(f))
            )
        except IsADirectoryError:
            shutil.copytree(
                src=os.path.join(src, f),
                dst=os.path.join(target, os.path.basename(f))
            )

    # Now install any additional pip dependencies.
    for reqs_file in [
        os.path.join(path, "requirements.txt"),
        os.path.join(path, "src", "requirements.txt"),
    ]:
        if os.path.exists(reqs_file):
            print(f"*** Installing dependencies from {reqs_file}")
            subprocess.check_call([
                'pip3', 'install', '--requirement', reqs_file, '--target', target
            ])
        else:
            print(f"*** No requirements.txt found at {reqs_file}")

    print(f'*** Creating zip bundle for {name}')
    os.makedirs(ZIP_DIR, exist_ok=True)
    src = target
    dst = os.path.join(ZIP_DIR, name)
    create_zip(src=src, dst=dst)
    return dst


def upload_to_s3(client, filename, bucket, key):
    print(f'*** Uploading {filename} to S3')

    # Download the file from S3, and compare it to the locally built ZIP.
    # If they have the same contents, we can save uploading to S3 (and skip
    # deploying a new version).
    _, tempname = tempfile.mkstemp()
    try:
        client.download_file(Bucket=bucket, Key=key, Filename=tempname)
    except ClientError as err:
        if err.response['Error']['Code'] == '404':
            print('*** No existing S3 object found, so uploading new file')
        else:
            raise
    else:
        if compare_zip_files(filename, tempname):
            print('*** Uploaded ZIP is already the most up-to-date code')
            return
        else:
            print('*** Differences between uploaded and built ZIP, re-uploading')

    client.upload_file(
        Bucket=bucket,
        Filename=filename,
        Key=key
    )


if __name__ == '__main__':
    args = docopt.docopt(__doc__)

    path = args['<PATH>']
    key = args['--key']
    bucket = args['--bucket']

    topic_arn = args['--sns-topic']

    client = boto3.client('s3')
    name = os.path.basename(key)
    filename = build_lambda_local(path=path, name=name)

    upload_to_s3(client=client, filename=filename, bucket=bucket, key=key)

    if topic_arn is not None:
        import json

        sns_client = boto3.client('sns')

        get_user_output = cmd('aws', 'iam', 'get-user')
        iam_user = json.loads(get_user_output)['User']['UserName']

        message = {
            'commit_id': git('rev-parse', '--abbrev-ref', 'HEAD'),
            'commit_msg': git('log', '-1', '--oneline', '--pretty=%B'),
            'git_branch': git('rev-parse', '--abbrev-ref', 'HEAD'),
            'iam_user': iam_user,
            'project': name,
            'push_type': 'aws_lambda',
        }
        sns_client.publish(TopicArn=topic_arn, Message=json.dumps(message))
