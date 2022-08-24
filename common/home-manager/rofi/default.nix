{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    plugins = with pkgs; [ rofi-calc rofi-emoji ];
    terminal = "${ pkgs.alacritty }/bin/alacritty";
    theme = "${ pkgs.rofi }/share/rofi/themes/DarkBlue.rasi";
  };

  home.packages = [ pkgs.rofi-rbw ];
}
