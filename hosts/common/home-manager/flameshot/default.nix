{ pkgs
, ...
}:
{
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
        uiColor = "#2d0096";
        showHelp = false;
      };
    };
  };
}
