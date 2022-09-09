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
      window_gap = 10;
      top_padding = 10;
      bottom_padding = 38;
      left_padding = 10;
      right_padding = 10;
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
      mouse_follows_focus = "true";
      focus_follows_mouse = "autoraise";
    };
    extraConfig = ''
      # rules
      yabai -m rule --add app='^System Preferences$' manage=off layer=above
      yabai -m rule --add app='Activity Monitor' manage=off layer=above
      yabai -m rule --add title='^(Opening)' manage=off layer=above
      yabai -m rule --add app='^System Information$' manage=off layer=above
    '';
  };

  services.skhd = {
    # Hotkey daemon
    enable = true;
    package = pkgs.skhd;
    skhdConfig = ''
      # open terminal
      cmd - return : iterm2

      # focus window
      lalt - h : yabai -m window --focus west
      lalt - j : yabai -m window --focus south
      lalt - k : yabai -m window --focus north
      lalt - l : yabai -m window --focus east
      # swap managed window
      shift + lalt - h : yabai -m window --swap west
      shift + lalt - l : yabai -m window --swap east
      shift + lalt - j : yabai -m window --swap south
      shift + lalt - k : yabai -m window --swap north
      # focus spaces
      lalt - x : yabai -m space --focus recent
      lalt - 1 : yabai -m space --focus 1
      lalt - 2 : yabai -m space --focus 2
      lalt - 3 : yabai -m space --focus 3
      lalt - 4 : yabai -m space --focus 4
      lalt - 5 : yabai -m space --focus 5
      lalt - 6 : yabai -m space --focus 6
      lalt - 7 : yabai -m space --focus 7
      lalt - 8 : yabai -m space --focus 8
      # focus on next/prev space
      alt + ctrl - q : yabai -m space --focus prev
      alt + ctrl - e : yabai -m space --focus next
      # send window to desktop
      shift + alt - x : yabai -m window --space recent
      shift + alt - 1 : yabai -m window --space 1
      shift + alt - 2 : yabai -m window --space 2
      shift + alt - 3 : yabai -m window --space 3
      shift + alt - 4 : yabai -m window --space 4
      shift + alt - 5 : yabai -m window --space 5
      shift + alt - 6 : yabai -m window --space 6
      shift + alt - 7 : yabai -m window --space 7
      shift + alt - 8 : yabai -m window --space 8
      # float / unfloat window and center on screen
      lalt - t : yabai -m window --toggle float;\
                 yabai -m window --grid 4:4:1:1:2:2
      # toggle window zoom
      lalt - d : yabai -m window --toggle zoom-parent
    '';
  };

  services.spacebar = {
    enable = true;
    package = pkgs.spacebar;
    config = {
      position = "bottom";
      height = 28;
      title = "on";
      spaces = "on";
      power = "on";
      clock = "on";
      right_shell = "on";
      padding_left = 20;
      padding_right = 20;
      spacing_left = 25;
      spacing_right = 25;
      text_font = ''"FiraCode Nerd Font Mono:16.0"'';
      icon_font = ''"FiraCode Nerd Font Mono:16.0"'';
      background_color = "0xff161616";
      foreground_color = "0xffFFFFFF";
      space_icon_color = "0xff3ddbd9";
      power_icon_strip = " ";
      space_icon_strip = "1 2 3 4 5 6 7 8 9 10";
      space_icon_color_secondary = "0xff78c4d4";
      space_icon_color_tertiary = "0xfffff9b0";
      spaces_for_all_displays = "off";
      display_separator = "on";
      display_separator_icon = "";
      clock_format = ''"%d/%m/%y %R"'';
      right_shell_icon = "";
      right_shell_command = "whoami";
      power_icon_color = "0xffcd950c";
      battery_icon_color = "0xffd75f5f";
      dnd_icon_color = "0xffa8a8a8";
      clock_icon_color = "0xffa8a8a8";
      space_icon = "•";
      clock_icon = "";
      dnd_icon = "";
    };
  };
}
