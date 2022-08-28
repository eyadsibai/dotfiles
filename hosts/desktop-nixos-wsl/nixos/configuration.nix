{ lib, pkgs, config, modulesPath, ... }:

with lib;
let
  # nixos-wsl = import ./nixos-wsl;
in
{
  imports = [
    # "${modulesPath}/profiles/minimal.nix"
    ../../common/system
    
  ];

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "eyad";
    startMenuLaunchers = true;

    # Enable native Docker support
    docker-native.enable = false;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = true;
    wslConf.network.hostname = "desktop-nixos-wsl";

  };


  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "22.05";
}
