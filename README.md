# android_device_alps_g81

Public LineageOS 15.1 and TWRP 8.1 device tree for the MT6580-based G81EM1
family.

`g81` is the stable community codename used for the repository, checkout path
(`device/alps/g81`), lunch products, artifact names, and documentation. The
stock technical target `g81em1_o_xc6_l10_17promax` remains in generated Android
runtime properties and bootloader matching fields because the validated MTK
vendor stack expects it. `PRODUCT_DEVICE` itself is `g81`, which is required
for Android 8.1 to discover `device/alps/g81/BoardConfig.mk` without a link.

## Branches

- `lineage-15.1`: Android 8.1 / LineageOS 15.1.
- `twrp-8.1`: Android 8.1 / TWRP recovery.

The tree needs `vendor/alps/g81` from the private
`proprietary_vendor_alps_g81` repository. It contains the legally restricted
kernel, vendor image and compatibility libraries, and is intentionally absent
from this repository. For an authorized local source extraction, provide an
input directory containing `kernel`, `vendor.img`, and `system/lib/`, then run:

```bash
device/alps/g81/extract-files.sh /path/to/g81-stock-input
```

No partitions, device identifiers, logs, or factory-only applications belong
in this public source tree. Use the `android_manifest` repository as the
supported setup, sync, build, validation, and release entry point.

## Confirmed hardware baseline

The LineageOS 15.1 hardware baseline has been boot-tested with SELinux
enforcing. Calls (incoming and outgoing), USSD, SMS, Wi-Fi, Bluetooth media,
cameras, microphone recording, charging, deep sleep, sensors, software
navigation, and recovery touch/display have been exercised. Published builds
use the `lineage_g81-user` target. The low-RAM/Go configuration and MTK HWC
software-VSYNC fallback are deliberate compatibility settings.

The device keeps 4 MiB of free ART heap after collection. Controlled A/B/A
testing on the 1 GiB target reduced allocation-heavy application startup GC
work without changing the Go heap growth limit. This is intentionally a small
headroom adjustment rather than a larger generic heap-size override.

The MTK GPS driver creates its sysfs controls after the vendor init script has
run. The device init repeats the vendor `gps:gps` ownership at the driver-load
property trigger so `mnld` can control the receiver under enforcing SELinux.

The panel reports 56.76 Hz and the stock MTK HWC composes the launcher and
notification shade as device layers. No persistent CPU/GPU frequency lock is
part of the device tree: controlled tests did not produce a repeatable
whole-UI benefit. A remaining first-frame latency is in the stock Mali-400
Utgard kernel path, where a touch boost can be discarded while the GPU is
powered down. That issue belongs in a future exact-source kernel tree rather
than a build-property workaround.

Bluetooth media routing uses the platform `audio.a2dp.default` HAL because the
stock MTK audio policy declares that standard module. It is built into the
Lineage product; no vendor blob or runtime workaround is required.

Recovery exposes the normal OS partitions plus `boot`, `recovery`, `logo`, and
the encryption metadata required for supported recovery workflows. Factory and
calibration partitions are deliberately not mounted or offered as backups.
