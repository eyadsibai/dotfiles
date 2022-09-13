{ config, pkgs, lib, modulesPath, username, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  system.stateVersion = "22.05";

  # Configure networking
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # Create user
  services.getty.autologinUser = "${username}";
  users.users.${username} = { isNormalUser = true; extraGroups = [ "wheel" ]; };

  # Enable paswordless ‘sudo’ for the "username" user
  security.sudo.wheelNeedsPassword = false;

  # Make it output to the terminal instead of separate window
  virtualisation = { graphics = false; useNixStoreImage = true; writableStore = true; };


  nixpkgs.hostPlatform = "aarch64-linux";
}
