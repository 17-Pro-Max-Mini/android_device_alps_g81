LOCAL_PATH := device/alps/g81

# Android 10 requires the XML audio policy parser for the Oreo vendor HAL.
USE_XML_AUDIO_POLICY_CONF := 1

# SurfaceFlinger reads this only during process startup.  Keep the stock
# recovery property's legacy value (1) from disabling frame backpressure in
# the normal system boot.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    debug.sf.disable_backpressure=0

# This device has no hardware navigation keys.  Keep the framework software
# navigation bar enabled through the product resource overlay.
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/keylayout/mtk-kpd.kl:system/usr/keylayout/mtk-kpd.kl \
    $(LOCAL_PATH)/permissions/default-permissions-g81.xml:system/etc/default-permissions/default-permissions-g81.xml \
    $(LOCAL_PATH)/prebuilt/product/etc/apns-conf.xml:product/etc/apns-conf.xml \
    $(LOCAL_PATH)/prebuilt/vendor/bin/audio-setparam:vendor/bin/audio-setparam \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6580.rc:root/init.recovery.mt6580.rc \
    $(LOCAL_PATH)/rootdir/init.mt6580.rc:root/init.mt6580.rc \
    $(LOCAL_PATH)/rootdir/fstab.enableswap:root/fstab.enableswap

# System-side proprietary libraries are supplied by vendor/alps/g81/g81-vendor.mk.

# CameraX on Android 10 selects the 640x480 camcorder profile.  The stock
# profile advertises m4v/mp4v-es, but this MT6580 vendor exposes a usable AVC
# encoder for that mode; keep the corrected profile in the generated vendor
# payload instead of relying on a runtime overlay.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/etc/media_profiles.xml:vendor/etc/media_profiles.xml

# The platform build already supplies mediacodec.policy; keep the flattened copy as a reference.

# The MT6580 WMT driver exposes wlan0 only after /dev/wmtWifi receives 1.
# Android 10's framework does not perform this legacy power-on write, and the
# Oreo supplicant service must be started with STA only (no forced p2p0).
# Apply the vendor-image transformation from tools/patch-vendor-hal.sh when
# generating the prebuilt vendor image.

# The checked-in vendor image also carries the legacy-Oreo HWC2 VSYNC
# normalization.  MT6580's HWC can report timestamp 0; the compatibility
# implementation converts non-positive timestamps to CLOCK_MONOTONIC before
# notifying SurfaceFlinger, preventing duplicate-VSYNC/faked-VSYNC stalls and
# the black-screen SurfaceFlinger crash seen on this Android 10 port.  The
# standalone payload and reproducible image transformer are kept under
# prebuilt/hwc-zero-vsync and tools/apply-hwc-zero-vsync.py.
