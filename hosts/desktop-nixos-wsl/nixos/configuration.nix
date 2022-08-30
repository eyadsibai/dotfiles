{ lib, pkgs, config, modulesPath, hostname, user, ... }:

with lib;
let
  # nixos-wsl = import ./nixos-wsl;
in
{
  imports = [
    ../../common/system
    ../../common/system/nixos
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = ${user};
    startMenuLaunchers = true;

    # Enable native Docker support
    docker-native.enable = false;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = true;
    wslConf.network.hostname = ${hostname};

  };


  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "22.05";
}
