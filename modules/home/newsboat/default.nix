# Newsboat, ported from the old dotfiles flake. The feed lists (urls, and yturls for
# `newsboat-yt`) are plain files in this directory, linked in place rather than copied,
# so adding a feed from newsboat or `rssadd` edits the repo directly.
{
  config,
  lib,
  pkgs,
  repoDir,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  here = "${repoDir}/modules/home/newsboat";
  opener = if isDarwin then "open" else "xdg-open";
  copy = if isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";

  # Videos to mpv, audio downloaded, everything else to the default browser/viewer
  linkhandler = pkgs.writeShellApplication {
    name = "linkhandler";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      [ -z "''${1:-}" ] && exit 1
      case "$1" in
        *mkv|*webm|*mp4|*youtube.com/watch*|*youtube.com/playlist*|*youtu.be*)
          setsid mpv --quiet "$1" >/dev/null 2>&1 & ;;
        *mp3|*flac|*opus|*mp3?source*)
          (cd ~/Downloads && setsid curl -sLO "$1" >/dev/null 2>&1 &) ;;
        *)
          setsid ${opener} "$1" >/dev/null 2>&1 & ;;
      esac
    '';
  };

  # Save an arXiv paper as ~/arxiv/<date>-<name>.pdf and open it
  downloadArxiv = pkgs.writeShellApplication {
    name = "download_arxiv";
    runtimeInputs = with pkgs; [
      wget
      gnugrep
      coreutils
    ];
    text = ''
      echo; echo "Path of output directory? Default = (~/arxiv)"
      read -r outdir
      outdir=''${outdir:-$HOME/arxiv}
      mkdir -p "$outdir"
      pdf_url=$(wget -qO- "$1" | grep "pdf_url" | cut -d "=" -f3 | cut -d '"' -f2)
      echo; echo "Name of file? (Excluding '.pdf')"
      read -r name
      out="$outdir/$(date +%Y_%m_%d)-$name.pdf"
      wget -q "$pdf_url" -O "$out"
      ${opener} "$out"
    '';
  };

  # Append a feed URL to the feed list
  rssadd = pkgs.writeShellScriptBin "rssadd" ''
    case "$1" in http*://*.*) ;; *) echo "That doesn't look like a full URL." >&2; exit 1 ;; esac
    if awk '{print $1}' "${here}/urls" | grep -qxF "$1"; then
      echo "You already have this RSS feed."
    else
      echo "$1" >> "${here}/urls" && echo "RSS feed added."
    fi
  '';
in
{
  programs.newsboat = {
    enable = true;
    autoReload = true;
    maxItems = 0;
    reloadThreads = 5;
    reloadTime = 60;
    # urls stay empty so Home Manager leaves the feed file to us (linked below)
    extraConfig = ''
      cache-file "${config.xdg.dataHome}/newsboat/cache.db"
      prepopulate-query-feeds yes

      browser ${lib.getExe linkhandler}
      external-url-viewer "${lib.getExe pkgs.urlscan} -dc -r '${lib.getExe linkhandler} {}'"

      feed-sort-order unreadarticlecount-asc
      show-read-feeds no
      show-read-articles no

      podcast-auto-enqueue yes
      download-path "~/Downloads/podcasts/%h/%n"
      player "${lib.getExe pkgs.mpv}"

      # --- navigation ---
      bind-key j down
      bind-key k up
      bind-key j next articlelist
      bind-key k prev articlelist
      bind-key J next-feed articlelist
      bind-key K prev-feed articlelist
      bind-key G end
      bind-key g home
      bind-key d pagedown
      bind-key u pageup
      bind-key l open
      bind-key h quit
      bind-key a toggle-article-read
      bind-key n next-unread
      bind-key N prev-unread
      bind-key D pb-download
      bind-key U show-urls
      bind-key x pb-delete

      color listnormal cyan default
      color listfocus black yellow standout bold
      color listnormal_unread blue default
      color listfocus_unread yellow default bold
      color info red black bold
      color article cyan default

      # , open · t download video · a download audio · v play in mpv
      # c copy link · P save an arXiv paper
      macro , open-in-browser
      macro t set browser "setsid yt-dlp --add-metadata -ic -P ~/Downloads"; open-in-browser ; set browser ${lib.getExe linkhandler}
      macro a set browser "setsid yt-dlp --add-metadata -xic -f bestaudio/best -P ~/Downloads"; open-in-browser ; set browser ${lib.getExe linkhandler}
      macro v set browser "setsid mpv"; open-in-browser ; set browser ${lib.getExe linkhandler}
      macro c set browser "printf %s %u | ${copy}"; open-in-browser ; set browser ${lib.getExe linkhandler}
      macro P set browser "${lib.getExe downloadArxiv} %u"; open-in-browser ; set browser ${lib.getExe linkhandler}
    '';
  };

  xdg.configFile = {
    "newsboat/urls".source = config.lib.file.mkOutOfStoreSymlink "${here}/urls";
    "newsboat/yturls".source = config.lib.file.mkOutOfStoreSymlink "${here}/yturls";
    "newsboat/ytconfig".text = ''
      browser mpv
      auto-reload yes
      cache-file "${config.xdg.dataHome}/newsboat/ytcache.db"
    '';
  };

  home.packages = [
    rssadd
    pkgs.yt-dlp
    (pkgs.writeShellScriptBin "newsboat-yt" ''
      exec ${lib.getExe pkgs.newsboat} -C ${config.xdg.configHome}/newsboat/ytconfig -u ${config.xdg.configHome}/newsboat/yturls "$@"
    '')
  ];
}
