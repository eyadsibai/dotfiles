{ lib, config, pkgs, ... }: {
  # services.redshift = {
  #   enable = false;
  #   settings = {
  #     redshift = {
  #       brightness-day = "1";
  #       brightness-night = "0.8";
  #     };

  #   };
  #   latitude = "51.985104";
  #   longitude = "5.898730";

  #   tray = false;
  # };

  # services.gammastep = {
  #   enable = true;
  #   provider = "geoclue2";
  #   # latitude = "51.985104";
  #   # longitude = "5.898730";
  # };

  services.caffeine.enable = true;

  services.clipmenu.enable = true;
  services.dropbox.enable = true;
  services.espanso.enable = true;
  services.flameshot.enable = true;
  # services.fusuma.enable = true;
  # services.git-sync.enable = true;
  services.gromit-mpx.enable = true;
  services.hound.enable = true;
  services.mopidy = {
    enable = true;
    extensionPackages =
      [ pkgs.mopidy-mpris pkgs.mopidy-soundcloud pkgs.mopidy-youtube ];
  };

  services.mpd.enable = true;
  services.mpdris2.enable = true;
  services.playerctld.enable = true;
  services.spotifyd.enable = true;
  services.sxhkd.enable = true;
  services.xcape.enable = true;
  # services.polybar.enable = true;
}
