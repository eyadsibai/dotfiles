# vm-utm: NixOS desktop VM in UTM on the Macs (modules/nixos/vm-guest.nix).
# Create the VM with the QEMU backend (Virtualize → Linux, not "Use Apple
# Virtualization"), a VirtIO disk (/dev/vda), and boot it from the aarch64 NixOS
# ISO; then `just vm-install vm-utm <ip>` on the Mac.
{ modulesPath, username, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../modules/nixos/vm-guest.nix
  ];

  networking.hostName = "vm-utm";

  # SPICE: clipboard sharing and resizing with the window
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # UTM's 3D acceleration doesn't work for this guest (as in Mitchell's config):
  # draw with the CPU rather than show a black screen
  environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

  # UTM's shared directory (VM settings → Sharing, "VirtFS"), under /host. Files
  # keep the Mac's owner id (501), so they show up owned by a number here.
  fileSystems."/host" = {
    device = "share";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "msize=104857600"
      "nofail" # boot without it when sharing is off
    ];
  };

  home-manager.users.${username}.home.stateVersion = "26.05";

  system.stateVersion = "26.05";
}
