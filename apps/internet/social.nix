{ pkgs, ... }:

{
  home.packages = with pkgs; [
    discord
    signal-desktop
    skypeforlinux
    slack
    slack-term
    zoom-us
    element-desktop
    pkgs.tdesktop
    teams
    whatsapp-for-linux
    gitter
    cawbird

  ];

  programs.hexchat = { enable = true; };

}
