# macOS defaults, keyboard, security and fonts.
# Option reference: https://nix-darwin.github.io/nix-darwin/manual/
# More `defaults` keys: https://github.com/yannbertrand/macos-defaults
{ pkgs, ... }:
let
  # Redirected to localhost via /etc/hosts
  blockedHosts = [ "apresolve.spotify.com" ];
in
{
  security.pam.services.sudo_local.touchIdAuth = true;
  security.sudo.extraConfig = "%admin ALL = (ALL) NOPASSWD: ALL";

  # Raise the file descriptor limit to 524288
  environment.launchDaemons."limit.maxfiles.plist" = {
    enable = true;
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
      "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      <key>Label</key>
      <string>limit.maxfiles</string>
      <key>ProgramArguments</key>
      <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>524288</string>
      <string>524288</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>ServiceIPC</key>
      <false/>
      </dict>
      </plist>
    '';
  };

  # Activation runs as root; only postActivation (not a custom name) is executed.
  # Append each entry once instead of on every switch.
  system.activationScripts.postActivation.text = builtins.concatStringsSep "\n" (
    map (host: ''
      grep -qxF "127.0.0.1 ${host}" /etc/hosts || echo "127.0.0.1 ${host}" >> /etc/hosts
    '') blockedHosts
  );

  # Allow downloaded signed apps through the application firewall
  networking.applicationFirewall.allowSignedApp = true;

  system.defaults = {
    menuExtraClock.Show24Hour = true;

    trackpad = {
      Clicking = true; # tap to click
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
      ActuationStrength = 0; # silent clicking
    };

    finder = {
      _FXShowPosixPathInTitle = true;
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      AppleShowAllFiles = true;
      CreateDesktop = false;
      FXDefaultSearchScope = "SCcf"; # search the current folder
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      show-recents = false;
      orientation = "bottom";
      show-process-indicators = false;
      static-only = true;
      # Hot corners: 1 = disabled, 14 = Quick Note
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 14;
      tilesize = 50;
      dashboard-in-overlay = true;
      mru-spaces = false;
      launchanim = false;
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      "com.apple.swipescrolldirection" = false; # no natural scrolling
      "com.apple.sound.beep.feedback" = 0;
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 3; # full keyboard access
      ApplePressAndHoldEnabled = true;
      NSScrollAnimationEnabled = true;
      _HIHideMenuBar = false;
      # Faster than the System Settings sliders allow (15 = 225 ms, 2 = 30 ms)
      InitialKeyRepeat = 13;
      KeyRepeat = 2;
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
      AppleShowAllFiles = true;
      "com.apple.keyboard.fnState" = false;
      "com.apple.sound.beep.volume" = 0.0;
    };

    spaces.spans-displays = true;

    CustomUserPreferences = {
      ".GlobalPreferences".AppleSpacesSwitchOnActivate = true;
      NSGlobalDomain.WebKitDeveloperExtras = true;
      "com.apple.finder" = {
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = true;
        ShowMountedServersOnDesktop = true;
        ShowRemovableMediaOnDesktop = true;
        _FXSortFoldersFirst = true;
        FXDefaultSearchScope = "SCcf";
      };
      # No .DS_Store files on network and USB volumes
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # NOTE: contradicts spaces.spans-displays = true above (kept from the old config)
      "com.apple.spaces"."spans-displays" = 0;
      "com.apple.WindowManager" = {
        EnableStandardClickToShowDesktop = 0;
        StandardHideDesktopIcons = 0;
        HideDesktop = 0;
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
      # Don't open Photos when a device is plugged in
      "com.apple.ImageCapture".disableHotPlug = true;
    };

    loginwindow = {
      GuestEnabled = false;
      SHOWFULLNAME = true;
    };

    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = false;
    remapCapsLockToEscape = true;
    swapLeftCommandAndLeftAlt = false;
  };

  programs.zsh.enable = true;
  environment.shells = [
    pkgs.zsh
    pkgs.nushell
  ];

  fonts.packages = with pkgs; [
    material-design-icons
    font-awesome
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    nerd-fonts.fira-mono
    nerd-fonts.ubuntu-mono
    nerd-fonts.ubuntu
    nerd-fonts.hack
    nerd-fonts.meslo-lg
    nerd-fonts.caskaydia-cove
    source-code-pro
    sketchybar-app-font
  ];
}
