{ lib, config, pkgs, username, ... }:

let
  cfg = config.virtualization.libvirt;
in
{
  options.virtualization.libvirt = {
    enable = lib.mkEnableOption "Libvirt/QEMU/KVM virtualization";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
        swtpm.enable = true;
      };
    };

    programs.virt-manager.enable = true;

    # Add user to libvirt group
    users.extraGroups.libvirt.members = [ username ];

    # Install related packages
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      win-virtio # for windows virtio drivers
      OVMF # UEFI firmware for qemu
    ];
  };
}
