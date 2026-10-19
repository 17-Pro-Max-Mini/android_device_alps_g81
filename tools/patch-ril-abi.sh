#!/usr/bin/env bash
set -euo pipefail

usage() { echo "usage: $0 INPUT_VENDOR_IMG OUTPUT_VENDOR_IMG" >&2; exit 2; }
[ "$#" -eq 2 ] || usage
in=$1
out=$2
root=$(cd "$(dirname "$0")/../../../../.." && pwd)
device="$root/workspace/device/alps/g81"
expected="ecd9abd743e64fcedae8a5485068d12ff8ff154e63f9eb9ba058af6d27df9621"
actual=$(sha256sum "$in" | awk '{print $1}')
[ "$actual" = "$expected" ] || { echo "input vendor hash mismatch: $actual" >&2; exit 1; }

cp --reflink=auto "$in" "$out"
e2mkdir() { debugfs -w -R "mkdir $1" "$out" >/dev/null 2>&1 || true; }
e2write() {
    local src=$1 dst=$2
    debugfs -w -R "rm $dst" "$out" >/dev/null 2>&1 || true
    debugfs -w -R "write $src $dst" "$out" >/dev/null
}

e2dump() {
    local src=$1 dst=$2
    debugfs -R "dump $src $dst" "$out" >/dev/null
}

# Keep the Oreo RIL dependency closure private to the legacy RIL processes.
# Android 10's linker namespaces do not make duplicate generic SONAMEs safe:
# a legacy libcrypto/libhidl/libbase can otherwise satisfy a system library's
# relocation. Every non-Bionic dependency is therefore given a unique SONAME
# and loaded from /vendor/lib/ril27. The audio client is a local ABI bridge;
# its original implementation pulls in media/GUI/EGL and private Bionic APIs.
e2mkdir /lib/ril27
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

declare -A seen source_path mapped
private_names=()
system_names=(libc.so libm.so libdl.so libdl_android.so liblog.so)

is_system_name() {
    local n=$1 s
    for s in "${system_names[@]}"; do [ "$n" = "$s" ] && return 0; done
    return 1
}

mapped_name() {
    local n=$1
    printf '%s-ril27.so' "${n%.so}"
}

canonical_name() {
    case "$1" in
        libcutils-oreo.so) printf '%s' libcutils.so ;;
        libutils-oreo.so) printf '%s' libutils.so ;;
        libcrypto-oreo.so) printf '%s' libcrypto.so ;;
        libssl-oreo.so) printf '%s' libssl.so ;;
        *) printf '%s' "$1" ;;
    esac
}

source_for_name() {
    local n=$1 local_src="$device/prebuilt/vendor/lib/ril27/$1"
    local override_dir="$root/workspace/android10-17.1/transactions/vendor-abi-closure-v5-20260919/staged"
    case "$n" in
        libcutils.so|libutils.so|libcrypto.so|libssl.so)
            if [ -s "$override_dir/${n%.so}-oreo.so" ]; then
                printf '%s' "$override_dir/${n%.so}-oreo.so"
                return 0
            fi
            ;;
    esac
    if [ "$n" = "libaudioprimarydevicehalifclient-ril27.so" ] && [ -s "$device/prebuilt/vendor/lib/ril27/$n" ]; then
        printf '%s' "$device/prebuilt/vendor/lib/ril27/$n"
        return 0
    fi
    if [ -f "$local_src" ]; then
        printf '%s' "$local_src"
        return 0
    fi
    local dst="$tmp/src/$n"
    mkdir -p "$(dirname "$dst")"
    [ -f "$dst" ] || debugfs -R "dump /lib/$n $dst" "$in" >/dev/null 2>&1 || true
    if [ ! -s "$dst" ]; then
        local stock="$root/workspace/android10-17.1/transactions/baseband-wifi-camera-20260920/stocklib-all/$n"
        [ -s "$stock" ] || return 1
        cp "$stock" "$dst"
    fi
    [ -s "$dst" ] || return 1
    printf '%s' "$dst"
}

queue_name() {
    local n
    n=$(canonical_name "$1")
    is_system_name "$n" && return 0
    [ -n "${seen[$n]+x}" ] && return 0
    local src
    src=$(source_for_name "$n") || {
        echo "missing RIL dependency in vendor image: $n" >&2
        return 1
    }
    seen[$n]=1
    source_path[$n]=$src
    mapped[$n]=$(mapped_name "$n")
    private_names+=("$n")
    local dep
    while read -r dep; do
        queue_name "$dep"
    done < <(readelf -d "$src" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
}

for root_name in \
    libcutils.so liblog.so librilmtk.so librilutilsmtk.so librilproxy.so \
    mtk-rilproxy.so mtk-ril.so libratconfig.so libmtk-rilproxy.so \
    librilproxyutils.so; do
    # The root RIL binaries below are patched in-place from the image; this
    # queue starts with their dependencies and the closure libraries found in
    # /vendor/lib. Missing optional roots are ignored.
    if source_for_name "$root_name" >/dev/null 2>&1; then queue_name "$root_name"; fi
done

# Add dependencies of the actual RIL executables and shared objects. Their
# own files remain at the stock paths, but all non-system DT_NEEDED entries are
# redirected to the private names generated above.
ril_paths=(
    bin/mtkrild bin/hw/rilproxy bin/netdagent lib/mtk-rilproxy.so lib/librilproxy.so
    lib/librilmtk.so lib/mtk-ril.so lib/libratconfig.so lib/librilutilsmtk.so
    lib/vendor.mediatek.hardware.radio@2.0_vendor.so
    lib/vendor.mediatek.hardware.radio.deprecated@1.1_vendor.so
    lib/vendor.mediatek.hardware.netdagent@1.0_vendor.so
)
for image_path in "${ril_paths[@]}"; do
    f="$tmp/root-${image_path//\//_}"
    debugfs -R "dump /$image_path $f" "$in" >/dev/null
    while read -r dep; do queue_name "$dep"; done < <(readelf -d "$f" | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
done

for n in "${private_names[@]}"; do
    src=${source_path[$n]}
    dst="$tmp/$(mapped_name "$n")"
    cp "$src" "$dst"
    patchelf --set-soname "$(mapped_name "$n")" "$dst"
    while read -r dep; do
        is_system_name "$dep" && continue
        canon=$(canonical_name "$dep")
        new=${mapped[$canon]:-$(mapped_name "$canon")}
        patchelf --replace-needed "$dep" "$new" "$dst" 2>/dev/null || true
    done < <(readelf -d "$dst" | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
    e2write "$dst" "/lib/ril27/$(mapped_name "$n")"
    debugfs -w -R "set_inode_field lib/ril27/$(mapped_name "$n") mode 33188" "$out" >/dev/null
done

patch_ril_elf() {
    local image_path=$1
    local name=${image_path##*/}
    local file="$tmp/$name"
    e2dump "/$image_path" "$file"
    while read -r old; do
        is_system_name "$old" && continue
        canon=$(canonical_name "$old")
        new=${mapped[$canon]:-$(mapped_name "$canon")}
        patchelf --replace-needed "$old" "$new" "$file" 2>/dev/null || true
    done < <(readelf -d "$file" | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
    e2write "$file" "/$image_path"
    case "$image_path" in
        bin/*) debugfs -w -R "set_inode_field $image_path mode 33261" "$out" >/dev/null ;;
        lib/*) debugfs -w -R "set_inode_field $image_path mode 33188" "$out" >/dev/null ;;
    esac
}

# Patch only the RIL dependency chain.  Other vendor services keep their
# existing Android 10/VNDK closure.
for path in \
    bin/mtkrild \
    bin/hw/rilproxy \
    bin/netdagent \
    lib/mtk-rilproxy.so \
    lib/librilproxy.so \
    lib/librilmtk.so \
    lib/mtk-ril.so \
    lib/libratconfig.so \
    lib/librilutilsmtk.so \
    lib/vendor.mediatek.hardware.radio@2.0_vendor.so \
    lib/vendor.mediatek.hardware.radio.deprecated@1.1_vendor.so \
    lib/vendor.mediatek.hardware.netdagent@1.0_vendor.so; do
    patch_ril_elf "$path"
done

e2write "$device/rootdir/rilproxy.ril27.rc" /etc/init/rilproxy.rc
e2write "$device/rootdir/rild.ril27.rc" /etc/init/rild.rc
if [ -f "$device/rootdir/netdagent.ril27.rc" ]; then
    e2write "$device/rootdir/netdagent.ril27.rc" /etc/init/netdagent.rc
fi
sha256sum "$in" "$out"
printf 'RIL ABI island installed under /vendor/lib/ril27; rild and rilproxy use LD_LIBRARY_PATH\n'
