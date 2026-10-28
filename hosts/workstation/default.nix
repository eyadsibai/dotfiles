# Workstation: Intel desktop with an NVIDIA GPU, running the Omarchy desktop.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
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

  # Stay on the default LTS kernel (nixarchy would default to the newest one):
  # fewer surprises with the NVIDIA driver on a machine that is often used remotely
  boot.kernelPackages = pkgs.linuxPackages;

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
    open = false; # closed driver: what this machine has always run; open modules also work on the 4090
    nvidiaSettings = true;
  };
  # Load the driver early (in the initrd) so the desktop starts on it straight away.
  # Gated on the driver being enabled, so `just vm` (no NVIDIA) still boots.
  boot.initrd.kernelModules = lib.mkIf config.hardware.nvidia.enabled [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

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

  # `just vm`: this configuration in a throwaway QEMU VM, to try desktop changes
  # before rebooting into them. No GPU passthrough, so the NVIDIA bits are off.
  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192;
      cores = 8;
      diskImage = null; # fresh state on every run
    };
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;
    services.ollama.enable = lib.mkForce false;
    services.sunshine.enable = lib.mkForce false;
    users.users.${username}.password = "vm"; # to unlock the lock screen
  };

  home-manager.users.${username} = {
    imports = [
      ../../modules/home
      ../../modules/home/desktop-apps.nix
      ../../modules/home/omarchy.nix
    ];
    home.stateVersion = "23.11";
  };

  system.stateVersion = "23.11";
}
