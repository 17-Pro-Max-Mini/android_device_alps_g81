$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/go_defaults.mk)
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, device/alps/g81/device.mk)

# Use the launcher variant designed for Android Go. It overrides the regular
# Trebuchet package pulled in by Lineage's common phone configuration.
PRODUCT_PACKAGES += \
    TrebuchetGo

# The stock Oreo system uses split framework/vendor SELinux policy and the
# full-Treble linker namespace layout, despite advertising VNDK 0.0.0.
PRODUCT_FULL_TREBLE_OVERRIDE := true

PRODUCT_DEVICE := g81
PRODUCT_NAME := lineage_g81
PRODUCT_BRAND := alps
PRODUCT_MODEL := 17_Pro_Max
PRODUCT_MANUFACTURER := alps

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=g81em1_o_xc6_l10_17promax \
    PRODUCT_NAME=full_g81em1_o_xc6_l10_17promax
