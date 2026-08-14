Content-Type: multipart/mixed; boundary="==BOUNDARY=="
MIME-Version: 1.0

--==BOUNDARY==
Content-Type: text/cloud-boothook; charset="us-ascii"

#!/bin/bash
set -euo pipefail

EBS_DEVICE="${ebs_device_path}"
EBS_HOST_PATH="${ebs_host_path}"
EBS_VOLUME_ID="${ebs_volume_id}"
EBS_READY_FILE="/run/archivematica-ebs-ready"
ECS_CLUSTER_NAME="${cluster_name}"

# The boothook runs before cloud-final.service, which the ECS agent waits for.
# Remove the EBS placement attribute until the expected volume is mounted so
# Archivematica tasks cannot use a directory on the instance root filesystem.
rm -f "$EBS_READY_FILE"
mkdir -p /etc/ecs
cat > /etc/ecs/ecs.config <<EOF
ECS_CLUSTER=$ECS_CLUSTER_NAME
EOF

# Refuse to start ECS if the bootstrap fails before /ebs is mounted.  The
# second daemon-reload below also regenerates the mount unit after fstab is
# updated on a new host.
mkdir -p /etc/systemd/system/ecs.service.d
cat > /etc/systemd/system/ecs.service.d/10-require-ebs.conf <<EOF
[Unit]
RequiresMountsFor=$EBS_HOST_PATH
ConditionPathIsMountPoint=$EBS_HOST_PATH
ConditionPathExists=$EBS_READY_FILE
EOF
systemctl daemon-reload

# aws_volume_attachment cannot complete until after the instance exists, so
# cloud-init can start before the EBS device is available.  Wait for the
# volume-specific NVMe symlink rather than assuming /dev/xvdb is ready.
for ((attempt = 1; attempt <= 300; attempt++)); do
  if [[ -b "$EBS_DEVICE" ]]; then
    break
  fi
  sleep 1
done

if [[ ! -b "$EBS_DEVICE" ]]; then
  echo "Timed out waiting for EBS volume $EBS_VOLUME_ID at $EBS_DEVICE" >&2
  exit 1
fi

# Preserve the manual formatting workflow used when bootstrapping a new stack.
# Existing volumes are never formatted automatically.
cat > /format_ebs_volume.sh <<EOF
#!/bin/bash
set -euo pipefail

EBS_DEVICE="$EBS_DEVICE"
FS_TYPE="\$(blkid --match-tag TYPE --output value "\$EBS_DEVICE" || true)"

case "\$FS_TYPE" in
  ext4)
    echo "\$EBS_DEVICE is already formatted as ext4"
    ;;
  "")
    mkfs --type ext4 "\$EBS_DEVICE"
    ;;
  *)
    echo "Refusing to overwrite \$EBS_DEVICE: found \$FS_TYPE filesystem" >&2
    exit 1
    ;;
esac
EOF
chmod 0700 /format_ebs_volume.sh

FS_TYPE="$(blkid --match-tag TYPE --output value "$EBS_DEVICE" || true)"
if [[ "$FS_TYPE" != "ext4" ]]; then
  echo "EBS volume $EBS_VOLUME_ID is not formatted as ext4; run /format_ebs_volume.sh and reboot" >&2
  exit 1
fi

FS_UUID="$(blkid --match-tag UUID --output value "$EBS_DEVICE")"
EXPECTED_DEVICE="$(readlink -f "$EBS_DEVICE")"
mkdir -p "$EBS_HOST_PATH"

FSTAB_SOURCE="$(awk -v mountpoint="$EBS_HOST_PATH" '$1 !~ /^#/ && $2 == mountpoint { print $1; exit }' /etc/fstab)"
if [[ -z "$FSTAB_SOURCE" ]]; then
  echo "UUID=$FS_UUID $EBS_HOST_PATH ext4 defaults,nofail 0 2" >> /etc/fstab
else
  case "$FSTAB_SOURCE" in
    "UUID=$FS_UUID"|"$EBS_DEVICE"|"$EXPECTED_DEVICE"|/dev/xvdb)
      ;;
    *)
      echo "Refusing to mount unexpected fstab source $FSTAB_SOURCE at $EBS_HOST_PATH" >&2
      exit 1
      ;;
  esac
fi

if ! mountpoint -q "$EBS_HOST_PATH"; then
  mount "$EBS_HOST_PATH"
fi

MOUNTED_SOURCE="$(findmnt --noheadings --output SOURCE --mountpoint "$EBS_HOST_PATH")"
if [[ "$(readlink -f "$MOUNTED_SOURCE")" != "$EXPECTED_DEVICE" ]]; then
  echo "Unexpected device $MOUNTED_SOURCE mounted at $EBS_HOST_PATH; expected $EBS_DEVICE" >&2
  exit 1
fi

# Only advertise the placement attribute after the EBS mount is verified.
cat >> /etc/ecs/ecs.config <<EOF
ECS_INSTANCE_ATTRIBUTES={"ebs.volume":"$EBS_VOLUME_ID"}
EOF

touch "$EBS_READY_FILE"
systemctl daemon-reload
--==BOUNDARY==--
