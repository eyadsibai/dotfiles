# Omarchy desktop (Hyprland, Quickshell bar/menus/lock, themes) through nixarchy,
# which packages the upstream Omarchy tree for NixOS. Started by greetd; with
# my.desktop.autoLogin the first session of each boot logs in by itself and locks
# straight away, so remote tools (Sunshine, gliff) have a session after a reboot.
{
  config,
  inputs,
  lib,
  pkgs,
  repoDir,
  username,
  ...
}:
let
  cfg = config.my.desktop;

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

  options.my.desktop.autoLogin = lib.mkEnableOption "logging in automatically at boot, then locking the screen";

  config = {
    programs.nixarchy = {
      enable = true;
      user = username;
      package = omarchy;
      flake = repoDir;
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

    # Hyprland from nixpkgs (on cache.nixos.org) instead of nixarchy's hyprwm input
    programs.hyprland.package = lib.mkForce pkgs.hyprland;
    programs.hyprland.portalPackage = lib.mkForce pkgs.xdg-desktop-portal-hyprland;

    services.greetd = {
      enable = true;
      settings = {
        # A text greeter that offers the Omarchy session
        default_session.command = lib.concatStringsSep " " [
          (lib.getExe pkgs.tuigreet)
          "--time"
          "--remember"
          "--asterisks"
          "--cmd ${omarchySession}"
        ];
        # Once per boot, straight into the desktop; it locks itself immediately
        initial_session = lib.mkIf cfg.autoLogin {
          command = "${omarchySession}";
          user = username;
        };
      };
    };

    home-manager.users.${username} = {
      imports = [
        ../home/omarchy.nix
        ../home/desktop-apps.nix
      ];
      programs.nixarchy.package = omarchy;

      # Lock the autologin session as soon as the shell can draw the lock screen.
      # Later logins went through the greeter and are left alone.
      xdg.configFile."omarchy/hooks/post-boot.d/10-lock-after-autologin" = lib.mkIf cfg.autoLogin {
        text = ''
          marker="/tmp/omarchy-autolock-$USER-$(cat /proc/sys/kernel/random/boot_id)"
          [[ -e $marker ]] && exit 0
          touch "$marker"
          for _ in $(seq 30); do
            omarchy-system-lock
            sleep 1
            omarchy-hyprland-session-locked && exit 0
          done
          echo "Could not lock the session after autologin" >&2
          exit 1
        '';
      };
    };
  };
}
