#!/usr/bin/env bash
set -euo pipefail
# Reproducibly retarget the MT6580 Oreo OMX decoder to its isolated Oreo libui ABI.
# Usage: apply-omx-abi-fix.sh INPUT_VENDOR.img OUTPUT_VENDOR.img
[ "$#" -eq 2 ] || { echo "usage: $0 INPUT_VENDOR.img OUTPUT_VENDOR.img" >&2; exit 2; }
in=$1; out=$2; device=$(cd "$(dirname "$0")/.." && pwd)
cp --reflink=auto "$in" "$out"
patch="$device/prebuilt/vendor/lib/libMtkOmxVdecEx.so"
[ -s "$patch" ] || { echo "missing $patch" >&2; exit 1; }
debugfs -w -R "rm /lib/libMtkOmxVdecEx.so" "$out" >/dev/null 2>&1 || true
debugfs -w -R "write $patch /lib/libMtkOmxVdecEx.so" "$out" >/dev/null
debugfs -w -R "set_inode_field /lib/libMtkOmxVdecEx.so mode 33188" "$out" >/dev/null
debugfs -w -R "ea_set /lib/libMtkOmxVdecEx.so security.selinux u:object_r:vendor_file:s0" "$out" >/dev/null
e2fsck -fy "$out" >/dev/null 2>&1
e2fsck -fn "$out" >/dev/null 2>&1
printf '%s\n' "patched $out"
