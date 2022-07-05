#!/usr/bin/env bash

set -o errexit
set -o nounset

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git rev-parse HEAD)

SERVICE_ID="$1"

docker build \
  --file "$ROOT/dockerfiles/$SERVICE_ID/Dockerfile" \
  --tag "$SERVICE_ID:$CURRENT_COMMIT" \
  "$ROOT/dockerfiles/$SERVICE_ID"

mkdir -p "$ROOT/.releases"
echo "$CURRENT_COMMIT" > "$ROOT/.releases/$SERVICE_ID"
