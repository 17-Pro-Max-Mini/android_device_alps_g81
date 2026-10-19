DEVICE_PATH := device/alps/g81

# Architecture: MT6580 is a 32-bit Cortex-A7 platform.
TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a7
TARGET_CPU_SMP := true
ARCH_ARM_HAVE_NEON := true
ARCH_ARM_HAVE_VFP := true
ARCH_ARM_HAVE_TLS_REGISTER := true

# Android Go / low-RAM allocator profile. A single jemalloc arena without the
# normal tcache reduces per-process PSS on this 1 GiB device.
MALLOC_SVELTE := true

# Platform and bootloader.
TARGET_BOARD_PLATFORM := mt6580
TARGET_BOOTLOADER_BOARD_NAME := g81em1_o_xc6_l10_17promax
TARGET_NO_BOOTLOADER := true

BOARD_HAS_MTK_HARDWARE := true
BOARD_USES_MTK_HARDWARE := true
MTK_HARDWARE := true

# The stock vendor exposes the HIDL composer 2.1 service. Build SurfaceFlinger
# against its HWC2 path instead of the legacy HWC1 fallback.
TARGET_USES_HWC2 := true

# The checked-out private vendor tree supplies the verified stock kernel and
# vendor image. Keep the stock kernel byte-for-byte intact for this port.
-include vendor/alps/g81/BoardConfigVendor.mk

ifeq ($(strip $(TARGET_PREBUILT_KERNEL)),)
$(error Missing vendor/alps/g81. Sync the private proprietary_vendor_alps_g81 repository or run extract-files.sh.)
endif

BOARD_KERNEL_IMAGE_NAME := zImage
BOARD_KERNEL_BASE := 0x80000000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x04000000
BOARD_TAGS_OFFSET := 0x0e000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_CMDLINE := bootopt=64S3,32S1,32S1
BOARD_MKBOOTIMG_ARGS := \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_RAMDISK_OFFSET) \
    --tags_offset $(BOARD_TAGS_OFFSET)

# Legacy, non-A/B GPT layout. Values come from the verified stock dump.
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 16777216
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
BOARD_VENDORIMAGE_PARTITION_SIZE := 419430400
BOARD_CACHEIMAGE_PARTITION_SIZE := 117440512
BOARD_USERDATAIMAGE_PARTITION_SIZE := 12739674112

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_COPY_OUT_VENDOR := vendor
BOARD_HAS_LARGE_FILESYSTEM := true

# Recovery.
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
BOARD_HAS_NO_SELECT_BUTTON := true
RECOVERY_SDCARD_ON_DATA := true
RECOVERY_GRAPHICS_USE_LINELENGTH := true

# The stock panel is 384x854 at density 200. Let TWRP select portrait_mdpi
# from these exact dimensions rather than hard-coding a mismatched theme.
TARGET_SCREEN_WIDTH := 384
TARGET_SCREEN_HEIGHT := 854
TARGET_SCREEN_DENSITY := 200
TW_BRIGHTNESS_PATH := /sys/class/leds/lcd-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_DEFAULT_BRIGHTNESS := 128

# Keep the gzip ramdisk small enough for the 16 MiB recovery partition. The
# stock kernel does not have CONFIG_RD_LZMA or CONFIG_RD_XZ.
TW_EXTRA_LANGUAGES := false
TW_EXCLUDE_BASH := true
TW_EXCLUDE_NANO := true
TW_EXCLUDE_TZDATA := true
# Python is not used by the supported recovery workflows. Excluding the
# interpreter preserves several MiB of recovery-partition headroom.
TW_EXCLUDE_PYTHON := true
TW_USE_TOOLBOX := true

TW_INCLUDE_CRYPTO := true
TW_HAS_MTP := true
TW_MTP_DEVICE := /dev/mtp_usb
TW_NO_CPU_TEMP := true
TW_REBOOT_RECOVERY := true

ALLOW_MISSING_DEPENDENCIES := true

# Install the pinned vendor prebuilt even without a generated VENDOR/ tree.
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)
# Accept the canonical ROM name and the original stock/TWRP board identity.
TARGET_OTA_ASSERT_DEVICE := g81,g81em1_o_xc6_l10_17promax
