#!/usr/bin/env python3
"""Install the verified MT6580 legacy-Oreo HWC2 VSYNC compatibility blob.

Usage: apply-hwc-zero-vsync.py INPUT_VENDOR_IMG OUTPUT_VENDOR_IMG
The input image is never modified.  The output is copied first, then only
vendor/lib/hw/android.hardware.graphics.composer@2.1-impl.so is replaced.
"""
from pathlib import Path
import hashlib
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[5]
DEVICE = ROOT / "workspace/device/alps/g81"
PAYLOAD = DEVICE / "prebuilt/hwc-zero-vsync/android.hardware.graphics.composer@2.1-impl.so"
TARGET = "/lib/hw/android.hardware.graphics.composer@2.1-impl.so"
BASE_TARGET_SHA = "185ea16bb45e5ea8409ea47be801e52dec5c864f0bdfe28236b2ac9d1dc5807b"
PATCH_TARGET_SHA = "714c142b137b7c9ecf703bcbc1a34804b757f0a6bf1170afa1650b321b3dd06a"

def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

def run(image: Path, command: str, write=False):
    args = ["debugfs"]
    if write:
        args += ["-w", "-R", command]
    else:
        args += ["-R", command]
    return subprocess.run(args + [str(image)], text=True, capture_output=True, check=True)

def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} INPUT_VENDOR_IMG OUTPUT_VENDOR_IMG", file=sys.stderr)
        return 2
    source, output = map(lambda x: Path(x).resolve(), sys.argv[1:])
    if not source.is_file():
        raise SystemExit(f"missing input image: {source}")
    if not PAYLOAD.is_file():
        raise SystemExit(f"missing HWC payload: {PAYLOAD}")
    if sha(PAYLOAD) != PATCH_TARGET_SHA:
        raise SystemExit("payload SHA256 does not match verified VSYNC patch")
    with tempfile.TemporaryDirectory(prefix="g81-hwc-") as td:
        before = Path(td) / "before.so"
        run(source, f"dump {TARGET} {before}")
        if sha(before) != BASE_TARGET_SHA:
            raise SystemExit("input HWC target SHA256 is not the expected unpatched blob")
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, output)
    run(output, f"rm {TARGET}", write=True)
    run(output, f"write {PAYLOAD} {TARGET}", write=True)
    run(output, f"set_inode_field {TARGET} mode 33188", write=True)
    # Keep the vendor_file label used by the original inode.
    run(output, f"ea_set {TARGET} security.selinux u:object_r:vendor_file:s0", write=True)
    with tempfile.TemporaryDirectory(prefix="g81-hwc-check-") as td:
        after = Path(td) / "after.so"
        run(output, f"dump {TARGET} {after}")
        if sha(after) != PATCH_TARGET_SHA:
            raise SystemExit("written HWC target does not match patch SHA256")
    fsck = subprocess.run(["e2fsck", "-fn", str(output)], text=True, capture_output=True)
    if fsck.returncode not in (0, 1):
        print(fsck.stdout + fsck.stderr, file=sys.stderr)
        raise SystemExit("e2fsck read-only check failed")
    print(f"BASE_TARGET_SHA256={BASE_TARGET_SHA}")
    print(f"PATCH_TARGET_SHA256={PATCH_TARGET_SHA}")
    print(f"OUTPUT_SHA256={sha(output)}")
    print("HWC_ZERO_VSYNC_IMAGE_OK")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
