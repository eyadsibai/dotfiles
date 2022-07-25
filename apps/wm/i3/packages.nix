{ pkgs, ... }: {
  home.packages = with pkgs; [
    networkmanager_dmenu
    haskellPackages.network-manager-tui
    rofi-rbw
    alsaUtils
  ];

  programs.rofi.enable = true;
}
