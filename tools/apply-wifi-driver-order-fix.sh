#!/usr/bin/env bash
set -euo pipefail
[ "$#" -eq 2 ] || { echo "usage: $0 INPUT_VENDOR.img OUTPUT_VENDOR.img" >&2; exit 2; }
in=$1; out=$2; work=$(mktemp -d)
trap 'rmdir "$work" 2>/dev/null || true' EXIT
cp --reflink=auto "$in" "$out"
debugfs -R "dump /etc/init/hw/meta_init.connectivity.rc $work/meta_init.connectivity.rc" "$in" >/dev/null
# init.wlan_drv.rc is the sole wlan_drv loader after wmt_chrdev_wifi.ko=1.
# Remove only the duplicate direct insmod from meta_init.connectivity.rc.
sed -i '/^[[:space:]]*insmod \/vendor\/lib\/modules\/wlan_drv\.ko[[:space:]]*$/c\\  # wlan_drv.ko is loaded once by init.wlan_drv.rc after wmt_chrdev_wifi.ko=1' "$work/meta_init.connectivity.rc"
grep -Fq 'wlan_drv.ko is loaded once by init.wlan_drv.rc' "$work/meta_init.connectivity.rc"
! grep -Eq '^[[:space:]]*insmod \/vendor\/lib\/modules\/wlan_drv\.ko[[:space:]]*$' "$work/meta_init.connectivity.rc"
debugfs -w -R "rm /etc/init/hw/meta_init.connectivity.rc" "$out" >/dev/null
debugfs -w -R "write $work/meta_init.connectivity.rc /etc/init/hw/meta_init.connectivity.rc" "$out" >/dev/null
debugfs -w -R 'set_inode_field /etc/init/hw/meta_init.connectivity.rc mode 33188' "$out" >/dev/null
debugfs -w -R 'ea_set /etc/init/hw/meta_init.connectivity.rc security.selinux u:object_r:vendor_configs_file:s0' "$out" >/dev/null
e2fsck -fy "$out" >/dev/null 2>&1
e2fsck -fn "$out" >/dev/null 2>&1
printf '%s\n' "patched $out"
