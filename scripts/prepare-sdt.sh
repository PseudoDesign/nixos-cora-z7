#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
xsa="$repo_dir/hardware/cora-z7-07s.xsa"
board="$repo_dir/hardware/cora-z7-07s.dtsi"
output="$repo_dir/hardware/sdt"

if [[ $# -gt 0 ]]; then
  echo "Usage: $0 (uses the bundled hardware/cora-z7-07s.xsa)" >&2
  exit 2
fi
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }
command -v xsct >/dev/null || {
  echo "Source your Vitis 2024.1 settings64.sh first; xsct is not on PATH." >&2
  exit 1
}
python3 "$repo_dir/scripts/inspect_xsa.py" "$xsa"

# Do not replace the previous handoff unless generation and validation succeed.
work=$(mktemp -d "$repo_dir/hardware/.sdt-XXXXXX")
trap 'rm -rf -- "$work"' EXIT
xsct "$repo_dir/scripts/generate-sdt.tcl" "$xsa" "$work/generated" "$board"
python3 "$repo_dir/scripts/record-handoff.py" "$work/generated" "$xsa" "$board"
python3 "$repo_dir/scripts/check-handoff.py" "$work/generated" "$xsa" "$board"

mkdir -p "$output"
# Only previously generated files are replaced. Preserve the tracked README.
find "$output" -mindepth 1 -maxdepth 1 ! -name README.md -exec rm -rf -- {} +
cp -R "$work/generated/." "$output/"
echo "SDT prepared in $output"
echo "Next: git add hardware/sdt && nix build .#sdImage -L"
