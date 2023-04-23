{ config
, options
, lib
, pkgs
, username
, ...
}:
with lib;

let
  cfg = config.modules.gaming.steam;
in
{
  options.modules.gaming.steam = {
    enable = lib.mkEnableOption "enable steam";

  };
  config = mkIf cfg.enable
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true;
        # Open ports in the firewall for Source Dedicated Server
      };
      home-manager.users.${username}.home.packages = mkIf config.programs.steam.enable [
        pkgs.steam-tui
        pkgs.steamPackages.steamcmd
        pkgs.steamPackages.steam-runtime
      ];

    };
}
