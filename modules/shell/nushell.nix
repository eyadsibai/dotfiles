{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.nushell;
in
{
  options.shell.nushell = {
    enable = lib.mkEnableOption "Nushell configuration";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}" = {
      programs.nushell = {
        enable = true;
        # Add other nushell settings here if needed
      };
    };
  };
}
