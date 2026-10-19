#!/usr/bin/env python3
import sys, pathlib, shutil, subprocess
src,out,payload=map(pathlib.Path,sys.argv[1:])
if src.resolve()==out.resolve(): raise SystemExit('distinct output copy required')
shutil.copyfile(src,out)
for name in ['nonplat_sepolicy.cil','precompiled_sepolicy']:
 f=payload/name
 assert f.is_file()
 commands=[f'rm /etc/selinux/{name}',f'write {f} /etc/selinux/{name}',f'set_inode_field etc/selinux/{name} mode 33188',f'ea_set etc/selinux/{name} security.selinux u:object_r:sepolicy_file:s0']
 for cmd in commands:
  p=subprocess.run(['debugfs','-w','-R',cmd,str(out)],capture_output=True,text=True)
  if p.returncode: raise SystemExit(p.stderr)
 print('PATCHED etc/selinux/'+name)
