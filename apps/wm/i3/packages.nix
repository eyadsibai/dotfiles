{pkgs, ...}: {
  home.packages = with pkgs; [
    networkmanager_dmenu
    haskellPackages.network-manager-tui
    rofi-rbw
    alsaUtils
    lxappearance
  ];

  programs.rofi = {
    enable = true;
    plugins = with pkgs; [rofi-calc rofi-emoji];
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = "${pkgs.rofi}/share/rofi/themes/DarkBlue.rasi";
  };
}
