{ lib, pkgs, config, hostname, username, ... }:

{
  imports = [
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = username;
    startMenuLaunchers = true;

    docker-native.enable = true;

    docker-desktop.enable = true;
    wslConf.network.hostname = hostname;

  };


  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "22.05";
}
