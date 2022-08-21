{ ... }: {

  system.defaults = {
    NSGlobalDomain = {
      # Global macOS system settings
      KeyRepeat = 1;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    dock = {
      autohide = true;
      autohide-delay = "0.24";
      autohide-time-modifier = "1.0";
      orientation = "bottom";
      show-recents = true;
      showhidden = true;
      tilesize = 32;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowStatusBar = true;
      QuitMenuItem = false; # I believe this probably will need to be true if using spacebar
    };

    loginwindow = {
      GuestEnabled = false;
      DisableConsoleAccess = false;
      SHOWFULLNAME = true;
    };

    trackpad = {
      ActuationStrength = 0;
      Clicking = true;
      Dragging = true;
      TrackpadRightClick = true;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
}
