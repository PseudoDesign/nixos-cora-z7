# SPDX-License-Identifier: MIT
# Adapted from nixos-xlnx/sd-image.nix (Copyright (c) 2024 Chuang Zhu).
# See ../COPYING.nixos-xlnx.
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];
  hardware.enableAllHardware = lib.mkForce false;
  sdImage = {
    firmwareSize = 128;
    populateFirmwareCommands = ''
      cp ${config.hardware.zynq.boot-bin} firmware/BOOT.BIN
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} \
        -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "xlnx-firmware-update";
      text = ''
        systemctl start boot-firmware.mount
        cp ${config.hardware.zynq.boot-bin} /boot/firmware/BOOT.BIN
        sync /boot/firmware/BOOT.BIN
      '';
    })
  ];
  # The base profile references EFI tools which fail on ARMv7; this board
  # boots with U-Boot/extlinux and does not use EFI.
  nixpkgs.overlays = [ (final: prev: {
    efivar = prev.emptyDirectory;
    efibootmgr = prev.emptyDirectory;
  }) ];
}
