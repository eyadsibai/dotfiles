#!/bin/bash

# Guard: omarchy-hook (May 2026+) runs this dir a second time without the color
# env exported by the parent theme-set hook; skip that env-less pass entirely.
[[ -n "$primary_background" ]] || exit 0

create_spicetify_styling() {
    mkdir -p "$HOME/.config/spicetify/Themes/omarchy"
cat > "$HOME/.config/spicetify/Themes/omarchy/user.css" << EOF
:root,
.encore-dark-theme,
.encore-base-set,
.encore-inverted-light-set {
    --background-highlight: rgba(var(--spice-rgb-highlight), 0.25) !important;
}
.main-nowPlayingBar-container {
    background-color: var(--background-base);
    border-radius: 0.5rem;
    padding: 0.5rem;
    color: var(--spice-text);
}
.main-entityHeader-backgroundColor {
    display: none !important;
}
.main-actionBarBackground-background {
    display: none !important;
}
.main-home-homeHeader {
    display: none !important;
}
.main-topBar-background,
.main-home-filterChipsSection {
    background-color: var(--spice-main) !important;
}
EOF
}

change_spicetify_theme() {
    spicetify config current_theme omarchy > /dev/null
    spicetify config color_scheme base > /dev/null
}

create_dynamic_theme() {
    color00=${primary_background}
    color01=${normal_black}
    color02=${bright_black}
    color03=${normal_white}
    color04=${bright_white}
    color05=${primary_foreground}
    color06=${bright_white}
    color07=${bright_white}
    color08=${normal_red}
    color09=${normal_yellow}
    color0A=${bright_yellow}
    color0B=${normal_green}
    color0C=${normal_cyan}
    color0D=${normal_blue}
    color0E=${normal_magenta}
    color0F=${bright_red}

cat > "$HOME/.config/spicetify/Themes/omarchy/color.ini" << EOF
[base]
main                = ${color00}
player              = ${color00}
card                = ${color00}
main-elevated       = ${color00}
sidebar             = ${color00}
shadow              = ${color00}
notification        = ${color02}
button-disabled     = ${color02}
misc                = ${color03}
selected-row        = ${color03}
button              = ${color03}
highlight           = ${color07}
notification-error  = ${color08}
button-active       = ${color0B}
subtext             = ${color03}
text                = ${color07}
EOF
}

if ! command -v spicetify >/dev/null 2>&1; then
    skipped "Spicetify"
fi

create_spicetify_styling
create_dynamic_theme
change_spicetify_theme

# Spotify writes its prefs at its first launch, and spicetify won't start without the
# file: an empty one does until then
if [[ ! -e $HOME/.config/spotify/prefs ]]; then
    mkdir -p "$HOME/.config/spotify"
    : > "$HOME/.config/spotify/prefs"
fi

# A plain apply needs spicetify's backup of this Spotify. There's none the first time,
# and an upgraded Spotify makes the old one useless; then take a fresh one. A Spotify
# that isn't running stays closed (-n); a running one restarts with the theme.
apply_theme() {
    local args=()
    pgrep -x spotify > /dev/null 2>&1 || args=(-n)
    spicetify apply "${args[@]}" ||
        spicetify backup apply "${args[@]}" ||
        spicetify restore backup apply "${args[@]}"
}

# The spotify-theme service (modules/home/arch.nix: after pacman installs or upgrades
# Spotify, or a switch finds it unthemed) waits for the result; a theme switch doesn't
if [[ -n $SPOTIFY_THEME_WAIT ]]; then
    if ! apply_theme > /dev/null 2>&1; then
        warning "spicetify couldn't theme Spotify; try: spicetify restore backup apply"
        exit 1
    fi
else
    (apply_theme > /dev/null 2>&1 &)
fi

success "Spotify theme updated!"
exit 0
