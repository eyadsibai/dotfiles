# vm-fusion: NixOS desktop VM in VMware Fusion on the Macs (modules/nixos/vm-guest.nix).
# Create the VM with a SATA disk (so it's /dev/sda), UEFI, 3D acceleration on, and
# boot it from the aarch64 NixOS ISO; then `just vm-install vm-fusion <ip>` on the Mac.
{ username, ... }:
{
  imports = [ ../../modules/nixos/vm-guest.nix ];

  networking.hostName = "vm-fusion";

  disko.devices.disk.main.device = "/dev/sda";

  # open-vm-tools: clipboard, resizing with the window, and the shared folders
  virtualisation.vmware.guest.enable = true;

  # Fusion's shared folders (Settings → Sharing), all of them under /host
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "nofail" # boot without it when sharing is off
    ];
  };

  home-manager.users.${username}.home.stateVersion = "26.05";

  system.stateVersion = "26.05";
}
