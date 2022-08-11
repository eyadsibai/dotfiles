{
  pkgs,
  lib,
  ...
}: {
  imports = [./shell.nix ./terminal_apps.nix ./terminal.nix];
}
