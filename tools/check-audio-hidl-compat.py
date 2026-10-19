#!/usr/bin/env python3
import pathlib,subprocess,sys,tempfile,hashlib
image=pathlib.Path(sys.argv[1]); base=pathlib.Path(__file__).resolve().parent.parent/'prebuilt/audio-hidl-compat'
errors=[]
with tempfile.TemporaryDirectory(dir=image.resolve().parent) as tmp:
 for src in sorted(base.rglob('*')):
  if not src.is_file():continue
  rel=src.relative_to(base).as_posix(); dest=pathlib.Path(tmp)/src.name
  subprocess.run(['debugfs','-R',f'dump /{rel} {dest}',str(image)],capture_output=True)
  if not dest.exists(): errors.append('MISSING '+rel);continue
  if dest.read_bytes()!=src.read_bytes():errors.append('MISMATCH '+rel)
  stat=subprocess.check_output(['debugfs','-R',f'stat /{rel}',str(image)],stderr=subprocess.DEVNULL,text=True)
  expected='mtk_hal_audio_exec' if rel.startswith('bin/') else 'vendor_file'
  if 'u:object_r:'+expected+':s0' not in stat:errors.append('CONTEXT '+rel)
  if 'Mode:  0'+('755' if rel.startswith('bin/') else '644') not in stat:errors.append('MODE '+rel)
  if rel.startswith('lib/'):
   soname=subprocess.check_output(['patchelf','--print-soname',str(dest)],text=True).strip()
   if soname!=src.name:errors.append('SONAME '+rel)
for e in errors:print(e)
print('AUDIO_PAYLOAD_FAIL' if errors else 'AUDIO_PAYLOAD_OK')
sys.exit(bool(errors))
