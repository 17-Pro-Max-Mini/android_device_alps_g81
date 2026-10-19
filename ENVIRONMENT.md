# G81 17.1 environment

Use the matching `lineage-17.1` vendor and patch branches. Do not mix
15.1 and 17.1 vendor images or device trees. The kernel stays the stock
3.18.79 ARMv7 kernel, with legacy non-A/B partitions and no super/vbmeta.

The vendor image is a pinned build input. Building source helpers or editing
SELinux .te files does not automatically change that prebuilt image. Review
and repackage it explicitly, then update release-inputs hashes, before release.
NVRAM/nvdata/protect partitions are device-specific and are not ROM inputs.

See android_manifest/g81-build and its pinned release XML for setup and build.
The stable Android 10 phone uses density 192 as a user override; ROM density
200 remains unchanged in this preservation release. No new display tuning or
binary substitutions were made just to prepare the PC-format backup.

The device-local releasetools hook includes the exact matching vendor image
in full/incremental OTA packages. Without this hook, the platform skips the
prebuilt vendor because target-files contains IMAGES/vendor.img but no VENDOR/.
The updater accepts both g81 and the stock board name, without removing device assertions.
