{ pkgs, config, ... }: {
  home.packages = with pkgs; [

    cli-visualizer
    # cmus
    vlc
    # media player
    yewtube

    # ytcc
    # darktable
    castget
  ];

  programs.cava.enable = true;
  programs.yt-dlp.enable = true;
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
    settings = {
      m3u = {
        enabled = true;
        default_encoding = "UTF-8";
        default_extension = ".m3u8";
        playlists_dir = "~/m3u/";
      };
      audio = {
        output = "autoaudiosink";
      };
      mpd = {
        enabled = true;
      };
      mpris = {
        enabled = true;
      };
      youtube = {
        enabled = true;
        api_enabled = true;
        youtube_api_key = "${config.secrets.mopidy.youtube_api_key}";
        threads_max = 16;
      };
      logging = {
        color = true;
        console_format = "%(levelname)-8s %(message)s";
        debug_format = "%(levelname)-8s %(asctime)s [%(process)d:%(threadName)s] %(name)s\n  %(message)s";
        debug_file = "$XDG_CONFIG_DIR/mopidy/mopidy.log";
      };
    };
  };
  services.mpd.enable = false;
  services.mpdris2.enable = false;
  services.playerctld.enable = true;
  services.mpd-mpris.enable = false;
}
