{config, pkgs, ...}:
{
  home.file.".config/networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = ${pkgs.rofi}/bin/rofi -dmenu
  '';

}