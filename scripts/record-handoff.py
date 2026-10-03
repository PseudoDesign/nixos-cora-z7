#!/usr/bin/env python3
"""Record inputs and hashes so a changed XSA/board cannot reuse a stale SDT."""
import hashlib
import json
import sys
from pathlib import Path
from inspect_xsa import inspect


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


if __name__ == "__main__":
    directory, xsa, board = map(Path, sys.argv[1:])
    info = inspect(xsa)
    info.update({"schema": 1, "xsct_version": "2024.1",
                 "board_sha256": sha(board),
                 "files": {str(p.relative_to(directory)): sha(p)
                           for p in sorted(directory.rglob("*")) if p.is_file()}})
    (directory / "handoff.json").write_text(json.dumps(info, indent=2) + "\n")
