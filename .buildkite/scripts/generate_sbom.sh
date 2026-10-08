#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Generate on every branch unless explicitly disabled.
if [[ "${SBOM_GENERATE:-true}" == "false" ]]; then
  echo "Skipping SBOM generation"
  exit 0
fi

IMAGE="$1"
SERVICE_ID="$2"
TRIVY_IMAGE="aquasec/trivy:0.75.0@sha256:af6acf9a6b85dfe389a1941505c0ce9efef52a4719635e1a962f022a3d855daa"

SBOM_DIR=$(mktemp -d)
trap 'rm -rf "$SBOM_DIR"' EXIT

echo "--- Generating SBOM for $SERVICE_ID"
docker save --output "$SBOM_DIR/image.tar" "$IMAGE"
# Scan an archive without exposing the agent's Docker socket or credentials.
docker run --rm \
  --mount "type=bind,src=$SBOM_DIR/image.tar,dst=/image.tar,readonly" \
  "$TRIVY_IMAGE" image --input /image.tar \
  --format cyclonedx --no-progress --timeout 15m > "$SBOM_DIR/$SERVICE_ID.cdx.json"

cd "$SBOM_DIR"
buildkite-agent artifact upload "$SERVICE_ID.cdx.json"
