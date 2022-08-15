{ config
, pkgs
, ...
}:
{
  home.packages = [ pkgs.networkmanager_dmenu ];
  xdg.configFile."networkmanager-dmenu/config.ini".text =
    ''
      [dmenu]
      dmenu_command = ${ pkgs.rofi }/bin/rofi -dmenu
      rofi_highlight = True
      wifi_chars = ▂▄▆█
      compact = True

      [editor]
      terminal = ${ pkgs.alacritty }/bin/alacritty

    '';
}
