{ config, pkgs, inputs, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ../hardware-configuration.nix
  ];

  # programs.zsh.enable = true; # Moved to modules/shell/zsh.nix
  programs.nix-ld.enable = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Disable sleep targets
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Set your time zone.
  time.timeZone = "Asia/Riyadh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.kernelPackages = pkgs.linuxPackages;
  boot.loader.efi.canTouchEfiVariables = true;

  # Hardware configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Services -> Moved to modules/services/* and modules/ai/ollama.nix
  # services.tailscale = { ... };
  # services.n8n = { ... };
  # services.ollama = { ... }; # Moved to modules/ai/ollama.nix
  # services.tika.enable = true;
  # services.xrdp = { ... };

  # Firewall configuration -> Moved to modules/security/firewall.nix
  # networking.firewall.allowedTCPPorts = [ ... ]; # Handled by service modules or firewall.nix
  # networking.firewall.allowedUDPPorts = [ 9200 ]; # Moved to firewall.nix

  # Security configuration -> Moved to modules/security/polkit.nix
  # security.polkit.enable = true;
  # security.polkit.extraConfig = '' ... '';

  # Nvidia configuration
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };

  hardware.steam-hardware.enable = true;

  # Virtualization -> Moved to modules/virtualization/*
  # virtualisation.libvirtd = { ... };
  # programs.virt-manager.enable = true;
  # virtualisation.docker.enable = true;
  # hardware.nvidia-container-toolkit.enable = true;
  # users.extraGroups.docker.members = [ "eyad" ]; # Handled in docker.nix
  # users.extraGroups.libvirt.members = [ "eyad" ]; # Handled in libvirt.nix
  # virtualisation.docker.rootless = { ... };

  # Common system packages
  # Moved to modules/apps.nix or modules/virtualization/*
  # environment.systemPackages = with pkgs; [
  #   docker-compose
  #   virt-manager
  #   virt-viewer
  #   spice
  #   spice-gtk
  #   win-virtio # for windows virtio drivers
  #   OVMF # UEFI firmware for qemu
  # ];

  # Keyboard layout
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Audio configuration -> Moved to modules/services/pipewire.nix
  # services.pulseaudio.enable = false;
  # security.rtkit.enable = true; # Moved to pipewire.nix
  # services.pipewire = { ... };

  # SSH server -> Moved to modules/services/openssh.nix
  # services.openssh = { ... };

  # Home Manager settings merged from home/ directory
  # Shell/CLI parts moved to modules/shell/*
  home-manager.users.eyad = { pkgs, ... }: {
    # Set state version (from original home/default.nix)
    home.stateVersion = "23.11";

    # Packages and programs from old home/core.nix and home/shell.nix
    # are now managed in modules/shell/cli-tools.nix, modules/shell/zsh.nix, etc.
    # home.packages = [ ... ];
    # programs = { ... };
  };

  system.stateVersion = "23.11";
}
