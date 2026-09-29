#!/bin/bash
set -euo pipefail
IMAGE=${1:?usage: $0 VENDOR_IMAGE RRO_APK}
APK=${2:?usage: $0 VENDOR_IMAGE RRO_APK}
PATH_IN_IMAGE=/overlay/framework-res__auto_generated_rro.apk
[ -f "$IMAGE" ]
[ -f "$APK" ]
CMD=$(mktemp)
trap 'rm -f "$CMD"' EXIT
{
  printf 'rm %s\n' "$PATH_IN_IMAGE"
  printf 'write %s %s\n' "$APK" "$PATH_IN_IMAGE"
  printf 'set_inode_field %s mode 0100644\n' "$PATH_IN_IMAGE"
  printf 'ea_set %s security.selinux u:object_r:vendor_overlay_file:s0\n' "$PATH_IN_IMAGE"
} > "$CMD"
debugfs -w -f "$CMD" "$IMAGE"
