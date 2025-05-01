{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.yazi;
in
{
  options.shell.yazi = {
    enable = lib.mkEnableOption "Yazi terminal file manager";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.yazi = {
          enable = true;
          # Add yazi config if needed
        };
      };
    };
  };
}
