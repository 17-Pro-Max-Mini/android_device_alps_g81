#!/usr/bin/env python3
import argparse, subprocess, shutil, pathlib
p=argparse.ArgumentParser(); p.add_argument('input'); p.add_argument('output'); p.add_argument('payload'); a=p.parse_args()
root=pathlib.Path(a.payload); src=pathlib.Path(a.input); out=pathlib.Path(a.output)
if src.resolve()==out.resolve(): raise SystemExit('use a distinct output copy')
shutil.copyfile(src,out)
for rel,file,mode,label in [
 ('bin/g81-pqctl','g81-pqctl',0o100755,'mtk_hal_pq_exec'),
 ('etc/init/g81-pq-neutral.rc','g81-pq-neutral.rc',0o100644,'vendor_configs_file'),
 ('etc/selinux/precompiled_sepolicy','precompiled_sepolicy',0o100644,'sepolicy_file'),
 ('etc/selinux/nonplat_sepolicy.cil','nonplat_sepolicy.cil',0o100644,'sepolicy_file'),
 ('etc/selinux/nonplat_file_contexts','nonplat_file_contexts',0o100644,'file_contexts_file')]:
 f=root/file; assert f.is_file(),f
 for cmd in [f'rm /{rel}',f'write {f} /{rel}',f'set_inode_field {rel} mode {mode}',f'ea_set {rel} security.selinux u:object_r:{label}:s0']:
  r=subprocess.run(['debugfs','-w','-R',cmd,str(out)],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
  if r.returncode: raise SystemExit(r.stderr.decode())
 print('PATCHED',rel)
