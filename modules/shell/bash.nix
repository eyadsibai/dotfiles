{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.bash;
in
{
  options.shell.bash = {
    enable = lib.mkEnableOption "Bash shell configuration";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}" = {
      programs.bash = {
        enable = true;
        # Add other bash settings here if needed
      };
    };
  };
}
