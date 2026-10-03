Generate the real SDT with `./scripts/prepare-sdt.sh /path/to/export.xsa` from
the repository root, after sourcing Vivado 2026.1's `settings64.sh`.

This directory intentionally contains no fabricated device tree. The image and
firmware builds require a matching `system-top.dts`, PS7 init files, bitstream,
and `handoff.json`, generated from a new Vivado 2026.1 XSA exported with the
bitstream included. The script copies that XSA here as `hardware.xsa` and
normalizes its bitstream filename to `system.bit`. Vitis is not required.

The preparation script checks the XSA version and part, adds the Cora board DTSI,
and records hashes. Stage generated files with `git add hardware/sdt` before
running a flake build from a Git checkout.
