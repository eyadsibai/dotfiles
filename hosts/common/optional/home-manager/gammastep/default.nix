{ lib
, config
, pkgs
, ...
}: {
  services.gammastep = {
    enable = false;
    provider = "geoclue2";
    # latitude = "51.985104";
    # longitude = "5.898730";
  };
}
