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
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/sunshine.nix
    ../../modules/nixos/virtualisation.nix
    ../../modules/nixos/ai.nix
  ];

  # Used remotely as much as at the desk: boot into the (locked) desktop so
  # Sunshine and gliff have a session, and never sleep
  my.desktop.autoLogin = true;
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Claude Code and codex come from their own installers in ~/.local/bin (modules/home/dev.nix);
  # drover starts seats over non-interactive ssh, whose PATH lacks it otherwise
  environment.localBinInPath = true;

  # 32 threads: up to 16 builds at once, 8 cores each. Most builds are tiny
  # (config files, wrappers), so many in parallel keeps the CPU busy; the rare
  # big compiles running together can oversubscribe, which 125 GB of RAM absorbs
  nix.settings.max-jobs = 16;
  nix.settings.cores = 8;

  networking.hostName = "workstation";

  # drover on cachy sends jobs here; set on this host only, unlike ./authorized-keys
  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDNAozUFBcNsBtpix+4MDs4DOal2M6iGWIAKe3vpmuCm drover@cachy -> workstation"
  ];

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
  # That makes each initrd about 205 MB (the driver's firmware comes along), and the
  # 511 MB ESP holds only two. Stale kernels are removed before new ones are written,
  # so keeping two generations leaves room for a kernel bump; three would not.
  boot.loader.systemd-boot.configurationLimit = 2;

  hardware.nvidia-container-toolkit.enable = true;
  # No global nixpkgs.config.cudaSupport: it only rebuilt Firefox and btop. CUDA is
  # enabled per package instead (ollama-cuda in modules/nixos/ai.nix, btop below).

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
    home.packages = [ pkgs.lmstudio ];
    # The Firefox profile that already holds this machine's history, logins and tabs
    programs.firefox.profiles.default.path = "go1slwu4.default-1734374689132";
    # System monitor with the NVIDIA GPU panel
    programs.btop.package = pkgs.btop.override { cudaSupport = true; };
    home.stateVersion = "23.11";
  };

  system.stateVersion = "23.11";
}
