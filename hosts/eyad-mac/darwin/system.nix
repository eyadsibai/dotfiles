{ ... }: {

  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.24;
    autohide-time-modifier = 1.0;
    orientation = "bottom";
    show-recents = true;
    tilesize = 32;
  };

  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true;
    ShowStatusBar = true;
  };

  loginwindow = {
    GuestEnable = false;
    DisableConsoleAccess = false;
    SHOWFULLNAME = true;
  };

  trackpad = {
    ActuationStrength = 0;
    Clicking = true;
    Dragging = true;
  };

  keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  }



    }
