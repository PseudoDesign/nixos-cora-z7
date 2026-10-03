# nixos-cora-z7

Initial NixOS board support for the **Digilent Cora Z7-07S** (XC7Z007S,
one Cortex-A9, 512 MiB RAM). The default image cross-compiles from x86-64 Linux
to `armv7l-linux`. An AArch64 Linux builder is also exposed.

This is an initial bring-up cut. The Nix configuration is evaluated before
publication, but a complete image build and physical board boot still need to
be tested. No bootable binary release is provided yet.

## Hardware and software boundary

```mermaid
flowchart TD
    X["Vivado 2024.1 XSA"] --> S["SDTGen 2024.1 handoff"]
    S --> F["SDT-based FSBL"]
    S --> D["Lopper Linux DTB"]
    S --> P["Bitstream"]
    F --> B["BOOT.BIN"]
    P --> B
    U["U-Boot"] --> B
    D --> B
    B --> I["SD image"]
    N["NixOS kernel, initrd and closure"] --> I
    D --> I
```

The SDT is used for both the FSBL and the Linux device tree. This project does
not call the legacy `device-tree-xlnx` generator. The Linux DTB is explicitly
supplied to the upstream NixOS Zynq module, replacing its legacy-tree default.
AMD tooling is needed for the XSA-to-SDT step; the subsequent build uses Nix.

Pinned initial versions:

| Component | Version |
|---|---|
| Bundled hardware export | Vivado 2024.1, `xc7z007sclg400-1` |
| SDT generator / XSCT | 2024.1 |
| AMD firmware, kernel and U-Boot integration | `nixos-xlnx` 2024.1 set |
| NixOS | 25.11, exact inputs in `flake.lock` |

The bundled XSA is copied unchanged from
[meta-pseudo-design at f94be4054df3](https://github.com/PseudoDesign/meta-pseudo-design/blob/f94be4054df3356cba288fa8af978a8321a0a322/meta-pd-xilinx/recipes-bsp/hdf/files/cora-z7.xsa).
It contains `cora-z7-wrapper.bit` and the PS7 initialization files. Its SHA-256
is `5c85b95f291576c8e011ad972145478d2f325502dd41b88c99ad3d423405ee40`.
The exported design's HWH contains the processing-system block and no separate
PL peripheral IP. The bitstream is nevertheless included in `BOOT.BIN`.

## Prepare the SDT once

Clone the repository on a Linux workstation with Nix and AMD Vitis 2024.1:

```bash
git clone https://github.com/PseudoDesign/nixos-cora-z7.git
cd nixos-cora-z7

# Substitute your actual Vitis installation directory.
source /path/to/Xilinx/Vitis/2024.1/settings64.sh
./scripts/prepare-sdt.sh
git add hardware/sdt
```

`python3` must be available. `nix develop` supplies Python and native inspection
tools if needed; AMD tools must be installed separately. The wrapper adds the
board include last, after SDTGen finishes, so generated properties cannot
override the 07S corrections. This also avoids release-specific custom-include
option differences in SDTGen.

The script verifies the bundled XSA part and version, generates the real SDT,
includes `hardware/cora-z7-07s.dtsi`, and records source/output hashes in
`hardware/sdt/handoff.json`. Builds reject a missing or stale handoff.
The generated directory is intentionally empty in the initial repository
except for its README: AMD tools were unavailable during implementation.

**Stage the generated files before building.** A Git-backed flake excludes
untracked files, so running SDTGen without `git add hardware/sdt` is insufficient.
After generation, the SDT directory can be committed and shared with builders
that do not have AMD tools installed.

## Cross-compile

Add your public SSH key in `configuration.nix` if you want remote access.
Then build on an x86-64 Linux workstation:

```bash
# Check the smallest hardware-dependent output first.
nix build .#linux-dtb -L --out-link result-dtb

# Build and package the firmware independently.
nix build .#boot-bin -L --out-link result-boot

# Build the complete SD image; no ARM emulation is required.
nix build .#sdImage -L
```

Equivalent explicit configuration output:

```bash
nix build .#nixosConfigurations.cora-z7-07s.config.system.build.sdImage -L
```

On an AArch64 Linux builder, `nix build .#sdImage -L` selects the AArch64-to-ARMv7
cross build automatically. The explicit configuration is
`cora-z7-07s-aarch64-builder`.

Useful outputs: `.#kernel`, `.#fsbl`, `.#linux-dtb`, `.#boot-bin`, `.#sdImage`.
An official ARMv7 binary cache is not available, so allow time and disk space
for a substantial source build. Start with the committed lock file; an input
upgrade is a separate change from the initial board bring-up.

## Write the SD card and test

The uncompressed image is under `result/sd-image/*.img`. It contains:

| Partition | Contents |
|---|---|
| 1, FAT (128 MiB) | `BOOT.BIN`: SDT FSBL, bundled bitstream, U-Boot, control DTB |
| 2, ext4 | NixOS store/root, kernel/initrd/DTB and `/boot/extlinux/extlinux.conf` |

Write the image using your usual image writer, selecting the intended SD card.
Set the Cora boot jumper to microSD and attach its USB UART. Serial settings are
**115200 baud, 8N1, no flow control**. The initial local login is **root / nixos**;
change it after boot. SSH accepts public keys only, including for root.

Record this first-boot sequence:

1. FSBL completes and U-Boot reports approximately 512 MiB DRAM.
2. U-Boot reads the SD card and finds the extlinux configuration on partition 2.
3. The kernel reports one CPU, initializes SD0 and mounts the ext4 root.
4. The NixOS serial login appears; log in and run `uname -a`, `lscpu`,
   `findmnt /`, `ip -br address`, and `systemctl --failed`.
5. Check Ethernet DHCP and SSH with the public key you configured.

If U-Boot stops before Linux, useful diagnostic commands are:

```text
mmc list
mmc dev 0
part list mmc 0
ls mmc 0:1 /
ls mmc 0:2 /boot/extlinux/
printenv bootcmd boot_targets kernel_addr_r ramdisk_addr_r fdt_addr_r
sysboot mmc 0:2 any 0x03000000 /boot/extlinux/extlinux.conf
```

The DTB is also packaged at `0x00100000` for U-Boot's external control-tree
handoff. Extlinux supplies the Linux DTB. Default runtime load addresses are
kernel `0x02000000`, initrd `0x03100000`, DTB `0x01f00000`; record component sizes
and the serial log if loading fails.

## Board corrections and scope

The board DTSI carries forward the original UART0, SD0, GEM0/MDIO PHY address 1,
and ULPI USB-host wiring. It removes CPU1, its trace unit, and its trace funnel
input, and reduces the PMU resources to CPU0. Lopper's Linux conversion alone
does not remove the second core from AMD's generic Zynq description.

Boot-critical SD, ext4 and console drivers, plus MACB and the Realtek PHY driver,
are built into the kernel. The initrd uses gzip and a small shell-based stage1.
There is no desktop and no Mender integration in this cut. The old project's
generic UIO boot argument is omitted because this XSA has no PL peripheral IP.

The Cora has no MAC-address EEPROM. Its sticker contains the assigned address;
configure it during later network integration. Do not assume the first-boot
MAC is stable across reboots.

NixOS generations cover the OS/kernel/initrd/DTB. Overwriting `BOOT.BIN` changes
the FSBL, U-Boot and bitstream separately. Automatic firmware rollback and
power-failure-safe firmware updates are not implemented here. Keep the working
Yocto SD card or an image backup for recovery during bring-up.

## Licenses and references

Original repository code is MIT. The upstream modules are referenced as a
pinned flake input, and retain their MIT license. Linux, U-Boot, AMD firmware
and generated device-tree sources retain their individual upstream licenses;
the repository license does not replace the licenses of image contents.

- [nixos-xlnx](https://github.com/chuangzhu/nixos-xlnx)
- [AMD SDTGen 2024.1](https://github.com/Xilinx/system-device-tree-xlnx/tree/xlnx_rel_v2024.1)
- [Lopper Linux domain conversion](https://github.com/devicetree-org/lopper/blob/f93c309fd206525216d7a57eee010d698391efcf/lopper/assists/gen_domain_dts.py)
- [Original Yocto Cora configuration](https://github.com/PseudoDesign/meta-pseudo-design/tree/scarthgap/meta-pd-xilinx)
