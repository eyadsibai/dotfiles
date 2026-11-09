# Newsboat, ported from the old dotfiles flake. The feed lists (urls, and yturls for
# `newsboat-yt`) are plain files in this directory, linked in place rather than copied,
# so adding a feed from newsboat or `rssadd` edits the repo directly.
{
  config,
  lib,
  pkgs,
  repoDir,
  isArch,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  here = "${repoDir}/modules/home/newsboat";
  opener = if isDarwin then "open" else "xdg-open";
  copy = if isDarwin then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";
  # On Arch, newsboat, urlscan, mpv and yt-dlp come from pacman (and Nix's mpv can't
  # reach the GPU there); elsewhere from nixpkgs
  exe = pkg: name: if isArch then name else lib.getExe pkg;

  paste = if isDarwin then "pbpaste" else "${pkgs.wl-clipboard}/bin/wl-paste --no-newline";
  notifySend = if isArch then "notify-send" else "${pkgs.libnotify}/bin/notify-send";
  # `notify <title> [body]` for the scripts below
  notifyFn =
    if isDarwin then
      ''
        notify() { osascript -e "display notification \"''${2:-}\" with title \"$1\"" >/dev/null 2>&1 || true; }
      ''
    else
      ''
        notify() { ${notifySend} -a newsboat "$@" >/dev/null 2>&1 || true; }
      '';

  # `qdl video|audio|file <url>`: download into ~/Downloads in the background, with a
  # notification when it starts and when it finishes or fails
  qdl = pkgs.writeShellApplication {
    name = "qdl";
    runtimeInputs = with pkgs; [
      curl
      coreutils
    ];
    text = ''
      ${notifyFn}
      mode=''${1:?usage: qdl video|audio|file <url>}
      url=''${2:?usage: qdl video|audio|file <url>}
      # Detach, so newsboat or linkhandler never waits on the download
      if [ -z "''${QDL_DETACHED:-}" ]; then
        QDL_DETACHED=1 nohup "$0" "$@" >/dev/null 2>&1 &
        exit 0
      fi
      dir=$HOME/Downloads
      mkdir -p "$dir"
      ytdlp() {
        ${exe pkgs.yt-dlp "yt-dlp"} --embed-metadata -ic --no-simulate --print after_move:filepath \
          -P "$dir" "$@" "$url" | tail -1
      }
      notify "Downloading…" "$url"
      out=""
      case "$mode" in
        video) out=$(ytdlp) || out="" ;;
        audio) out=$(ytdlp -x -f bestaudio/best) || out="" ;;
        *)
          out="$dir/$(basename "''${url%%\?*}")"
          curl -fsSL -o "$out" "$url" || out="" ;;
      esac
      if [ -n "$out" ]; then
        notify "Downloaded" "$(basename "$out")"
      else
        notify "Download failed" "$url"
      fi
    '';
  };

  # Videos to mpv, images and PDFs fetched and opened in the default viewer (imv and
  # Evince on Omarchy), audio downloaded, everything else to the browser. With no
  # argument it takes the clipboard (Super+Alt+V on the Omarchy hosts).
  linkhandler = pkgs.writeShellApplication {
    name = "linkhandler";
    runtimeInputs = with pkgs; [
      curl
      coreutils
    ];
    text = ''
      url=''${1:-$(${paste} 2>/dev/null || true)}
      [ -n "$url" ] || exit 1
      if [ -e "$url" ]; then
        setsid ${opener} "$url" >/dev/null 2>&1 &
        exit 0
      fi
      case "$url" in
        *mkv|*webm|*mp4|*youtube.com/watch*|*youtube.com/playlist*|*youtube.com/shorts/*|*youtu.be*|*vimeo.com/*|*twitch.tv/*)
          setsid mpv --quiet "$url" >/dev/null 2>&1 & ;;
        *.png|*.jpg|*.jpe|*.jpeg|*.gif|*.webp|*.pdf|*.cbz|*.cbr|*.png\?*|*.jpg\?*|*.jpeg\?*|*.webp\?*|*.pdf\?*)
          dir=''${XDG_RUNTIME_DIR:-/tmp}/linkhandler
          mkdir -p "$dir"
          f="$dir/$(basename "''${url%%\?*}")"
          (curl -fsSL -o "$f" "$url" && setsid ${opener} "$f") >/dev/null 2>&1 & ;;
        *mp3|*flac|*opus|*m4a|*ogg|*mp3?source*)
          ${lib.getExe qdl} file "$url" ;;
        *)
          setsid ${opener} "$url" >/dev/null 2>&1 & ;;
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

  # Subscribe newsboat-yt to a channel: ytadd https://www.youtube.com/@handle (or a
  # /channel/UC… URL, or a bare UC… id)
  ytadd = pkgs.writeShellApplication {
    name = "ytadd";
    runtimeInputs = with pkgs; [
      curl
      gnugrep
      coreutils
    ];
    text = ''
      arg=''${1:-$(${paste} 2>/dev/null || true)}
      [ -n "$arg" ] || { echo "usage: ytadd <channel or video url, @handle or UC… id>" >&2; exit 1; }
      case "$arg" in
        UC*) id=$arg ;;
        @*) arg="https://www.youtube.com/$arg" ;&
        *)
          id=$(printf '%s' "$arg" | grep -oE 'channel/UC[A-Za-z0-9_-]{22}' | cut -d/ -f2 || true)
          if [ -z "$id" ]; then
            page=$(curl -sL --max-time 15 -b 'CONSENT=YES+1' "$arg" || true)
            id=$(printf '%s' "$page" |
              grep -oE '<link rel="canonical" href="https://www.youtube.com/channel/UC[A-Za-z0-9_-]{22}' |
              head -1 | grep -oE 'UC[A-Za-z0-9_-]{22}' || true)
            # A video page: follow its channel's @handle link
            handle=$(printf '%s' "$page" | grep -oE '<link itemprop="url" href="https?://www.youtube.com/@[^"]+' |
              head -1 | grep -oE '@[^"]+' || true)
            if [ -z "$id" ] && [ -n "$handle" ]; then exec "$0" "$handle"; fi
          fi ;;
      esac
      [ -n "''${id:-}" ] || { echo "No channel id found for $arg" >&2; exit 1; }
      feed="https://www.youtube.com/feeds/videos.xml?channel_id=$id"
      if grep -qF "$id" "${here}/yturls"; then
        echo "Already subscribed: $feed"
      else
        printf '%s "YouTube Subscriptions"\n' "$feed" >> "${here}/yturls"
        echo "Added $feed"
      fi
    '';
  };

  # Ctrl-B in either newsboat appends the article to a plain-text bookmark list
  bookmark = pkgs.writeShellScript "newsboat-bookmark" ''
    f="${config.xdg.dataHome}/newsboat/bookmarks.txt"
    mkdir -p "$(dirname "$f")"
    printf '%s | %s | %s | %s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" "$2" "$4" >> "$f"
  '';

  # A desktop notification when a reload brings new articles (newsboat stays quiet otherwise)
  notify =
    what:
    lib.optionalString (!isDarwin) ''
      notify-program "${notifySend}"
      notify-format "%d new ${what}"
    '';

  lh = lib.getExe linkhandler;

  # Keys, colours and macros shared by newsboat and newsboat-yt
  common = ''
    show-read-feeds no
    show-read-articles no
    feed-sort-order unreadarticlecount-asc

    bookmark-cmd "${bookmark}"
    bookmark-autopilot yes

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

    # Only ANSI names and `default`, never fixed colours: the terminal maps them to
    # its palette, which the Omarchy theme sets, so newsboat follows theme switches.
    # The focused row is reverse video, readable on light and dark themes alike.
    color background default default
    color listnormal default default
    color listnormal_unread blue default bold
    color listfocus default default reverse
    color listfocus_unread default default reverse bold
    color info default default reverse bold
    color article default default

    highlight all "---.*---" yellow default bold
    highlight article "^(Feed|Title|Author):.*" cyan default bold
    highlight article "^(Link|Date):.*" color8 default
    highlight article "https?://[^ ]+" green default
    highlight article "\\[[0-9]+\\]" magenta default bold
    highlight article "\\[image [0-9]+\\]" green default bold
    highlight article ":.*\\(link\\)$" cyan default
    highlight article ":.*\\(image\\)$" blue default

    # , open · t download video · a download audio · v play in mpv · c copy link
    macro , open-in-browser
    macro t set browser "${lib.getExe qdl} video %u"; open-in-browser ; set browser ${lh}
    macro a set browser "${lib.getExe qdl} audio %u"; open-in-browser ; set browser ${lh}
    macro v set browser "setsid mpv"; open-in-browser ; set browser ${lh}
    macro c set browser "printf %s %u | ${copy}"; open-in-browser ; set browser ${lh}
  '';

  # Subscribe to a site: `rssadd <page or feed url>` finds the feed itself, the way
  # voidrice's rssget does (GitHub releases/commits/tags, GitLab, Reddit, a site's own
  # <link rel=alternate>); YouTube goes to ytadd. Also takes feed:// links, a downloaded
  # feed file, or the clipboard, and answers with a notification when not in a terminal.
  rssadd = pkgs.writeShellApplication {
    name = "rssadd";
    runtimeInputs = with pkgs; [
      curl
      gnugrep
      gnused
      gawk
      coreutils
      fzf
    ];
    text = ''
      ${notifyFn}
      say() { if [ -t 1 ]; then echo "$1"; else notify newsboat "$1"; fi; }

      src=''${1:-$(${paste} 2>/dev/null || true)}
      case "$src" in
        feed:http*) src=''${src#feed:} ;;
        feed://*) src="https://''${src#feed://}" ;;
      esac
      # A downloaded feed file: subscribe to the address it says it lives at
      if [ -f "$src" ]; then
        src=$(grep -Eom1 '<[^>]+(rel="self"|application/[a-z]+\+xml)[^>]+>' "$src" |
          grep -oE 'https?://[^" ]+' | head -1 || true)
      fi
      case "$src" in
        http*://*.*) ;;
        *) say "That doesn't look like a URL or a feed file."; exit 1 ;;
      esac
      case "$src" in
        *youtube.com/*|*youtu.be/*) exec ${lib.getExe ytadd} "$src" ;;
      esac

      origin=$(printf '%s' "$src" | grep -oE '^https?://[^/]+')
      base=''${src%%[?#]*}
      base=''${base%/}
      case "$src" in
        *://github.com/*/*) feeds=$(printf '%s\n' "$base/releases.atom" "$base/commits.atom" "$base/tags.atom") ;;
        *://github.com/*|*://gitlab.com/*) feeds="$base.atom" ;;
        *reddit.com/*) feeds="$base/.rss" ;;
        *)
          page=$(curl -sL --max-time 15 -A newsboat "$src" || true)
          if printf '%s' "$page" | head -c 2000 | grep -qiE '<rss|<feed|<rdf:RDF'; then
            feeds=$src
          else
            feeds=$(printf '%s' "$page" | grep -oiE '<link[^>]+>' |
              grep -iE "type=[\"']application/(rss|atom)\+xml" |
              sed -nE "s/.*href=[\"']([^\"']+)[\"'].*/\1/p" | sed 's/&amp;/\&/g' |
              while read -r h; do
                case "$h" in
                  http*) echo "$h" ;;
                  //*) echo "https:$h" ;;
                  /*) echo "$origin$h" ;;
                  *) echo "$base/$h" ;;
                esac
              done | awk '!seen[$0]++' || true)
          fi ;;
      esac
      [ -n "$feeds" ] || { say "No feed found on $src"; exit 1; }
      if [ "$(printf '%s\n' "$feeds" | wc -l)" -gt 1 ] && [ -t 0 ]; then
        feed=$(printf '%s\n' "$feeds" | fzf --prompt 'feed> ' --height 40%) || exit 1
      else
        feed=$(printf '%s\n' "$feeds" | head -1)
      fi
      if awk '{print $1}' "${here}/urls" | grep -qxF "$feed"; then
        say "Already subscribed: $feed"
      else
        echo "$feed" >> "${here}/urls" && say "Added $feed"
      fi
    '';
  };

  # Feed files and feed:// links open with rssadd
  rssTypes = [
    "application/rss+xml"
    "application/atom+xml"
    "x-scheme-handler/feed"
  ];
  xdgMime = if isArch then "/usr/bin/xdg-mime" else "${pkgs.xdg-utils}/bin/xdg-mime";
in
{
  programs.newsboat = {
    enable = true;
    package = lib.mkIf isArch null;
    autoReload = true;
    maxItems = 0;
    reloadThreads = 5;
    reloadTime = 60;
    # urls stay empty so Home Manager leaves the feed file to us (linked below)
    extraConfig = ''
      cache-file "${config.xdg.dataHome}/newsboat/cache.db"
      prepopulate-query-feeds yes

      browser ${lh}
      external-url-viewer "${exe pkgs.urlscan "urlscan"} -dc -r '${lh} {}'"

      podcast-auto-enqueue yes
      download-path "~/Downloads/podcasts/%h/%n"
      player "${exe pkgs.mpv "mpv"}"

      ${notify "articles"}
      ${common}
      # P save an arXiv paper
      macro P set browser "${lib.getExe downloadArxiv} %u"; open-in-browser ; set browser ${lh}
    '';
  };

  xdg.configFile = {
    "newsboat/urls".source = config.lib.file.mkOutOfStoreSymlink "${here}/urls";
    "newsboat/yturls".source = config.lib.file.mkOutOfStoreSymlink "${here}/yturls";
    # newsboat-yt: ~475 channel feeds, so reload them in parallel
    "newsboat/ytconfig".text = ''
      cache-file "${config.xdg.dataHome}/newsboat/ytcache.db"
      auto-reload yes
      reload-time 60
      reload-threads 10
      browser ${lh}
      ${notify "videos"}
      ${common}
    '';
  };

  home.packages = [
    rssadd
    ytadd
    qdl
    linkhandler
  ]
  ++ lib.optional (!isArch) pkgs.yt-dlp
  ++ [
    (pkgs.writeShellScriptBin "newsboat-yt" ''
      exec ${exe pkgs.newsboat "newsboat"} -C ${config.xdg.configHome}/newsboat/ytconfig -u ${config.xdg.configHome}/newsboat/yturls "$@"
    '')
  ];

  # A hidden "Add to newsboat" app for feed files and feed:// links. Only its own MIME
  # types are made default, with xdg-mime, so mimeapps.list stays unmanaged.
  xdg.desktopEntries = lib.mkIf (!isDarwin) {
    rssadd = {
      name = "Add to newsboat";
      exec = "${lib.getExe rssadd} %u";
      noDisplay = true;
      mimeType = rssTypes;
    };
  };
  home.activation.rssaddHandler = lib.mkIf (!isDarwin) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for t in ${lib.concatStringsSep " " rssTypes}; do
        if [ "$(${xdgMime} query default "$t" 2>/dev/null)" != rssadd.desktop ]; then
          run ${xdgMime} default rssadd.desktop "$t"
        fi
      done
    ''
  );
}
