# Omarchy on Arch, the root-owned side, through system-manager (github:numtide/system-manager):
# Home Manager runs as me and can't write these. `just switch` builds this first and
# only asks for sudo when the result differs from what's active (scripts/arch-system).
#
# Arch keeps everything else: users, packages, services, the nix-daemon itself.
{ lib, pkgs, ... }:
let
  caches = import ../common/caches.nix;
  nixConf = ''
    # Written by system-manager from modules/arch-system (dotfiles); edit there
    build-users-group = nixbld
    max-jobs = auto
    experimental-features = nix-command flakes
    substituters = ${lib.concatStringsSep " " caches.substituters}
    trusted-public-keys = ${lib.concatStringsSep " " caches.trusted-public-keys}
  '';
in
{
  nixpkgs.hostPlatform = "x86_64-linux";

  # Activation otherwise refuses anything but NixOS, Ubuntu and Debian
  system-manager.allowAnyDistro = true;

  # system-manager turns userborn on to manage /etc/passwd; Arch owns the users
  services.userborn.enable = false;

  # NixOS-style setuid wrappers in /run/wrappers: Arch's own sudo and friends are
  # setuid already. Their unit also orders itself after userborn.service, and that
  # dangling reference makes every activation try (and fail) to restart userborn.
  security.enableWrappers = false;

  environment.etc = {
    # pacman's nix reads this; the daemon is restarted when it changes (below)
    "nix/nix.conf" = {
      replaceExisting = true; # the first switch moves Arch's own aside
      text = nixConf;
    };

    # Keeps Spotify patchable by spicetify (Spotify themed from Omarchy): installing
    # or upgrading the package resets /opt/spotify to root-only, and spicetify, run
    # as me, has to write there
    "pacman.d/hooks/spicetify.hook" = {
      replaceExisting = true;
      source = ../../arch/spicetify.hook;
    };
  };

  systemd.services = {
    # The daemon reads nix.conf only when it starts
    nix-daemon-reload-config = {
      description = "Restart nix-daemon for a changed /etc/nix/nix.conf";
      wantedBy = [ "system-manager.target" ];
      restartTriggers = [ nixConf ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.systemd}/bin/systemctl try-restart --no-block nix-daemon.service";
      };
    };

    # The hook's job, for a Spotify installed before it
    spotify-writable = {
      description = "Let spicetify write to /opt/spotify";
      wantedBy = [ "system-manager.target" ];
      unitConfig.ConditionPathExists = "/opt/spotify/Apps";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.coreutils}/bin/chmod a+wr /opt/spotify"
          "${pkgs.coreutils}/bin/chmod -R a+wr /opt/spotify/Apps"
        ];
      };
    };
  };
}
