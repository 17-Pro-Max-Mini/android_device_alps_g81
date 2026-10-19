LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := g81-pqctl
LOCAL_SRC_FILES := pqctl.cpp
LOCAL_VENDOR_MODULE := true
LOCAL_CPPFLAGS := -Wall -Werror
LOCAL_SHARED_LIBRARIES := libhidlbase libhidltransport libhwbinder libutils liblog
include $(BUILD_EXECUTABLE)
