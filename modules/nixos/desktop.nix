# Omarchy desktop (Hyprland, Quickshell bar/menus/lock, themes) through nixarchy,
# which packages the upstream Omarchy tree for NixOS. Logs in automatically and
# locks straight away (see the post-boot hook in modules/home/omarchy.nix), so
# Sunshine and gliff have a session to attach to after a reboot.
{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
let
  # Omarchy's tree, built against nixpkgs' Hyprland rather than the hyprwm flake
  # (which would otherwise be compiled locally, as its cache is not trusted here)
  omarchy = (pkgs.extend inputs.nixarchy.overlays.default).omarchy.override {
    inherit (pkgs) hyprland;
  };

  # nixarchy's session launcher, read from its wayland-sessions entry at login
  # so greetd always starts the current generation's build
  omarchySession = pkgs.writeShellScript "omarchy-session" ''
    exec $(${lib.getExe pkgs.gnused} -n 's/^Exec=//p' /run/current-system/sw/share/wayland-sessions/omarchy.desktop)
  '';
in
{
  imports = [ inputs.nixarchy.nixosModules.nixarchy ];

  programs.nixarchy = {
    enable = true;
    user = username;
    package = omarchy;
    flake = "/home/${username}/dev/nixconfig-workstation";
    displayManager = false; # greetd below instead of SDDM
    bootSplash = "off";
    # Only cache.nixos.org and the caches in nix.nix are trusted; nixarchy's own
    # pieces are small and build locally
    binaryCaches = false;
    # Leave Claude Code's config, editors and command-not-found as Home Manager has them
    mcp = false;
    nixSkills = false;
    languageServer = false;
    commandNotFound = false;
  };

  home-manager.users.${username}.programs.nixarchy.package = omarchy;

  # Hyprland from nixpkgs (on cache.nixos.org) instead of nixarchy's hyprwm input
  programs.hyprland.package = lib.mkForce pkgs.hyprland;
  programs.hyprland.portalPackage = lib.mkForce pkgs.xdg-desktop-portal-hyprland;

  services.greetd = {
    enable = true;
    settings = {
      # Boot straight into the desktop once; it locks itself immediately
      initial_session = {
        command = "${omarchySession}";
        user = username;
      };
      # After logging out: a text greeter that offers the same session
      default_session.command = lib.concatStringsSep " " [
        (lib.getExe pkgs.tuigreet)
        "--time"
        "--remember"
        "--asterisks"
        "--cmd ${omarchySession}"
      ];
    };
  };
}
