{ config, pkgs, lib, ... }:

let
  gamingCfg = config.services.gaming;
in
{
  # No new options are defined here, but could be if Steam-specific options were needed.
  # options = { services.gaming.steam = { ... }; };

  config = lib.mkIf gamingCfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [ proton-ge-bin steamtinkerlaunch ];
    };

    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };

    environment.systemPackages = with pkgs; [
      steamtinkerlaunch # Already in extraCompatPackages but good to be explicit if used standalone
      mangohud
      protonup
      protontricks
      steam-rom-manager
    ];
  };
}
