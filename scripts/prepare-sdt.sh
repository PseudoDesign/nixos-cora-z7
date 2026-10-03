#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
output=${2:-"$repo_dir/hardware/cora-z7-07s-hardware.tar.gz"}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <Vivado-2026.1-export.xsa> [output-release.tar.gz]" >&2
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
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
sdtgen "$repo_dir/scripts/generate-sdt.tcl" "$xsa" "$work/generated"
python3 "$repo_dir/scripts/pack-hardware.py" "$work/generated" "$xsa" "$output"
echo "Add the release archive to your flake and build: nix build .#sdImage -L"
