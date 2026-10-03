#!/usr/bin/env python3
"""Import a Vivado hardware release and apply the current Nix board sources."""
import shutil
import sys
import tarfile
import zipfile
from pathlib import Path
from hardware_release import unpack
from inspect_xsa import inspect


def import_release(archive, destination, board):
    unpack(archive, destination)
    # Check the archived XSA itself, independent of the release manifest.
    inspect(destination / "hardware.xsa")
    if (destination / board.name).exists():
        raise ValueError("Hardware release contains board corrections; export a raw SDT")
    shutil.copyfile(board, destination / board.name)
    with (destination / "system-top.dts").open("a") as top:
        top.write(f'\n// Cora wiring and 07S corrections must take precedence.\n#include "{board.name}"\n')
    print("Imported Vivado 2026.1 SDT release; applied current Cora Z7-07S corrections")


if __name__ == "__main__":
    try:
        if len(sys.argv) != 4:
            raise ValueError("Usage: import-hardware.py <release.tar.gz> <output-directory> <board-dtsi>")
        import_release(*map(Path, sys.argv[1:]))
    except (ValueError, KeyError, OSError, tarfile.TarError, zipfile.BadZipFile) as error:
        sys.exit(str(error))
