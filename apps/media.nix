{ pkgs, ... }: {

  home.packages = with pkgs; [
    spotify-tui
    spotify
    cava
    cli-visualizer
    cmus
    pyradio
    vlc # media player

  ];
}
