#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
SOURCE_COMMIT=$(git log -1 --pretty=format:"%H" archivematica-apps/archivematica-observability)
IMAGE=${1:-archivematica-observability:$SOURCE_COMMIT}
TERRAFORM_IMAGE="public.ecr.aws/hashicorp/terraform:1.16.4"
TERRAFORM_DIGEST="sha256:985cdc6c1d9b0a65b83377f666efd2f740b47f02ac55be1ced3d18f7d3b0e829"

# Render the production definition in isolation from AWS resources and state.
# Keep the temporary files under ROOT so Docker can mount them on macOS too.
RENDER_DIR=$(mktemp -d "$ROOT/.otel-test.XXXXXX")
trap 'rm -rf -- "$RENDER_DIR"' EXIT
cp "$ROOT/terraform/modules/observability/otel.tf" \
  "$ROOT/terraform/modules/observability/variables.tf" "$RENDER_DIR/"
cat >"$RENDER_DIR/terraform.tfvars" <<'EOF'
enabled       = true
environment   = "staging"
region        = "eu-west-1"
cluster_name  = "archivematica-staging"
cluster_arn   = "arn:aws:ecs:eu-west-1:123456789012:cluster/archivematica-staging"
ebs_volume_id = "vol-0123456789abcdef0"
service_names = ["am-staging-mcp_client", "am-staging-storage-service"]
EOF

# Terraform console returns a quoted JSON string; decode it into a JSON object.
printf 'jsonencode(local.otel_config)\n' \
  | docker run --rm --interactive --network none --read-only \
      --tmpfs /tmp:rw,nosuid,nodev,noexec,size=16m,mode=1777 \
      --env CHECKPOINT_DISABLE=1 \
      --volume "$RENDER_DIR:/config:ro" --workdir /config \
      "$TERRAFORM_IMAGE@$TERRAFORM_DIGEST" \
      console -state=/tmp/terraform.tfstate \
  | python3 -c 'import json, sys; json.dump(json.loads(json.load(sys.stdin)), sys.stdout)' \
  >"$RENDER_DIR/otel-config.json"
chmod 644 "$RENDER_DIR/otel-config.json"

# Test the same runtime with the locked development group added. Production
# contains neither the tests nor their dependencies.
docker build --target test --tag "${IMAGE}-test" \
  "$ROOT/archivematica-apps/archivematica-observability"
docker run --rm --network none --read-only --cap-drop ALL \
  --tmpfs /tmp:rw,nosuid,nodev,noexec,size=64m,mode=1777 \
  --volume "$RENDER_DIR/otel-config.json:/otel-config.json:ro" \
  "${IMAGE}-test" --otel-config=/otel-config.json
