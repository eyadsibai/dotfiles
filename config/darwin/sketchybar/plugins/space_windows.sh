#!/usr/bin/env bash

if [ "$SENDER" = "space_windows_change" ]; then
  space="$(aerospace list-workspaces focused)"
  apps="$(aerospace list-windows --workspace "$space" | awk -F'|' '{print $2}' | xargs)"

  icon_strip=" "
  if [ "${apps}" != "" ]; then
    while read -r app
    do
      icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
    done <<< "${apps}"
  else
    icon_strip=" —"
  fi

  sketchybar --set space.$space label="$icon_strip"
fi
