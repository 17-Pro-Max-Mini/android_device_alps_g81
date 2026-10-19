LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := libg81_gnsscompat
LOCAL_SRC_FILES := gnsscompat.c
LOCAL_VENDOR_MODULE := true
LOCAL_CFLAGS := -Wall -Werror -fvisibility=hidden
LOCAL_SHARED_LIBRARIES := libc
include $(BUILD_SHARED_LIBRARY)
