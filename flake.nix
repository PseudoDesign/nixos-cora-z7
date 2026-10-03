{
  description = "NixOS SD images for the Digilent Cora Z7-07S, using AMD System Device Tree";

  inputs = {
    nixos-xlnx.url = "github:chuangzhu/nixos-xlnx/8bb30b706ad4f89ecc92f6ce6f5b19de86cc19d1";
    nixpkgs.follows = "nixos-xlnx/nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-xlnx }:
    let
      lib = nixpkgs.lib;
      builders = [ "x86_64-linux" "aarch64-linux" ];
      forBuilders = lib.genAttrs builders;
      mkSystem = buildPlatform: lib.nixosSystem {
        modules = [
          nixos-xlnx.nixosModules.sd-image
          self.nixosModules.cora-z7-07s
          ./configuration.nix
          { nixpkgs.buildPlatform = buildPlatform; }
        ];
      };
      crossSystems = forBuilders mkSystem;
      toolsFor = system: import nixpkgs {
        inherit system;
        overlays = [ nixos-xlnx.overlays.xlnx2024_1 ];
      };
    in {
      nixosModules.cora-z7-07s = import ./modules/cora-z7-07s.nix;
      # Default is a genuine x86_64 -> ARMv7 cross build.
      nixosConfigurations.cora-z7-07s = crossSystems.x86_64-linux;
      nixosConfigurations.cora-z7-07s-aarch64-builder = crossSystems.aarch64-linux;

      packages = forBuilders (system:
        let
          cfg = crossSystems.${system}.config;
          native = toolsFor system;
        in {
          default = cfg.system.build.sdImage;
          sdImage = cfg.system.build.sdImage;
          boot-bin = cfg.hardware.zynq.boot-bin;
          fsbl = native.runCommand "zynq_fsbl.elf" { } ''
            cp ${cfg.hardware.zynq.fsbl} "$out"
          '';
          linux-dtb = cfg.hardware.zynq.dtb;
          kernel = cfg.boot.kernelPackages.kernel;
        });

      devShells = forBuilders (system:
        let pkgs = toolsFor system;
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.python3 pkgs.dtc pkgs.git pkgs.nixfmt-rfc-style
              pkgs.xilinx-bootgen_2024_1
            ];
            shellHook = ''
              echo "Prepare the hardware handoff with ./scripts/prepare-sdt.sh (Vitis/XSCT 2024.1 required)."
              echo "Build the image with: nix build .#sdImage -L"
            '';
          };
        });
      formatter = forBuilders (system: (toolsFor system).nixfmt-rfc-style);
    };
}
