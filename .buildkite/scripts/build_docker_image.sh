#!/usr/bin/env bash

set -o errexit
set -o nounset

SERVICE_ID="$1"

ROOT=$(git rev-parse --show-toplevel)
# Where the image came from, so a vulnerability finding on it can link to the
# commit and Dockerfile that built it.
SOURCE_REPOSITORY=$(git config --get remote.origin.url | sed -E 's#^.*github\.com(:[0-9]+)?[:/]##; s#\.git$##')
CURRENT_COMMIT=$(git log -1 --pretty=format:"%H" archivematica-apps/$SERVICE_ID)
# The commit that defines the image, which is also its tag, so rebuilds of one tag are identical.
SOURCE_REVISION="$CURRENT_COMMIT"

docker build \
  --file "$ROOT/archivematica-apps/$SERVICE_ID/Dockerfile" \
  --tag "$SERVICE_ID:$CURRENT_COMMIT" \
  --label "org.opencontainers.image.source=https://github.com/$SOURCE_REPOSITORY" \
  --label "org.opencontainers.image.revision=$SOURCE_REVISION" \
  --label "org.wellcomecollection.dockerfile=archivematica-apps/$SERVICE_ID/Dockerfile" \
  "$ROOT/archivematica-apps/$SERVICE_ID"
