{ config
, pkgs
, lib
, username
, ...
}: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true;
    # Open ports in the firewall for Source Dedicated Server
  };

  # programs.gamemode.enable = true;

  home-manager.users.${username}.home.packages = [
    pkgs.steam-tui
    pkgs.steamPackages.steamcmd
    pkgs.steamPackages.steam-runtime
  ];
}
