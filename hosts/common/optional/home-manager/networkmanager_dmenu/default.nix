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
  xdg.configFile."networkmanager-dmenu/config.ini".text = lib.generators.toINI { } {
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

  xdg.configFile."networkmanager-dmenu/networkmenu.rasi".source = ./networkmenu.rasi;
  xdg.configFile."networkmanager-dmenu/colors.rasi".text = ''
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


  red = mkLiteral "#${colors.base08}";
  blue = mkLiteral "#${colors.base0D}";
  lightfg = mkLiteral "#${colors.base06}";
  lightbg = mkLiteral "#${colors.base01}";
  foreground = mkLiteral "#${colors.base05}";
  background = mkLiteral "#${colors.base00}";
  background-color = mkLiteral "#${colors.base00}";
  separatorcolor = mkLiteral "@foreground";
  border-color = mkLiteral "@foreground";
  selected-normal-foreground = mkLiteral "@lightbg";
  selected-normal-background = mkLiteral "@lightfg";
  selected-active-foreground = mkLiteral "@background";
  selected-active-background = mkLiteral "@blue";
  selected-urgent-foreground = mkLiteral "@background";
  selected-urgent-background = mkLiteral "@red";
  normal-foreground = mkLiteral "@foreground";
  normal-background = mkLiteral "@background";
  active-foreground = mkLiteral "@blue";
  active-background = mkLiteral "@background";
  urgent-foreground = mkLiteral "@red";
  urgent-background = mkLiteral "@background";
  alternate-normal-foreground = mkLiteral "@foreground";
  alternate-normal-background = mkLiteral "@lightbg";
  alternate-active-foreground = mkLiteral "@blue";
  alternate-active-background = mkLiteral "@lightbg";
  alternate-urgent-foreground = mkLiteral "@red";
  alternate-urgent-background = mkLiteral "@lightbg";

  # base00: "#24283B"
  # base01: "#16161E"
  # base02: "#343A52"
  # base03: "#444B6A"
  # base04: "#787C99"
  # base05: "#A9B1D6"
  # base06: "#CBCCD1"
  # base07: "#D5D6DB"
  # base08: "#C0CAF5"
  # base09: "#A9B1D6"
  # base0A: "#0DB9D7"
  # base0B: "#9ECE6A"
  # base0C: "#B4F9F8"
  # base0D: "#2AC3DE"
  # base0E: "#BB9AF7"
  # base0F: "#F7768E"
}
