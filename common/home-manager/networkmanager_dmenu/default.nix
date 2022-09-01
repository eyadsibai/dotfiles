{ config
, pkgs
, ...
}:
{
  home.packages = [ pkgs.networkmanager_dmenu ];
  xdg.configFile."networkmanager-dmenu/config.ini".text =
    ''
      [dmenu]
      dmenu_command = ${config.home.preferredApps.menu.dmenu-cmd}
      rofi_highlight = True
      wifi_chars = ▂▄▆█
      compact = True
      rofi_obscure = True

      [editor]
      terminal = ${config.home.preferredApps.terminal.cmd}
      gui_if_available = True
    '';
}
