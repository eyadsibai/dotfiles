# Backups with restic, nightly: every service's state (/var/lib), /persist, /home and
# the photos. Media is left out: it can be fetched again, and SnapRAID covers a failed
# disk. PostgreSQL is dumped first and the dump backed up, because copying a running
# database's files doesn't give a usable copy.
#
# Two copies of the same backup: one off-site, for a fire or a break-in, and one on
# the data disks (/data/backups/restic), for the NVMe dying, which restores at disk
# speed instead of over the internet. The local one exists once there are data disks;
# before that it would sit on the very NVMe it protects.
#
# Secrets (in secrets/home-server.yaml): restic/repository (e.g.
# s3:https://<account>.r2.cloudflarestorage.com/homelab or b2:bucket:homelab),
# restic/password (keep a copy in 1Password: without it the backup is unreadable; both
# copies use it) and restic/env (the storage's credentials, as AWS_ACCESS_KEY_ID=... lines).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.homelab;
  bk = cfg.backup;
  dumps = "/var/lib/postgresql-backup";
  localRepo = "/data/backups/restic";
  hasDisks = cfg.storage.dataDisks != { };
  pg = config.services.postgresql.enable;

  # What both copies hold
  common = {
    passwordFile = config.sops.secrets."restic/password".path;
    initialize = true;
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
      "${config.services.immich.mediaLocation}/thumbs"
      "${config.services.immich.mediaLocation}/encoded-video"
      "/var/lib/systemd/coredump"
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/lib/influxdb2"
      "/var/lib/meilisearch"
      "/home/*/.cache"
      # /data while it is still a folder on the NVMe (storage.nix): media, not state
      "/persist/data"
    ]
    ++ bk.extraExcludes;
    extraBackupArgs = [ "--exclude-caches" ];
    # Reads back a sample of the data each run, so a broken repository shows up early
    checkOpts = [ "--read-data-subset=2%" ];
  };

  # The apps keep SQLite databases in /var/lib (Plex, the *arr apps, Pocket ID,
  # Gatus) and write them while they run; a copy read file by file during a write is
  # torn. So each backup reads read-only btrfs snapshots of the state subvolumes,
  # taken just before it, mounted in its place so the paths in the backup stay
  # /var/lib, /persist and /home. The snapshots go when the backup ends.
  snapshotted = {
    var-lib = "/var/lib";
    persist = "/persist";
    home = "/home";
  };
  snapshotUnits =
    name:
    let
      dir = "/mnt/btr-pool/restic/${name}";
      unit = "restic-snapshot-${name}";
    in
    {
      systemd.services.${unit} = {
        description = "Snapshots of the state subvolumes for the ${name} backup";
        after = lib.optional pg "postgresqlBackup.service";
        path = [ pkgs.btrfs-progs ];
        unitConfig = {
          RequiresMountsFor = [ "/mnt/btr-pool" ];
          # Stopped, and the snapshots deleted, once the backup no longer needs them
          StopWhenUnneeded = true;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          mkdir -p ${dir}
          for sub in ${toString (lib.attrNames snapshotted)}; do
            [[ -e ${dir}/$sub ]] && btrfs subvolume delete ${dir}/$sub
            btrfs subvolume snapshot -r /mnt/btr-pool/$sub ${dir}/$sub
          done
        '';
        preStop = ''
          for sub in ${toString (lib.attrNames snapshotted)}; do
            [[ -e ${dir}/$sub ]] && btrfs subvolume delete ${dir}/$sub || true
          done
        '';
      };
      systemd.services."restic-backups-${name}" = {
        requires = [ "${unit}.service" ];
        after = [ "${unit}.service" ];
        serviceConfig.BindReadOnlyPaths = lib.mapAttrsToList (
          sub: path: "${dir}/${sub}:${path}"
        ) snapshotted;
      };
    };
in
{
  options.my.homelab.backup = {
    enable = lib.mkEnableOption "nightly backups with restic, off-site and on the data disks (needs my.homelab.secrets.enable)";
    extraPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "More paths to back up, beyond service state, /persist, /home and photos.";
    };
    extraExcludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths (restic patterns) to leave out of both copies.";
    };
  };

  config = lib.mkIf (cfg.enable && bk.enable) (
    lib.mkMerge [
      {
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

        services.postgresqlBackup = lib.mkIf pg {
          enable = true;
          location = dumps;
          compression = "zstd";
          startAt = "*-*-* 02:30:00";
        };
        systemd.services.postgresqlBackup.onFailure = lib.mkIf pg [ "notify-failure@%n.service" ];

        services.restic.backups.homelab = common // {
          repositoryFile = config.sops.secrets."restic/repository".path;
          environmentFile = config.sops.secrets."restic/env".path;
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
        };

        systemd.services.restic-backups-homelab = {
          after = lib.optional pg "postgresqlBackup.service";
          onFailure = [ "notify-failure@%n.service" ];
        };

        # Paperless's own export (documents plus a manifest of their tags and
        # metadata) is what its docs say to back up; it lands in /var/lib/paperless
        services.paperless.exporter.enable = lib.mkIf config.services.paperless.enable true;

        # A backup is only known to work once something has been restored from it.
        # Monthly, a small part of the off-site one is restored and checked.
        systemd.services.restic-restore-test = {
          description = "Restore part of the off-site backup and check it";
          onFailure = [ "notify-failure@%n.service" ];
          serviceConfig = {
            Type = "oneshot";
            PrivateTmp = true;
          };
          script = ''
            target=$(mktemp -d)
            /run/current-system/sw/bin/restic-homelab restore latest --target "$target" --include /var/lib/nixos
            if [[ ! -s $target/var/lib/nixos/uid-map ]]; then
              echo "The restore finished but /var/lib/nixos/uid-map is missing or empty" >&2
              exit 1
            fi
            echo "Restored and checked $(du -sh "$target" | cut -f1) from the latest snapshot"
          '';
          startAt = "*-*-01 05:00:00";
        };
      }
      (snapshotUnits "homelab")

      (lib.mkIf hasDisks (snapshotUnits "local"))
      (lib.mkIf hasDisks {
        # Fewer old versions than off-site: this one is for getting back last
        # night's state quickly, the other for going back further
        services.restic.backups.local = common // {
          repository = localRepo;
          timerConfig = {
            OnCalendar = "02:45";
            Persistent = true;
          };
          pruneOpts = [
            "--keep-daily 7"
            "--keep-weekly 4"
          ];
        };

        systemd.services.restic-backups-local = {
          after = lib.optional pg "postgresqlBackup.service";
          # Never into the NVMe's /data if the disks failed to mount
          unitConfig.RequiresMountsFor = "/data";
          onFailure = [ "notify-failure@%n.service" ];
        };

        systemd.tmpfiles.settings.homelab-backup = {
          "/data/backups".d = {
            mode = "0700";
            user = "root";
            group = "root";
          };
        };
      })
    ]
  );
}
