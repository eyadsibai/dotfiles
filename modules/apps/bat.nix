{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.bat;
in
{
  options.apps.bat = {
    enable = lib.mkEnableOption "bat (cat clone with syntax highlighting)";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.bat = {
          enable = true;
          # Add config if needed
        };
      };
    };
  };
}
