{ config, pkgs, inputs, ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ../hardware-configuration.nix
  ];

  programs.zsh.enable = true;
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

  # Services
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.extraSetFlags = [
    "--advertise-routes=192.168.50.0/24" # allow routing traffic from other nodes to lan
    "--accept-routes" # route traffic to other lan
    "--advertise-exit-node" # allow allow routing traffic through this node
  ];

  services.n8n.enable = false;
  services.n8n.openFirewall = true;

  services.ollama = {
    enable = true;
    openFirewall = true;
    package = pkgs.ollama-cuda;
  };

  services.tika.enable = true;

  services.xrdp.enable = true;
  services.xrdp.openFirewall = true;

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [
    3389
  ];
  networking.firewall.allowedUDPPorts = [ 9200 ];

  # Security configuration
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

  # Virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      # OVMF images shipped with QEMU are now available by default
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  # Docker configuration
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  users.extraGroups.docker.members = [ "eyad" ];
  users.extraGroups.libvirt.members = [ "eyad" ];

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Common system packages
  # Moved to modules/apps.nix
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

  # Audio configuration
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      X11Forwarding = true;
    };
  };

  # Home Manager settings merged from home/ directory
  home-manager.users.eyad = { pkgs, ... }: {
    # Set state version (from original home/default.nix)
    home.stateVersion = "23.11";

    # From home/core.nix
    home.packages = with pkgs; [
      nnn # terminal file manager

      # archives
      zip
      xz
      unzip
      p7zip

      # utils
      ripgrep # recursively searches directories for a regex pattern
      jq # A lightweight and flexible command-line JSON processor
      yq-go # yaml processer https://github.com/mikefarah/yq
      fzf # A command-line fuzzy finder

      aria2 # A lightweight multi-protocol & multi-source command-line download utility
      socat # replacement of openbsd-netcat
      nmap # A utility for network discovery and security auditing

      # misc
      cowsay
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd
      caddy
      gnupg

      # productivity
      glow # markdown previewer in terminal
    ];

    programs = {
      # From home/core.nix
      eza = {
        enable = true;
        git = true;
        icons = "auto";
      };
      skim = {
        enable = true;
        enableBashIntegration = true;
      };

      # From home/shell.nix
      zsh = {
        enable = true;
        enableCompletion = true;
      };
      bash = {
        enable = true;
      };
      nushell = {
        enable = true;
      };
      carapace = {
        enable = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
      };

      # From home/starship.nix
      starship = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
        enableTransience = true;
        settings = {
          format = builtins.concatStringsSep "" [
            "$nix_shell"
            "$os"
            "$directory"
            "$container"
            "$git_branch $git_status"
            "$python"
            "$nodejs"
            "$lua"
            "$rust"
            "$java"
            "$c"
            "$golang"
            "$cmd_duration"
            "$status"
            "$line_break"
            "[❯](bold purple)"
            ''''${custom.space}''
          ];
          character = {
            success_symbol = "[›](bold green)";
            error_symbol = "[›](bold red)";
          };
          aws = {
            symbol = "🅰 ";
          };
          gcloud = {
            format = "on [$symbol$active(\($region\))]($style) ";
            symbol = "🅶 ️";
          };
        };
      };
    };
  };

  system.stateVersion = "23.11";
}
