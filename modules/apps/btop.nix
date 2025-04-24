{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.btop;
in
{
  options.apps.btop = {
    enable = lib.mkEnableOption "btop resource monitor";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}".programs.btop = {
      enable = true;
      # Add config if needed
    };
  };
}
