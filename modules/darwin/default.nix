{ lib, pkgs, ... }:

{
  # This module is only imported on Darwin, so the imports list can be unconditional.
  imports = [
    ./sketchybar.nix
    ./borders.nix
    ./system-settings.nix
    ./fonts.nix
    ./security.nix
    ./homebrew.nix
    ./stylix.nix
    ./system-packages.nix
    # Add other darwin modules here if created
  ];

  options.darwin = {
    # Options are defined in imported files
  };
}
