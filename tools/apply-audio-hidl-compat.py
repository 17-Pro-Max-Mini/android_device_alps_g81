#!/usr/bin/env python3
"""Apply verified audio ABI payload to a COPY of a raw vendor image."""
import pathlib, subprocess, sys
src,out=map(pathlib.Path,sys.argv[1:])
assert src.resolve()!=out.resolve(), 'input must remain unchanged'
subprocess.run(['cp','--reflink=auto',str(src),str(out)],check=True)
payload=pathlib.Path(__file__).resolve().parent.parent/'prebuilt/audio-hidl-compat'
for f in sorted(payload.rglob('*')):
    if not f.is_file(): continue
    rel=f.relative_to(payload).as_posix(); path='/'+rel
    if rel.startswith('lib/'):
        soname=subprocess.check_output(['patchelf','--print-soname',str(f)],text=True).strip()
        assert soname==f.name,(f,soname)
    cmds=[f'rm {path}', f'write {f} {path}',f'set_inode_field {path} mode 0100'+('755' if rel.startswith('bin/') else '644'),f'set_inode_field {path} uid 0',f'set_inode_field {path} gid 0',f'ea_set {path} security.selinux u:object_r:'+('mtk_hal_audio_exec:s0' if rel.startswith('bin/') else 'vendor_file:s0')]
    for c in cmds:
        r=subprocess.run(['debugfs','-w','-R',c,str(out)],capture_output=True,text=True,check=True)
        if 'write '==c[:6]: assert 'Allocated inode:' in r.stdout+r.stderr,r.stdout+r.stderr
    print('INSTALLED',path)
r=subprocess.run(['e2fsck','-fy',str(out)])
assert r.returncode in (0,1), 'filesystem repair failed'
subprocess.run(['e2fsck','-fn',str(out)],check=True)
print('IMAGE_OK')
