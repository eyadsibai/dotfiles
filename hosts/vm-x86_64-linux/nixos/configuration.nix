{ config, pkgs, lib, modulesPath, username, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  system.stateVersion = "22.05";

  # Configure networking
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # Create user "test"
  services.getty.autologinUser = "test";
  users.users.${username}.isNormalUser = true;

  # Enable paswordless ‘sudo’ for the "test" user
  users.users.${username}.extraGroups = [ "wheel" ];
  security.sudo.wheelNeedsPassword = false;

  # Make it output to the terminal instead of separate window
  virtualisation.graphics = false;

  virtualisation.useNixStoreImage = true;
  virtualisation.writableStore = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
