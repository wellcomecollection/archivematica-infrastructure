#!/usr/bin/env bash

set -o errexit
set -o nounset

SERVICE_ID="$1"

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git log -1 --pretty=format:"%H" archivematica-apps/$SERVICE_ID)

docker build \
  --file "$ROOT/archivematica-apps/$SERVICE_ID/Dockerfile" \
  --tag "$SERVICE_ID:$CURRENT_COMMIT" \
  "$ROOT/archivematica-apps/$SERVICE_ID"
