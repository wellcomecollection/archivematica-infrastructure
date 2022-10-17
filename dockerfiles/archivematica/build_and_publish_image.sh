#!/usr/bin/env bash

set -o errexit
set -o nounset

ARCHIVEMATICA_TAG=v1.13.2
SERVICE="$1"

ROOT=$(git rev-parse --show-toplevel)
CURRENT_COMMIT=$(git log --oneline dockerfiles/archivematica | head -n 1 | awk '{print $1}')

eval $(aws ecr get-login --no-include-email)

pushd $(mktemp -d)

  echo "*** Checking out the core Artefactual repository"
  git clone https://github.com/artefactual/archivematica.git
  cd archivematica

  echo "*** Checking out tag $ARCHIVEMATICA_TAG"
  git checkout "$ARCHIVEMATICA_TAG"

  echo "*** Applying overlay files to repository"
  python3 "$ROOT/dockerfiles/archivematica/copy_overlay_files.py"
  git status

  echo "*** Building the Docker image"
  cd hack

  docker-compose build "archivematica-$SERVICE"

  # if [[ "${BUILDKITE:-}" == "true" && "$BUILDKITE_BRANCH" != "main" ]]
  # then
  #   echo "*** Not pushing to ECR because running in a Buildkite pull request"
  # else
    echo "*** Pushing to ECR"

    ECR_IMAGE_TAG="299497370133.dkr.ecr.eu-west-1.amazonaws.com/weco/archivematica-$SERVICE:$ARCHIVEMATICA_TAG-$CURRENT_COMMIT"
    docker tag "hack_archivematica-$SERVICE" "$ECR_IMAGE_TAG"

    docker push "$ECR_IMAGE_TAG"

    echo "✨ Published new images with tag $ARCHIVEMATICA_TAG-$CURRENT_COMMIT ✨"
  # fi
popd
