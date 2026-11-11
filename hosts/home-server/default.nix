# home-server: planned NixOS replacement for the Unraid server. Not installed yet; the
# hardware below is generic until `nixos-generate-config --show-hardware-config` on the
# machine says otherwise. Installing: docs/home-server.md.
#
# Built to run unattended (ideas from github.com/Misterio77/Foundry):
#   - encrypted disk unlocked by the TPM; Secure Boot once its keys exist (disk.nix,
#     modules/nixos/secure-boot.nix)
#   - a root that starts empty on every boot, with state on its own subvolumes
#   - upgrades itself nightly from GitHub (or from the self-hosted CI's builds)
#   - sudo approved through the SSH agent (1Password), so it holds no password
{
  inputs,
  lib,
  username,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ./disk.nix
    ../../modules/nixos
    ../../modules/nixos/homelab
  ];

  # The services (modules/nixos/homelab, docs/homelab.md). Next steps, as they're
  # decided: storage.dataDisks/parityDisks from `ls -l /dev/disk/by-id`, then
  # secrets.enable once secrets/home-server.yaml exists, then domain, vpn and backup.
  my.homelab.enable = true;

  # RTX 2070, for Plex's transcoding and the games Wolf streams to the TVs
  # (modules/nixos/homelab/gaming.nix). No display: the open kernel modules (Turing
  # supports them) and the persistence daemon, which keeps the driver loaded
  # between uses instead of initialising the card each time.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    open = true;
    nvidiaPersistenced = true;
    nvidiaSettings = false;
  };

  networking.hostName = "home-server";
  nixpkgs.hostPlatform = "x86_64-linux";

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    # Network drivers for the common onboard chips, for SSH in the initrd (below);
    # only the one present loads. Check against nixos-generate-config's list once
    # the hardware is known.
    "r8169"
    "igc"
    "igb"
    "e1000e"
  ];
  hardware.enableRedistributableFirmware = true;
  security.tpm2.enable = true;

  # The few single files outside the subvolumes that must outlive the root wipe
  environment.persistence."/persist" = {
    hideMounts = true;
    files = [ "/etc/machine-id" ];
  };
  # SSH host keys on /persist: they're the machine's identity, and sops-nix decrypts
  # with them (modules/nixos/secrets.nix) before anything else is mounted
  services.openssh.hostKeys = [
    {
      path = "/persist/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
  sops.age.sshKeyPaths = lib.mkForce [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  # Users come from this config alone (the root is rebuilt every boot anyway). No
  # passwords: SSH keys to log in, and sudo approved by the forwarded agent (`ssh -A`,
  # i.e. 1Password on the machine I'm at), checked against the root-owned key list
  users.mutableUsers = false;
  security.pam.rssh = {
    enable = true;
    settings.auth_key_file = "/etc/ssh/authorized_keys.d/$ruser";
  };
  security.pam.services.sudo.rssh = true;

  my.server = true;
  my.autoUpgrade.enable = true;
  # Not master: what the desktops have already run (`just promote`)
  my.autoUpgrade.branch = "server";
  # A new kernel or NVIDIA driver only takes effect after a reboot; until then Plex
  # can't transcode (the driver's libraries no longer match the loaded module). So
  # the nightly upgrade reboots when one changed, within 04:00-06:00. Turn on once
  # a reboot has been seen to unlock the disk through the TPM by itself
  # (docs/home-server.md, step 3): otherwise it would wait at the passphrase.
  my.autoUpgrade.allowReboot = false;

  # The CPU's microcode fixes. Both are listed until the hardware is known; each
  # loads only on its own make of CPU.
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  # Nobody is at the console (from srvos' server profile): a failed mount or unit
  # at boot carries on to SSH rather than waiting at an emergency shell; a kernel
  # or systemd that stops responding is rebooted by the hardware watchdog; and it
  # never sleeps
  systemd.enableEmergencyMode = false;
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "15s";
    RebootWatchdogSec = "30s";
  };
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # When the TPM won't unlock the disk (after a firmware update, say), the boot
  # stops at the passphrase. SSH in the initrd lets me type it from another machine
  # at home: `ssh -p 2222 root@<its LAN address>`, then `systemd-tty-ask-password-agent`.
  # It has a host key of its own, made at install (docs/home-server.md), because the
  # initrd sits unencrypted on the boot partition. Port 2222 keeps its key apart
  # from the real host's in known_hosts.
  boot.initrd = {
    systemd.network = {
      enable = true;
      networks."10-lan" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };
    };
    network.ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/persist/etc/ssh/initrd_ssh_host_ed25519_key" ];
      authorizedKeyFiles = [ ../../modules/nixos/authorized-keys ];
    };
  };

  home-manager.users.${username}.home.stateVersion = "26.05";

  system.stateVersion = "26.05";
}
