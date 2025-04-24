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
    (lib.mkIf (cfg.environment == "gnome") ./gnome.nix)
    (lib.mkIf (cfg.environment == "hyprland") ./hyprland.nix)
    (lib.mkIf (cfg.environment == "kde") ./kde.nix)
    (lib.mkIf (cfg.environment == "bspwm") ./bspwm.nix)
    (lib.mkIf (cfg.environment == "i3") ./i3.nix)
    (lib.mkIf (cfg.environment == "awesome") ./awesome.nix)
    (lib.mkIf (cfg.environment == "dwm") ./dwm.nix)
    (lib.mkIf (cfg.environment == "sway") ./sway.nix)
  ];
}
