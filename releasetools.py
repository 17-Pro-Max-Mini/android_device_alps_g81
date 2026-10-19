"""G81 legacy prebuilt-vendor installation; compatible with Python2/3 releasetools."""
import hashlib
import common

VENDOR_SIZE = 419430400
EXPECTED_VENDOR_SHA256 = '9d4bee1e55a3a274e7e06ea8685c77bf2a260466e1a3c148edb8f414d68350b8'
VENDOR_DEVICE = '/dev/block/platform/mtk-msdc.0/11120000.msdc0/by-name/vendor'

def _InstallVendor(info, target_zip):
    # AOSP sees no VENDOR/ tree when BOARD_PREBUILT_VENDORIMAGE is used.
    # IMAGES/vendor.img alone is therefore omitted from the normal full OTA.
    # Carry the exact pinned image through a device-local hook, not a platform
    # modification or a filesystem regeneration from partial vendor files.
    image = target_zip.read('IMAGES/vendor.img')
    if len(image) != VENDOR_SIZE or hashlib.sha256(image).hexdigest() != EXPECTED_VENDOR_SHA256:
        raise ValueError('G81 vendor image does not match this Android-version snapshot')
    partition = info.script.fstab.get('/vendor')
    if partition is None or partition.device != VENDOR_DEVICE or partition.fs_type != 'ext4':
        raise ValueError('Unexpected G81 vendor partition in recovery fstab')
    common.ZipWriteStr(info.output_zip, 'vendor.img', image)
    info.script.Print('Installing matching G81 vendor image...')
    info.script.AppendExtra('unmount("/vendor");')
    info.script.AppendExtra('assert(package_extract_file("vendor.img", "%s"));' % VENDOR_DEVICE)

def FullOTA_InstallEnd(info):
    _InstallVendor(info, info.input_zip)

def IncrementalOTA_InstallEnd(info):
    _InstallVendor(info, info.target_zip)
