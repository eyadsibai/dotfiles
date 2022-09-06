{ config
, pkgs
, lib
, ...
}:
{
  home.packages = [
    pkgs.networkmanager_dmenu
  ];
  xdg.configFile."networkmanager-dmenu/config.ini".text =

    lib.generators.toINI { } {
      dmenu = {
        dmenu_command = "${config.home.preferredApps.menu.dmenu-cmd} -theme ${config.xdg.configHome}/networkmanager-dmenu/networkmenu.rasi";
        rofi_highlight = false;
        wifi_chars = "▂▄▆█";
        compact = true;
        list_saved = false;
      };
      dmenu_passphrase = {
        obscure = true;
        rofi_obscure = true;
      };
      editor = {
        terminal = "${config.home.preferredApps.terminal.cmd}";
        gui_if_available = true;
      };
    };

  # [dmenu]
  # dmenu_command =
  # rofi_highlight = True
  # wifi_chars = ▂▄▆█
  # compact = True
  # list_saved = False

  # [dmenu_passphrase]
  # obscure = True

  # [editor]
  # terminal = ${config.home.preferredApps.terminal.cmd}
  # gui_if_available = True
  # '';

  xdg.configFile."networkmanager-dmenu/networkmenu.rasi".source = ./networkmenu.rasi;
  xdg.configFile."networkmanager-dmenu/colors.rasi".source = ./colors.rasi;

}
