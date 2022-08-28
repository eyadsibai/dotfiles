{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    autoUpdate = false;
    cleanup = "zap";
    brews = [ "wireguard-tools" ];
    casks = [
      "hammerspoon" # desktop automation app
      "gitup" # git interface focused on visual interaction
      "macs-fan-control" # macs fan control app
      "jetbrains-toolbox"
      "keycastr"
      "karabiner-elements"

    ];
    taps = [
      "homebrew/bundle"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/core"
      "homebrew/services"
    ];
    masApps = { };
  };
}
