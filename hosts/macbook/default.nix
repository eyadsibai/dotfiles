{ inputs, system, specialArgs, pkgs, ... }: # Added pkgs

let
  username = specialArgs.username; # Get username from specialArgs
in
{
  # Import shared modules
  imports = [
    ../../modules/nix/default.nix # Core Nix settings
    ../../modules/host-users.nix # Shared host/user settings
    ../../modules/shell/default.nix
    ../../modules/dev/default.nix
    ../../modules/apps/default.nix
    ../../modules/ai/default.nix
    # ../../modules/services/default.nix # Linux-specific
    # ../../modules/security/default.nix # Linux-specific
    # ../../modules/virtualization/default.nix # Linux-specific
    # ../../modules/desktop/default.nix # Linux-specific

    # Darwin-specific modules
    ../../modules/darwin/default.nix # Imports sketchybar, borders, system-settings etc.

    # Home Manager darwin module itself
    inputs.home-manager.darwinModules.home-manager
  ];

  # Basic Darwin System Settings (Most moved to modules/darwin/*)
  # users.users.${username}.home = "/Users/${username}"; # HM handles this now
  # system.stateVersion = 5; # Set below

  # Home Manager Configuration for this host
  home-manager.useUserPackages = true; # From original Darwin flake
  home-manager.extraSpecialArgs = specialArgs; # From original Darwin flake
  home-manager.backupFileExtension = "bak"; # From original Darwin flake
  home-manager.users.${username} = {
    # HM settings are imported via the feature modules above

    # Set HM state version and home directory
    home.stateVersion = "23.11"; # Match the NixOS host
    home.homeDirectory = "/Users/${username}"; # Correct home for macOS
  };

  # --- Set Custom Options for this Host ---

  # Nix settings (using shared module)
  nix = {
    allowUnfree = true;
    enableFlakes = true;
    gc = {
      automatic = true;
      deleteOlderThan = "7d";
    };
    optimise.automatic = true; # From Darwin core
    darwin = { # Darwin specific settings
      hostPlatform = "aarch64-darwin"; # From Darwin core
      nixbldGID = 30000; # From Darwin core
    };
  };

  # Shell settings (enable features used in Darwin config)
  shell = {
    zsh.enable = true;
    nushell.enable = true;
    starship.enable = true;
    carapace.enable = true;
    cli-tools = {
      enable = true;
      enableEza = true;
      enableSkim = true;
      enableRipgrep = true; # From Darwin apps.nix
      enableJq = true; # From Darwin apps.nix
    };
    yazi.enable = true; # From Darwin shell.nix
  };

  # Dev settings (enable features used in Darwin config)
  dev = {
    git = {
      enable = true;
      includeWorkConfig = true; # From Darwin git.nix
      delta.enable = true; # From Darwin git.nix
    };
    editors = {
      nixvim.enable = true;
      helix.enable = true;
      kakoune.enable = true;
    };
    # languages.java.enable = false;
    tools = {
      direnv.enable = true;
      # make.enable = false;
      # devbox.enable = false;
      idea.enable = false; # Managed by Homebrew Cask on Darwin
      # nix.enable = false;
    };
    # envfs.enable = false;
  };

  # Apps settings (enable features used in Darwin config, disable overlaps with Homebrew)
  apps = {
    general = {
      enable = true;
      # Override default packages to remove those handled by Homebrew Cask
      packages = with pkgs; [
        cachix
        just
        timg
        gum
        oterm
        # spotify # Managed by Homebrew Cask
        # ghostty # Managed by Homebrew Cask
        quickemu
      ];
    };
    # system.enable = false;
    firefox.enable = false; # Managed by Homebrew Cask
    micro.enable = true;
    htop.enable = true;
    tmux.enable = true;
    gnupg-agent = { # Keep gnupg agent via HM
      enable = true;
      enableSSHSupport = true;
    };
    yt-dlp.enable = false; # Managed by Homebrew Brew
    btop.enable = true;
    bat.enable = true;
    zathura.enable = true;
  };

  # AI settings (disable features not used in Darwin config)
  # ai = {
  #   lmstudio.enable = false;
  #   ollama.enable = false; # No Ollama in original Darwin config
  # };

  # Darwin specific settings
  darwin = {
    sketchybar.enable = true;
    borders.enable = true;
    system-settings.enable = true;
    fonts.enable = true;
    security.enableTouchIdSudo = true;
    homebrew.enable = true;
    stylix = {
      enable = true;
      image = ../../config/darwin/wallpaper.png; # Assuming wallpaper is copied here
      polarity = "dark";
    };
    system-packages.enable = true; # Enable Darwin system packages
  };

  # Ensure nix-darwin sets the hostname if not done elsewhere
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 5; # Set state version from original Darwin config

  # Set hostname (can be overridden by a module if needed)
  networking.hostName = specialArgs.hostname;
}
