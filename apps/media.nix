{ pkgs, ... }: {

  home.packages = with pkgs; [
    spotify-tui
    spotify
    cava
    cli-visualizer
    cmus
    pyradio
    vlc # media player
    mps-youtube
    youtube-dl

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
  programs.ncmpcpp = { enable = true; };
  programs.mpv = {
    enable = true;
    bindings = {
      l = "seek 5";
      h = "seek -5";
      k = "seek 60";
      S = "cycle sub";
    };
  };
}
