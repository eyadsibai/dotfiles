{ config
, pkgs
, lib
, ...
}:
let
  inherit (config.colorscheme) colors;
in
{
  home.packages = [
    pkgs.networkmanager_dmenu
  ];
  xdg.configFile."networkmanager-dmenu/config.ini".text = lib.generators.toINI { } {
    dmenu = {
      dmenu_command = "${config.home.preferredApps.menu.dmenu-cmd} -theme ${config.xdg.configHome}/networkmanager-dmenu/networkmenu.rasi";
      rofi_highlight = false;
      wifi_chars = "▂▄▆█";
      pinentry = "${pkgs.pinentry-rofi}/bin/pinentry-rofi";
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

  xdg.configFile."networkmanager-dmenu/networkmenu.rasi".source = ./networkmenu.rasi;
  xdg.configFile."networkmanager-dmenu/colors.rasi".text = ''
      * {
      al:   #00000000;
      bg:   #${colors.base00};
      bga:  #${colors.base03};
      fga:  #${colors.base0D};
      fg:   #${colors.base05};
      ac:   #${colors.base02};
      se:   #6D889540;
    }
  '';
}
