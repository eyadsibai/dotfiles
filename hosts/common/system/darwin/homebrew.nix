{ lib, pkgs, ... }:
{
  homebrew = {
    enable = lib.mkForce true;
    autoUpdate = lib.mkForce false;
    cleanup = lib.mkForce "zap";

    taps = lib.mkForce [
      "homebrew/bundle"
      "homebrew/cask-fonts"

      "homebrew/core"
      "homebrew/services"
    ];
  };
}
