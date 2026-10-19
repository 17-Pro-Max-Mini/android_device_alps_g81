#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 INPUT_VENDOR_IMG OUTPUT_VENDOR_IMG" >&2; exit 2; }
[ "$#" -eq 2 ] || usage
in=$1
out=$2
root=$(cd "$(dirname "$0")/../../../../.." && pwd)
device="$root/workspace/device/alps/g81"
tx="$root/workspace/android10-17.1/transactions/vendor-hal-wifi-$(date +%Y%m%d%H%M%S)"
mkdir -p "$tx/root" "$tx/meta"

expected="ecd9abd743e64fcedae8a5485068d12ff8ff154e63f9eb9ba058af6d27df9621"
actual=$(sha256sum "$in" | awk '{print $1}')
[ "$actual" = "$expected" ] || { echo "input vendor hash mismatch: $actual" >&2; exit 1; }

cp --reflink=auto "$in" "$out"
e2mkdir() { debugfs -w -R "mkdir $1" "$out" >/dev/null 2>&1 || true; }
e2write() {
  local src=$1 dst=$2 tmpdst
  debugfs -w -R "rm $dst" "$out" >/dev/null 2>&1 || true
  debugfs -w -R "write $src $dst" "$out" >/dev/null
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
debugfs -R "dump /etc/init/hw/init.connectivity.rc $tmp/init.connectivity.rc" "$out" >/dev/null 2>&1

# Keep non-Treble Android 10 build consistency true. The stock Oreo vendor
# image carries a Ruby/O11019 fingerprint, while the generated system image
# uses the G81 Android 10 fingerprint; Build.isBuildConsistent() otherwise
# raises the persistent internal-problem dialog at every boot.
system_fp="${G81_SYSTEM_FINGERPRINT:-}"
if [ -z "$system_fp" ]; then
    echo 'G81_SYSTEM_FINGERPRINT must be set to the exact generated Lineage fingerprint' >&2
    exit 1
fi
case "$system_fp" in
    alps/lineage_g81/g81:10/*:userdebug/*) ;;
    *) echo "unexpected G81 fingerprint: $system_fp" >&2; exit 1 ;;
esac
debugfs -R "dump /build.prop $tmp/vendor.build.prop" "$out" >/dev/null 2>&1
sed -i "s|^ro.vendor.build.fingerprint=.*|ro.vendor.build.fingerprint=$system_fp|" "$tmp/vendor.build.prop"
grep -Fqx "ro.vendor.build.fingerprint=$system_fp" "$tmp/vendor.build.prop"
e2write "$tmp/vendor.build.prop" /build.prop
debugfs -w -R 'set_inode_field build.prop mode 33152' "$out" >/dev/null
sed -i '/-I\/vendor\/etc\/wifi\/wpa_supplicant_overlay.conf -N/,+2c\\    -I/vendor/etc/wifi/wpa_supplicant_overlay.conf -e/data/misc/wifi/entropy.bin \\\\' "$tmp/init.connectivity.rc"
sed -i '/^[[:space:]]*on boot$/,/^$/d' "$tmp/init.connectivity.rc"
# Power-on must follow the framework's driver transition.  The status property
# is emitted before the legacy HAL creates wlan0; restore the marker first so
# the source-tree trigger and the kernel-facing write both fire on re-enable.
awk '
BEGIN {
    block = "# WMT and wlan_drv.ko must be loaded before the legacy MTK power-on write.\n"
    block = block "on property:wlan_drv.ko=1\n    write /dev/wmtWifi 1\n\n"
    block = block "on property:wlan.driver.status=unloaded\n    setprop wlan_drv.ko 0\n\n"
    block = block "on property:wlan.driver.status=ok\n    setprop wlan_drv.ko 1\n    write /dev/wmtWifi 1\n\n"
    block = block "on property:init.svc.wpa_supplicant=running\n    write /dev/wmtWifi 1\n    start wifi_legacy_poweron\n\n"
    block = block "service wifi_legacy_poweron /system/bin/sleep 1\n    class core\n    user root\n    oneshot\n    seclabel u:r:init:s0\n\n"
    block = block "on property:init.svc.wifi_legacy_poweron=stopped\n    setprop wlan_drv.ko 1\n    write /dev/wmtWifi 1\n\n"
    block = block "# Framework owns supplicant startup; delayed init retry handles legacy power-on."
    count = split(block, lines, "\n")
}
/^# Connectivity related services \(Begin\)$/ {
    for (i = 1; i <= count; i++) print lines[i]
}
{ print }
' "$tmp/init.connectivity.rc" > "$tmp/init.connectivity.rc.new"
mv "$tmp/init.connectivity.rc.new" "$tmp/init.connectivity.rc"
sed -i '/^on property:sys.boot_completed=1$/,/^    oneshot$/d' "$tmp/init.connectivity.rc"
e2write "$tmp/init.connectivity.rc" /etc/init/hw/init.connectivity.rc

# Android 10's split policy is missing the legacy MTK property/binder edges.
# A policy rebuilt from the verified live rules is staged beside this tool and
# replaced as one file so the boot-time init write and modem startup survive a
# reboot.  The script deliberately refuses a missing policy artifact.
policy_src="$root/workspace/device/alps/g81/prebuilt/selinux/precompiled_sepolicy"
if [ ! -f "$policy_src" ]; then
    echo "missing staged policy: $policy_src" >&2
    exit 1
fi
e2write "$policy_src" /etc/selinux/precompiled_sepolicy

# The Oreo libui compatibility copy must not retain the generic libui.so
# SONAME.  If it does, the dynamic linker reuses it for Android 10 libgui.so;
# libgui's GraphicBuffer::toAHardwareBuffer relocation then fails, the OMX
# service restart-loops, and AudioService blocks forever while SoundPool asks
# MediaPlayerService for the codec list.  Stage the uniquely named SONAME so
# both libui generations can coexist in the mediacodec process.
omx_ui_src="$device/prebuilt/vendor/lib/libui-oreo.so"
if [ ! -f "$omx_ui_src" ]; then
    echo "missing staged OMX libui compatibility library: $omx_ui_src" >&2
    exit 1
fi
readelf -d "$omx_ui_src" | grep -Fq 'Library soname: [libui-oreo.so]' || {
    echo "invalid OMX libui SONAME; expected libui-oreo.so" >&2
    exit 1
}
e2write "$omx_ui_src" /lib/libui-oreo.so
debugfs -w -R "set_inode_field lib/libui-oreo.so mode 33188" "$out" >/dev/null

sha256sum "$in" "$out" > "$tx/meta/hashes.txt"
printf '%s\n' \
    'wlan0 re-enable: status=ok marker plus delayed init-owned power-on retry' \
    'supplicant: STA-only, no -N/-ip2p0' \
    'removed failed wifi_legacy_poweron helper' \
    'precompiled policy: init/wmtWifi_device plus ccci_fsd/mtkrild hwservicemanager edges' \
    'OMX ABI: libui-oreo.so has a unique SONAME so Android 10 libgui loads Android 10 libui' \
    > "$tx/meta/change.txt"
echo "$out"
