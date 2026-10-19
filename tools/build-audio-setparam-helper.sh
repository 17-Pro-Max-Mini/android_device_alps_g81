#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")/../../../../.." && pwd)
device="$root/workspace/device/alps/g81"
ndk="$HOME/Android/Sdk/ndk/28.2.13676358"
clang="$ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi23-clang"
out="$device/prebuilt/vendor/bin/audio-setparam"
mkdir -p "$(dirname "$out")"
"$clang" -fPIE -pie -fno-stack-protector -Wl,--no-undefined \
    "$device/ril27/audio_setparam_helper.c" -ldl -o "$out"
file "$out"
