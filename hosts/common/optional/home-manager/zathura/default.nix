{ inputs
, pkgs
, config
, ...
}:
# TODO https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zathura/zathurarc
let
  inherit (config.colorscheme) colors;
in
{
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      font = "${config.fontProfiles.regular.family} 12";
      recolor = true;
      default-bg = "#${colors.base00}";
      default-fg = "#${colors.base01}";
      statusbar-bg = "#${colors.base02}";
      statusbar-fg = "#${colors.base04}";
      index-bg = "#${colors.base02}";
      index-fg = "#${colors.base04}";
      index-active-bg = "#${colors.base04}";
      index-active-fg = "#${colors.base02}";
      render-loading-bg = "#${colors.base02}";
      render-loading-fg = "#${colors.base04}";

      inputbar-bg = "#${colors.base00}";
      inputbar-fg = "#${colors.base07}";
      notification-bg = "#${colors.base00}";
      notification-fg = "#${colors.base07}";
      notification-error-bg = "#${colors.base00}";
      notification-error-fg = "#${colors.base08}";
      notification-warning-bg = "#${colors.base00}";
      notification-warning-fg = "#${colors.base08}";
      highlight-color = "#${colors.base0A}";
      highlight-active-color = "#${colors.base0D}";
      completion-bg = "#${colors.base01}";
      completion-fg = "#${colors.base05}";
      completion-highlight-bg = "#${colors.base0D}";
      completion-highlight-fg = "#${colors.base07}";
      completion-group-bg = "#${colors.base02}";
      completion-group-fg = "#${colors.base08}";
      recolor-lightcolor = "#${colors.base00}";
      recolor-darkcolor = "#${colors.base06}";
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
