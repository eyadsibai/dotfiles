{ config, pkgs, ... }:
{
  # Import shared configuration
  # imports = [
  #   ../system.nix
  # ];

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable GNOME Desktop Environment
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # XRDP configuration for GNOME
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";

  # Enable GNOME Remote Desktop
  services.gnome.gnome-remote-desktop.enable = true;
}
