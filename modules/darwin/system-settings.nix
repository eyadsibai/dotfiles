{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.system-settings;
in
{
  options.darwin.system-settings = {
    enable = lib.mkEnableOption "Apply common macOS system defaults and settings";
    # Add more granular options later if needed
  };

  # Define config unconditionally
  config = {
    # Use lib.mkIf for non-list attributes
    system.defaults = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      # From Darwin system.nix
      menuExtraClock.Show24Hour = true;
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        show-recents = false;
        orientation = "bottom";
        show-process-indicators = false;
        static-only = true;
        wvous-tl-corner = 1; # Disabled
        wvous-tr-corner = 1; # Disabled
        wvous-bl-corner = 1; # Disabled
        wvous-br-corner = 1; # Disabled
        tilesize = 32;
        dashboard-in-overlay = true;
        mru-spaces = false;
        launchanim = false;
      };
      finder = {
        _FXShowPosixPathInTitle = true;
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        AppleShowAllFiles = true;
        CreateDesktop = false; # Don't show items on desktop
        FXDefaultSearchScope = "SCcf";
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
        ActuationStrength = 0; # Silent clicking
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        "com.apple.swipescrolldirection" = false; # Disable natural scrolling
        "com.apple.sound.beep.feedback" = 0;
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3; # Full keyboard access
        ApplePressAndHoldEnabled = true; # Enable press and hold key repeat
        InitialKeyRepeat = 15;
        KeyRepeat = 3;
        NSScrollAnimationEnabled = true; # Smooth scrolling
        _HIHideMenuBar = true; # Autohide menu bar
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;
        AppleTemperatureUnit = "Celsius";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        NSDocumentSaveNewDocumentsToCloud = false;
        AppleICUForce24HourTime = true;
        AppleShowAllFiles = true; # Show hidden files
        "com.apple.keyboard.fnState" = false; # Use F-keys as standard function keys
        "com.apple.sound.beep.volume" = 0.0;
      };
      spaces.spans-displays = true; # Span space across displays
      loginwindow = {
        GuestEnabled = false;
        SHOWFULLNAME = true;
      };
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
      alf.allowdownloadsignedenabled = 1; # Allow signed apps downloaded from the internet

      # Custom preferences from Darwin system.nix
      CustomUserPreferences = {
        ".GlobalPreferences".AppleSpacesSwitchOnActivate = true;
        NSGlobalDomain.WebKitDeveloperExtras = true; # Enable web inspector
        "com.apple.finder" = {
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXSortFoldersFirst = true;
          FXDefaultSearchScope = "SCcf";
        };
        "com.apple.desktopservices" = {
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };
        "com.apple.spaces"."spans-displays" = 0; # Override: Displays have separate spaces
        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0;
          StandardHideDesktopIcons = 0; # Override: Show desktop icons
          HideDesktop = 0; # Override: Show desktop icons
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };
        "com.apple.screensaver" = {
          askForPassword = 1;
          askForPasswordDelay = 0;
        };
        "com.apple.screencapture" = {
          location = "~/Downloads";
          type = "png";
        };
        "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
        "com.apple.ImageCapture".disableHotPlug = true; # Prevent Photos auto-launch
      };
    };

    # Keyboard settings from Darwin system.nix
    system.keyboard = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      enableKeyMapping = true;
      remapCapsLockToControl = false;
      remapCapsLockToEscape = true; # CapsLock -> Escape
      swapLeftCommandAndLeftAlt = false;
    };

    # Enable system-wide zsh integration (from Darwin system.nix)
    programs.zsh.enable = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) true;
    environment.shells = lib.optionals (cfg.enable && pkgs.stdenv.isDarwin) [ pkgs.zsh pkgs.nushell ]; # Add shells to system list
  };
}
