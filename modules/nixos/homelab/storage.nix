# /data: media, downloads and photos. The media apps share it through the `media`
# group. Downloads and the library sit on the same filesystem, so Sonarr and Radarr
# hard-link finished downloads into the library instead of copying them (the TRaSH
# Guides layout).
#
# Each data disk keeps its own filesystem, and mergerfs merges them into /data.
# SnapRAID keeps parity on separate disks and rebuilds a failed data disk from it.
# Disks of any size can be added one at a time, as on Unraid.
#
# Every disk is encrypted (LUKS), with one key shared by all of them kept in sops
# (storage/disk-key), so they unlock at boot without anyone there, and a disk that's
# sent back under warranty or thrown away gives nothing away. `data-disk-prepare`
# formats a disk that way. The Unraid disks hold plain XFS; listed in plainDisks they
# mount as they are, for the move across (docs/homelab.md, Disks).
#
# Until disks are listed, /data is a folder on the NVMe (kept in /persist).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.homelab;
  st = cfg.storage;
  inherit (lib) mkOption types;
  mountOf = name: "/mnt/${name}";
  dataMounts = map mountOf (lib.attrNames st.dataDisks);
  allDisks = st.dataDisks // st.parityDisks;
  encrypted = lib.filterAttrs (name: _: !lib.elem name st.plainDisks) allDisks;
  keyFile = st.keyFile;
  diskMounts = lib.mapAttrs' (
    name: device:
    lib.nameValuePair (mountOf name) {
      device = if encrypted ? ${name} then "/dev/mapper/disk-${name}" else device;
      fsType = st.fsType;
      # A missing or failed disk shouldn't stop the machine from booting
      options = [
        "nofail"
        "noatime"
      ];
    }
  ) allDisks;

  # The disks, and /data merging them
  mounts = diskMounts // {
    "/data" = {
      device = lib.concatStringsSep ":" dataMounts;
      fsType = "fuse.mergerfs";
      # mergerfs's own recommendations for Linux 6.6+ (its quickstart)
      options = [
        # New files go to a disk picked at random, weighted by free space; a
        # hard link always lands on the same disk as its source
        "category.create=pfrd"
        "func.getattr=newest"
        "minfreespace=${st.minFreeSpace}"
        "moveonenospc=true"
        "cache.files=off"
        "dropcacheonclose=false"
        # A disk that isn't there would otherwise be an empty folder, and new
        # files would go onto the root under it, which the next boot wipes:
        # wait a minute for every disk, then fail rather than mount without one
        "branches-mount-timeout=60"
        "branches-mount-timeout-fail=true"
        "fsname=mergerfs"
        "nofail"
      ];
      depends = dataMounts;
    };
  };

  # Formats a new disk the way the config expects it: one partition, LUKS with the
  # shared key, XFS inside
  prepare = pkgs.writeShellApplication {
    name = "data-disk-prepare";
    runtimeInputs = with pkgs; [
      cryptsetup
      gptfdisk
      util-linux
      xfsprogs
      systemd
    ];
    text = ''
      disk=''${1:-}
      if [[ $disk != /dev/disk/by-id/* || $disk == *-part* ]]; then
        echo "usage: sudo data-disk-prepare /dev/disk/by-id/<whole disk>" >&2
        exit 1
      fi
      if [[ ! -r ${keyFile} ]]; then
        echo "No key at ${keyFile}: add storage/disk-key to the secrets first" >&2
        exit 1
      fi
      if lsblk -no MOUNTPOINTS "$disk" | grep -q .; then
        echo "$disk is mounted: not touching it" >&2
        exit 1
      fi
      lsblk -o NAME,SIZE,FSTYPE,LABEL,MODEL "$disk"
      read -rp "Everything on $disk will be erased. Type the word erase to go on: " answer
      [[ $answer == erase ]] || exit 1

      sgdisk --zap-all --new=1:0:0 --typecode=1:8309 "$disk"
      udevadm settle
      part="$disk-part1"
      cryptsetup luksFormat --batch-mode --type luks2 --key-file ${keyFile} "$part"
      cryptsetup open --key-file ${keyFile} "$part" disk-prepare
      mkfs.${st.fsType} -q /dev/mapper/disk-prepare
      cryptsetup close disk-prepare
      echo
      echo "Done. Add it to my.homelab.storage.dataDisks or parityDisks as"
      echo "  <name> = \"$part\";"
    '';
  };

  # Stops the nightly SnapRAID sync after a mass deletion (below)
  guard = pkgs.writeShellApplication {
    name = "snapraid-delete-guard";
    runtimeInputs = [
      pkgs.snapraid
      pkgs.gawk
    ];
    text = ''
      # diff exits non-zero whenever a sync is due, which is most nights
      removed=$(snapraid diff 2>/dev/null | awk '$2 == "removed" { print $1 }' || true)
      if (( ''${removed:-0} > ${toString st.deleteThreshold} )); then
        echo "$removed files deleted since the last sync (limit ${toString st.deleteThreshold}): not syncing. Check with 'snapraid diff', then 'sudo snapraid sync' if it was meant." >&2
        exit 1
      fi
    '';
  };

  # The units that use /data, each with whether it is on
  s = config.services;
  dataUsers = {
    plex = s.plex.enable;
    jellyfin = s.jellyfin.enable;
    navidrome = s.navidrome.enable;
    sonarr = s.sonarr.enable;
    radarr = s.radarr.enable;
    lidarr = s.lidarr.enable;
    bazarr = s.bazarr.enable;
    pinchflat = s.pinchflat.enable;
    audiobookshelf = s.audiobookshelf.enable;
    immich-server = s.immich.enable;
    immich-machine-learning = s.immich.enable && s.immich.machine-learning.enable;
    qbittorrent = s.qbittorrent.enable;
    sabnzbd = s.sabnzbd.enable;
    samba-smbd = s.samba.enable;
    restic-backups-homelab = s.restic.backups ? homelab;
  };

  # The disks themselves, from their first partitions' names: spin-down and the
  # fans work on whole disks
  wholeDisks = lib.unique (
    map (
      part:
      let
        m = builtins.match "(.*)-part[0-9]+" part;
      in
      if m == null then part else builtins.head m
    ) (lib.attrValues (st.dataDisks // st.parityDisks))
  );

  # Owned by root:media and group-writable; setgid so new files stay in `media`
  shared = {
    d = {
      mode = "2775";
      user = "root";
      group = "media";
    };
  };
in
{
  options.my.homelab.storage = {
    dataDisks = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        disk1 = "/dev/disk/by-id/ata-WDC_WD80EFZZ-68BTXN0_XXXXXXXX-part1";
      };
      description = "Data disks by name (mounted at /mnt/<name>) to merge into /data.";
    };
    parityDisks = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        parity1 = "/dev/disk/by-id/ata-WDC_WD120EFBX-68B0EN0_XXXXXXXX-part1";
      };
      description = ''
        SnapRAID parity disks. Each must be at least as big as the largest data disk;
        one survives one failed disk, two survive two.
      '';
    };
    plainDisks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "disk1" ];
      description = ''
        Disks (by their name above) that aren't encrypted and mount as they are: the
        Unraid disks, until their files have moved to encrypted ones.
      '';
    };
    minFreeSpace = mkOption {
      type = types.str;
      default = "50G";
      description = "New files go to a disk with at least this much free.";
    };
    mounts = mkOption {
      type = types.attrsOf types.anything;
      internal = true;
      readOnly = true;
      default = mounts;
      description = ''
        The mounts above, for the VM test: a VM replaces fileSystems with its own,
        so the test lists these again.
      '';
    };
    keyFile = mkOption {
      type = types.nullOr types.str;
      default = if cfg.secrets.enable then config.sops.secrets."storage/disk-key".path else null;
      defaultText = lib.literalMD "storage/disk-key from the secrets, once they're on";
      description = "The key the encrypted disks unlock with (the VM test uses its own).";
    };
    fsType = mkOption {
      type = types.str;
      default = "xfs";
      description = "Filesystem of the data and parity disks (Unraid's arrays use XFS).";
    };
    deleteThreshold = mkOption {
      type = types.ints.unsigned;
      default = 500;
      description = "More files deleted since the last SnapRAID sync than this stops the nightly sync.";
    };
    spinDownMinutes = mkOption {
      type = types.ints.unsigned;
      default = 30;
      description = "Minutes a data or parity disk sits idle before it spins down; 0 keeps them spinning.";
    };
    fanPwmPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/sys/class/hwmon/hwmon5/pwm2:50:50" ];
      description = ''
        The case fans over the disks, as hddfancontrol takes them
        (`<pwm file>:<start value>:<stop value>`), to speed up with the disks'
        temperature. Which file drives which fan depends on the motherboard:
        `nix run nixpkgs#lm_sensors -- pwmconfig` finds out. Empty leaves the fans to
        the BIOS.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # A fixed number: the data disks keep it on every file, and must still
        # match after a reinstall, when ids would otherwise be handed out afresh
        users.groups.media.gid = 2000;

        systemd.tmpfiles.settings.homelab-data =
          lib.genAttrs [
            "/data"
            "/data/torrents"
            "/data/torrents/incomplete"
            "/data/torrents/tv"
            "/data/torrents/movies"
            "/data/torrents/music"
            "/data/usenet"
            "/data/usenet/incomplete"
            "/data/usenet/complete"
            "/data/media"
            "/data/media/tv"
            "/data/media/movies"
            "/data/media/music"
            "/data/media/youtube"
            "/data/media/audiobooks"
            "/data/media/podcasts"
          ] (_: shared)
          // {
            "/var/lib/snapraid".d = {
              mode = "0700";
            };
          };
      }

      (lib.mkIf (st.dataDisks == { }) {
        environment.persistence."/persist".directories = [
          {
            directory = "/data";
            group = "media";
            mode = "2775";
          }
        ];
      })

      {
        assertions = [
          {
            assertion = encrypted == { } || keyFile != null;
            message = "Encrypted data disks need my.homelab.secrets.enable for storage/disk-key (or list them in my.homelab.storage.plainDisks).";
          }
        ];
      }

      # Any long random string, the same for every disk: `openssl rand -hex 64`. In
      # sops it's backed up with the repo; lose it and the disks are unreadable.
      (lib.mkIf cfg.secrets.enable {
        sops.secrets."storage/disk-key" = { };
      })

      (lib.mkIf (keyFile != null) {
        environment.systemPackages = [ prepare ];
      })

      (lib.mkIf (encrypted != { } && keyFile != null) {
        # Unlocked after the NVMe, once the secrets are in place. A missing disk is
        # skipped rather than holding up the boot (mergerfs then refuses to mount)
        environment.etc.crypttab.text = lib.concatStrings (
          lib.mapAttrsToList (name: device: ''
            disk-${name} ${device} ${keyFile} luks,nofail
          '') encrypted
        );
      })

      (lib.mkIf (st.dataDisks != { }) {
        fileSystems = st.mounts;
        system.fsPackages = [ pkgs.mergerfs ];

        services.snapraid = lib.mkIf (st.parityDisks != { }) {
          enable = true;
          dataDisks = lib.mapAttrs (name: _: "${mountOf name}/") st.dataDisks;
          parityFiles = map (name: "${mountOf name}/snapraid.parity") (lib.attrNames st.parityDisks);
          # Several copies of the content file, in case the disk holding one dies
          contentFiles = [
            "/var/lib/snapraid/snapraid.content"
          ]
          ++ map (m: "${m}/snapraid.content") dataMounts;
          exclude = [
            "*.unrecoverable"
            "/lost+found/"
            "*.!qB"
            "*.part"
            "/torrents/incomplete/"
            "/usenet/incomplete/"
            # Files that change every night weaken parity for every other disk until
            # the next sync. These are backups or caches that are rebuilt anyway.
            "/timemachine/"
            "/backups/"
            "/photos/thumbs/"
            "/photos/encoded-video/"
          ];
        };
        systemd.services = lib.mkIf (st.parityDisks != { }) {
          # A sync makes the parity match the disks as they are. If something
          # deleted a large part of the library, syncing would make that permanent,
          # so it stops and asks: `snapraid diff` to see what went, then
          # `sudo snapraid sync` by hand if it was meant.
          # (nixpkgs' module sets `snapraid touch` here as a single command, so the
          # list replaces it and keeps it, after the guard)
          snapraid-sync.serviceConfig.ExecStartPre = lib.mkForce [
            (lib.getExe guard)
            "${pkgs.snapraid}/bin/snapraid touch"
          ];
          snapraid-sync.onFailure = [ "notify-failure@%n.service" ];
          # nixpkgs makes the parity file itself writable, which systemd can't do
          # before the first sync has made it: the unit wouldn't start. The disk
          # holding it is enough.
          snapraid-sync.serviceConfig.ReadWritePaths = map mountOf (lib.attrNames st.parityDisks);
          # A scrub that fails has found data that doesn't match its parity
          snapraid-scrub.onFailure = [ "notify-failure@%n.service" ];
        };
      })

      # Everything that reads or writes /data starts only once it is mounted, and
      # stops if it goes away; otherwise it would write into the root underneath
      (lib.mkIf (st.dataDisks != { }) {
        systemd.services =
          lib.genAttrs (lib.attrNames (lib.filterAttrs (_: on: on) dataUsers)) (_: {
            unitConfig.RequiresMountsFor = [ "/data" ];
            wants = [ "data-dirs.service" ];
            after = [ "data-dirs.service" ];
          })
          // {
            # The folders in /data (here and in the other modules' tmpfiles rules)
            # are made at boot before the disks may be mounted, which puts them on
            # the root under /data instead. They're made again once it's mounted.
            data-dirs = {
              description = "Create the folders in /data";
              unitConfig.RequiresMountsFor = [ "/data" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${config.systemd.package}/bin/systemd-tmpfiles --create --prefix=/data";
              };
            };
          };
      })

      # Spinning disks rest when nothing reads them, as Unraid had them. The NVMe and
      # anything not listed are left alone. A disk wakes on the next read, which takes
      # a few seconds; the nightly SnapRAID sync wakes them all.
      (lib.mkIf (st.dataDisks != { } && st.spinDownMinutes > 0) {
        systemd.services.hd-idle = {
          description = "Spin down idle data and parity disks";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = lib.escapeShellArgs (
              [
                (lib.getExe pkgs.hd-idle)
                "-i"
                "0"
              ]
              ++ lib.concatMap (disk: [
                "-a"
                disk
                "-i"
                (toString (st.spinDownMinutes * 60))
              ]) wholeDisks
            );
            Restart = "on-failure";
          };
        };
      })

      (lib.mkIf (st.fanPwmPaths != [ ]) {
        services.hddfancontrol = {
          enable = true;
          settings.disks = {
            disks = wholeDisks;
            pwmPaths = st.fanPwmPaths;
          };
        };
      })
    ]
  );
}
