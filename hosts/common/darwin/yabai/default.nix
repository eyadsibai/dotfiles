{ pkgs, ... }: {
  services.yabai = {
    enable = true;
    package = pkgs.yabai;
    config = {
      enableScriptingAddition = true;

      # layout
      layout = "bsp";
      auto_balance = "on";
      split_ratio = "0.50";
      window_placement = "second_child";
      # Gaps
      window_gap = 18;
      top_padding = 18;
      bottom_padding = 46;
      left_padding = 18;
      right_padding = 18;
      # shadows and borders
      window_shadow = "on";
      window_border = "off";
      window_border_width = 3;
      window_opacity = "on";
      window_opacity_duration = "0.1";
      active_window_opacity = "1.0";
      normal_window_opacity = "1.0";
      # mouse
      mouse_modifier = "cmd";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      mouse_drop_action = "swap";
      # mouse_follows_focus = "true";
      focus_follows_mouse = "autoraise";

    };
    extraConfig = ''
      # rules
      yabai -m rule --add app=emacs-29.0.50 manage=on
      yabai -m rule --add app='Firefox Nightly' manage=on
      yabai -m rule --add app='System Preferences' manage=off
      yabai -m rule --add app='Activity Monitor' manage=off
    '';
    #   config = {
    #     # Other configuration options

    #     auto_balance = "off";
    #     window_border = "on";
    #     window_border_width = "2";
    #
    #     top_padding = "10";
    #     bottom_padding = "10";
    #     left_padding = "10";
    #     right_padding = "10";
    #     window_gap = "10";
    #   };
    #   extraConfig = ''
    #     yabai -m rule --add app='^Emacs$' manage=on
    #     yabai -m rule --add title='Preferences' manage=off layer=above
    #     yabai -m rule --add title='^(Opening)' manage=off layer=above
    #     yabai -m rule --add title='Library' manage=off layer=above
    #     yabai -m rule --add app='^System Preferences$' manage=off layer=above
    #     yabai -m rule --add app='Activity Monitor' manage=off layer=above
    #     yabai -m rule --add app='Finder' manage=off layer=above
    #     yabai -m rule --add app='^System Information$' manage=off layer=above
    #     #yabai -m rule --add=
    #     #yabai -m rule --add=
    #   ''; # Specific rules for if it is managed and on which layer
    # };

  };
}
