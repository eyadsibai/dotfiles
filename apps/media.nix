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
    ytcc

  ];

  services.mopidy = {
    enable = false;
    extensionPackages = with pkgs; [
      mopidy-mpris
      mopidy-soundcloud
      mopidy-youtube
      mopidy-mpd
      mopidy-tunein
      mopidy-ytmusic
      mopidy-podcast
      # mopidy-muse
    ];
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
    scripts = with pkgs; [
      mpvScripts.mpris
      mpvScripts.convert
      mpvScripts.cutter
      mpvScripts.autoload
      mpvScripts.thumbnail
    ];
  };
}
