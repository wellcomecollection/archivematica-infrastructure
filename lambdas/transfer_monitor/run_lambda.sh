#!/usr/bin/env bash

set -o errexit
set -o nounset

if (( $# != 1 ))
then
  echo "Usage: $0 <prod|staging>" >&2
  exit 1
fi

case $1 in
  prod)
    FUNCTION_NAME=archivematica-transfer_monitor-prod
    ;;

  staging)
    FUNCTION_NAME=archivematica-transfer_monitor-staging
    ;;

  *)
    echo "Usage: $0 <prod|staging>" >&2
    exit 1
    ;;
esac


ENV_VARS=$(aws lambda get-function-configuration \
  --function-name "$FUNCTION_NAME" \
  | jq .Environment.Variables
)

export TRANSFER_BUCKET=$(echo "$ENV_VARS" | jq -r .TRANSFER_BUCKET)
export REPORTING_FILES_INDEX=$(echo "$ENV_VARS" | jq -r .REPORTING_FILES_INDEX)
export DAYS_TO_CHECK=$(echo "$ENV_VARS" | jq -r .DAYS_TO_CHECK)
export ENVIRONMENT=$(echo "$ENV_VARS" | jq -r .ENVIRONMENT)
#
# export HOLDINGS_READER_TOPIC_ARN=$(echo "$ENVIRONMENT" | jq -r .HOLDINGS_READER_TOPIC_ARN)
#
python3 src/transfer_monitor.py
