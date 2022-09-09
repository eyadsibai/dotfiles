{ writeShellApplication
, curl
, sxiv
, mpv
,
}:
writeShellApplication {
  name = "linkhandler";

  runtimeInputs = [ curl sxiv mpv ];

  text = ''
      #!/bin/sh

    # Feed script a url or file location.
    # If an image, it will view in sxiv,
    # if a video or gif, it will view in mpv
    # if a music file or pdf, it will download,
    # otherwise it opens link in browser.

    # If no url given. Opens browser. For using script as $BROWSER.
    [ -z "$1" ] && { "$BROWSER"; exit; }

    case "$1" in
      *mkv|*webm|*mp4|*youtube.com/watch*|*youtube.com/playlist*|*youtu.be*|*hooktube.com*|*bitchute.com*)
        setsid mpv --input-ipc-server=/tmp/mpvsoc"$(date +%s)" -quiet "$1" >/dev/null 2>&1 & ;;
      *png|*jpg|*jpe|*jpeg|*gif)
        curl -sL "$1" > "/tmp/$(echo "$1" | sed "s/.*\///")" && sxiv -a "/tmp/$(echo "$1" | sed "s/.*\///")"  >/dev/null 2>&1 & ;;
      *mp3|*flac|*opus|*mp3?source*)
        setsid tsp curl -LO "$1" >/dev/null 2>&1 & ;;
      *)
        if [ -f "$1" ]; then "$TERMINAL" -e "$EDITOR $1"
        else setsid "$BROWSER" "$1" >/dev/null 2>&1 & fi ;;
    esac

  '';
}
