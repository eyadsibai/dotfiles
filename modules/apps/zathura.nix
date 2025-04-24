{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.zathura;
in
{
  options.apps.zathura = {
    enable = lib.mkEnableOption "Zathura document viewer";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}".programs.zathura = {
      enable = true;
      # Add config if needed
    };
  };
}
