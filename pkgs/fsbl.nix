# SPDX-License-Identifier: MIT
# Adapted from nixos-xlnx/pkgs/embeddedsw.nix, Copyright (c) Chuang Zhu.
# See ../COPYING.nixos-xlnx for the upstream license notice.
{
  lib,
  stdenv,
  buildPackages,
  cmake,
  ninja,
  dtc,
  sdtDir,
  eswSrc,
  libmetalSrc,
  lopper,
}:
let
  # The Python BSP tools expect libmetal sources under XILINX_VITIS/data.
  # Build this source-only dependency with the workstation's package set.
  libmetal = buildPackages.stdenvNoCC.mkDerivation {
    pname = "embeddedsw-libmetal-source";
    version = "2026.1";
    src = libmetalSrc;
    dontConfigure = true;
    dontBuild = true;
    postPatch = ''
      # Older minimum versions are rejected by CMake 4.
      sed -i 's/cmake_minimum_required *(VERSION .*)/cmake_minimum_required(VERSION 3.24.2)/' CMakeLists.txt
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -a . "$out/"
      runHook postInstall
    '';
  };
  vitisDepsDir = buildPackages.linkFarm "embeddedsw-vitis-deps-2026.1" [
    {
      name = "data/libmetal";
      path = libmetal;
    }
  ];
  python = buildPackages.python3.withPackages (p: [
    lopper
    p.pyyaml
    # AMD's pyesw utilities still import distutils.dir_util.
    p.setuptools
    p.libfdt
  ]);
in
stdenv.mkDerivation {
  pname = "zynq-fsbl";
  version = "2026.1";
  src = eswSrc;

  nativeBuildInputs = [ python cmake ninja dtc ];
  # Lopper must preprocess the SDT using a compiler executable on the builder.
  depsBuildBuild = [ buildPackages.stdenv.cc ];

  env = {
    LOPPER_DTC_FLAGS = "-@";
    XILINX_VITIS = vitisDepsDir;
    NIX_CFLAGS_COMPILE = "-Wno-error=return-mismatch -Wno-error=int-conversion -Wno-error=implicit-function-declaration";
  };

  postPatch = ''
    # Keep all subprojects compatible with CMake 4, including copied BSP files.
    find \( -name '*CMakeLists.txt' -o -name '*.cmake' \) -exec \
      sed -i 's/cmake_minimum_required *(VERSION .*)/cmake_minimum_required(VERSION 3.24.2)/' {} +
    substituteInPlace cmake/toolchainfiles/cortexa9_toolchain.cmake \
      --replace-fail arm-none-eabi- ${stdenv.cc.targetPrefix}
    # 2026.1 already includes the repo.py resolve_paths correction.
  '';

  configurePhase = ''
    runHook preConfigure
    export ESW_REPO=$(readlink -f .)
    export BSP_DIR=$(mktemp -d)
    export APP_DIR=$(mktemp -d)
    pushd "$BSP_DIR"
    python "$ESW_REPO/scripts/pyesw/create_bsp.py" \
      -t zynq_fsbl -s ${sdtDir}/system-top.dts -p ps7_cortexa9_0
    popd
    pushd "$APP_DIR"
    python "$ESW_REPO/scripts/pyesw/create_app.py" \
      -t zynq_fsbl -d "$BSP_DIR"
    popd
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    pushd "$APP_DIR"
    python "$ESW_REPO/scripts/pyesw/build_app.py"
    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm555 "$APP_DIR/build/zynq_fsbl.elf" "$out/zynq_fsbl.elf"
    runHook postInstall
  '';
  dontStrip = true;

  meta = {
    description = "AMD 2026.1 Zynq-7000 First Stage Boot Loader built from SDT";
    homepage = "https://github.com/Xilinx/embeddedsw";
    license = lib.licenses.mit;
    platforms = [ "arm-none" ];
  };
}
