{ config, username, ... }: {
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      ApplePressAndHoldEnabled = false;
      NSWindowResizeTime = 0.001;
      AppleShowAllExtensions = true;

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
      mru-spaces = false;
      # Whether to automatically hide and show the Dock. Default is false.
      autohide = true;
      # Sets the speed of the autohide delay. Default is "0.24".
      autohide-delay = 0.0;
      # Sets the speed of animation when hiding/showing the Dock. Default is "1.0".
      autohide-time-modifier = 1.0;
      # Position of dock. Default is "bottom"; alternatives are "left" and "right".
      orientation = "bottom";
      # Whether to make icons of hidden applications translucent. Default is false.
      showhidden = true;
      # Show recent applications in the dock. Default is true.
      show-recents = false;
      # Show only open applications in the Dock. Default is false.
      static-only = false;
      # Size of the icons in the Dock. Default is 64.
      tilesize = 32;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      ShowStatusBar = true;
      QuitMenuItem = true; # I believe this probably will need to be true if using spacebar
      FXEnableExtensionChangeWarning = true;
      CreateDesktop = false;
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

  targets.darwin.dock = {
    # Apps to be added to Dock.
    apps = [
      "Visual Studio Code"
      # "iTerm2"
      "Slack"
    ];

    # "Others" section in Dock (the one after the bar, where the Bin sits).
    others = [
      ({ path = "/Applications"; })
      ({ path = "${config.users.users.${username}.home}/Downloads"; sort = "dateadded"; view = "fan"; })
    ];
  };
  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;
}
