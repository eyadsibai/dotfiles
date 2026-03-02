{ lib, ... }:
{
  imports = [
    ./options.nix
    ./gnome.nix
    ./hyprland.nix
    ./kde.nix
    ./bspwm.nix
    ./i3.nix
    ./awesome.nix
    ./dwm.nix
    ./sway.nix
  ];
}
