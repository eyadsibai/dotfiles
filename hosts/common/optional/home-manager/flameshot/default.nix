{ pkgs
, config
, ...
}:
let
  inherit (config.colorscheme) palette;
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
