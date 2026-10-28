# Workstation: Intel desktop with an NVIDIA GPU, running GNOME.
{ username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "workstation";

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10; # boot-menu rollback targets
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # NVIDIA proprietary driver
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };
  hardware.nvidia-container-toolkit.enable = true;
  # No global nixpkgs.config.cudaSupport: it only rebuilt Firefox and btop. CUDA is
  # enabled per package instead (ollama-cuda in modules/nixos/ai.nix, btop in modules/home/cli.nix).

  hardware.steam-hardware.enable = true;

  # Act as Tailscale subnet router and exit node for the home LAN
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.extraSetFlags = [
    "--advertise-routes=192.168.50.0/24"
    "--accept-routes"
    "--advertise-exit-node"
  ];

  # TODO: document what listens on this port
  networking.firewall.allowedUDPPorts = [ 9200 ];

  home-manager.users.${username} = {
    imports = [
      ../../modules/home
      ../../modules/home/desktop-apps.nix
    ];
    home.stateVersion = "23.11";
  };

  system.stateVersion = "23.11";
}
