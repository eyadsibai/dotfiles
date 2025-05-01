{ inputs, system, pkgs, specialArgs, ... }: {
  imports = [
    # Import host-specific hardware configuration
    ./hardware-configuration.nix

    # Import shared modules
    # ../../modules/nix-core.nix # Replaced by modules/nix/default.nix
    ../../modules/nix/default.nix # Core Nix settings
    ../../modules/system.nix # Will be cleaned up later
    ../../modules/shell/default.nix # Shell, prompt, CLI tools
    ../../modules/host-users.nix
    # ../../modules/apps.nix # Replaced by modules/apps/default.nix
    ../../modules/apps/default.nix # General application config
    # ../../modules/coding.nix # Replaced by dev module
    ../../modules/dev/default.nix # Development tools/languages
    ../../modules/virtualization/default.nix # Virtualization (Docker, Libvirt)
    ../../modules/services/default.nix # System services
    ../../modules/security/default.nix # Firewall, Polkit
    ../../modules/ai/default.nix # AI tools (lmstudio, ollama)

    # Desktop Environment Selection
    ../../modules/desktop/default.nix

    # Home Manager module itself
    inputs.home-manager.nixosModules.home-manager
    {
      # Configure HM options here if needed globally,
      # user-specific settings are now in respective modules.
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
      home-manager.extraSpecialArgs = specialArgs; # Pass specialArgs down
    }

    # Other modules
    inputs.nix-index-database.nixosModules.nix-index
    { programs.nix-index-database.comma.enable = true; }
  ];

  # Set hostname (can also be done in modules/host-users.nix if preferred)
  networking.hostName = specialArgs.hostname;

  # Set system state version
  system.stateVersion = "23.11"; # Or your desired version

  # --- Set Custom Options ---
  desktop.environment = "gnome"; # Set the desired desktop environment

  # Enable desired development features
  dev = {
    git = {
      enable = true;
      includeWorkConfig = true; # Assuming you want this enabled
      delta.enable = true; # Assuming you want delta enabled (was true in Darwin)
    };
    editors.nixvim.enable = true; # Updated path
    languages.java.enable = true;
    tools.direnv.enable = true;
    tools.nix.enable = true;
    tools.make.enable = true;
    tools.devbox.enable = true;
    tools.idea.enable = true;
    envfs.enable = true;
  };

  # Enable desired shell/CLI features
  shell = {
    zsh.enable = true;
    bash.enable = true;
    nushell.enable = true;
    starship.enable = true;
    carapace.enable = true;
    cli-tools = {
      enable = true; # Enable the core tool packages
      enableEza = true;
      enableSkim = true;
    };
  };

  # Set Home Manager state version for this user on this host
  home-manager.users.eyad.home.stateVersion = "23.11";

  # Enable desired virtualization features
  virtualization = {
    libvirt.enable = true;
    docker = {
      enable = true;
      rootless.enable = true;
      nvidiaToolkit.enable = true;
    };
  };

  # Enable desired services
  services = {
    tailscale.enable = true;
    n8n = {
      enable = false; # Keep previous setting
      openFirewall = true;
    };
    tika.enable = true;
    xrdp = {
      enable = true;
      openFirewall = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = false; # Assuming JACK not needed unless specified
    };
    openssh = {
      enable = true;
      passwordAuthentication = true; # Keep previous setting
      x11Forwarding = true; # Keep previous setting
    };
  };

  # Enable desired AI features
  ai = {
    lmstudio.enable = true; # From previous step
    ollama = {
      enable = true;
      openFirewall = true;
      acceleration = "cuda"; # Keep previous setting
    };
  };

  # Enable desired security features
  security = {
    firewall = {
      enable = true;
      # extraAllowedTCPPorts = []; # Add ports not handled by service modules if needed
      extraAllowedUDPPorts = [ 9200 ]; # Keep existing UDP port
    };
    polkit = {
      enable = true;
      allowUserPowerManagement = true; # Keep existing rule enabled
    };
  };

  # Configure Nix settings for this host
  nix = {
    allowUnfree = true;
    enableFlakes = true;
    gc = {
      automatic = true;
      deleteOlderThan = "7d";
    };
    optimise.automatic = true;
    linux = {
      # Linux specific settings
      sandbox = true;
      cudaSupport = true;
      keepOutputs = true;
      keepDerivations = true;
      maxJobs = 32;
      cores = 0;
      substituters = [
        "https://cache.nixos.org/"
        "https://ai.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trustedPublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # Enable desired apps features
  apps = {
    general.enable = true; # Enable the general HM packages
    system.enable = true; # Enable the general system packages (currently none)
    firefox.enable = true;
    micro.enable = true;
    htop.enable = true;
    tmux.enable = true;
    gnupg-agent = {
      enable = true;
      enableSSHSupport = true;
    };
    # Enable apps from Darwin config
    yt-dlp.enable = true;
    kakoune.enable = true; # Note: Also enabling helix and nixvim in dev section
    btop.enable = true;
    bat.enable = true;
    zathura.enable = true;
  };
}
