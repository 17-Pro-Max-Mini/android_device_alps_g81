# G81 Android 10 device tree

Branch `lineage-17.1`, daily-use snapshot `g81-17.1-20261019`.
Entry point and pinned source manifest:
https://github.com/17-Pro-Max-Mini/android_manifest/tree/lineage-17.1

MT6580 / ARMv7 / 1 GiB RAM / 384x854 / legacy 3.18.79 kernel. This is not a
generic modern Treble/GSI target. The separate vendor image carries legacy MTK
HAL and ABI compatibility changes. Do not replace it with arbitrary stock/GSI
vendor input. The stock kernel is used; a full kernel source tree is not part
of this snapshot.

`prebuilt` is a symlink to `vendor/alps/g81/device-prebuilts` in the private
vendor checkout. It deliberately keeps binary inputs out of this public repo.
Use the manifest rather than cloning this tree alone to build.

Device-local sources include Health 2.0 MTK sysfs selection, GNSS compatibility,
PQ control and Wi-Fi/HAL helper sources. Resource overlays retain gesture
navigation/status-bar dimensions and fill the missing Settings SetupDesign
boolean. `rootdir/vendor_file_contexts` provides labels before vendor coldboot.
SELinux policy fragments are documented here; the active cumulative CIL and
compiled policy are shipped by the pinned private vendor image.

Historical transform scripts are retained for provenance. They have specific
input hashes and are not an ordered release pipeline; do not apply them again
to the already-patched release vendor image. In particular, the experimental
zero-vsync HWC payload is not used by this snapshot.
