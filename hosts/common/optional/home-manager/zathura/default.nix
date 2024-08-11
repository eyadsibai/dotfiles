{ inputs
, pkgs
, config
, ...
}:
# TODO https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zathura/zathurarc
let
  inherit (config.colorscheme) palette;
in
{
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      font = "${config.stylix.fonts.sansSerif.name} 12";
      recolor = true;
      default-bg = "#${palette.base00}";
      default-fg = "#${palette.base01}";
      statusbar-bg = "#${palette.base02}";
      statusbar-fg = "#${palette.base04}";
      index-bg = "#${palette.base02}";
      index-fg = "#${palette.base04}";
      index-active-bg = "#${palette.base04}";
      index-active-fg = "#${palette.base02}";
      render-loading-bg = "#${palette.base02}";
      render-loading-fg = "#${palette.base04}";

      inputbar-bg = "#${palette.base00}";
      inputbar-fg = "#${palette.base07}";
      notification-bg = "#${palette.base00}";
      notification-fg = "#${palette.base07}";
      notification-error-bg = "#${palette.base00}";
      notification-error-fg = "#${palette.base08}";
      notification-warning-bg = "#${palette.base00}";
      notification-warning-fg = "#${palette.base08}";
      highlight-color = "#${palette.base0A}";
      highlight-active-color = "#${palette.base0D}";
      completion-bg = "#${palette.base01}";
      completion-fg = "#${palette.base05}";
      completion-highlight-bg = "#${palette.base0D}";
      completion-highlight-fg = "#${palette.base07}";
      completion-group-bg = "#${palette.base02}";
      completion-group-fg = "#${palette.base08}";
      recolor-lightcolor = "#${palette.base00}";
      recolor-darkcolor = "#${palette.base06}";
      window-title-home-tilde = true;
      statusbar-basename = true;
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
    };
    mappings = {
      f = "toggle_fullscreen";
      "[fullscreen] f" = "toggle_fullscreen";
      # "<C-i>" = "recolor";
      w = "adjust_window width";
      n = "navigate next";
      b = "navigate previous";
      "<Space>" = "toggle_statusbar";
      u = "scroll half-up";
      d = "scroll half-down";
      D = "toggle_page_mode";
      r = "reload";
      R = "rotate";
      K = "zoom in";
      J = "zoom out";
      i = "recolor";
      p = "print";
    };
  };
}
