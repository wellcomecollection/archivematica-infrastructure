#!/usr/bin/env bash

set -o errexit
set -o nounset

SERVICE_ID="$1"

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git log -1 --pretty=format:"%H" dockerfiles/$SERVICE_ID)

docker build \
  --file "$ROOT/dockerfiles/$SERVICE_ID/Dockerfile" \
  --tag "$SERVICE_ID:$CURRENT_COMMIT" \
  "$ROOT/dockerfiles/$SERVICE_ID"
