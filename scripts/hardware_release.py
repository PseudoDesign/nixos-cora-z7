"""Portable hardware release format: raw SDT, XSA, bitstream and provenance."""
import hashlib
import json
import re
import tarfile
import zipfile
from pathlib import Path, PurePosixPath
from inspect_xsa import inspect

FORMAT = "cora-z7-hardware-release"
PREFIX = "hardware"
REQUIRED = {"system-top.dts", "ps7_init.c", "ps7_init.h", "hardware.xsa",
            "system.bit", "sdtgen-version.txt"}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def release_version(version):
    if not re.match(r"^2026\.1(?:\D|$)", version):
        raise ValueError(f"Expected Vivado/SDTGen 2026.1, found {version}")


def payload(directory, xsa):
    info = inspect(xsa)
    files = {}
    for path in sorted(directory.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"SDT release must contain files, not symlinks: {path}")
        if path.is_file():
            files[path.relative_to(directory).as_posix()] = path.read_bytes()
    if "cora-z7-07s.dtsi" in files or "handoff.json" in files or "release.json" in files:
        raise ValueError("Export raw SDT without board corrections; Nix applies them during the build")
    missing = {"system-top.dts", "ps7_init.c", "ps7_init.h", "sdtgen-version.txt"} - files.keys()
    if missing:
        raise ValueError(f"Incomplete SDT export: {sorted(missing)}")
    version = files["sdtgen-version.txt"].decode().strip()
    release_version(version)
    with zipfile.ZipFile(xsa) as archive:
        for name in ("ps7_init.c", "ps7_init.h"):
            if files[name] != archive.read(name):
                raise ValueError(f"SDT {name} does not match the XSA")
        bitstream = archive.read(info["bitstream_member"])
    if not any(name.endswith(".bit") and data == bitstream for name, data in files.items()):
        raise ValueError("SDT export is missing the XSA's bitstream")
    files["system.bit"] = bitstream
    files["hardware.xsa"] = xsa.read_bytes()
    manifest = {"format": FORMAT, "schema": 1, **info, "sdtgen_version": version,
                "files": {name: digest(data) for name, data in sorted(files.items())}}
    files["release.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    return files


def unpack(archive_path, destination):
    if not archive_path.is_file():
        raise ValueError(
            f"Missing hardware release: {archive_path}. Export with export_cora_release "
            "in Vivado, copy the archive to hardware/cora-z7-07s-hardware.tar.gz, "
            "then git add that archive before building."
        )
    files = {}
    with tarfile.open(archive_path, "r:gz") as archive:
        for member in archive.getmembers():
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts or not path.parts or path.parts[0] != PREFIX:
                raise ValueError(f"Invalid hardware release path: {member.name}")
            if member.isdir():
                continue
            if not member.isfile() or len(path.parts) < 2:
                raise ValueError(f"Invalid hardware release entry: {member.name}")
            name = PurePosixPath(*path.parts[1:]).as_posix()
            if name in files:
                raise ValueError(f"Duplicate hardware release file: {name}")
            files[name] = archive.extractfile(member).read()
    if "release.json" not in files:
        raise ValueError("Missing release.json: use the repository's hardware release exporter")
    manifest = json.loads(files.pop("release.json"))
    if manifest.get("format") != FORMAT or manifest.get("schema") != 1:
        raise ValueError("Unsupported hardware release format")
    release_version(manifest["vivado_version"])
    release_version(manifest["sdtgen_version"])
    if REQUIRED - files.keys() or set(manifest["files"]) != files.keys():
        raise ValueError("Hardware release file list is incomplete or modified")
    for name, data in files.items():
        if digest(data) != manifest["files"][name]:
            raise ValueError(f"Hardware release file hash mismatch: {name}")
    if manifest["part"] != "xc7z007sclg400-1":
        raise ValueError("Hardware release is not for a Cora Z7-07S")
    if digest(files["hardware.xsa"]) != manifest["xsa_sha256"]:
        raise ValueError("Hardware release XSA hash mismatch")
    if digest(files["system.bit"]) != manifest["bitstream_sha256"]:
        raise ValueError("Hardware release bitstream hash mismatch")
    if files["sdtgen-version.txt"].decode().strip() != manifest["sdtgen_version"]:
        raise ValueError("Hardware release SDTGen version mismatch")
    # Write only checked regular files, never using tar's link/path extraction.
    destination.mkdir(parents=True, exist_ok=True)
    for name, data in files.items():
        path = destination / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    (destination / "release.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest
