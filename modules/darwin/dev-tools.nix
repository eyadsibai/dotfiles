# System-wide dev tools on the Macs; git, neovim, direnv etc. are in modules/home/dev.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nixpkgs-fmt
    statix
    alejandra
    devbox
    atuin
    curlFull
    R
  ];

  programs.gnupg.agent.enable = true;
  programs.nix-index.enable = true;
}
