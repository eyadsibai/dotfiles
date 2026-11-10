# Off-site backups with restic, nightly: every service's state (/var/lib), /persist,
# /home and the photos. Media is left out: it can be fetched again, and SnapRAID
# covers a failed disk. PostgreSQL is dumped first and the dump backed up, because
# copying a running database's files doesn't give a usable copy.
#
# Secrets (in secrets/home-server.yaml): restic/repository (e.g.
# s3:https://<account>.r2.cloudflarestorage.com/homelab or b2:bucket:homelab),
# restic/password (keep a copy in 1Password: without it the backup is unreadable) and
# restic/env (the storage's credentials, as AWS_ACCESS_KEY_ID=... lines).
{ config, lib, ... }:
let
  cfg = config.my.homelab;
  bk = cfg.backup;
  dumps = "/var/lib/postgresql-backup";
in
{
  options.my.homelab.backup = {
    enable = lib.mkEnableOption "nightly off-site backups with restic (needs my.homelab.secrets.enable)";
    extraPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "More paths to back up, beyond service state, /persist, /home and photos.";
    };
  };

  config = lib.mkIf (cfg.enable && bk.enable) {
    assertions = [
      {
        assertion = cfg.secrets.enable;
        message = "my.homelab.backup needs my.homelab.secrets.enable for the restic repository and password.";
      }
    ];

    sops.secrets = {
      "restic/repository" = { };
      "restic/password" = { };
      "restic/env" = { };
    };

    services.postgresqlBackup = lib.mkIf config.services.postgresql.enable {
      enable = true;
      location = dumps;
      compression = "zstd";
      startAt = "*-*-* 02:30:00";
    };

    services.restic.backups.homelab = {
      initialize = true;
      repositoryFile = config.sops.secrets."restic/repository".path;
      passwordFile = config.sops.secrets."restic/password".path;
      environmentFile = config.sops.secrets."restic/env".path;
      paths = [
        "/var/lib"
        "/persist"
        "/home"
      ]
      ++ lib.optional config.services.immich.enable config.services.immich.mediaLocation
      ++ bk.extraPaths;
      exclude = [
        # Dumped to ${dumps} instead
        "/var/lib/postgresql"
        # Caches and things rebuilt on their own
        "/var/lib/plex/Plex Media Server/Cache"
        "/var/lib/plex/Plex Media Server/Media"
        "/var/lib/immich/thumbs"
        "/var/lib/immich/encoded-video"
        "/var/lib/systemd/coredump"
        "/var/lib/containers"
        "/var/lib/docker"
        "/var/lib/influxdb2"
        "/var/lib/meilisearch"
        "/home/*/.cache"
      ];
      extraBackupArgs = [ "--exclude-caches" ];
      timerConfig = {
        OnCalendar = "03:00";
        Persistent = true;
        RandomizedDelaySec = "30min";
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 3"
      ];
      # Reads back a sample of the data each run, so a broken repository shows up early
      checkOpts = [ "--read-data-subset=2%" ];
    };

    systemd.services.restic-backups-homelab = {
      after = lib.optional config.services.postgresql.enable "postgresqlBackup.service";
      onFailure = [ "notify-failure@%n.service" ];
    };
  };
}
