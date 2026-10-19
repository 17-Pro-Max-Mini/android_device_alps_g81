#!/bin/sh
set -eu

# The Oreo MT6580 audio HAL dereferences its DC-removal filter manager even
# when the optional manager cannot be created on the Android 10 userspace.
# Skip that optional path while retaining the normal ALSA output path.

input=${1:?usage: $0 INPUT_VENDOR_IMG OUTPUT_VENDOR_IMG}
output=${2:?usage: $0 INPUT_VENDOR_IMG OUTPUT_VENDOR_IMG}
work=${TMPDIR:-/tmp}/g81-audio-patch.$$
mkdir -p "$work"

cp -f "$input" "$output"
debugfs -R "dump lib/hw/audio.primary.mt6580.so $work/audio.primary.mt6580.so" "$output" >/dev/null 2>&1

expected=0700001a
actual=$(dd if="$work/audio.primary.mt6580.so" bs=1 skip=$((0x9b67c)) count=4 2>/dev/null | od -An -tx1 | tr -d ' \n')
test "$actual" = "$expected"

printf '\033\000\000\012' > "$work/branch.beq"
dd if="$work/branch.beq" of="$work/audio.primary.mt6580.so" bs=1 seek=$((0x9b67c)) conv=notrunc 2>/dev/null

debugfs -w -R 'rm lib/hw/audio.primary.mt6580.so' "$output" >/dev/null 2>&1 || true
debugfs -w -R "write $work/audio.primary.mt6580.so lib/hw/audio.primary.mt6580.so" "$output" >/dev/null
debugfs -w -R 'set_inode_field lib/hw/audio.primary.mt6580.so mode 0100644' "$output" >/dev/null

debugfs -R "dump lib/hw/audio.primary.mt6580.so $work/verify.so" "$output" >/dev/null 2>&1
patched=$(dd if="$work/verify.so" bs=1 skip=$((0x9b67c)) count=4 2>/dev/null | od -An -tx1 | tr -d ' \n')
test "$patched" = "1b00000a"
printf 'audio.primary.mt6580.so DC-removal guard applied: %s -> %s\n' "$actual" "$patched"
