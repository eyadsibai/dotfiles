{ lib, ... }:
{
  options.desktop = {
    environment = lib.mkOption {
      type = lib.types.enum [ "gnome" "hyprland" "kde" "bspwm" "i3" "awesome" "dwm" "sway" "none" ];
      default = "gnome";
      description = "Which desktop environment or window manager to enable.";
    };
  };
}
