{ runCommandCC, python3, dtc, lopper, sdtDir }:
runCommandCC "cora-z7-07s-linux.dtb" {
  nativeBuildInputs = [ python3 dtc lopper ];
  LOPPER_DTC_FLAGS = "-b 0 -@";
} ''
  # Lopper preprocessing expects relative include/ paths in the SDT directory.
  cp -r ${sdtDir} sdt
  chmod -R u+w sdt
  cd sdt
  mkdir linux
  lopper -f --enhanced -O linux system-top.dts system.dtb -- \
    gen_domain_dts ps7_cortexa9_0 linux_dt
  python3 ${../scripts/check-linux-dtb.py} linux/system.dtb
  cp linux/system.dtb "$out"
''
