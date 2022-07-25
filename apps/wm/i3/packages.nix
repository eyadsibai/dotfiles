{ pkgs, ... }: {
  home.packages = with pkgs; [
    networkmanager_dmenu
    haskellPackages.network-manager-tui
    rofi-rbw
    alsaUtils
  ];

    programs.rofi = {
    enable = true;
    plugins = [ pkgs.rofi-calc pkgs.rofi-emoji pkgs.rofimoji ];
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = "${pkgs.rofi}/share/rofi/themes/DarkBlue.rasi";
  };
}
