{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ./networking.nix ./sound.nix];

  nix = {
    # Automate garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    package = pkgs.nixFlakes;

    settings = {
      auto-optimise-store = true;
      extra-experimental-features = [ "nix-command" "flakes" ];
    };

  };

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    cleanTmpDir = true;
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "acpi_osi=Linux" "acpi_backlight=none" ];
    kernelModules = [
      "fuse"
      "kvm-amd"
      "msr"
      "kvm-intel"
      "amdgpu"
      "acpi_call"
      "usbmon"
      "usbserial"
      "timer_stats"
    ];
  };

  # NOTE: required for the wireless card
  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };

  services.blueman.enable = true;
  systemd.coredump.enable = true;
  services.tlp.enable = true;

  # hardware.ledger.enable = true;

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;

  time.timeZone = "Asia/Riyadh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # services.xserver.layout = "en";
  # xkbOptions = "eurosign:e";

  services.usbmuxd.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.displayManager.gdm.wayland = false;

  # services.xserver.desktopManager.gnome.enable = true;

  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xterm.enable = true;

  services.gnome.gnome-keyring.enable = true;

  # Configure keymap in X11
  services.xserver.layout = "us,ar";

  services.xserver.xkbOptions = "grp:win_space_toggle";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };

    # virtualbox.host = {
    #   enable = true;
    #   enableExtensionPack = true;
    # };

    libvirtd.enable = false;
  };


  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  users.users.eyad = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "plugdev" ];
    hashedPassword =
      "$6$Yus5zggqZoBmm/2q$XCdVkAvX6.9TXnxotti5tUcAokV8u38tKwWbKg9HcJdpUohdsidOr32K/ER5wfhLJraUJQMeS6zqFBPu8MJQe/";
    openssh.authorizedKeys.keys = [
      # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    ];
  };

  environment.systemPackages = with pkgs; [ vim wget git ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  services.fwupd.enable = true;

  nixpkgs.config.allowUnfree = true;

  # List services that you want to enable:
  services.fstrim.enable = true;
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    # Use keys only. Remove if you want to SSH using password (not recommended)
    passwordAuthentication = false;
  };

  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;
    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      source-code-pro
      ubuntu_font_family
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
  };

  services.xserver.desktopManager.session = [{
    name = "HomeManager";
    start = ''
      ${pkgs.runtimeShell} $HOME/.hm-xsession &
      waitPID=$!
    '';
  }];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
