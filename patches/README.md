# G81 vendor compatibility patches

`patch-vendor-audio-dc-removal.sh` updates a copy of the stock vendor image.
The MT6580 Oreo audio HAL's optional DC-removal manager is absent on the
Android 10 userspace. Its null check logs the failure but continues into a
null vtable, restarting the audio HAL every few seconds. The patch changes
that conditional branch to return without the optional filter; normal ALSA
playback and capture remain enabled.

The script checks the original instruction bytes before writing and verifies
the patched bytes after reinserting the file. It must be run against a copy
of `vendor.img`; the source image remains available for rollback.
