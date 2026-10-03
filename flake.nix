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
          ./modules/sd-image.nix
          self.nixosModules.xlnx-2026-1
          self.nixosModules.cora-z7-07s
          ./configuration.nix
          { nixpkgs.buildPlatform = buildPlatform; }
        ];
      };
      crossSystems = forBuilders mkSystem;
      toolsFor = system: import nixpkgs {
        inherit system;
        overlays = [ (import ./pkgs/overlay.nix { upstream = nixos-xlnx; }) ];
      };
    in {
      nixosModules.cora-z7-07s = import ./modules/cora-z7-07s.nix;
      nixosModules.xlnx-2026-1 = import ./modules/xlnx-2026-1.nix { upstream = nixos-xlnx; };
      overlays.default = import ./pkgs/overlay.nix { upstream = nixos-xlnx; };
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
          sdt = cfg.hardware.zynq.sdtDir;
          kernel = cfg.boot.kernelPackages.kernel;
          security-capabilities = native.writeText "zynq-security-capabilities.json"
            (builtins.readFile ./security/capabilities.json);
        });

      devShells = forBuilders (system:
        let pkgs = toolsFor system;
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.python3 pkgs.dtc pkgs.git pkgs.nixfmt-rfc-style
              pkgs.xilinx-bootgen_2026_1
            ];
            shellHook = ''
              echo "In Vivado: source scripts/export-hardware.tcl; export_cora_release /path/to/release.tar.gz"
              echo "Copy the release to hardware/cora-z7-07s-hardware.tar.gz and git add that archive."
              echo "Build the image with: nix build .#sdImage -L"
            '';
          };
        });
      formatter = forBuilders (system: (toolsFor system).nixfmt-rfc-style);
    };
}
