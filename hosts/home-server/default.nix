# home-server: planned NixOS replacement for the Unraid server. Not installed yet; the
# hardware below is generic until `nixos-generate-config --show-hardware-config` on the
# machine says otherwise. Installing: docs/home-server.md.
#
# Built to run unattended (ideas from github.com/Misterio77/Foundry):
#   - encrypted disk unlocked by the TPM; Secure Boot once its keys exist (disk.nix,
#     modules/nixos/secure-boot.nix)
#   - a root that starts empty on every boot, with state on its own subvolumes
#   - upgrades itself nightly from GitHub (or from the self-hosted CI's builds)
#   - sudo approved through the SSH agent (1Password), so it holds no password
{
  inputs,
  lib,
  username,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disk.nix
    ../../modules/nixos
  ];

  networking.hostName = "home-server";
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  hardware.enableRedistributableFirmware = true;
  security.tpm2.enable = true;

  # The few single files outside the subvolumes that must outlive the root wipe
  environment.persistence."/persist" = {
    hideMounts = true;
    files = [ "/etc/machine-id" ];
  };
  # SSH host keys on /persist: they're the machine's identity, and sops-nix decrypts
  # with them (modules/nixos/secrets.nix) before anything else is mounted
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
  sops.age.sshKeyPaths = lib.mkForce [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  # Users come from this config alone (the root is rebuilt every boot anyway). No
  # passwords: SSH keys to log in, and sudo approved by the forwarded agent (`ssh -A`,
  # i.e. 1Password on the machine I'm at), checked against the root-owned key list
  users.mutableUsers = false;
  security.pam.rssh = {
    enable = true;
    settings.auth_key_file = "/etc/ssh/authorized_keys.d/$ruser";
  };
  security.pam.services.sudo.rssh = true;

  my.autoUpgrade.enable = true;

  home-manager.users.${username}.home.stateVersion = "26.05";

  system.stateVersion = "26.05";
}
