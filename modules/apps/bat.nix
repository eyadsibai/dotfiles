{ lib, config, pkgs, username, ... }:

let
  cfg = config.apps.bat;
in
{
  options.apps.bat = {
    enable = lib.mkEnableOption "bat (cat clone with syntax highlighting)";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}".programs.bat = {
      enable = true;
      # Add config if needed
    };
  };
}
