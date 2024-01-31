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
        uiColor = "#${colors.base00}";
        showHelp = false;
      };
    };
  };
}
