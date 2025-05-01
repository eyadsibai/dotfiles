{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.zsh;
  stdenv = pkgs.stdenv;
in
{
  options.shell.zsh = {
    enable = lib.mkEnableOption "Zsh shell configuration";
  };

  config = lib.mkIf cfg.enable {
    # System-level setting (if needed, though often handled by HM)
    # programs.zsh.enable = true; # This might conflict if HM also enables it

    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.zsh = {
          enable = true;
          enableCompletion = true;
          # Add initExtra for Darwin Homebrew compatibility
          initExtra = lib.mkIf stdenv.isDarwin ''
            if [[ $(uname -m) == 'arm64' ]]; then
             eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
          '';
          # Add other zsh settings here if needed
        };
      };
    };
  };
}
