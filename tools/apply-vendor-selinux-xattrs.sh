#!/usr/bin/env bash
set -euo pipefail
img=${1:?usage: $0 vendor.img}
root=$(cd "$(dirname "$0")/../../../../.." && pwd)
manifest="$root/workspace/device/alps/g81/prebuilt/vendor-relabeled/SELINUX_XATTR_MANIFEST.txt"
while IFS='|' read -r path context; do
  path=${path#\#}; path=$(echo "$path" | xargs); context=$(echo "$context" | xargs)
  [ -n "$path" ] || continue
  debugfs -w -R "ea_set ${path#/} security.selinux $context" "$img" >/dev/null
done < "$manifest"
e2fsck -fy "$img" >/dev/null
e2fsck -fn "$img"
