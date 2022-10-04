{ lib
, config
, pkgs
, ...
}:
{
  # services.caffeine.enable = true;
  services.clipmenu.enable = false;
  services.parcellite = {
    enable = false;
    package = pkgs.clipit;
  };

  xdg.configFile."clipit/clipitrc" = lib.mkIf config.services.parcellite.enable {
    text = ''
      [rc]
      use_copy=true
      use_primary=false
      synchronize=false
      automatic_paste=false
      show_indexes=false
      save_uris=true
      use_rmb_menu=false
      save_history=true
      history_limit=50
      items_menu=20
      statics_show=true
      statics_items=10
      hyperlinks_only=false
      confirm_clear=false
      single_line=true
      reverse_history=false
      item_length=50
      ellipsize=2
      history_key=<Ctrl><Alt>H
      actions_key=<Ctrl><Alt>A
      menu_key=<Ctrl><Alt>P
      search_key=<Ctrl><Alt>F
      offline_key=<Ctrl><Alt>O
      offline_mode=false
    '';
  };





  services.dropbox.enable = true;
  services.espanso.enable = false;
  # services.fusuma.enable = true;
  # services.git-sync.enable = true;
  # services.gromit-mpx.enable = true;
  services.hound.enable = false;
}
