#!/bin/bash

# Guard: omarchy-hook runs this dir a second time without the color env exported
# by the parent theme-set hook; skip that env-less pass entirely.
[[ -n "$primary_background" ]] || exit 0

# qutebrowser colors itself: ~/.config/qutebrowser/omarchy/theme.py reads the
# applied theme's colors.toml on every config load. This hook only tells a
# running instance to re-source its config, and asks for a restart when the
# light/dark mode flipped (colors.webpage.preferred_color_scheme needs one).

if ! command -v qutebrowser >/dev/null 2>&1; then
    skipped "Qutebrowser"
fi

state_file="$HOME/.config/qutebrowser/omarchy/.last-mode"
prev_mode=""
[[ -f "$state_file" ]] && prev_mode=$(<"$state_file")
mkdir -p "$(dirname "$state_file")"
printf '%s\n' "$theme_mode" > "$state_file"

if pgrep -x qutebrowser >/dev/null 2>&1; then
    qutebrowser ':config-source' >/dev/null 2>&1 &
fi

if [[ -n "$prev_mode" && "$prev_mode" != "$theme_mode" ]]; then
    require_restart "qutebrowser"
fi

success "Qutebrowser theme reloaded!"
exit 0
