#!/usr/bin/env bash

set -o errexit
set -o nounset

ACCOUNT_ID="299497370133"
SERVICE_ID="$1"

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git log -1 --pretty=format:"%H" archivematica-apps/$SERVICE_ID)

ROOT=$(git rev-parse --show-toplevel)

echo "*** Logging in to ECR Private"
eval $(aws ecr get-login --no-include-email --registry-ids "$ACCOUNT_ID")

LOCAL_IMAGE_TAG="$SERVICE_ID:$CURRENT_COMMIT"
REMOTE_IMAGE_TAG="$ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/weco/$LOCAL_IMAGE_TAG"

echo "*** Pushing $LOCAL_IMAGE_TAG to $REMOTE_IMAGE_TAG"
docker tag "$LOCAL_IMAGE_TAG" "$REMOTE_IMAGE_TAG"
docker push "$REMOTE_IMAGE_TAG"
docker rmi "$REMOTE_IMAGE_TAG"

buildkite-agent annotate --append --style info "Published image $LOCAL_IMAGE_TAG\n"
