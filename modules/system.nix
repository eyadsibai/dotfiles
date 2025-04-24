{ config, pkgs, inputs, ... }:
{
  # Hardware config should be imported by the host config (e.g., hosts/workstation/default.nix)
  # imports = [
  #  ../hardware-configuration.nix
  # ];

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

  # Keyboard layout
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Home Manager settings merged from home/ directory
  # Shell/CLI parts moved to modules/shell/*
  # Home Manager user block is needed for HM module to function, but specific settings
  # like stateVersion are better set per-host or within feature modules.
  # This empty block might still be needed for the HM module to evaluate correctly across all features.
  home-manager.users.eyad = { pkgs, ... }: {
    # All specific HM settings moved to feature modules (shell, dev, etc.) or host config (stateVersion)
  };

  system.stateVersion = "23.11"; # System state version remains relevant here
}
