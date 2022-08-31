{ lib, pkgs, config, hostname, username, ... }:

{
  imports = [
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = username;
    startMenuLaunchers = true;

    # Enable native Docker support
    docker-native.enable = true;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = true;
    wslConf.network.hostname = hostname;

  };


  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "22.05";
}
