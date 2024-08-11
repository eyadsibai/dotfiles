{ pkgs
, lib
, config
, ...
}: {
  xsession.windowManager.i3 = {
    enable = true;
    package = pkgs.i3-gaps;
    config = rec {
      modifier = "Mod4";
      bars = [ ];
      window.border = 0;
      gaps = {
        inner = 14;
        outer = -2;
      };
      keybindings =
        lib.mkOptionDefault
          {
            "XF86AudioMute" = "exec ${pkgs.alsa-utils}/bin/amixer set Master toggle";
            "XF86AudioLowerVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 5%-";
            "XF86AudioRaiseVolume" = "exec ${pkgs.alsa-utils}/bin/amixer set Master 5%+";
            "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 4%-";
            "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 4%+";
            "${modifier}+Return" = "exec ${config.home.preferredApps.terminal.cmd}";
            "${modifier}+d" = "exec ${config.home.preferredApps.menu.drun-cmd}";
            "${modifier}+Shift+d" = "exec ${pkgs.rofi}/bin/rofi -show window";
            "${modifier}+n" = "exec ${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu";
            "${modifier}+p" = "exec ${config.home.preferredApps.menu.password-cmd}";
            "${modifier}+Shift+x" = "exec systemctl suspend";
            "Print" = "exec ${pkgs.flameshot}/bin/flameshot gui";
          };
      startup = [
        {
          command = "exec i3-msg workspace 1";
          always = true;
          notification = false;
        }
        {
          command = "systemctl --user restart polybar.service";
          always = true;
          notification = false;
        }
        {
          command = "${pkgs.feh}/bin/feh --bg-scale ${config.stylix.image}";
          always = true;
          notification = false;
        }
      ];
    };
  };
}
