{ lib, config, pkgs, ... }: {
  services.redshift = {
    enable = true;
    latitude = "51.985104";
    longitude = "5.898730";
    brightness.day = "1";
    brightness.night = "0.8";
    tray = false;
  };
}
