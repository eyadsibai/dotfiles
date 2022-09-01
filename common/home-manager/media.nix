{ pkgs
, ...
}:
{
  home.packages =
    with pkgs;
    [
      cava
      cli-visualizer
      cmus
      pyradio
      vlc
      # media player
      mps-youtube
      youtube-dl
      ytcc
      darktable
    ];
  services.mopidy = {
    enable = false;
    extensionPackages =
      with pkgs;
      [
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
  programs.ncmpcpp = { enable = true; };



}
