{ config
, pkgs
, ...
}:
let
  dmenu-command = "${ pkgs.rofi }/bin/rofi - dmenu";
  default-terminal = "${ pkgs.alacritty }/bin/alacritty";
  {
  home.packages = [ pkgs.networkmanager_dmenu ];
  xdg.configFile."networkmanager-dmenu/config.ini".text =
    ''
      [dmenu]
      dmenu_command = ${dmenu-command}
      rofi_highlight = True
      wifi_chars = ▂▄▆█
      compact = True

      [editor]
      terminal = ${default-terminal}

    '';
  }
