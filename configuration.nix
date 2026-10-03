{ lib, ... }:
{
  networking.hostName = "cora-z7-07s";
  networking.useDHCP = lib.mkDefault true;

  # Initial bring-up: local serial login only until a public SSH key is added.
  users.users.root.initialPassword = "nixos";
  users.users.root.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAA... your-key"
  ];
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Keep the ARMv7 closure small; build updates on the workstation.
  environment.defaultPackages = lib.mkForce [ ];
  documentation.enable = false;
  documentation.nixos.enable = false;
  documentation.man.enable = false;
  documentation.info.enable = false;
  documentation.doc.enable = false;
  services.udisks2.enable = false;

  system.stateVersion = "25.11";
}
