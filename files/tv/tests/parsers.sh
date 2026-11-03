#!/usr/bin/env bash
# The playlist is parsed three times: by tv (awk), tv-check (Python) and tv.lua.
# Check that they agree on every channel's number, group, name and URL, for the
# real playlist and for tests/edge.m3u.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
# tv builds its channel list under XDG_STATE_HOME; keep that out of the real one.
export XDG_STATE_HOME="$tmp/state"

fail=0
for m3u in "$root/.config/tv/tv.m3u" "$root/tests/edge.m3u"; do
  name="$(basename "$m3u")"
  TV_M3U="$m3u" "$root/.local/bin/tv" --dump > "$tmp/awk"
  "$root/.local/bin/tv-check" --dump -p "$m3u" > "$tmp/python"
  if ! diff -u --label "$name: tv (awk)" --label "$name: tv-check (python)" "$tmp/awk" "$tmp/python"; then
    fail=1
  fi

  # tv.lua keys channels by URL (first entry wins) and has no numbering, so
  # compare the unique group/name/url rows.
  if command -v mpv >/dev/null; then
    timeout 20 mpv --no-config --idle=yes --vo=null --ao=null --msg-level=all=error \
      --script="$root/.config/mpv/tv/tv.lua" \
      --script-opts="tv-playlist=$m3u,tv-dump=$tmp/lua.raw,tv-health_file=$tmp/none.json"
    sort -u "$tmp/lua.raw" > "$tmp/lua"
    awk -F'\t' '!seen[$4]++ { print $2 "\t" $3 "\t" $4 }' "$tmp/awk" | sort -u > "$tmp/awk-rows"
    if ! diff -u --label "$name: tv (awk)" --label "$name: tv.lua" "$tmp/awk-rows" "$tmp/lua"; then
      fail=1
    fi
  else
    echo "parsers.sh: mpv not found, skipping tv.lua" >&2
  fi
done

if [ "$fail" -eq 0 ]; then echo "parsers agree"; fi
exit "$fail"
