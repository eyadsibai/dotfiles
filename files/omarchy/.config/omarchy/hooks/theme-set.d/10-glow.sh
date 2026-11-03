#!/bin/bash

# Guard: omarchy-hook runs this dir a second time without the color env exported
# by the parent theme-set hook; skip that env-less pass entirely.
[[ -n "$primary_background" ]] || exit 0

# glow renders markdown with a named style; only "dark" vs "light" matters here.
# Edits the style line in place so the rest of glow.yml is untouched.

if ! command -v glow >/dev/null 2>&1; then
    skipped "Glow"
fi

config_dir="$HOME/.config/glow"
config_file="$config_dir/glow.yml"
style="dark"
[[ "$theme_mode" == "light" ]] && style="light"

mkdir -p "$config_dir"
if [[ ! -f "$config_file" ]]; then
    printf '# style name or JSON path (default "auto")\nstyle: "%s"\n' "$style" > "$config_file"
elif grep -qE '^\s*style:' "$config_file"; then
    sed -i -E "s|^(\s*style:).*|\1 \"$style\"|" "$config_file"
else
    printf 'style: "%s"\n' "$style" >> "$config_file"
fi

success "Glow style set to $style!"
exit 0
