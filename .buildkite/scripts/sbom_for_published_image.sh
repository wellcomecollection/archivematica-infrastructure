#!/usr/bin/env bash
# Generate the SBOM for an image that is already in ECR, so a build that skips publishing it
# still has the artifact the main-branch Dependency-Track upload needs.
#
#   sbom_for_published_image.sh REPOSITORY TAG SERVICE_ID

set -o errexit
set -o nounset
set -o pipefail

if [[ "${SBOM_GENERATE:-true}" == "false" ]]; then
  echo "Skipping SBOM generation"
  exit 0
fi

REGISTRY="299497370133.dkr.ecr.eu-west-1.amazonaws.com"
IMAGE="$REGISTRY/$1:$2"
SERVICE_ID="$3"
ROOT=$(git rev-parse --show-toplevel)

aws ecr get-login-password --region eu-west-1 \
| docker login --username AWS --password-stdin "$REGISTRY"

docker pull "$IMAGE"
bash "$ROOT/.buildkite/scripts/generate_sbom.sh" "$IMAGE" "$SERVICE_ID"
docker rmi "$IMAGE"
