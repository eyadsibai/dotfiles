#!/usr/bin/env bash
# newsboat-urlhandler.sh - Smart URL router
# Routes videos to mpv, images to kitty icat, rest to browser
URL="$1"

case "$URL" in
    *youtube.com/watch*|*youtu.be/*|*youtube.com/shorts/*|\
    *vimeo.com/*|*twitch.tv/*|*odysee.com/*|\
    *.mp4|*.mkv|*.webm|*.mp3|*.m4a|*.ogg|*.opus)
        setsid mpv --really-quiet "$URL" &>/dev/null &
        ;;
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.svg)
        kitty +kitten icat --hold "$URL"
        ;;
    *)
        setsid xdg-open "$URL" &>/dev/null &
        ;;
esac
