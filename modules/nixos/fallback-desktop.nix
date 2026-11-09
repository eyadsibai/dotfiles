# A second boot entry, "gnome", beside the Omarchy one: the same system with GNOME
# and GDM instead of greetd and the Omarchy session. For when a nixarchy, Omarchy
# or Hyprland update breaks the desktop: pick it in the boot menu, fix, switch back.
# (Mitchell Hashimoto keeps his alternative desktops as specialisations the same way.)
{ lib, ... }:
{
  specialisation.gnome.configuration = {
    system.nixos.tags = [ "gnome" ];
    services.greetd.enable = lib.mkForce false;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  };
}
