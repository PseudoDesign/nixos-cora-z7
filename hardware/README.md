The Nix build consumes one Vivado hardware release:
`cora-z7-07s-hardware.tar.gz`. Export it from an open, implemented Vivado
2026.1 project using `scripts/export-hardware.tcl`, then add the archive to Git.

The archive contains raw SDT sources and includes, PS7 initialization files,
the bitstream, the input XSA, and a version/hash manifest. Nix applies the
current `cora-z7-07s.dtsi` during the build and builds the FSBL from source.
No Vivado or Vitis installation is needed on the Nix builder.

`cora-z7-07s.xsa` is the unchanged Vivado 2024.1 reference export from the
original Yocto project. It is retained for reference and is not a build input.
No fabricated 2026.1 hardware release is included.
