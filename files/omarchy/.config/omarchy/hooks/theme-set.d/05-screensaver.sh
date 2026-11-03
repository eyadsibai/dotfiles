#!/bin/bash

# Guard: omarchy-hook runs this dir a second time without the color env exported
# by the parent theme-set hook; skip that env-less pass entirely.
[[ -n "$primary_background" ]] || exit 0

# Per-theme screensaver art. Omarchy's screensaver only ever plays
# ~/.config/omarchy/branding/screensaver.txt, so a theme that ships its own
# screensaver.txt (e.g. sanabil) gets it copied there on apply, and switching to
# a theme without one puts back whatever was there before.
#
# The copy we installed is remembered by checksum. If the branding file no longer
# matches it (edited via Style > Screensaver, or `omarchy branding screensaver`),
# the user's edit wins: it is stashed rather than overwritten, and never replaced
# by a stale stash on the way out.

branding="$HOME/.config/omarchy/branding/screensaver.txt"
state_dir="$HOME/.local/state/omarchy/theme-screensaver"
stash="$state_dir/user-screensaver.txt"
marker="$state_dir/applied.sha256"
theme_art="$theme_dir/screensaver.txt"

checksum() {
    sha256sum "$1" 2>/dev/null | cut -d' ' -f1
}

ours_is_installed() {
    [[ -f "$marker" && -f "$branding" && "$(checksum "$branding")" == "$(<"$marker")" ]]
}

mkdir -p "$state_dir" "${branding%/*}"

if [[ -f "$theme_art" ]]; then
    if [[ -f "$branding" ]] && ! ours_is_installed; then
        cp "$branding" "$stash"
    fi
    cp "$theme_art" "$branding"
    checksum "$branding" > "$marker"
    success "screensaver art from theme"
elif [[ -f "$marker" ]]; then
    if ours_is_installed; then
        if [[ -f "$stash" ]]; then
            cp "$stash" "$branding"
        else
            cp "${OMARCHY_PATH:-/usr/share/omarchy}/logo.txt" "$branding"
        fi
        success "screensaver art restored"
    fi
    rm -f "$marker" "$stash"
fi
