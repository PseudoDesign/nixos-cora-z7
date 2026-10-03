#!/usr/bin/env python3
"""Record inputs and hashes so a changed XSA/board cannot reuse a stale SDT."""
import hashlib
import json
import sys
import shutil
import zipfile
from pathlib import Path
from inspect_xsa import inspect


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


if __name__ == "__main__":
    directory, xsa, board = map(Path, sys.argv[1:])
    info = inspect(xsa)
    # Include the input XSA in the staged handoff, independent of the user's
    # Vivado project location and bitstream filename.
    if xsa.resolve() != (directory / "hardware.xsa").resolve():
        shutil.copyfile(xsa, directory / "hardware.xsa")
    with zipfile.ZipFile(xsa) as archive:
        (directory / "system.bit").write_bytes(archive.read(info["bitstream_member"]))
    info.update({"schema": 2,
                 "sdtgen_version": (directory / "sdtgen-version.txt").read_text().strip(),
                 "board_sha256": sha(board),
                 "files": {str(p.relative_to(directory)): sha(p)
                           for p in sorted(directory.rglob("*"))
                           if p.is_file() and p.name != "handoff.json"}})
    (directory / "handoff.json").write_text(json.dumps(info, indent=2) + "\n")
