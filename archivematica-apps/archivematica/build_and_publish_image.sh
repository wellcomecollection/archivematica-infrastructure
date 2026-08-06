#!/usr/bin/env bash

set -o errexit
set -o nounset

if (( $# != 1 ))
then
  echo "Usage: $0 <SERVICE>" >&2
  exit 1
fi

# This untagged commit was the tip of qa/1.x when the overlay was updated.
# Pin the SHA so later changes to the branch do not alter this build.
UPSTREAM_COMMIT=306db6773216e607cf5687f84fb0be353949ddb7
SERVICE="$1"

ROOT=$(git rev-parse --show-toplevel)
OVERLAY_COMMIT=$(git log -1 --pretty=format:"%H" "$ROOT"/archivematica-apps/archivematica)

aws ecr get-login-password \
| docker login \
    --username AWS \
    --password-stdin 299497370133.dkr.ecr.eu-west-1.amazonaws.com

pushd $(mktemp -d)

  echo "*** Checking out the core Artefactual repository"
  git clone https://github.com/artefactual/archivematica.git
  cd archivematica

  echo "*** Checking out upstream commit $UPSTREAM_COMMIT"
  git checkout "$UPSTREAM_COMMIT"

  echo "*** Applying overlay files to repository"
  python3 "$ROOT/archivematica-apps/archivematica/copy_overlay_files.py"
  git status

  echo "*** Building the Docker image"
  cd hack

  docker-compose build "archivematica-$SERVICE"

  echo "*** Pushing to ECR"

  IMAGE_TAG="$UPSTREAM_COMMIT-$OVERLAY_COMMIT"
  ECR_IMAGE_TAG="299497370133.dkr.ecr.eu-west-1.amazonaws.com/weco/archivematica-$SERVICE:$IMAGE_TAG"
  docker tag "am-archivematica-$SERVICE" "$ECR_IMAGE_TAG"

  echo "*** Image provenance"
  echo "Upstream Archivematica commit: $UPSTREAM_COMMIT"
  echo "Wellcome overlay commit: $OVERLAY_COMMIT"
  echo "Image tag: $IMAGE_TAG"

  docker push "$ECR_IMAGE_TAG"

  buildkite-agent annotate --append --style info "Published image archivematica-$SERVICE:$IMAGE_TAG<br/>Upstream Archivematica commit: $UPSTREAM_COMMIT<br/>Wellcome overlay commit: $OVERLAY_COMMIT<br/>"
popd
