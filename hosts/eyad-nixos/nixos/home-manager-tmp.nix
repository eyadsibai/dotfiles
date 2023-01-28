{ config
, pkgs
, lib
, username
, ...
}: {
  home-manager.users.${username} = {
    programs.papis.enable = true;
    programs.kakoune.enable = true;
    programs.yt-dlp.enable = true;
    programs.gallery-dl.enable = true;
    home.enableNixpkgsReleaseCheck = true;

    services.dunst = {
      enable = true;
      settings = {
        global = {
          monitor = 0;
          follow = "keyboard";
          # Show how many messages are currently hidden (because of geometry)
          indicate_hidden = "yes";
          shrink = "yes";
          transparency = 10;
          notification_height = 0;
          # Draw a line of 'separatpr_height' pixel height between two notifications.
          # Set to 0 to disable
          separator_height = 2;
          padding = 0;
          horizontal_padding = 8;
          frame_width = 3;
          # the geometry of the window
          # geometry [{width}]x{height}][+/-{x}+/-{y}]
          # The geometry of the message window.
          # The height is measured in number of notifications everything else in pixels. If the width
          # is omitted but the height is given ("-geometry x2"), the message window
          # expands over the whole screen (dmenu-like). If width is 0,
          # the window expands to the longest message displayed.
          # A positive x is measured from the left, a negative from the
          # right side of the screen. Y is measured from the top and down respectevly.
          # The width can be negative. In this case the actual width is the
          # screen width minus the width defined in within the geometry option.

          geometry = "350x5-0+24";
          # Sort messages by urgency
          sort = "yes";
          idle_threshold = 20;
          # The height of a single line. If the height is smaller than the font height,
          # it will get raised to the font height.
          # This adds empty space above and under the text.
          line_height = 0;
          markup = "full";
          alignment = "right";
          show_age_threshold = "60";
          # The frequency with wich text that is longer than the notification
          # window allows bounces back and forth.
          # This option conflicts with 'word_wrap'.
          # Set to 0 to disable
          # bounce_freq = 1;
          word_wrap = "yes";
          ellipsize = "middle";
          ignore_newline = "no";
          stack_duplicates = "true";
          hide_duplicate_count = "true";
          show_indicators = "yes";
          icon_position = "left";
          max_icon_size = "40";
          # The format of the message. Possible variables are:
          # %a appname
          # %s summary
          # %b body
          # %i iconname (including its path)
          # %I iconname (without its path)
          # %p progress value if set ([ 0%] to [100%]) or nothing
          # format = "%s > %b"
          format = "<b>%s</b>\n%b";
          color = "#${colors.base00}";
          frame_color = "#${colors.base03}";
          separator_color = "#${colors.base03}";
          font = "${config.fontProfiles.regular.family} 12";
          sticky_history = "yes";
          history_length = 20;
          dmenu = "${config.home.preferredApps.menu.dmenu-cmd}";
          browser = "${config.home.preferredApps.browser.cmd} -new-tab"; # TODO
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          startup_notification = false;
          force_xinerama = true;
        };

        frame = {
          width = 0;
          color = "#${colors.base01}";
        };
        experimental = {
          per_monitor_dpi = true;
        };
        shortcuts = {
          close = "ctrl+space";
          close_all = "ctrl+shift+space";
          # redisplay last message(s)
          # On the US keyboard layout 'grave' is normally above TAB and left of '1'.

          history = "ctrl+grave";
          context = "ctrl+shift+period";
        };
        urgency_low = {
          background = "#${colors.base00}";
          foreground = "#${colors.base05}";
          timeout = 10;
        };
        urgency_normal = {
          background = "#${colors.base00}";
          foreground = "#${colors.base05}";
          timeout = 5;
        };
        urgency_critical = {
          background = "#${colors.base00}";
          foreground = "#${colors.base05}";
          timeout = 5;
        };
      };

      # [signed _on]
      #  appname = Pidgin
      #  summary = "*signed on*"
      #  urgency = low

      # [signed_off]
      #  appname = Pidgin
      #  summary = *signed off*
      #  urgency = low

      # [says]
      #  appname = Pidgin
      #  summary = *says*
      #  urgency = critical

      # [twitter]
      #  appname = Pidgin
      #  summary = *twitter.com*
      #  urgency = normal

      # [libpurple_signed]
      #     appname = libpurple
      #     summary = *igned*
      #     urgency = low
      #     timeout = 3
      #     background = "#ccff33"

      # [libpurple_came_back]
      #     appname = libpurple
      #     summary = "*came*"
      #     format = ""

      # [libpurple_went_away]
      #     appname = libpurple
      #     summary = "*went*"
      #     format = ""

      # [libpurple_says]
      #     appname = libpurple
      #     summary = *ays*
      #     urgency = critical
      #     background = "#ccff33"

      # [libpurple]
      #     appname = libpurple
      #     urgency = critical
      #     background = "#ccff33"

      # [ttytter]
      #     summary = "TTYtter*"
      #     urgency = low

      # [dunst-sum]
      #     appname = gmailnotify.py
      #     summary = "*[dD]unst*"
      #     urgency = critical


      # [mcabber]
      #     appname = notify-send
      #     summary = "*jabber*"
      #     urgency = critical


      # [test]
      #     summary = "*test*"
      #     background="#22dd22"

    };

  };
}
