{ config
, pkgs
, ...
}:
let
  palette = config.lib.stylix.colors;

  kitty-xterm = pkgs.writeShellScriptBin "xterm" ''
    ${config.programs.kitty.package}/bin/kitty -1 "$@"
  '';
in
{
  home = {
    packages = [ kitty-xterm ];
    sessionVariables = {
      TERMINAL = "kitty";
    };
  };

  programs.kitty = {
    enable = true;
    font = {
      name = config.stylix.fonts.monospace.name;
    };
    settings = {
      window_padding_width = 15;
      foreground = "#${palette.base05}";
      background = "#${palette.base00}";
      selection_background = "#${palette.base05}";
      selection_foreground = "#${palette.base00}";
      url_color = "#${palette.base04}";
      cursor = "#${palette.base05}";
      enable_audio_bell = false;
      active_border_color = "#${palette.base03}";
      inactive_border_color = "#${palette.base01}";
      active_tab_background = "#${palette.base00}";
      active_tab_foreground = "#${palette.base05}";
      inactive_tab_background = "#${palette.base01}";
      inactive_tab_foreground = "#${palette.base04}";
      tab_bar_background = "#${palette.base01}";
      disable_ligatures = false;
      url_style = "curly";
      detect_urls = true;
      copy_on_select = true;
      focus_follows_mouse = true;
      sync_to_monitor = true;

      color0 = "#${palette.base00}";
      color1 = "#${palette.base08}";
      color2 = "#${palette.base0B}";
      color3 = "#${palette.base0A}";
      color4 = "#${palette.base0D}";
      color5 = "#${palette.base0E}";
      color6 = "#${palette.base0C}";
      color7 = "#${palette.base05}";
      color8 = "#${palette.base03}";
      color9 = "#${palette.base08}";
      color10 = "#${palette.base0B}";
      color11 = "#${palette.base0A}";
      color12 = "#${palette.base0D}";
      color13 = "#${palette.base0E}";
      color14 = "#${palette.base0C}";
      color15 = "#${palette.base07}";
      color16 = "#${palette.base09}";
      color17 = "#${palette.base0F}";
      color18 = "#${palette.base01}";
      color19 = "#${palette.base02}";
      color20 = "#${palette.base04}";
      color21 = "#${palette.base06}";
    };
  };
}
