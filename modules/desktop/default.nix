{ lib, config, ... }:

let
  cfg = config.desktop;
in
{
  options.desktop = {
    environment = lib.mkOption {
      type = lib.types.enum [ "gnome" "hyprland" "kde" "bspwm" "i3" "awesome" "dwm" "sway" "none" ];
      default = "gnome"; # Set default to gnome as requested
      description = "Which desktop environment or window manager to enable.";
    };
  };

  imports = [
    # Explicitly import the module content within mkIf
    (lib.mkIf (cfg.environment == "gnome") (import ./gnome.nix))
    (lib.mkIf (cfg.environment == "hyprland") (import ./hyprland.nix))
    (lib.mkIf (cfg.environment == "kde") (import ./kde.nix))
    (lib.mkIf (cfg.environment == "bspwm") (import ./bspwm.nix))
    (lib.mkIf (cfg.environment == "i3") (import ./i3.nix))
    (lib.mkIf (cfg.environment == "awesome") (import ./awesome.nix))
    (lib.mkIf (cfg.environment == "dwm") (import ./dwm.nix))
    (lib.mkIf (cfg.environment == "sway") (import ./sway.nix))
    # No import needed for "none"
  ];
}
