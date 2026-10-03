#!/usr/bin/env python3
"""Check a Vivado 2026.1 Cora Z7-07S export before invoking AMD tools."""
import hashlib
import json
import sys
import zipfile
from pathlib import Path


def inspect(path):
    with zipfile.ZipFile(path) as archive:
        info = json.loads(archive.read("xsa.json"))
        version = info["generatedVersion"]
        part = info["board"]["part"]
        bitstreams = [name for name in archive.namelist() if name.endswith(".bit")]
        required = {"ps7_init.c", "ps7_init.h"}
        missing = required - set(archive.namelist())
        release = ".".join(version.split(".")[:2])
        if release != "2026.1" or part != "xc7z007sclg400-1" or missing or len(bitstreams) != 1:
            raise ValueError(
                f"Expected Vivado 2026.1 / xc7z007sclg400-1, PS7 init files and one bitstream; "
                f"found version={version}, part={part}, missing={sorted(missing)}, "
                f"bitstreams={bitstreams}. Re-export using write_hw_platform -include_bit."
            )
        return {"vivado_version": version, "part": part, "bitstream_member": bitstreams[0],
                "bitstream_sha256": hashlib.sha256(archive.read(bitstreams[0])).hexdigest(),
                "xsa_sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest()}


if __name__ == "__main__":
    try:
        print(json.dumps(inspect(Path(sys.argv[1])), indent=2))
    except (ValueError, KeyError, OSError, zipfile.BadZipFile) as error:
        sys.exit(str(error))
