{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.zathura;
in
{
  options.apps.zathura = {
    enable = lib.mkEnableOption "Zathura document viewer";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        programs.zathura = {
          enable = true;
          # Add config if needed
        };
      };
    };
  };
}
