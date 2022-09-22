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


  # DNS fails for QEMU user networking (SLiRP) on macOS.  See:
  #
  # https://github.com/utmapp/UTM/issues/2353
  #
  # This works around that by using a public DNS server other than the
  # DNS server that QEMU provides (normally 10.0.2.3)
  networking.nameservers = [ "8.8.8.8" ];

}
