#!/usr/bin/env bash

set -o errexit
set -o nounset

ACCOUNT_ID="299497370133"
SERVICE_ID="$1"

ROOT=$(git rev-parse --show-toplevel)

echo "*** Logging in to ECR Private"
eval $(aws ecr get-login --no-include-email --registry-ids "$ACCOUNT_ID")

echo "*** Retrieving image tag for $SERVICE_ID"
RELEASE_ID=$(cat "$ROOT/.releases/$SERVICE_ID")
echo "*** Release ID is $RELEASE_ID"

LOCAL_IMAGE_TAG="$SERVICE_ID:$RELEASE_ID"
REMOTE_IMAGE_TAG="$ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/uk.ac.wellcome/$LOCAL_IMAGE_TAG"

echo "*** Pushing $LOCAL_IMAGE_TAG to $REMOTE_IMAGE_TAG"
docker tag "$LOCAL_IMAGE_TAG" "$REMOTE_IMAGE_TAG"
docker push "$REMOTE_IMAGE_TAG"
docker rmi "$REMOTE_IMAGE_TAG"

SSM_PATH="/archivematica/images/prod/$SERVICE_ID"
echo "*** Updating image tag in SSM path $SSM_PATH"
aws ssm put-parameter \
    --name="$SSM_PATH" \
    --value="$REMOTE_IMAGE_TAG" \
    --overwrite \
    --type String
