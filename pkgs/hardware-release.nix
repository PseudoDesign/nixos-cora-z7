{ lib, runCommand, python3, releasePackage, boardDtsi }:
runCommand "cora-z7-07s-sdt" {
  nativeBuildInputs = [ python3 ];
} ''
  python3 ${../scripts}/import-hardware.py ${lib.escapeShellArg (toString releasePackage)} "$out" ${boardDtsi}
  python3 ${../scripts}/record-handoff.py "$out" "$out/hardware.xsa" ${boardDtsi}
  python3 ${../scripts}/check-handoff.py "$out" ${boardDtsi}
''
