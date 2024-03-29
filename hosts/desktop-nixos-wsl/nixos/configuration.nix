{ lib
, pkgs
, config
, hostname
, username
, ...
}: {
  imports = [
  ];

  home-manager.users.${username} = {home.stateVersion = "22.05";};

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = username;
    startMenuLaunchers = true;

    docker-native.enable = true;
    docker-desktop.enable = true;
    wslConf.network.hostname = hostname;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "22.05";
}
