{ pkgs, ... }: {

  programs.htop = { enable = true; };

  programs.feh = {
    enable = true;
    keybindings = {
      menu_parent = "h Left";
      menu_child = "l";
      menu_down = "j";
      menu_up = "k";
      menu_select = "space";
    };
  };
}
