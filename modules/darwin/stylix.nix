{ lib, config, pkgs, ... }:
# Remove inputs from function arguments to avoid circular dependency

let
  cfg = config.darwin.stylix;
in
{
  options.darwin.stylix = {
    enable = lib.mkEnableOption "Stylix theme management for Darwin";
    base16Scheme = lib.mkOption {
      # type = lib.types.enum [ "default" "gruvbox" "catppuccin" ];
      default = "default";
      description = "Base16 color scheme to use.";
    };
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

  # Remove imports section - stylix should be imported directly in the host file
  # instead of here to avoid circular dependencies

  # Define config unconditionally
  config = {
    # Use lib.mkIf for non-list attributes
    stylix = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      enable = true; # Enable stylix itself
      base16Scheme = cfg.base16Scheme or "default"; # Default to "default" if not set
      # image = cfg.image;
      polarity = cfg.polarity;
      # Add other stylix settings here if needed
    };
  };
}
