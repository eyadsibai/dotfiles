{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    autoUpdate = false;
    cleanup = "zap";
    brews = [ "wireguard-tools" ];
    casks = [ ];
    taps = [ "homebrew/cask-fonts" "mongodb/brew" ];
    masApps = { };
  };
}
