{ username, ... }: {

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      NSWindowResizeTime = 0.001;


      AppleFontSmoothing = 1;
      # Global macOS system settings
      KeyRepeat = 1;
      _HIHideMenuBar = true;
      InitialKeyRepeat = 25;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      "com.apple.mouse.tapBehavior" = 1;
      # "com.apple.swipescrolldirection" = true;
    };
    dock = {
      autohide = true;
      autohide-delay = 0.24;
      autohide-time-modifier = 1.0;
      orientation = "bottom";
      show-recents = true;
      showhidden = true;
      tilesize = 32;
      mru-spaces = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowStatusBar = true;
      QuitMenuItem = true; # I believe this probably will need to be true if using spacebar
      FXEnableExtensionChangeWarning = true;
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
    screencapture.location = "/Users/${username}/Downloads";
    LaunchServices = {
      # Disable the "Are you sure you want to open this application?" dialog
      LSQuarantine = false;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };
}
