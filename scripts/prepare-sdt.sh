#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
board="$repo_dir/hardware/cora-z7-07s.dtsi"
output="$repo_dir/hardware/sdt"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <Vivado-2026.1-export.xsa> (export with bitstream included)" >&2
  exit 2
fi
xsa=$(realpath -- "$1")
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }
command -v sdtgen >/dev/null || {
  echo "Source your Vivado 2026.1 settings64.sh first; sdtgen is not on PATH." >&2
  exit 1
}
if [[ -n ${CUSTOM_SDT_REPO:-} ]]; then
  echo "Unset CUSTOM_SDT_REPO to use the SDT repository shipped with Vivado 2026.1." >&2
  exit 1
fi
python3 "$repo_dir/scripts/inspect_xsa.py" "$xsa"

# Do not replace the previous handoff unless generation and validation succeed.
work=$(mktemp -d "$repo_dir/hardware/.sdt-XXXXXX")
trap 'rm -rf -- "$work"' EXIT
sdtgen "$repo_dir/scripts/generate-sdt.tcl" "$xsa" "$work/generated" "$board"
python3 "$repo_dir/scripts/record-handoff.py" "$work/generated" "$xsa" "$board"
python3 "$repo_dir/scripts/check-handoff.py" "$work/generated" "$board"

mkdir -p "$output"
# Only previously generated files are replaced. Preserve the tracked README.
find "$output" -mindepth 1 -maxdepth 1 ! -name README.md -exec rm -rf -- {} +
cp -R "$work/generated/." "$output/"
echo "SDT prepared in $output"
echo "Next: git add hardware/sdt && nix build .#sdImage -L"
