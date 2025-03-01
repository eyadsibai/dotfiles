{ config, pkgs, ... }:
{


  imports =
    [
      # Include the results of the hardware scan.
      ../hardware-configuration.nix
    ];

  programs.zsh.enable = true;
  programs.nix-ld.enable = true;


  # Enable networking
  networking.networkmanager.enable = true;

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  # Set your time zone.
  # comment this due to the issue:
  #   https://github.com/LnL7/nix-darwin/issues/359
  # time.timeZone = "Asia/shanghai";


  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 4;
  boot.kernelPackages = pkgs.linuxPackages;

  boot.loader.efi.canTouchEfiVariables = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };


  services.xserver.videoDrivers = [ "nvidia" ];
  services.tailscale.enable = true;
  services.n8n.enable = true;
  services.n8n.openFirewall = true;

  services.ollama = {
    enable = false;
    acceleration = "cuda";
  };

  services.xrdp.enable = true;

  services.xrdp.openFirewall = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  networking.firewall.allowedTCPPorts = [
    3389
    # 9200 #elasticsearch
  ];
  networking.firewall.allowedUDPPorts = [ 9200 ];
  services.gnome.gnome-remote-desktop.enable = true;


  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("users")
          && (
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions"
          )
        )
      {
        return polkit.Result.YES;
      }
    })
  '';

  # hardware.logitech.wireless.enable = true;
  # hardware.logitech.wireless.enableGraphical = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    #    package = inputs.hyprland.packages."${pkgs.system}".hyprland;

  };


  hardware.nvidia = {

    # most wayland compositors need this
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    open = false;
    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # package = config.boot.kernelPackages.nvidiaPackages.beta;
  };



  # Set your time zone.
  time.timeZone = "Asia/Riyadh";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";


  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;


  virtualisation.docker.enable = true;
  # virtualisation.docker.enableNvidia = true; ## deprecated

  hardware.nvidia-container-toolkit.enable = true;
  users.extraGroups.docker.members = [ "eyad" ];
  users.extraGroups.libvirt.members = [ "eyad" ];





  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };


  environment.systemPackages = with pkgs; [
    docker-compose
    virt-manager
    virt-viewer
    spice
    spice-gtk
    win-virtio # for windows virtio drivers
    OVMF # UEFI firmware for qemu
  ];

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";

    xkb.variant = "";
  };


  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  # sound.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };


  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;


  # List services that you want to enable:


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  system.stateVersion = "23.11"; # Did you read the comment?

}
