# SPDX-License-Identifier: MIT
# Adapted from nixos-xlnx (Copyright (c) 2024 Chuang Zhu).
# See ../COPYING.nixos-xlnx.
{ upstream }:
{ config, lib, pkgs, ... }:
let
  overlay = import ../pkgs/overlay.nix { inherit upstream; };
  baremetal = import pkgs.path {
    localSystem.system = pkgs.stdenv.buildPlatform.system;
    crossSystem = {
      config = "arm-none-eabihf";
      libc = "newlib";
      gcc = {
        cpu = "cortex-a9";
        fpu = "vfpv3";
        float-abi = "hard";
      };
    };
    overlays = [ overlay ];
  };
in {
  # Reuse upstream BOOT.BIN machinery with our release overlay and bare-metal
  # FSBL. Upstream's NixOS module/version enum stops at 2025.1.
  imports = [ "${upstream}/boot-bin.nix" ];
  options.hardware.zynq.xlnxVersion = lib.mkOption {
    type = lib.types.enum [ "2026.1" ];
    default = "2026.1";
    description = "AMD release used by the XSA, SDT generator and firmware.";
  };
  config = {
    nixpkgs.overlays = [ overlay ];
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zynq;
    hardware.zynq.fsbl = lib.mkDefault (
      (baremetal.zynq-fsbl.override { sdtDir = config.hardware.zynq.sdtDir; })
      + "/zynq_fsbl.elf"
    );
    hardware.deviceTree = {
      enable = true;
      name = "system.dtb";
      dtbSource = pkgs.buildPackages.runCommand "dtb-source" { } ''
        mkdir -p "$out"
        cp ${config.hardware.zynq.dtb} "$out/system.dtb"
      '';
    };
  };
}
