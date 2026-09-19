$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, vendor/omni/config/common.mk)
$(call inherit-product, device/alps/g81/device.mk)

PRODUCT_DEVICE := g81
PRODUCT_NAME := omni_g81
PRODUCT_BRAND := alps
PRODUCT_MODEL := 17_Pro_Max
PRODUCT_MANUFACTURER := alps

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=g81em1_o_xc6_l10_17promax \
    PRODUCT_NAME=full_g81em1_o_xc6_l10_17promax
