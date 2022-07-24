{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.package = pkgs.nixFlakes;
  nix.settings = { auto-optimise-store = true; };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  nix = {
    # Automate garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
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

  networking = {
    hostName = "eyad-nixos";
    networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };
    wireless.enable = true; # Enables wireless support via wpa_supplicant.
    useDHCP = false; # deprecated
    interfaces = {
      enp3s0f0.useDHCP = true;
      wlp1s0.useDHCP = true;
    };
  };

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

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false;

  # services.xserver.desktopManager.gnome.enable = true;

  # services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xterm.enable = true;

  services.gnome.gnome-keyring.enable = true;

  # environment.gnome.excludePackages =
  #   (with pkgs; [ gnome-photos gnome-tour kgx ]) ++ (with pkgs.gnome; [
  #     cheese # webcam tool
  #     gnome-music
  #     gnome-terminal
  #     gedit # text editor
  #     epiphany # web browser
  #     geary # email reader
  #     evince # document viewer
  #     gnome-characters
  #     totem # video player
  #     tali # poker game
  #     iagno # go game
  #     hitori # sudoku game
  #     atomix # puzzle game
  #   ]);

  # services.xserver.windowManager.i3 = {
  #   enable = true;
  #   package = pkgs.i3-gaps;
  #   };

  # Configure keymap in X11
  services.xserver.layout = "us,ar";

  services.xserver.xkbOptions = "grp:win_space_toggle";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  #sound.enable = true;

  #hardware.pulseaudio = {
  # 	enable = true;
  # 	package = pkgs.pulseaudioFull;
  # };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

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

  services.pipewire = {
    #     config.pipewire = {
    #   "context.properties" = {
    #"link.max-buffers" = 64;
    #     "link.max-buffers" = 16; # version < 3 clients can't handle more than this
    #     "log.level" = 2; # https://docs.pipewire.org/page_daemon.html
    #"default.clock.rate" = 48000;
    #"default.clock.quantum" = 1024;
    #"default.clock.min-quantum" = 32;
    #"default.clock.max-quantum" = 8192;
    # };

    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.eyad = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "plugdev"
    ]; # Enable ‘sudo’ for the user.
    hashedPassword =
      "$6$Yus5zggqZoBmm/2q$XCdVkAvX6.9TXnxotti5tUcAokV8u38tKwWbKg9HcJdpUohdsidOr32K/ER5wfhLJraUJQMeS6zqFBPu8MJQe/";
    openssh.authorizedKeys.keys = [
      # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    # Forbid root login through SSH.
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];

  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}

