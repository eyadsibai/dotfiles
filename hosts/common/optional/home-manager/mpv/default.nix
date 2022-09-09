{ inputs
, pkgs
, ...
}: {
  programs.mpv = {
    enable = true;
    bindings = {
      l = "seek 5";
      h = "seek -5";
      j = "seek -60";
      k = "seek 60";
      S = "cycle sub";
      P = "cycle pause";
      ">" = "playlist-next";
      "<" = "playlist-prev";
      "Alt+LEFT" = "add video-rotate -90"; # Rotate video counter-clockwise witheft Arrow Key
      "Alt+RIGHT" = "add video-rotate 90"; # Rotate video clockwise with.....ALT+Right Arrow Key
      "Ctrl+right" = "playlist-next";
      "Ctrl+left" = "playlist-prev";

      # Skip to previous/next subtitle (subject to some restrictions; see manpage)
      "Ctrl+LEFT" = "no-osd sub-seek -1";
      "Ctrl+RIGHT" = "no-osd sub-seek  1";

      "q" = "quit";
      "d" = "quit";
      "Q" = "quit-watch-later";

      ## Volume Control
      # Scroll wheel up/down

      "MOUSE_BTN3" = "add volume 2";
      "MOUSE_BTN4" = "add volume -2";
      "MOUSE_BTN5" = "add volume 2";
      "MOUSE_BTN6" = "add volume -2";

      "o" = "show-progress";
      # Mouse wheels, touchpad or other input devices that have axes
      # if the input devices supports precise scrolling it will also scale the
      # numeric value accordingly
      "AXIS_UP" = "add volume 2";
      "AXIS_DOWN" = "add volume -2";
      "AXIS_LEFT" = "add volume 2";
      "AXIS_RIGHT" = "add volume -2";

      "-" = "add video-zoom -0.25";
      "+" = "add video-zoom 0.25";
    };
    scripts = with pkgs; [ mpvScripts.mpris mpvScripts.convert mpvScripts.cutter mpvScripts.autoload mpvScripts.thumbnail ];
  };
  xdg.configFile."mpv/scripts/iptv.lua".source = "${inputs.mpv-iptv}/iptv.lua";
}
# "Ctrl+e" = "run youtube-dl \"${path}" -o %USERPROFILE%\Desktop\%(title)s.%(ext)s; show_text "Downloading \${filename}\""; # Download currently playing video to desktop using youtube-dl
#Ctrl+c run "cmd.exe" "/d" "/c" "echo ${path}|clip"; show_text "Link copied to clipboard"
#ctrl+v                                    # Append clipboard URL to playlist
#c easy_crop                        # Crop video to selection
#
# Do smaller, always exact (non-keyframe-limited), seeks with shift.
# Don't show them on the OSD (no-osd).
#Shift+RIGHT no-osd seek  1 exact
#Shift+LEFT  no-osd seek -1 exact
#Shift+UP    no-osd seek  5 exact
#Shift+DOWN  no-osd seek -5 exact
#I show-text "${filename}"              # display filename in osd
#z add sub-delay -0.1                   # subtract 100 ms delay from subs
#x add sub-delay +0.1
#r add sub-pos -1                       # move subtitles up
#t add sub-pos +1
#v cycle sub-visibility
#j cycle sub                            # cycle through subtitles
#_ cycle video
#S screenshot video                     # ...without subtitles
#Ctrl+s screenshot window               # ...with subtitles and OSD, and scaled
#Alt+s screenshot each-frame            # automatically screenshot eve
# For tv://
#h cycle tv-channel -1                  # previous channel
#k cycle tv-channel +1                  # next channel

