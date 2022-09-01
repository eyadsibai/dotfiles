{ pkgs
, ...
}:
{
  programs.feh = {
    enable = true;
    keybindings = {
      menu_parent = "h Left";
      menu_child = "l Right";
      menu_down = "j Down";
      menu_up = "k Up";
      menu_select = "space Return";

      next_img = "j Right space";
      prev_img = "k Left BackSpace";

      scroll_up = "J C-Up";
      scroll_down = "K C-Down";
      scroll_left = "H C-Left";
      scroll_right = "L C-Right";

      remove = "d   Delete";
      delete = "C-d C-Delete";

      toggle_filenames = "n";

      zoom_in = "C-Up i";
      zoom_out = "C-Down o";
      zoom_default = "d";
      zoom_fit = "s";

      # save_image
      # save_filelist

      scroll_down_page = "S-Down";
      toggle_fullscreen = "f";


    };
  };
}
