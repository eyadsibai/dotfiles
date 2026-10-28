# mpv on every machine (Omarchy ships no mpv config), with the vim-style keys from
# the old dotfiles flake
{
  programs.mpv = {
    enable = true;
    config = {
      profile = "high-quality"; # formerly gpu-hq
      force-window = true;
      ytdl-format = "bestvideo+bestaudio";
      demuxer-max-bytes = "4000MiB"; # replaces the removed cache-default
    };
    bindings = {
      l = "seek 5";
      h = "seek -5";
      j = "seek -60";
      k = "seek 60";
      S = "cycle sub";
      P = "cycle pause";
      ">" = "playlist-next";
      "<" = "playlist-prev";
      "Ctrl+RIGHT" = "playlist-next";
      "Ctrl+LEFT" = "playlist-prev";
      "Alt+LEFT" = "add video-rotate -90";
      "Alt+RIGHT" = "add video-rotate 90";
      q = "quit";
      d = "quit";
      Q = "quit-watch-later";
      o = "show-progress";
      "-" = "add video-zoom -0.25";
      "+" = "add video-zoom 0.25";
      # wheel and touchpad scroll change the volume
      AXIS_UP = "add volume 2";
      AXIS_DOWN = "add volume -2";
      AXIS_LEFT = "add volume 2";
      AXIS_RIGHT = "add volume -2";
    };
  };
}
