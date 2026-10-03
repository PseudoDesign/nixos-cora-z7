#!/usr/bin/env python3
"""Bundle a complete raw Vivado SDT export into one reproducible release file."""
import gzip
import io
import os
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path
from hardware_release import PREFIX, payload


def pack(directory, xsa, output):
    files = payload(directory, xsa)
    output.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".hardware-release-", dir=output.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            with gzip.GzipFile(filename="", fileobj=stream, mode="wb", mtime=0) as compressed:
                with tarfile.open(fileobj=compressed, mode="w", format=tarfile.PAX_FORMAT) as archive:
                    for name, data in sorted(files.items()):
                        entry = tarfile.TarInfo(f"{PREFIX}/{name}")
                        entry.size, entry.mode, entry.mtime = len(data), 0o644, 0
                        archive.addfile(entry, io.BytesIO(data))
        os.replace(temporary, output)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f"Hardware release written to {output}")


if __name__ == "__main__":
    try:
        if len(sys.argv) != 4:
            raise ValueError("Usage: pack-hardware.py <raw-sdt-directory> <xsa> <output.tar.gz>")
        pack(*map(Path, sys.argv[1:]))
    except (ValueError, KeyError, OSError, tarfile.TarError, zipfile.BadZipFile) as error:
        sys.exit(str(error))
