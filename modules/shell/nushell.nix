{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.nushell;
in
{
  options.shell.nushell = {
    enable = lib.mkEnableOption "Nushell configuration";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.nushell = {
          enable = true;
          # Add other nushell settings here if needed
        };
      };
    };
  };
}
