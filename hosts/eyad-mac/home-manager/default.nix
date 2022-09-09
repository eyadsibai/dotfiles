{ config, pkgs, lib, ... }:

{
  home.stateVersion = "22.05";

  imports = [
    ../../common/optional/home-manager/htop
    ../../common/optional/home-manager/direnv
    ../../common/optional/home-manager/terminal
    ../../common/optional/home-manager/micro

  ];

  # programs.firefox.package = pkgs.firefox-bin;

  # https://github.com/malob/nixpkgs/blob/master/home/default.nix


  home.packages = with pkgs; [
    # Some basics
    coreutils
    curl
    wget
    jq
    cachix
    iterm2
    # micro
    # vscode
    terminal-notifier
  ] ++ lib.optionals
    stdenv.isDarwin
    [
      # not needed but nice to demo for future refactoring
      m-cli
      cocoapods
    ];
}
