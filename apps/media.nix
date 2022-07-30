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

    services.mopidy = {
    enable = false;
    extensionPackages =
      [ pkgs.mopidy-mpris pkgs.mopidy-soundcloud pkgs.mopidy-youtube ];
  };

  services.mpd.enable = true;
  services.mpdris2.enable = true;
  services.playerctld.enable = true;
  services.spotifyd.enable = true;
}
