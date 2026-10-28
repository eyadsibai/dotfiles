# home-server: planned NixOS replacement for the Unraid server. Skeleton only:
# replace the placeholder hardware below with the real hardware-configuration.nix
# (nixos-generate-config) before installing.
{ username, ... }:
{
  imports = [ ../../modules/nixos ];

  networking.hostName = "home-server";

  # Placeholder hardware so the configuration evaluates
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };
  nixpkgs.hostPlatform = "x86_64-linux";

  home-manager.users.${username} = {
    imports = [ ../../modules/home ];
    home.stateVersion = "26.05";
  };

  system.stateVersion = "26.05";
}
