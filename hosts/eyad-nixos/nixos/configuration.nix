{ inputs
, config
, pkgs
, lib
, username
, hostname
, ...
}:
let
  homeConfig = config.home-manager.users.${username};
in
{
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd-pstate
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-laptop-ssd
    inputs.hardware.nixosModules.lenovo-thinkpad

    ./hardware-configuration.nix
    ./networking.nix
    ./audio.nix
    ./nix.nix
    ./steam.nix
    # ./fonts.nix
    ../../common/optional/nixos/samba
  ];

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
    kernelParams = [
      "acpi_osi=Linux"
      "acpi_backlight=none"
      "processor.max_cstate=4"
      "iommu=soft"
      "idle=nomwait"
      "tpm_tis.interrupts=0"
      # "initcall_blacklist=acpi_cpufreq_init"
    ];
    kernelModules = [
      "fuse"
      "kvm-amd"
      "msr"
      # "kvm-intel"
      # "amdgpu"
      "acpi_call"
      "usbmon"
      "usbserial"
      "timer_stats"
      # "amd-pstate"
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
  hardware.trackpoint.enable = true;
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
    powerOnBoot = true;
  };
  services.blueman.enable = true;
  systemd.coredump.enable = true;

  services.flatpak.enable = true;
  xdg.portal = {

    enable = true;
    # TODO add for i3
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # add xdg-desktopn-portal-wlr for wayland
  };
  services.tlp = {
    enable = !config.services.xserver.desktopManager.gnome.enable;
    settings = {
      USB_AUTOSUSPEND = 0;
      RUNTIME_PM_BLACKLIST = "05:00.3 04:00.3 04:00.4";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  services.upower.enable = true;
  # services.auto-cpufreq.enable = true;
  # services.logind.lidSwitch = "ignore"; # Laptop does not go to sleep when lid is closed
  # hardware.ledger.enable = true;
  # hardware.cpu.amd.updateMicrocode = true;
  hardware.enableAllFirmware = true;
  # time.timeZone = "Asia/Riyadh";
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
    # videoDrivers = [ "amdgpu" ];
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
    lxd.enable = true;
    # virtualbox.host = {
    #   enable = true;
    #   enableExtensionPack = true;
    # };
    libvirtd.enable = true;
    docker.rootless = {
      enable = false;
      setSocketVariable = true;
    };
  };
  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = false;
      disableWhileTyping = true;
    };
  };
  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups =
      [ "wheel" ]
      ++ (lib.optional config.virtualisation.docker.enable "docker")
      ++ (lib.optional config.virtualisation.podman.enable "podman")
      ++ (lib.optional config.virtualisation.libvirtd.enable "libvirtd")
      ++ (lib.optional config.programs.wireshark.enable "wireshark")
      ++ (lib.optional config.hardware.i2c.enable "i2c")
      ++ (lib.optional config.services.mysql.enable "mysql")
      ++ (lib.optional config.networking.networkmanager.enable "networkmanager");

    hashedPassword = "${config.secrets.${hostname}.passwd.${username}}";

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDeo6sUBHLNcMFePaungk359lteQLCaKyufYm7og8sYCuh50mWPcyTXqvMWURHLiGRMwrBg4re9JvMkYgCiSWowA5YOwhQdA460NWgBP7ctqHqE33v5/2/aNB/QngjcgrSUCsJfQTxNq6eqznkwdRc1b9JyyKL30TyGS8w8Cao+h+/pagI01SWpmUczIOmbS6R42gfAGcWd41/ZiHWGy3lNC22a/E9H4NFPu/G+n6BmHYTX8Z1Of3Etmk3e2gRybLpt/kt9sT/SawmVC4Y3YqUHRYc7Hua8RnpT35bYEAjVZcHqg2N4z9aYz1L8DA2qZJeLTbQlWfTERV46XaazUfASwnVEmUnV62UdEYvKWCpOFkn752dT/IE43BjrjscH5Vvk3ptIXrs/HjvaO9h6ghNccp3wz337eiqcY3sy89e6S56zNmNETDO5tNdrjSM031u9LJ/7leb540/xlBhcijwXlwgwEi1diOy8gNnV1kSY3MByyDgrN6QF2HUckaOOrhU= eyada@desktop"
      # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    ];
  };
  environment.systemPackages = with pkgs;
    [
      arion # support docker-compose ... etc
      docker-compose
      vim
      wget
      git
      # openvpn
      wine
      # native wayland support (unstable)
      # wineWowPackages.waylandFull
      dig
    ]
    ++ (lib.optional (!config.virtualisation.docker.enable) docker-client)
    ++ (lib.optional (config.virtualisation.podman.enable) podman-compose);
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  environment.enableAllTerminfo = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.fwupd.enable = true;
  nixpkgs.config.allowUnfree = true;

  # services.fstrim.enable = true;
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
      start = ''
        ${pkgs.runtimeShell} $HOME/.hm-xsession &
        waitPID=$!
      '';
    }
  ];

  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

  # No access time and continuous TRIM for SSD
  fileSystems."/".options = [ "noatime" "discard" ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    # Allow VS Code to watch more files
  };
  programs.dconf.enable = true;
  services.localtimed.enable = true;
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05";
  # Did you read the comment?
}
