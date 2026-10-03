#!/usr/bin/env python3
"""Check the bundled hardware export before invoking AMD tools."""
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
        required = {"cora-z7-wrapper.bit", "ps7_init.c", "ps7_init.h"}
        missing = required - set(archive.namelist())
        if version != "2024.1" or part != "xc7z007sclg400-1" or missing:
            raise ValueError(
                f"Expected Vivado 2024.1 / xc7z007sclg400-1 and {sorted(required)}; "
                f"found version={version}, part={part}, missing={sorted(missing)}"
            )
        return {"vivado_version": version, "part": part,
                "xsa_sha256": hashlib.sha256(Path(path).read_bytes()).hexdigest()}


if __name__ == "__main__":
    try:
        print(json.dumps(inspect(Path(sys.argv[1])), indent=2))
    except (ValueError, KeyError, zipfile.BadZipFile) as error:
        sys.exit(str(error))
