LOCAL_PATH := $(call my-dir)

# Board-specific healthd built from the verified MTK sysfs-path correction.
# It replaces the generic Q healthd target without changing framework code.
include $(CLEAR_VARS)
LOCAL_MODULE := g81-healthd
LOCAL_MODULE_STEM := healthd
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_OWNER := mtk
LOCAL_SRC_FILES := prebuilt/system/bin/healthd
LOCAL_MODULE_PATH := $(TARGET_OUT)
LOCAL_OVERRIDES_MODULES := healthd
include $(BUILD_PREBUILT)

# Device-local PQ control helper; selected in PRODUCT_PACKAGES for the neutralizer.
include $(LOCAL_PATH)/pqctl/Android.mk

# Explicit libmnl DT_NEEDED compatibility; secure mnld ignores LD_PRELOAD.
include device/alps/g81/gnsscompat/Android.mk
