{ pkgs, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  virtualisation.docker = {
    enable = true;
    # Remove stopped containers, unused networks and dangling images weekly
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    docker-compose
    virt-viewer
    spice
    spice-gtk
    virtio-win # Windows guest drivers
    OVMF # UEFI firmware for QEMU
    quickemu
  ];
}
