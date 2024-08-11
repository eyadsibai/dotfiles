{ pkgs
, config
, ...
}:
let
  palette = config.lib.stylix.colors;

in
{
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
        uiColor = "#${palette
.base00}";
        showHelp = false;
      };
    };
  };
}
