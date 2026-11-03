#!/usr/bin/env bash
# newsboat-bookmark.sh - Save bookmarks from newsboat
# Arguments: $1=url $2=title $3=description $4=feed_title
BOOKMARKS="${HOME}/.newsboat/bookmarks.txt"
echo "$(date '+%Y-%m-%d %H:%M') | ${1} | ${2} | ${4}" >> "${BOOKMARKS}"
