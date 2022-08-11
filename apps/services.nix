{
  lib,
  config,
  pkgs,
  ...
}: {
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

  # services.caffeine.enable = true;

  services.clipmenu.enable = false;
  services.dropbox.enable = true;
  services.espanso.enable = false;
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
      };
    };
  };
  # services.fusuma.enable = true;
  # services.git-sync.enable = true;
  # services.gromit-mpx.enable = true;
  services.hound.enable = false;

  services.sxhkd.enable = true;
  services.xcape.enable = true;

  services.unclutter.enable = true;
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "never";
  };
}
