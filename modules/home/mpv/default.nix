# mpv, one configuration on every machine (Omarchy ships none): uosc with hjkl menus,
# gpu-next, resume, the quality and SponsorBlock scripts, a quiet profile for pyradio,
# and vim-style seeking.
#
# On Arch, mpv and uosc come from pacman (Nix's mpv can't reach the GPU there; the
# other scripts sit by hand in ~/.config/mpv/scripts); elsewhere from nixpkgs.
{
  config,
  lib,
  pkgs,
  isArch,
  ...
}:
let
  uosc = pkgs.mpvScripts.uosc;
  # uosc.lua loads uosc from its install directory and adds hjkl to its menus
  uoscDir = if isArch then "/usr/share/mpv/scripts/uosc" else "${uosc}/share/mpv/scripts/uosc";
  # uosc reads its fonts from ~/.config/mpv/fonts
  font =
    arch: nix:
    if isArch then
      config.lib.file.mkOutOfStoreSymlink "/usr/share/mpv/fonts/${arch}"
    else
      "${uosc}/share/fonts/${nix}";
in
{
  programs.mpv = {
    enable = true;
    package = lib.mkIf isArch null;
    scripts = lib.optionals (!isArch) (
      with pkgs.mpvScripts;
      [
        thumbfast
        quality-menu
        sponsorblock
      ]
      ++ lib.optional pkgs.stdenv.hostPlatform.isLinux mpris
    );

    config = {
      profile = "high-quality";
      force-window = true;
      ytdl-format = "bestvideo+bestaudio";
      demuxer-max-bytes = "4000MiB";
      osc = false; # uosc draws the controls
      vo = "gpu-next";
      gpu-api = "vulkan";
      hwdec = "auto-safe";
      screenshot-directory = "~/Pictures/mpv";
      screenshot-format = "png";
      screenshot-template = "%F-%P";
      save-position-on-quit = true;
      keep-open = true;
      input-default-bindings = true;
      input-vo-keyboard = true;
      osd-font-size = 24;
      osd-bar-h = 2;
      osd-bar = false;
      border = false;
    };

    profiles.pyradio = {
      volume = 90;
      # pyradio's backend is headless audio-only: no uosc, thumbfast or sponsorblock,
      # and above all no mpris, which would register a second MPRIS player next to
      # pyradio's own and confuse playerctl and the bar
      load-scripts = false;
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
      "Alt+-" = "add video-zoom -0.25";
      "Alt+=" = "add video-zoom 0.25";
      # wheel and touchpad scroll change the volume
      AXIS_UP = "add volume 2";
      AXIS_DOWN = "add volume -2";
      AXIS_LEFT = "add volume 2";
      AXIS_RIGHT = "add volume -2";
      PGUP = "playlist-prev"; # channel up/down in `tv`
      PGDWN = "playlist-next";
      "-" = "add volume -2";
      "+" = "add volume 2";
      "=" = "add volume 2";
      M = "cycle mute";
      F = "script-binding quality_menu/video_formats_toggle";
      "Alt+f" = "script-binding quality_menu/audio_formats_toggle";
      "Ctrl+r" = "script-binding quality_menu/reload";
      "Shift+ENTER" = "script-binding uosc/playlist"; # type to search
      "/" = "script-binding uosc/playlist";
    };

    scriptOpts = {
      console.font_size = 20;
      thumbfast = {
        max_height = 200;
        max_width = 200;
        hwdec = true;
        network = true;
      };
      uosc = {
        use_trash = true;
        font_scale = 0.7;
        timeline_size = 46;
        controls_size = 36;
        menu_item_height = 44;
        menu_min_width = 200;
        opacity = "curtain:1,menu:1"; # opaque menus
      };
    };
  };

  xdg.configFile = {
    "mpv/scripts/uosc.lua".text = builtins.replaceStrings [ "@uoscDir@" ] [ uoscDir ] (
      builtins.readFile ./uosc.lua
    );
    "mpv/fonts/uosc_icons.otf".source = font "uosc_icons.otf" "opentype/uosc_icons.otf";
    "mpv/fonts/uosc_textures.ttf".source = font "uosc_textures.ttf" "truetype/uosc_textures.ttf";
  };
}
