{ lib
, config
, pkgs
, ...
}: {
  services.redshift = {
    enable = false;
    provider = "geoclue2";
    settings = {
      redshift = {
        brightness-day = "1";
        brightness-night = "0.8";
      };
    };
    # latitude = "51.985104";
    # longitude = "5.898730";
    tray = false;
  };
}
