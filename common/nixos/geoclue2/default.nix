{ config, lib, ... }:
let
  homeConfig = config.home-manager.users.eyad;
in
{
  services.geoclue2 = {
    enable = lib.mkDefault (
      (homeConfig.services.gammastep.enable or false) &&
      (homeConfig.services.gammastep.provider == "geoclue2")
    );

    enableWifi = true;
  };
}
