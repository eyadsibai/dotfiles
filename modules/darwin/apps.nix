# macOS-only packages from nixpkgs; CLI tools shared with Linux are in modules/home/cli.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # communication
    discord
    slack
    teams
    signal-desktop
    zoom-us

    # media
    iina
    spotify
    spotify-player
    losslesscut-bin
    ffmpeg-full
    feh
    diff-pdf
    imagemagick
    ghostscript

    # productivity
    nb
    cointop

    # utilities
    m-cli
    appcleaner
    localsend
    wireshark
    insomnia
    colima
    wget
    httpie
    duf
    dust
    tldr
    ttyd
    lazysql

    # jujutsu
    jujutsu
    gg-jj
    jjui
    lazyjj

    # languages & tooling
    uv
    nodejs
    ast-grep
    luarocks
    lua5_1
    fd
    go
    php
    texliveBasic
    mermaid-cli
  ];
}
