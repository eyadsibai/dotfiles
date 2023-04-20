{ config, lib, pkgs, username, ... }:


let cfg = config.gaming.steam;
in {
  options.modules.gaming.steam = {
    enable = mkBoolOpt false;

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
      home-manager.users.${username}.home.packages = lib.mkIf config.programs.steam.enable [
        pkgs.steam-tui
        pkgs.steamPackages.steamcmd
        pkgs.steamPackages.steam-runtime
      ];

    };
}
