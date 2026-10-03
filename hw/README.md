# Hardware development from a fresh checkout

The authoritative sources are Tcl, HDL, constraints and the pinned board
definitions in this directory. Vivado projects, generated block designs,
wrappers, IP products, logs and reports are disposable build outputs.

The initial design creates PS7 using Digilent's Cora Z7-07S B.0 preset:
512 MiB DDR, UART0, SD0, GEM0/MDIO and USB0. It disables unused PS-to-PL AXI,
fabric clocks and resets. There are no custom PL peripherals yet. It still
generates a bitstream to match the existing hardware-release/BOOT.BIN contract.
This is a new design from the board preset, not a reconstruction of the old XSA.

## Prerequisites

On the hardware workstation, install Vivado **2026.1** with Zynq-7000 device
support and its standalone `sdtgen`. Source its `settings64.sh`. Python 3 is
needed for release packaging (`nix develop` can supply it). Vitis is not needed.
The Bash launcher supports Linux; the NixOS builder only needs the exported
archive. Board definitions are vendored, so no global board installation or
board-store refresh is needed.

## Create and inspect

From the repository root:

```bash
source /path/to/Vivado/2026.1/settings64.sh
./scripts/hardware.sh create
./scripts/hardware.sh gui
```

The first command creates `build/vivado/cora-z7-07s.xpr`; the second opens it.
`gui` also creates the project if it does not exist. Inspect `system` in IP
Integrator and check PS DDR and MIO configuration before the first board boot.

You can use another directory, including one with spaces:

```bash
./scripts/hardware.sh create "$PWD/build/experiment-1"
./scripts/hardware.sh gui "$PWD/build/experiment-1"
```

`create` and `build` refuse an existing directory. They never erase GUI edits.
Choose a new directory for each clean reconstruction, or explicitly remove a
disposable directory after saving your source changes.

## Save GUI changes back to source

Keep the block design named `system`. After editing it, open that block design
and run in Vivado's Tcl console (substitute your repository path):

```tcl
validate_bd_design
save_bd_design
write_bd_tcl -force /path/to/nixos-cora-z7/hw/bd/design.tcl
```

This replaces the small initial script with Vivado's full recreation script.
Review the Git diff, including IP versions, addresses and peripheral settings.
Keep the exporter version checks. Do not also commit the generated `.bd` as a
second authoritative copy. Project-level changes such as added HDL/XDC, custom
IP paths, synthesis settings and top-module changes belong in
`hw/create-project.tcl`; `write_bd_tcl` does not capture them. Copy any sources
imported through the GUI into `hw/` and register their paths there.

For reference when translating project-level GUI changes, export
`write_project_tcl -force /path/to/nixos-cora-z7/build/project-capture.tcl`.
Review its relevant changes; it is a reference capture, not a second build path.
Avoid absolute machine-specific paths and unpinned external IP dependencies.

Before committing, recreate in a new directory and inspect the resulting BD:

```bash
./scripts/hardware.sh create "$PWD/build/recreate-check"
git diff -- hw
git add hw
git commit -m "Describe the hardware change"
```

## Build a release from tracked source

```bash
./scripts/hardware.sh build
```

This recreates the project under `build/release`, runs synthesis and
implementation through bitstream generation, checks run completion, DRC and
available setup/hold paths, then invokes `scripts/export-hardware.tcl`.
DRC and timing reports are in `build/release/reports`; inspect them, including
unconstrained paths when adding PL logic. No timing paths is valid for the
initial PS-only design; the automated checks are not a complete timing signoff.
Logs and journals are under `build/logs`.

To select a new output directory and parallel job count:

```bash
./scripts/hardware.sh build "$PWD/build/release-2" 8
```

The release archive is `build/release/cora-z7-07s-hardware.tar.gz` by default.
Build from a committed source revision, and associate that revision with the
published archive (for example, attach it to a GitHub release tagged at that
commit). The archive already records tool versions and payload hashes.

Copy it into the existing Nix workflow:

```bash
cp build/release/cora-z7-07s-hardware.tar.gz hardware/cora-z7-07s-hardware.tar.gz
git add hardware/cora-z7-07s-hardware.tar.gz
nix build .#sdImage -L
```

A strong portability check is to commit your changes, make a separate checkout
of that commit, and run `hardware.sh build` there. It must not read anything
from the original project directory. Keep Vivado 2026.1 and the board/IP pins
fixed while bringing up the board; review tool upgrades separately.

## Validation status

`python3 tests/test-hardware-workflow.py` (Python with `tkinter`) exercises
launcher paths with spaces, process error propagation, preservation of existing
GUI work, and synthesis/DRC/timing failure gates using mocked Vivado commands
inside a Tcl interpreter. These checks pass; they do not validate Vivado APIs
or the generated hardware.

Vivado is not available in the development environment where these scripts
were added. The real 2026.1 project creation, implementation, SDT export and
physical board boot need validation on the hardware workstation. This workflow
provides the source and commands for that first test; it does not claim a
verified bootable design.

References: AMD's [revision-control methodology](https://docs.amd.com/r/en-US/ug994-vivado-ip-subsystems/Revision-Control-Methodology),
[`write_bd_tcl`](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/write_bd_tcl)
and [`write_project_tcl`](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/write_project_tcl).
