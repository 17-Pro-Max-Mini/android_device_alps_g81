#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/../../../../.." && pwd)
device="$root/workspace/device/alps/g81"
ndk="$HOME/Android/Sdk/ndk/28.2.13676358"
clang="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi23-clang"
out="$device/prebuilt/vendor/lib/ril27/libaudioprimarydevicehalifclient.so"
out_ril27="$device/prebuilt/vendor/lib/ril27/libaudioprimarydevicehalifclient-ril27.so"
libdir="$device/prebuilt/vendor/lib/ril27"

[ -x "$clang" ] || { echo "missing Android NDK compiler: $clang" >&2; exit 1; }
[ -f "$libdir/libutils.so" ] || {
    echo "missing libutils.so in $libdir" >&2
    exit 1
}

mkdir -p "$(dirname "$out")"
"$clang" -shared -fPIC -fvisibility=hidden -fno-stack-protector \
    -Wl,-soname,libaudioprimarydevicehalifclient.so \
    -Wl,-z,defs -Wl,--no-undefined \
    -L"$libdir" -Wl,-l:libutils.so \
    "$device/ril27/audio_client_bridge_stub.c" -o "$out"

readelf -d "$out" | grep -F 'Shared library: [libutils.so]'
readelf -Ws "$out" | grep -F '_ZN7android26MTKPrimaryDevicesHalClient11getInstanceEv'

# mtk-rilproxy is isolated under the private -ril27 namespace. Keep a second
# copy with the dependency name it requests; patch-ril-abi.sh can then remap
# that dependency without falling back to the original media/HIDL client.
cp "$out" "$out_ril27"
patchelf --set-soname libaudioprimarydevicehalifclient-ril27.so "$out_ril27"
patchelf --replace-needed libutils.so libutils-ril27.so "$out_ril27"
readelf -d "$out_ril27" | grep -E 'SONAME|NEEDED.*libutils-ril27.so'
