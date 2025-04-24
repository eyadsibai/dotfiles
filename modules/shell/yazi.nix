{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.yazi;
in
{
  options.shell.yazi = {
    enable = lib.mkEnableOption "Yazi terminal file manager";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}".programs.yazi = {
      enable = true;
      # Add yazi config if needed
    };
  };
}
