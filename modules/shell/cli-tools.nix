{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.cli-tools;
in
{
  options.shell.cli-tools = {
    enable = lib.mkEnableOption "Core CLI tools (nnn, archives, utils, misc, glow)";
    enableEza = lib.mkEnableOption "eza (ls replacement)";
    enableSkim = lib.mkEnableOption "skim (grep replacement)";
    enableRipgrep = lib.mkEnableOption "ripgrep program (completions, etc)";
    enableJq = lib.mkEnableOption "jq program (completions, etc)";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
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
          eza = lib.mkIf cfg.enableEza {
            enable = true;
            git = true;
            icons = "auto";
          };
          skim = lib.mkIf cfg.enableSkim {
            enable = true;
            enableBashIntegration = true; # Consider making conditional
          };
          # Enable programs for completions etc.
          ripgrep = lib.mkIf cfg.enableRipgrep {
            enable = true;
          };
          jq = lib.mkIf cfg.enableJq {
            enable = true;
          };
        };
      };
    };
  };
}
