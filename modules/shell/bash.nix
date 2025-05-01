{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.bash;
in
{
  options.shell.bash = {
    enable = lib.mkEnableOption "Bash shell configuration";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.bash = {
          enable = true;
          # Add other bash settings here if needed
        };
      };
    };
  };
}
