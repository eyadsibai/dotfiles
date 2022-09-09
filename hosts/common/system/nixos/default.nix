{ config
, pkgs
, lib
, username
, is-laptop
, ...
}:
let
  homeConfig = config.home-manager.users.${username};
in
{
  imports = [ ../. ];
  services.locate.enable = true;
  services.geoclue2 = {
    enable =
      lib.mkDefault
        (
          ((homeConfig.services.gammastep.enable or false)
          && (homeConfig.services.gammastep.provider == "geoclue2"))
          || ((homeConfig.services.redshift.enable or false)
          && (homeConfig.services.redshift.provider == "geoclue2"))
          || (config.services.localtimed.enable or false)
        );
    enableWifi = true;
  };

  services.tlp = {
    enable = is-laptop;
    settings = {
      USB_AUTOSUSPEND = 0;
    };
  };
}
