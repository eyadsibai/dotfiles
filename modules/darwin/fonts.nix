{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.fonts;
in
{
  options.darwin.fonts = {
    enable = lib.mkEnableOption "Install common fonts for Darwin";
  };

  # Define config unconditionally
  config = {
    # Use lib.optionals for list assignments
    fonts.packages = lib.optionals (cfg.enable && pkgs.stdenv.isDarwin) (with pkgs; [
      # From Darwin system.nix
      material-design-icons
      font-awesome
      nerd-fonts.fira-code
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      # From Darwin apps.nix
      sketchybar-app-font
    ]);
  };
}
