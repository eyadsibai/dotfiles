# Host configuration for eyad-m3 (macOS)
{
  imports = [
    ../../modules/nix
    ../../modules/host-and-users.nix
    ../../modules/shell
    ../../modules/dev
    ../../modules/apps
    # ../../modules/ai
    # ../../modules/services/default.nix
    # ../../modules/security/default.nix
    # ../../modules/virtualization/default.nix
    # ../../modules/desktop/default.nix
    ../../modules/darwin/default.nix
    ./module.nix
  ];

  # --- Set Custom Options for this Host ---
  # (all dynamic config using specialArgs is now in module.nix)

  nix = {
    allowUnfree = true;
    enableFlakes = true;
    gc = {
      automatic = true;
      deleteOlderThan = "7d";
    };
    optimise.automatic = true;
    darwin = {
      hostPlatform = "aarch64-darwin";
      nixbldGID = 30000;
    };
  };

  shell = {
    zsh.enable = true;
    nushell.enable = true;
    starship.enable = true;
    carapace.enable = true;
    cli-tools = {
      enable = true;
      enableEza = true;
      enableSkim = true;
      enableRipgrep = true;
      enableJq = true;
    };
    yazi.enable = true;
  };

  dev = {
    git = {
      enable = true;
      includeWorkConfig = true;
      delta.enable = true;
    };
    editors = {
      nixvim.enable = true;
      helix.enable = true;
      kakoune.enable = true;
    };
    tools = {
      direnv.enable = true;
      idea.enable = false;
    };
  };

  apps = {
    general = {
      enable = true;
      packages = [
        "cachix"
        "just"
        "timg"
        "gum"
        "oterm"
      ];
    };
    firefox.enable = false;
    micro.enable = true;
    htop.enable = true;
    tmux.enable = true;
    gnupg-agent = {
      enable = true;
      enableSSHSupport = true;
    };
    yt-dlp.enable = false;
    btop.enable = true;
    bat.enable = true;
    zathura.enable = true;
  };

  darwin = {
    sketchybar.enable = true;
    borders.enable = true;
    system-settings.enable = true;
    fonts.enable = true;
    security.enableTouchIdSudo = true;
    homebrew.enable = true;
    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      polarity = "dark";
    };
    system-packages.enable = true;
  };

  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.stateVersion = 5;
}
