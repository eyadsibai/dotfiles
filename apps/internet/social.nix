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
    tdesktop
    teams
    whatsapp-for-linux
    gitter
    cawbird
    haxor-news
    rainbowstream

  ];

  programs.hexchat = { enable = true; };

}
