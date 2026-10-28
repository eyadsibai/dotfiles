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

  # Rootless Docker only: the daemon runs as the user, so no docker group (which is
  # root-equivalent) and no second daemon. GPU containers work through CDI:
  # `docker run --device nvidia.com/gpu=all ...`
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  # The rootful daemon's autoPrune has no rootless counterpart: same weekly cleanup
  # (stopped containers, unused networks, dangling images) as a user timer
  systemd.user.services.docker-prune = {
    description = "Prune the rootless Docker daemon";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    environment.DOCKER_HOST = "unix://%t/docker.sock";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker system prune -f";
    };
  };
  systemd.user.timers.docker-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
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
