#!/usr/bin/env python3
from pathlib import Path
import shutil,subprocess,sys,hashlib
src,out,payload=map(Path,sys.argv[1:]);assert src.resolve()!=out.resolve()
sha=hashlib.sha256(src.read_bytes()).hexdigest()
assert sha=='c79172383a53e1f52d31e764bce90b3b02a371da6039bb67f622ae2b141da412',sha
shutil.copyfile(src,out)
for name,dest,label in [('libmnl.so','/lib/libmnl.so','vendor_file'),('libg81_gnsscompat.so','/lib/libg81_gnsscompat.so','vendor_file'),('init.connectivity.rc','/etc/init/hw/init.connectivity.rc','vendor_configs_file'),('nonplat_sepolicy.cil','/etc/selinux/nonplat_sepolicy.cil','sepolicy_file'),('precompiled_sepolicy','/etc/selinux/precompiled_sepolicy','sepolicy_file')]:
 f=payload/name;assert f.is_file()
 for cmd in [f'rm {dest}',f'write {f} {dest}',f'set_inode_field {dest.lstrip("/")} mode 33188',f'ea_set {dest.lstrip("/")} security.selinux u:object_r:{label}:s0']:
  p=subprocess.run(['debugfs','-w','-R',cmd,str(out)],capture_output=True,text=True);assert p.returncode==0,p.stderr
 verify=out.parent/('verified-'+name)
 p=subprocess.run(['debugfs','-R',f'dump {dest} {verify}',str(out)],capture_output=True,text=True);assert p.returncode==0 and verify.read_bytes()==f.read_bytes(),p.stderr;verify.unlink()
 print('VENDOR_VERIFIED='+dest)
print('VENDOR_SHA256='+hashlib.sha256(out.read_bytes()).hexdigest())
