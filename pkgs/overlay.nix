# SPDX-License-Identifier: MIT
# Adapted from nixos-xlnx (Copyright (c) 2024 Chuang Zhu).
# See ../COPYING.nixos-xlnx.
{ upstream }:
final: prev:
let
  sources = prev.callPackage ./sources.nix { };
in {
  python-lopper = (prev.python3Packages.callPackage "${upstream}/pkgs/lopper.nix" { }).overrideAttrs {
    version = "1.3.2-xilinx-2026.1";
    src = sources.lopper;
  };
  zynq-fsbl = prev.callPackage ./fsbl.nix {
    eswSrc = sources.embeddedsw;
    libmetalSrc = sources.libmetal;
    lopper = final.buildPackages.python-lopper;
    # sdtDir is supplied by the board module.
    sdtDir = null;
  };
  xilinx-bootgen_2026_1 = prev.xilinx-bootgen.overrideAttrs {
    version = "xilinx_v2026.1";
    src = sources.bootgen;
    installPhase = ''
      runHook preInstall
      install -Dm755 build/bin/bootgen "$out/bin/bootgen"
      runHook postInstall
    '';
  };
  ubootZynq = prev.buildUBoot {
    version = "2026.01-xilinx-v2026.1";
    src = sources.uboot;
    defconfig = "xilinx_zynq_virt_defconfig";
    filesToInstall = [ "u-boot.elf" ];
    extraMeta.platforms = [ "armv7l-linux" ];
  };
  linux_zynq = prev.buildLinux {
    version = "6.18.10-xilinx-v2026.1";
    modDirVersion = "6.18.10-xilinx";
    src = sources.linux;
    defconfig = "xilinx_zynq_defconfig";
    kernelPatches = [ ];
    structuredExtraConfig = with prev.lib.kernel; {
      DEBUG_INFO_BTF = prev.lib.mkForce no;
      CRYPTO_DEV_XILINX_ECDSA = no;
      MMC_BLOCK = yes;
      RPMB = no;
      DRM_XLNX_BRIDGE = yes;
      USB_XHCI_PLATFORM = no;
      USB_XHCI_HCD = no;
      USB_DWC3 = no;
      USB_CDNS_SUPPORT = no;
      # Exclude unused display/HDCP drivers with 32-bit build problems.
      VIDEO_XILINX_HDMI21RXSS = no;
      VIDEO_XILINX_DPRXSS = no;
      VIDEO_XILINX_HDCP1X_RX = no;
      VIDEO_XILINX_HDCP2X_RX = no;
      DRM_XLNX_HDCP = no;
      DRM_XLNX_DPTX = no;
      DRM_XLNX_HDMITX = no;
      DRM_XLNX_MIXER = no;
    };
    # Vendor Kconfig differs from mainline; board boot requirements are checked
    # separately by system.requiredKernelConfig.
    ignoreConfigErrors = true;
    extraMeta.platforms = [ "armv7l-linux" ];
  };
  linuxPackages_zynq = prev.linuxKernel.packagesFor final.linux_zynq;
}
