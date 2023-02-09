#!/usr/bin/env bash

set -o errexit
set -o nounset

ARCHIVEMATICA_TAG=v1.13.2
SERVICE="$1"

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git log -1 --pretty=format:"%H" archivematica-apps/archivematica)

eval $(aws ecr get-login --no-include-email)

pushd $(mktemp -d)

  echo "*** Checking out the core Artefactual repository"
  git clone https://github.com/artefactual/archivematica.git
  cd archivematica

  echo "*** Checking out tag $ARCHIVEMATICA_TAG"
  git checkout "$ARCHIVEMATICA_TAG"

  echo "*** Applying overlay files to repository"
  python3 "$ROOT/archivematica-apps/archivematica/copy_overlay_files.py"
  git status

  echo "*** Building the Docker image"
  cd hack

  docker-compose build "archivematica-$SERVICE"

  echo "*** Pushing to ECR"

  ECR_IMAGE_TAG="299497370133.dkr.ecr.eu-west-1.amazonaws.com/weco/archivematica-$SERVICE:$ARCHIVEMATICA_TAG-$CURRENT_COMMIT"
  docker tag "hack_archivematica-$SERVICE" "$ECR_IMAGE_TAG"

  docker push "$ECR_IMAGE_TAG"

  buildkite-agent annotate --append --style info "Published image $ARCHIVEMATICA_TAG-$CURRENT_COMMIT<br/>"
popd
