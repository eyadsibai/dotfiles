# /data: media, downloads and photos. The media apps share it through the `media`
# group. Downloads and the library sit on the same filesystem, so Sonarr and Radarr
# hard-link finished downloads into the library instead of copying them (the TRaSH
# Guides layout).
#
# Each data disk keeps its own filesystem: the Unraid array's disks are plain XFS and
# mount as they are, with no copying. mergerfs merges them into /data. SnapRAID
# keeps parity on separate disks, which have to be formatted fresh (Unraid's parity
# can't be reused), and rebuilds a failed data disk from it. Disks of any size can be
# added one at a time, as on Unraid.
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
  diskMounts = lib.mapAttrs' (
    name: device:
    lib.nameValuePair (mountOf name) {
      inherit device;
      fsType = st.fsType;
      # A missing or failed disk shouldn't stop the machine from booting
      options = [
        "nofail"
        "noatime"
      ];
    }
  ) (st.dataDisks // st.parityDisks);

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
    fsType = mkOption {
      type = types.str;
      default = "xfs";
      description = "Filesystem of the data and parity disks (Unraid's arrays use XFS).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        users.groups.media = { };

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

      (lib.mkIf (st.dataDisks != { }) {
        fileSystems = diskMounts // {
          "/data" = {
            device = lib.concatStringsSep ":" dataMounts;
            fsType = "fuse.mergerfs";
            options = [
              # New files go to the disk with the most free space; a hard link always
              # lands on the same disk as its source
              "category.create=mfs"
              "minfreespace=50G"
              "moveonenospc=true"
              "cache.files=partial"
              "dropcacheonclose=true"
              "fsname=mergerfs"
              "nofail"
            ];
            depends = dataMounts;
          };
        };
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
          ];
        };
        systemd.services.snapraid-sync.onFailure = lib.mkIf (st.parityDisks != { }) [
          "notify-failure@%n.service"
        ];
      })
    ]
  );
}
