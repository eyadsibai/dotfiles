{ config
, options
, lib
, pkgs
, username
, ...
}:
with lib;

let
  cfg = config.modules.gaming;
in
{
  options.modules.gaming = {
    enable = lib.mkEnableOption "enable gaming";

  };
  config = mkIf cfg.enable
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true;
        # Open ports in the firewall for Source Dedicated Server
      
        gamescopeSession.enable = true;
      };
      
        programs.gamemode.enable = true;x

      home-manager.users.${username}.home.packages = mkIf config.programs.steam.enable [
        pkgs.steam-tui
        pkgs.steamPackages.steamcmd
        pkgs.steamPackages.steam-runtime
        mangohud
        protonup
        lutris
        heroic
        bottles
      ];

      home-manager.users.${username}.home.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATH = "\${HOME}/.steam/root/compatibilitytools.d";
      };

    };
}
