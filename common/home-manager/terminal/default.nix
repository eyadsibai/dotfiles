{ pkgs, lib, ... }: {
  imports = [
    ./shell.nix
    ./terminal_apps.nix
    ./starship.nix
  ];
}
