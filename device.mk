LOCAL_PATH := device/alps/g81

# Android 10 requires the XML audio policy parser for the Oreo vendor HAL.
USE_XML_AUDIO_POLICY_CONF := 1

# The legacy MTK HWC2 stack relies on the stock no-backpressure mode.
# This prevents native-window buffer stalls while the vendor EGL path
# tears down and recreates its four-buffer surface queue.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    debug.sf.disable_backpressure=1


# The MT6580 vendor gralloc/HIDL path crashes Codec2's graphic allocator.
# Keep software Codec2 disabled; OMX.MTK AVC remains available for decode/encode.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    debug.stagefright.ccodec=0

# The Oreo MTK picture-quality service enables HDR/ADL/sharpening defaults
# that are not compatible with Android 10's HWC2 composition path.  Disable
# those post-processing stages so video frames keep a stable luminance.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    persist.sys.pq.hdr.en=0 \
    persist.sys.pq.mdp.color.dbg=0 \
    persist.sys.pq.ultrares.en=0 \
    persist.sys.pq.iso.shp.en=0 \
    persist.sys.pq.adl.idx=0 \
    persist.sys.pq.shp.idx=0 \
    persist.sys.pq.mdp.color.idx=0 \
    debug.pq.dshp.en=0 \
    debug.pq.shp.en=0

# libcutils' Android 10 memfd/ashmem path requires an explicit VNDK level on
# the system property file.  The legacy PRODUCT_DEFAULT_PROPERTY_OVERRIDES
# bucket is not emitted for this system-as-root product, so use the system
# default bucket directly.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.vndk.version=29

# The 1 GiB MT6580 build uses Android 10's ashmem compatibility daemon.  The
# modules are built by system/ashmemd but are not pulled into a small legacy
# product automatically; explicitly package both the daemon and its dlopen
# client so libcutils does not fall back to the missing-library path.
PRODUCT_PACKAGES += \
    ashmemd \
    libashmemd_client

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

# The checked-in vendor image carries the verified legacy-Oreo HWC2 adapter
# stack.  The historical prebuilt/hwc-zero-vsync payload is retained only as
# an analysis fixture; it produced a black spinner on this device and must not
# be applied to a release image.  The remaining EGL cancel_buffers warning is
# inside the proprietary Mali EGL blob and is tracked separately.

# Board-specific Health 2.0 consumes MTK batt_vol/batt_temp (generic HAL misses them).
PRODUCT_PACKAGES += \
    g81-healthd \
    android.hardware.health@2.0-service.g81

# Legacy MTK SoftAP starts hostapd through the Android 10 HIDL bridge.
# Ship both interface versions; the vendor hostapd binary links these from /system/lib.
PRODUCT_PACKAGES += \
    android.hardware.wifi.hostapd@1.0 \
    android.hardware.wifi.hostapd@1.1

# Real PQ switch control; the prebuilt vendor image contains the rc and policy.
PRODUCT_PACKAGES += g81-pqctl
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/vendor/etc/init/g81-pq-neutral.rc:vendor/etc/init/g81-pq-neutral.rc

# libmnl's exact destroy import is redirected by the cumulative vendor transform.
PRODUCT_PACKAGES += libg81_gnsscompat

# Vendor mounts after early uevent coldboot on this legacy system-as-root port.
# Make its labels available before /vendor is mounted, using libselinux fallback.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/vendor_file_contexts:$(TARGET_COPY_OUT_ROOT)/vendor_file_contexts
