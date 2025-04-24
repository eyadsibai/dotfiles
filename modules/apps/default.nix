{ lib, config, pkgs, username, ... }:

{
  # This module replaces the old top-level modules/apps.nix
  # It imports specific application modules.

  imports = [
    ./yt-dlp.nix
    ./btop.nix
    ./bat.nix
    ./zathura.nix
    # Import other app modules here as they are created
  ];

  options.apps = {
    # Options are defined in imported files
    # e.g., apps.yt-dlp.enable, apps.btop.enable, etc.

    # Option for general HM packages from the old apps.nix
    general = {
      enable = lib.mkEnableOption "General Home Manager packages from old apps.nix";
      packages = lib.mkOption {
        type = with lib.types; listOf package;
        default = with pkgs; [
          # CLI/TUI Tools without specific programs.* modules
          cachix
          just
          timg
          gum
          oterm
          # GUI Apps without specific programs.* modules
          spotify
          ghostty # Primarily terminal, but often used like a GUI app
          quickemu
        ];
        description = "List of general packages to install via Home Manager.";
      };
    };

    # Option for general system packages from the old apps.nix
    system = {
      enable = lib.mkEnableOption "General system packages from old apps.nix";
      packages = lib.mkOption {
        type = with lib.types; listOf package;
        default = with pkgs; [
          # Keep system packages that remained after moving others to HM
          # (Currently empty based on last edit, but good structure to have)
          # Example: some_system_only_app
        ];
        description = "List of general packages to install system-wide.";
      };
    };

    # Option for firefox (moved from old apps.nix)
    firefox = {
      enable = lib.mkEnableOption "Firefox browser";
    };
    # Option for micro (moved from old apps.nix)
    micro = {
      enable = lib.mkEnableOption "Micro editor";
    };
    # Option for htop (moved from old apps.nix)
    htop = {
      enable = lib.mkEnableOption "htop process viewer";
    };
    # Option for tmux (moved from old apps.nix)
    tmux = {
      enable = lib.mkEnableOption "tmux terminal multiplexer";
    };
    # Option for gnupg agent (moved from old apps.nix)
    gnupg-agent = {
      enable = lib.mkEnableOption "GnuPG Agent";
      enableSSHSupport = lib.mkEnableOption "GnuPG Agent SSH Support";
    };

  };

  config = {
    # Configure based on options
    home-manager.users."${username}".home.packages = lib.mkIf config.apps.general.enable config.apps.general.packages;
    environment.systemPackages = lib.mkIf config.apps.system.enable config.apps.system.packages;

    home-manager.users."${username}".programs = {
      firefox.enable = lib.mkIf config.apps.firefox.enable true;
      micro.enable = lib.mkIf config.apps.micro.enable true;
      htop.enable = lib.mkIf config.apps.htop.enable true;
      tmux.enable = lib.mkIf config.apps.tmux.enable true;
      gnupg.agent = lib.mkIf config.apps.gnupg-agent.enable {
        enable = true;
        enableSSHSupport = config.apps.gnupg-agent.enableSSHSupport;
      };
    };
  };
}
