Generate the real SDT with `./scripts/prepare-sdt.sh` from the repository root.

This directory intentionally contains no fabricated device tree. The image and
firmware builds require a matching `system-top.dts`, PS7 init files, bitstream,
and `handoff.json`, generated from the bundled Vivado 2024.1 XSA.

The preparation script checks the XSA version and part, adds the Cora board DTSI,
and records hashes. Stage generated files with `git add hardware/sdt` before
running a flake build from a Git checkout.
