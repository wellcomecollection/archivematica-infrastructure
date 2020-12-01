#!/usr/bin/env bash
# If an Archivematica transfer package hasn't been picked up -- e.g. if the transfer
# Lambda was temporarily broken -- you can use this script to restart it.
#
# It copies the object back into the S3 bucket, thus re-triggering the Lambda.
#
# Usage: retry_transfer_package.sh <S3_URI>
#

set -o errexit
set -o nounset

S3_URI="$1"
TMP_URI="s3://wellcomedigitisation-infra/tmp/archivematica-$(uuidgen).zip"

AWS_PROFILE=digitisation-dev aws s3 cp "$S3_URI" "$TMP_URI"
AWS_PROFILE=digitisation-dev aws s3 cp "$TMP_URI" "$S3_URI"
