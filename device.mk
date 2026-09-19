LOCAL_PATH := device/alps/g81

# SurfaceFlinger reads this only during process startup.  Keep the stock
# recovery property's legacy value (1) from disabling frame backpressure in
# the normal system boot.
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    debug.sf.disable_backpressure=0

# ART's low-RAM mode uses a 1.0 foreground heap growth multiplier. Retaining
# 4 MiB after collection reduces allocation-heavy startup GC without changing
# the 128 MiB growth limit supplied by go_defaults.mk.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapmaxfree=4m

# This device has no hardware navigation keys.  Keep the framework software
# navigation bar enabled through the product resource overlay.
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# The vendor audio policy exposes the standard A2DP module.  Include the
# matching system-side audio HAL so media can be routed to Bluetooth sinks.
PRODUCT_PACKAGES += \
    audio.a2dp.default

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/permissions/default-permissions-g81.xml:system/etc/default-permissions/default-permissions-g81.xml \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6580.rc:root/init.recovery.mt6580.rc \
    $(LOCAL_PATH)/rootdir/init.mt6580.rc:root/init.mt6580.rc \
    $(LOCAL_PATH)/rootdir/init.cdfinger.rc:root/init.cdfinger.rc \
    $(LOCAL_PATH)/rootdir/fstab.enableswap:root/fstab.enableswap

# The private vendor tree supplies the stock vendor image and the system-side
# compatibility libraries required by its Oreo HIDL services.
$(call inherit-product, vendor/alps/g81/g81-vendor.mk)
