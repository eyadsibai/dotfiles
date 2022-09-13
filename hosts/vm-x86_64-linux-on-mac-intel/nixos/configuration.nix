{ config, pkgs, lib, modulesPath, username, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  system.stateVersion = "22.05";

  # Configure networking
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # Create user account
  services.getty.autologinUser = "${username}";
  users.users.${username} = { isNormalUser = true; extraGroups = [ "wheel" ]; };
  security.sudo.wheelNeedsPassword = false;

  # Make it output to the terminal instead of separate window
  virtualisation = { graphics = false; useNixStoreImage = true; writableStore = true; };

  nixpkgs.hostPlatform = "x86_64-linux";
}
