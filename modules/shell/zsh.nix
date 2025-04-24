{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.zsh;
in
{
  options.shell.zsh = {
    enable = lib.mkEnableOption "Zsh shell configuration";
  };

  config = lib.mkIf cfg.enable {
    # System-level setting (if needed, though often handled by HM)
    # programs.zsh.enable = true; # This might conflict if HM also enables it

    home-manager.users."${username}" = {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        # Add other zsh settings here if needed
      };
    };
  };
}
