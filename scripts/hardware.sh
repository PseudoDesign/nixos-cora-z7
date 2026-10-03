#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
usage() {
    cat <<'EOF'
Usage: scripts/hardware.sh create|gui|build [build-directory] [jobs]
  create  Recreate a project for inspection (default: build/vivado).
  gui     Create and open a project, or open its existing .xpr.
  build   Recreate, implement and export (default: build/release).
Existing directories are never deleted or overwritten by create/build.
Source Vivado 2026.1 settings64.sh first. Python 3 is needed for build.
EOF
}
if [[ $# == 0 || ${1:-} == --help || ${1:-} == -h ]]; then usage; exit 0; fi
action=$1
case "$action" in
    create|gui) default_dir="$repo_root/build/vivado" ;;
    build) default_dir="$repo_root/build/release" ;;
    *) usage >&2; exit 2 ;;
esac
if (( $# > 3 )); then usage >&2; exit 2; fi
project_dir=${2:-$default_dir}
jobs=${3:-4}
[[ $jobs =~ ^[1-9][0-9]*$ ]] || { echo 'Jobs must be a positive integer' >&2; exit 2; }
command -v vivado >/dev/null || { echo 'Source Vivado 2026.1 settings64.sh first.' >&2; exit 1; }
if [[ $action == build ]]; then
    command -v python3 >/dev/null || { echo 'Python 3 is required; use nix develop.' >&2; exit 1; }
fi
# Resolve relative paths before moving logs and .Xil into the ignored directory.
[[ $project_dir == /* ]] || project_dir="$PWD/$project_dir"
mkdir -p "$repo_root/build/logs"
cd "$repo_root/build/logs"
log="${action}-$(date +%Y%m%d-%H%M%S)-$$"
if [[ $action == gui && -f "$project_dir/cora-z7-07s.xpr" ]]; then
    exec vivado -mode gui -log "$log.log" -journal "$log.jou" "$project_dir/cora-z7-07s.xpr"
fi
mode=batch
[[ $action != gui ]] || mode=gui
exec vivado -mode "$mode" -log "$log.log" -journal "$log.jou" \
    -source "$repo_root/hw/entry.tcl" -tclargs "$action" "$project_dir" "$jobs"
