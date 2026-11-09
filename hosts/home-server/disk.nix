# home-server's disk (disko, partitioned by nixos-anywhere at install): one encrypted
# btrfs partition, unlocked by the TPM once it's enrolled (passphrase until then).
#
# Subvolumes: / is `root`, rolled back to an empty snapshot (`root-blank`) on every
# boot (below), so nothing accumulates outside what the config declares. What has to
# survive lives on its own subvolumes: /nix, /home, /var/lib (every service's state),
# /var/log, and /persist for the odd single file (impermanence, in default.nix).
{ lib, ... }:
let
  mount = path: {
    mountpoint = path;
    mountOptions = [
      "compress=zstd"
      "noatime"
    ];
  };
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/nvme0n1"; # check with lsblk before installing
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            # The passphrase, given to nixos-anywhere with --disk-encryption-keys
            passwordFile = "/tmp/disk.key";
            settings = {
              allowDiscards = true;
              crypttabExtraOpts = [ "tpm2-device=auto" ];
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/root" = mount "/";
                "/nix" = mount "/nix";
                "/home" = mount "/home";
                "/var-lib" = mount "/var/lib";
                "/var-log" = mount "/var/log";
                "/persist" = mount "/persist";
                "/swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "8G";
                };
              };
              # The empty root every boot starts from
              postCreateHook = ''
                MNTPOINT=$(mktemp -d)
                mount /dev/mapper/crypted "$MNTPOINT" -o subvol=/
                trap 'umount "$MNTPOINT"; rmdir "$MNTPOINT"' EXIT
                btrfs subvolume snapshot -r "$MNTPOINT/root" "$MNTPOINT/root-blank"
              '';
            };
          };
        };
      };
    };
  };

  fileSystems = {
    "/persist".neededForBoot = true;
    "/var/lib".neededForBoot = true; # /var/lib/nixos keeps users' ids stable
    "/var/log".neededForBoot = true;
  };

  # Roll / back to root-blank before it's mounted. `touch /dont-wipe` on the top-level
  # subvolume (mounted with subvol=/) skips it for one investigation.
  boot.initrd = {
    supportedFilesystems = [ "btrfs" ];
    systemd.services.rollback-root = {
      description = "Roll the btrfs root back to an empty snapshot";
      wantedBy = [ "initrd.target" ];
      requires = [ "dev-mapper-crypted.device" ];
      after = [ "dev-mapper-crypted.device" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
        mount -t btrfs -o subvol=/ /dev/mapper/crypted /mnt
        if [ -e /mnt/dont-wipe ]; then
          echo "dont-wipe present: keeping the root"
        else
          btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read -r sub; do
            btrfs subvolume delete "/mnt/$sub"
          done
          btrfs subvolume delete /mnt/root
          btrfs subvolume snapshot /mnt/root-blank /mnt/root
        fi
        umount /mnt
      '';
    };
  };
}
