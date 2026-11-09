# NixOS as a full-desktop VM on the Macs, the way Mitchell Hashimoto works
# (github.com/mitchellh/nixos-config): macOS for the apps, this VM full screen for
# everything dev. Shared by hosts/vm-fusion (VMware Fusion) and hosts/vm-utm (UTM).
#
# Installed from the Mac with `just vm-install <host> <ip>` (nixos-anywhere +
# the disko layout below); after that, `just switch` inside the VM like any host.
{
  inputs,
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./default.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # The whole virtual disk: an EFI partition and ext4 for the rest. The device is
  # the hypervisor's (vm-fusion sets SATA's /dev/sda; UTM's virtio disk is /dev/vda).
  disko.devices.disk.main = {
    type = "disk";
    device = lib.mkDefault "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
  zramSwap.enable = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "uhci_hcd"
    "ahci"
    "nvme"
    "virtio_pci"
    "virtio_blk"
    "usbhid"
    "usb_storage"
    "sr_mod"
  ];
  # Some VM firmware only takes mode 0 ("error switching console mode" otherwise)
  boot.loader.systemd-boot.consoleMode = "0";

  # Run x86_64 Linux binaries too (through QEMU, so slowly)
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  # GNOME, logged in automatically: the Mac has already checked who you are, and
  # the VM runs full screen as if it were the machine
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
  # GDM's autologin races the console on tty1 (NixOS wiki, "GNOME")
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Nobody else can reach the VM's console, and with autologin there's no password
  # to type; set one with `passwd` if you want the lock screen to mean something
  security.sudo.wheelNeedsPassword = false;

  # Desktop apps that run on aarch64-linux (modules/home/desktop-apps.nix is
  # mostly x86_64-only: Spotify, Slack, Zoom, Discord, IntelliJ)
  home-manager.users.${username} = {
    imports = [ ../home/firefox.nix ];
    home.packages = with pkgs; [
      ghostty
      vscode
    ];
  };
}
