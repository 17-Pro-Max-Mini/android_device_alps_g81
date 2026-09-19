#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: $0 <stock-input-root> [vendor-output-root]" >&2
    echo "Expected input: kernel, vendor.img, and system/lib/." >&2
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 2
fi

source_root="$(cd -- "$1" && pwd)"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
android_root="$(cd -- "${script_dir}/../../.." && pwd)"
vendor_root="${2:-${android_root}/vendor/alps/g81}"

for required in kernel vendor.img system/lib; do
    if [[ ! -e "${source_root}/${required}" ]]; then
        echo "Missing ${source_root}/${required}" >&2
        exit 1
    fi
done

kernel_sha256="$(sha256sum "${source_root}/kernel" | awk '{print $1}')"
vendor_sha256="$(sha256sum "${source_root}/vendor.img" | awk '{print $1}')"
if [[ "${kernel_sha256}" != "c6d2c9b973d859054bc60c98e9afed37b5d11c813ab66b930534405b8e6a1c7d" ]]; then
    echo "Unexpected kernel SHA-256: ${kernel_sha256}" >&2
    exit 1
fi
if [[ "${vendor_sha256}" != "95a5dfaaaa9f3db8d5d5cf37fae1f21b28027dafd910c815c3068162c7892f9e" ]]; then
    echo "Unexpected vendor image SHA-256: ${vendor_sha256}" >&2
    exit 1
fi

mkdir -p -- "${vendor_root}/proprietary/system/lib"
install -m 0644 -- "${source_root}/kernel" "${vendor_root}/proprietary/kernel"
install -m 0644 -- "${source_root}/vendor.img" "${vendor_root}/proprietary/vendor.img"
rsync -a --delete -- "${source_root}/system/lib/" "${vendor_root}/proprietary/system/lib/"
"${script_dir}/setup-makefiles.sh" "${vendor_root}"

echo "Extracted private vendor inputs to ${vendor_root}"
