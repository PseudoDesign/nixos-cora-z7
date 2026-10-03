#!/usr/bin/env python3
"""Reject absent, mismatched, or modified AMD-generated hardware inputs."""
import hashlib
import json
import sys
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(directory, xsa, board):
    manifest = directory / "handoff.json"
    if not manifest.is_file():
        raise ValueError(
            "Missing SDT handoff. Source Vitis 2024.1 settings64.sh, run "
            "./scripts/prepare-sdt.sh, then git add hardware/sdt before building."
        )
    data = json.loads(manifest.read_text())
    if data.get("schema") != 1 or data.get("vivado_version") != "2024.1" or data.get("xsct_version") != "2024.1":
        raise ValueError("Expected the version-1 Vivado/XSCT 2024.1 handoff")
    if data.get("part") != "xc7z007sclg400-1":
        raise ValueError("Handoff is not for the Cora Z7-07S")
    if data["xsa_sha256"] != digest(xsa) or data["board_sha256"] != digest(board):
        raise ValueError("XSA or board DTSI changed: regenerate with ./scripts/prepare-sdt.sh")
    required = ["system-top.dts", "ps7_init.c", "ps7_init.h", "cora-z7-wrapper.bit", board.name]
    for name in required:
        if not (directory / name).is_file() or name not in data["files"]:
            raise ValueError(f"Missing generated SDT input: {name}")
    for name, expected in data["files"].items():
        path = directory / name
        if Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError(f"Invalid manifest path: {name}")
        if not path.is_file() or digest(path) != expected:
            raise ValueError(f"SDT file changed or is missing: {name}; regenerate the handoff")
    if digest(directory / board.name) != digest(board):
        raise ValueError("The generated SDT did not copy the current board DTSI")
    top = (directory / "system-top.dts").read_text()
    if board.name not in top:
        raise ValueError("system-top.dts does not include the Cora board corrections")
    print("Validated Vivado/XSCT 2024.1 Cora Z7-07S handoff")


if __name__ == "__main__":
    try:
        check(*map(Path, sys.argv[1:]))
    except (ValueError, KeyError, OSError) as error:
        sys.exit(str(error))
