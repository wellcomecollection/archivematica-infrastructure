#!/usr/bin/env bash

set -o errexit
set -o nounset

ARCHIVEMATICA_TAG=v0.20.1

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git log -1 --pretty=format:"%H" "$ROOT"/archivematica-apps/archivematica-storage-service)

aws ecr get-login-password \
| docker login \
    --username AWS \
    --password-stdin 299497370133.dkr.ecr.eu-west-1.amazonaws.com

pushd $(mktemp -d)

  echo "*** Checking out the core Artefactual repository"
  git clone https://github.com/artefactual/archivematica-storage-service.git
  cd archivematica-storage-service

  echo "*** Checking out tag $ARCHIVEMATICA_TAG"
  git checkout "$ARCHIVEMATICA_TAG"

  echo "*** Applying overlay files to repository"
  python3 "$ROOT/archivematica-apps/archivematica-storage-service/copy_overlay_files.py"
  git status

  echo "*** Building the Docker image"
  docker build --tag "archivematica-storage-service" .

  echo "*** Pushing to ECR"

  ECR_IMAGE_TAG="299497370133.dkr.ecr.eu-west-1.amazonaws.com/weco/archivematica-storage-service:$ARCHIVEMATICA_TAG-$CURRENT_COMMIT"
  docker tag "archivematica-storage-service" "$ECR_IMAGE_TAG"
  docker push "$ECR_IMAGE_TAG"

  buildkite-agent annotate --append --style info "Published image archivematica-storage-service:$ARCHIVEMATICA_TAG-$CURRENT_COMMIT<br/>"
popd
