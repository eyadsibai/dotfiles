{ config
, pkgs
, lib
, username
, ...
}:
let
  sysConfig = config;
  homeConfig = config.home-manager.users.${username};




in
{
  environment.systemPackages = with pkgs; [
    # spotify-player
  ];

  home-manager.users.${username} = {
    programs.kakoune.enable = true;

    home.packages = with pkgs; [
      # spotify-player
    ];

  };
}
