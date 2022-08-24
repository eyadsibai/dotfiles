{ config, pkgs, lib, ... }:

{
  home.stateVersion = "22.05";

  imports = [
    ../../common/home-manager
    ../../common/home-manager/darwin
    ../../../common/home-manager/htop
    ../../../common/home-manager/git
    ../../../common/home-manager/direnv
    ../../../common/home-manager/terminal/shell.nix
    ../../../common/home-manager/kitty
    ../../../common/home-manager/micro
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
    comma
    # micro
    vscode
    terminal-notifier
    any-nix-shell
    nixpkgs-fmt
  ] ++ lib.optionals
    stdenv.isDarwin
    [
      # not needed but nice to demo for future refactoring
      m-cli
      cocoapods
    ];
}
