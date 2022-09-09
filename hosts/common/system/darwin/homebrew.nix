{ lib
, pkgs
, ...
}: {
  homebrew = {
    enable = lib.mkForce true;
    onActivation.autoUpdate = lib.mkForce false;
    onActivation.cleanup = lib.mkForce "zap";
    onActivation.upgrade = true;

    taps = lib.mkForce [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/core"
      "homebrew/services"
    ];
  };
}
