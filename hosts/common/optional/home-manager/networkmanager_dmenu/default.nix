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
    pkgs.icomoon-feather-ttf
  ];
  xdg.configFile."networkmanager-dmenu/config.ini" = lib.mkIf (builtins.elem pkgs.networkmanager_dmenu config.home.packages) {
    text = lib.generators.toINI { }
      {
        dmenu = {
          dmenu_command = "${config.home.preferredApps.menu.dmenu-cmd} -theme ${config.xdg.configHome}/networkmanager-dmenu/networkmenu.rasi";
          rofi_highlight = true;
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
  };

  xdg.configFile."networkmanager-dmenu/networkmenu.rasi" = lib.mkIf (builtins.elem pkgs.networkmanager_dmenu config.home.packages) { source = ./networkmenu.rasi; };
  xdg.configFile."networkmanager-dmenu/colors.rasi" = lib.mkIf (builtins.elem pkgs.networkmanager_dmenu config.home.packages) {
    text = ''
        * {
        al:   #${colors.base00};
        bg:   #${colors.base00};
        bga:  #${colors.base01};
        fga:  #${colors.base0E};
        fg:   #${colors.base0B};
        ac:   #${colors.base03};
        se:   #${colors.base01};
      }
    '';
  };
}
