#!/usr/bin/env bash

set -o errexit
set -o nounset

# Pin the qa/0.x tip as of 2026-09-23, after rc.2.
# Use the SHA so later branch changes do not alter this build.
UPSTREAM_COMMIT=b39daf5d9c4afb290719df0ca6f61a6109e34377

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

  bash "$ROOT/.buildkite/scripts/generate_sbom.sh" "$ECR_IMAGE_TAG" "archivematica-storage-service"

  buildkite-agent annotate --append --style info "Published image archivematica-storage-service:$IMAGE_TAG<br/>Upstream Storage Service commit: $UPSTREAM_COMMIT<br/>Wellcome overlay commit: $OVERLAY_COMMIT<br/>"
popd
