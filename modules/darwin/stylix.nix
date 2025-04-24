{ lib, config, pkgs, inputs, ... }:

let
  cfg = config.darwin.stylix;
in
{
  options.darwin.stylix = {
    enable = lib.mkEnableOption "Stylix theme management for Darwin";
    image = lib.mkOption {
      type = lib.types.path;
      description = "Path to the wallpaper image for Stylix.";
      # No default, must be set by host config
    };
    polarity = lib.mkOption {
      type = lib.types.enum [ "dark" "light" ];
      default = "dark";
      description = "Whether to use a dark or light theme.";
    };
  };

  imports = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) [
    inputs.stylix.darwinModules.stylix # Import the actual stylix darwin module
  ];

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    stylix = {
      enable = true; # Enable stylix itself
      image = cfg.image;
      polarity = cfg.polarity;
      # Add other stylix settings here if needed
    };
  };
}
