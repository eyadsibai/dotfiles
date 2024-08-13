{ inputs
, pkgs
, config
, ...
}:
# TODO https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zathura/zathurarc
{
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      recolor = true;
      window-title-home-tilde = true;
      statusbar-basename = true;
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
    };
    mappings = {
      f = "toggle_fullscreen";
     # "[fullscreen] f" = "toggle_fullscreen";
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
