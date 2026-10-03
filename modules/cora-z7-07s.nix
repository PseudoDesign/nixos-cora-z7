{ config, lib, pkgs, ... }:
let
  native = pkgs.buildPackages;
  sdt = native.callPackage ../pkgs/hardware-release.nix {
    releasePackage = config.hardware.coraZ7.releasePackage;
    boardDtsi = ../hardware/cora-z7-07s.dtsi;
  };
  linuxDtb = native.callPackage ../pkgs/linux-dtb.nix {
    sdtDir = sdt;
    lopper = native.python-lopper;
  };
in {
  options.hardware.coraZ7.releasePackage = lib.mkOption {
    type = lib.types.path;
    # A string below the tracked hardware directory keeps the flake evaluable
    # before the first real hardware release has been exported.
    default = "${../hardware}/cora-z7-07s-hardware.tar.gz";
    example = lib.literalExpression "./my-hardware-release.tar.gz";
    description = "Raw Vivado 2026.1 SDT hardware release, produced by export_cora_release.";
  };

  config = {
    nixpkgs.hostPlatform = "armv7l-linux";

    hardware.zynq = {
      platform = "zynq";
      xlnxVersion = "2026.1";
      sdtDir = sdt;
      dtb = linuxDtb;
      # dtDir is deliberately unused: dtb above is generated from the SDT.
      bitstream = "${sdt}/system.bit";
    };

    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      generic-extlinux-compatible.configurationLimit = 3;
    };
    boot.kernelParams = [ "console=ttyPS0,115200n8" "earlycon" ];
    boot.kernelModules = lib.mkForce [ ];
    boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];
    boot.initrd = {
      systemd.enable = false;
      includeDefaultModules = false;
      availableKernelModules = lib.mkForce [ ];
      kernelModules = lib.mkForce [ ];
      compressor = "gzip";
    };
    boot.kernelPatches = [
      {
        name = "cora-z7-07s-boot-drivers";
        patch = null;
        structuredExtraConfig = with lib.kernel; {
          BLK_DEV_INITRD = yes;
          RD_GZIP = yes;
          DEVTMPFS = yes;
          MMC = yes;
          MMC_BLOCK = yes;
          MMC_SDHCI = yes;
          MMC_SDHCI_PLTFM = yes;
          MMC_SDHCI_OF_ARASAN = yes;
          EXT4_FS = yes;
          FAT_FS = yes;
          VFAT_FS = yes;
          SERIAL_XILINX_PS_UART = yes;
          SERIAL_XILINX_PS_UART_CONSOLE = yes;
          MACB = yes;
          REALTEK_PHY = yes;
          # Ensure USB host support from the board DTSI is usable.
          USB = yes;
          USB_EHCI_HCD = yes;
          USB_CHIPIDEA = yes;
          USB_CHIPIDEA_HOST = yes;
          USB_CHIPIDEA_GENERIC = yes;
          USB_ULPI = yes;
          USB_ULPI_VIEWPORT = yes;
        };
      }
    ];
    system.requiredKernelConfig = with config.lib.kernelConfig; [
      (isYes "BLK_DEV_INITRD")
      (isYes "RD_GZIP")
      (isYes "DEVTMPFS")
      (isYes "MMC")
      (isYes "MMC_BLOCK")
      (isYes "MMC_SDHCI")
      (isYes "MMC_SDHCI_PLTFM")
      (isYes "MMC_SDHCI_OF_ARASAN")
      (isYes "EXT4_FS")
      (isYes "VFAT_FS")
      (isYes "SERIAL_XILINX_PS_UART")
      (isYes "SERIAL_XILINX_PS_UART_CONSOLE")
      (isYes "MACB")
      (isYes "REALTEK_PHY")
    ];

    sdImage = {
      firmwareSize = lib.mkForce 128;
      compressImage = false;
    };
  };
}
