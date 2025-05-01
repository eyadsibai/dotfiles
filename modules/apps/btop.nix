{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.btop;
in
{
  options.apps.btop = {
    enable = lib.mkEnableOption "btop resource monitor";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.btop = {
          enable = true;
          # Add config if needed
        };
      };
    };
  };
}
