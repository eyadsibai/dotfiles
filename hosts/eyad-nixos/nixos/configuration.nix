{ config
, pkgs
, lib
, ...
}:
let
  secrets = import ../../../secrets;
in
{
  imports = [ ./hardware-configuration.nix ./networking.nix ./sound.nix ./fonts.nix ./nix.nix ];

  # Thermals and cooling
  services.thermald.enable = true;
  boot = {
    loader.systemd-boot = {
      enable = true;
      # Bigger console font
      # consoleMode = "2";
      # Prohibits gaining root access by passing init=/bin/sh as a kernel parameter
      editor = false;
      # memtest86.enable = true;
    };
    plymouth.enable = true;
    loader.efi.canTouchEfiVariables = true;
    cleanTmpDir = true;
    supportedFilesystems = [ "ntfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "acpi_osi=Linux" "acpi_backlight=none" "processor.max_cstate=4" "iommu=soft" "idle=nomwait" "tpm_tis.interrupts=0" ];
    kernelModules = [
      "fuse"
      "kvm-amd"
      "msr"
      # "kvm-intel"
      "amdgpu"
      "acpi_call"
      "usbmon"
      "usbserial"
      "timer_stats"
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.addresses = true;
    publish.domain = true;
  };
  # NOTE: required for the wireless card
  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
  systemd.coredump.enable = true;

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # add xdg-desktopn-portal-wlr for wayland

  services.tlp = {
    enable = true;
    settings = {
      USB_AUTOSUSPEND = 0;
      RUNTIME_PM_BLACKLIST = "05:00.3 04:00.3 04:00.4";
    };
  };
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
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm.enable = true;
      gdm.enable = false;
      gdm.wayland = false;
    };
    videoDrivers = [ "amdgpu" ];
    desktopManager = {
      xterm.enable = false;
      gnome.enable = false;
    };
    layout = "us,ar";
    xkbOptions = "grp:win_space_toggle,eurosign:e";
  };
  services.usbmuxd.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gnome.core-utilities.enable = false;
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "127.0.0.1";
      };
    };
  };
  # this is required for mounting android phones over mtp://
  services.gvfs.enable = true;
  # Enable CUPS to print documents.
  services.printing.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.dnsname.enable = true;

    };
    # lxd.enable = true; # broken on unstable
    # virtualbox.host = {
    #   enable = true;
    #   enableExtensionPack = true;
    # };
    libvirtd.enable = false;
  };
  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  users.mutableUsers = false;
  users.users.eyad = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "podman" ];
    hashedPassword = secrets.eyad-nixos.passwd.eyad;

    openssh.authorizedKeys.keys = [
      # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    ];
  };
  environment.systemPackages =
    with pkgs;
    [
      arion # support docker-compose ... etc
      vim
      wget
      git
      # openvpn
      wine
      docker-client # not needed when virtualization.docker.enable = true;
      # podman-compose
      # support both 32- and 64-bit applications
      # wine64WowPackages.stable
      # support 32-bit only
      # wine64
      # support 64-bit only
      # (wine.override { wineBuild = "wine64"; })
      # wine-staging (version with experimental features)
      # wineWowPackages.staging
      # winetricks and other programs depending on wine need to use the same wine version
      # (winetricks.override { wine = wineWowPackages.staging; })
      # native wayland support (unstable)
      # wineWowPackages.waylandFull
    ];
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.fwupd.enable = true;
  nixpkgs.config.allowUnfree = true;
  # List services that you want to enable:
  services.fstrim.enable = true;
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    # Use keys only. Remove if you want to SSH using password (not recommended)
    passwordAuthentication = false;
    allowSFTP = true;
  };
  security.apparmor.enable = false;


  security.sudo.extraConfig = ''
    Defaults lecture = never
    Defaults  insults

  '';

  services.xserver.desktopManager.session = [
    {
      name = "HomeManager";
      start =
        ''
          ${ pkgs.runtimeShell } $HOME/.hm-xsession &
          waitPID=$!
        '';
    }
  ];
  # No access time and continuous TRIM for SSD
  fileSystems."/".options = [ "noatime" "discard" ];
  # Sysctl params
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    # Allow VS Code to watch more files
  };
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = [ pkgs.libvdpau-va-gl pkgs.vaapiVdpau pkgs.amdvlk pkgs.rocm-opencl-icd ];
  hardware.opengl.driSupport32Bit = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true;
    # Open ports in the firewall for Source Dedicated Server
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05";
  # Did you read the comment?
}