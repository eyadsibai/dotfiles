# The homelab in a VM: `nix build .#checks.x86_64-linux.homelab -L` (a few minutes,
# needs KVM). `just check` only evaluates it.
#
# It boots with three blank disks and checks what can't be seen from evaluation:
#   - with the disks missing, /data isn't mounted and the apps that use it stay
#     stopped, rather than writing onto the root
#   - data-disk-prepare's encrypted disks and a plain (Unraid-style) one unlock and
#     merge into /data at the next boot, with the folders made on the disks
#   - SnapRAID syncs, and refuses to after a mass deletion
#   - the web apps start and answer on their health paths
#
# Secrets, the domain, the VPN and the GPU are off; Plex, Immich, Wolf and the other
# heavy or unfree apps too.
{
  pkgs,
  inputs,
  username,
  useremail,
}:
pkgs.testers.runNixOSTest {
  name = "homelab";

  node.specialArgs = {
    inherit inputs username useremail;
  };

  nodes.server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
        inputs.impermanence.nixosModules.impermanence
        ../modules/nixos/auto-upgrade.nix
        ../modules/nixos/homelab
      ];

      users.users.${username}.isNormalUser = true;

      virtualisation = {
        # A VM test replaces the machine's mounts with its own; these put the
        # homelab's back
        fileSystems = config.my.homelab.storage.mounts;
        memorySize = 4096;
        cores = 4;
        diskSize = 8192;
        # Serial numbers give them /dev/disk/by-id names, as real disks have
        emptyDiskImages =
          map
            (serial: {
              size = 1024;
              driveConfig.deviceExtraOpts = { inherit serial; };
            })
            [
              "disk1"
              "disk2"
              "parity1"
            ];
      };

      # For the test to format the plain disk itself
      environment.systemPackages = [
        pkgs.gptfdisk
        pkgs.xfsprogs
      ];

      # Stands in for storage/disk-key from the secrets
      environment.etc."disk-key".text = "a key only for this test";

      my.homelab = {
        enable = true;
        storage = {
          dataDisks = {
            disk1 = "/dev/disk/by-id/virtio-disk1-part1";
            disk2 = "/dev/disk/by-id/virtio-disk2-part1";
          };
          parityDisks.parity1 = "/dev/disk/by-id/virtio-parity1-part1";
          # disk2 is left plain, as an Unraid disk would be
          plainDisks = [ "disk2" ];
          keyFile = "/etc/disk-key";
          deleteThreshold = 5;
          minFreeSpace = "10M";
          spinDownMinutes = 0;
        };
        apps =
          lib.genAttrs
            [
              "plex"
              "immich"
              "wolf"
              "karakeep"
              "paperless"
              "pinchflat"
              "seerr"
              "flaresolverr"
              "adguard"
              "scrutiny"
            ]
            (_: {
              enable = false;
            });
      };
    };

  testScript =
    { nodes, ... }:
    let
      apps = nodes.server.my.homelab.apps;
      enabled = lib.filterAttrs (_: a: a.enable) apps;
      inherit (pkgs) lib;
      checks = lib.concatStrings (
        lib.mapAttrsToList (name: a: ''
          with subtest("${name} answers"):
              server.wait_until_succeeds("curl -fsS -o /dev/null http://${a.upstream}${a.health}", timeout=300)
        '') enabled
      );
    in
    ''
      server.wait_for_unit("multi-user.target")

      with subtest("without its disks, /data isn't mounted and its apps wait"):
          server.fail("mountpoint -q /data")
          server.fail("systemctl is-active sonarr.service")

      with subtest("disks are prepared"):
          server.succeed("echo erase | data-disk-prepare /dev/disk/by-id/virtio-disk1")
          server.succeed("echo erase | data-disk-prepare /dev/disk/by-id/virtio-parity1")
          server.fail("echo no | data-disk-prepare /dev/disk/by-id/virtio-disk2")
          server.succeed(
              "sgdisk --new=1:0:0 /dev/disk/by-id/virtio-disk2",
              "udevadm settle",
              "mkfs.xfs -q /dev/disk/by-id/virtio-disk2-part1",
          )

      server.shutdown()
      server.start()
      server.wait_for_unit("multi-user.target")

      with subtest("the disks unlock and merge into /data"):
          server.succeed("test -b /dev/mapper/disk-disk1 && test -b /dev/mapper/disk-parity1")
          server.fail("test -e /dev/mapper/disk-disk2")
          server.succeed("lsblk -no FSTYPE /dev/disk/by-id/virtio-disk1-part1 | grep -qx crypto_LUKS")
          server.succeed("findmnt -no FSTYPE /data | grep -q fuse.mergerfs")
          server.wait_for_unit("data-dirs.service")
          server.succeed("test -d /data/media/tv && test -d /data/usenet/complete")
          server.succeed("stat -c %G:%a /data/media/tv | grep -qx media:2775")
          # The folders are on the disks, not on the root under the mount
          server.succeed("test -d /mnt/disk1/media/tv || test -d /mnt/disk2/media/tv")
          server.wait_for_unit("sonarr.service")

      with subtest("SnapRAID syncs, and stops after a mass deletion"):
          server.succeed("for i in $(seq 20); do echo $i > /data/media/file$i; done")
          # The first sync is by hand, as docs/homelab.md says; the nightly one after
          server.succeed("snapraid sync")
          server.succeed("echo more > /data/media/another")
          server.succeed("systemctl start snapraid-sync.service")
          server.succeed("rm /data/media/file*")
          server.fail("systemctl start snapraid-sync.service")
          server.succeed("journalctl -u snapraid-sync | grep -q 'files deleted since the last sync'")

      ${checks}
    '';
}
