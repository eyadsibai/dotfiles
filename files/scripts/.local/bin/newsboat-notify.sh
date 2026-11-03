#!/usr/bin/env bash
# newsboat-notify.sh - Desktop notification for new articles
# Arguments: $1=number of new articles
if [ "$1" -gt 0 ] 2>/dev/null; then
    notify-send -a "Newsboat" -i "application-rss+xml" \
        "Newsboat" "$1 new article(s)" \
        -t 5000
fi
