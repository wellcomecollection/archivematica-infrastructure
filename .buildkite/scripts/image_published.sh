#!/usr/bin/env bash
# Prints "yes" if REPOSITORY:TAG is already in ECR and "no" if it is not; fails on any other error.
# Tags name the commit that defines an image, so a published tag is never rebuilt: republishing
# gave it a new digest and let ECR expire the one running services pulled.

set -o errexit
set -o nounset

REPOSITORY="$1"
TAG="$2"

if error=$(aws ecr describe-images \
    --region eu-west-1 \
    --repository-name "$REPOSITORY" \
    --image-ids "imageTag=$TAG" 2>&1 >/dev/null); then
  echo yes
elif [[ "$error" == *ImageNotFoundException* ]]; then
  echo no
else
  echo "$error" >&2
  exit 1
fi
