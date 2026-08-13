#!/usr/bin/env bash

set -o errexit
set -o nounset

# This untagged commit was the tip of qa/0.x when the overlay was updated.
# Pin the SHA so later changes to the branch do not alter this build.
UPSTREAM_COMMIT=324f1cfcabe1a3ad9e4a9191735e8e9367f52456

ROOT=$(git rev-parse --show-toplevel)
OVERLAY_COMMIT=$(git log -1 --pretty=format:"%H" "$ROOT"/archivematica-apps/archivematica-storage-service)

aws ecr get-login-password \
| docker login \
    --username AWS \
    --password-stdin 299497370133.dkr.ecr.eu-west-1.amazonaws.com

pushd $(mktemp -d)

  echo "*** Checking out the core Artefactual repository"
  git clone https://github.com/artefactual/archivematica-storage-service.git
  cd archivematica-storage-service

  echo "*** Checking out upstream commit $UPSTREAM_COMMIT"
  git checkout "$UPSTREAM_COMMIT"

  echo "*** Applying overlay files to repository"
  python3 "$ROOT/archivematica-apps/archivematica-storage-service/copy_overlay_files.py"
  git status

  echo "*** Building the Docker image"
  docker build --tag "archivematica-storage-service" .

  echo "*** Pushing to ECR"

  IMAGE_TAG="$UPSTREAM_COMMIT-$OVERLAY_COMMIT"
  ECR_IMAGE_TAG="299497370133.dkr.ecr.eu-west-1.amazonaws.com/weco/archivematica-storage-service:$IMAGE_TAG"
  docker tag "archivematica-storage-service" "$ECR_IMAGE_TAG"

  echo "*** Image provenance"
  echo "Upstream Storage Service commit: $UPSTREAM_COMMIT"
  echo "Wellcome overlay commit: $OVERLAY_COMMIT"
  echo "Image tag: $IMAGE_TAG"

  docker push "$ECR_IMAGE_TAG"

  buildkite-agent annotate --append --style info "Published image archivematica-storage-service:$IMAGE_TAG<br/>Upstream Storage Service commit: $UPSTREAM_COMMIT<br/>Wellcome overlay commit: $OVERLAY_COMMIT<br/>"
popd
