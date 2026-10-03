#!/usr/bin/env python3
"""Reject absent, mismatched, or modified AMD-generated hardware inputs."""
import hashlib
import json
import re
import sys
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(directory, board):
    manifest = directory / "handoff.json"
    if not manifest.is_file():
        raise ValueError(
            "Missing SDT handoff. Source Vivado 2026.1 settings64.sh, run "
            "./scripts/prepare-sdt.sh /path/to/export.xsa, then git add hardware/sdt."
        )
    data = json.loads(manifest.read_text())
    if (data.get("schema") != 2
            or not re.match(r"^2026\.1(?:\D|$)", data.get("vivado_version", ""))
            or not re.match(r"^2026\.1(?:\D|$)", data.get("sdtgen_version", ""))):
        raise ValueError("Expected a version-2 Vivado/SDTGen 2026.1 handoff")
    if data.get("part") != "xc7z007sclg400-1":
        raise ValueError("Handoff is not for the Cora Z7-07S")
    if data["xsa_sha256"] != digest(directory / "hardware.xsa") or data["board_sha256"] != digest(board):
        raise ValueError("XSA or board DTSI changed: regenerate with ./scripts/prepare-sdt.sh")
    required = ["system-top.dts", "ps7_init.c", "ps7_init.h", "system.bit",
                "hardware.xsa", "sdtgen-version.txt", board.name]
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
    if digest(directory / "system.bit") != data["bitstream_sha256"]:
        raise ValueError("Bitstream does not match the exported XSA")
    top = (directory / "system-top.dts").read_text()
    if board.name not in top:
        raise ValueError("system-top.dts does not include the Cora board corrections")
    print("Validated Vivado/SDTGen 2026.1 Cora Z7-07S handoff")


if __name__ == "__main__":
    try:
        check(*map(Path, sys.argv[1:]))
    except (ValueError, KeyError, OSError) as error:
        sys.exit(str(error))
