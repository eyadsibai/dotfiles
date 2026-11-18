#!/bin/bash

# Guard: omarchy-hook (May 2026+) runs this dir a second time without the color
# env exported by the parent theme-set hook; skip that env-less pass entirely.
[[ -n "$primary_background" ]] || exit 0

# What spicetify adds to Spotify besides the colours. The first four come with
# spicetify; the rest are in files/spotify: alwaysPrivateSession.js is mine, and the two
# .mjs are the community's, each a loader that fetches its current code when Spotify
# starts. The lists are the whole truth: something enabled by hand with `spicetify
# config` is gone at the next theme change. What's installed inside Spotify from the
# Marketplace is the Marketplace's own and isn't touched.
extensions=(
    shuffle+.js             # "Play with Shuffle+" on a playlist or album: an unbiased shuffle
    keyboardShortcut.js     # vim keys: j/k scroll, g/G top and bottom, f jumps to a link
    fullAppDisplay.js       # the playing album over the whole window, for the TV
    trashbin.js             # a song or artist thrown in is skipped from then on
    alwaysPrivateSession.js # a private session, put back whenever Spotify ends it
    spicy-lyrics.mjs        # Spicy Lyrics: animated word-by-word lyrics as the lyrics view
    sort-play-loader.mjs    # Sort Play: sort a playlist by play count, release date and more
)
custom_apps=(
    lyrics-plus  # synced lyrics from several sources
    new-releases # what the artists I follow have released
    marketplace  # the community's extensions, installed and updated inside Spotify
)

create_spicetify_styling() {
    mkdir -p "$spicetify_dir/Themes/omarchy"
cat > "$spicetify_dir/Themes/omarchy/user.css" << EOF
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
/* The same three by where they sit, for a Spotify whose names spicetify doesn't know
   yet (1.3.8): the bands Spotify colours from the cover art, behind the top of Home,
   a playlist's header and its row of buttons. */
.main-view-container__scroll-node-child > main > div > div[style*="background-color"]:first-child,
.main-entityHeader-container > div[style*="background-color"]:first-child,
.main-view-container__scroll-node-child > main > section > div[style*="background-color"] {
    display: none !important;
}
.main-topBar-background,
.main-home-filterChipsSection {
    background-color: var(--spice-main) !important;
}
EOF
}

# The names from a list that are installed here, joined the way the config wants them.
# A list written for every machine mustn't name what one of them lacks, and the
# Marketplace arrives from the AUR after spicetify itself.
installed() { # installed -e "${extensions[@]}" | installed -a "${custom_apps[@]}"
    local kind=$1 name found=()
    shift
    for name in "$@"; do
        spicetify path "$kind" "$name" > /dev/null 2>&1 && found+=("$name")
    done
    local IFS='|'
    echo "${found[*]}"
}

# Writes one key of spicetify's config file directly. `spicetify config` can only add
# to or take from the two lists, never replace them, and silently drops a value that
# starts with a dash, as every launch flag does.
set_key() { # set_key extensions "a.js|b.js"
    local file=$spicetify_dir/config-xpui.ini
    KEY=$1 VALUE=$2 awk '
        $0 ~ "^" ENVIRON["KEY"] "[ \t]*=" { sub(/=.*/, ""); print $0 "= " ENVIRON["VALUE"]; next }
        { print }
    ' "$file" > "$file.new" && mv "$file.new" "$file"
}

configure_spicetify() {
    # inject_css and replace_colors are the theme: with either off Spotify stays stock.
    # spicetify's own update check only nags inside Spotify; pacman updates it here.
    spicetify config \
        current_theme omarchy color_scheme base \
        inject_css 1 replace_colors 1 \
        check_spicetify_update 0 > /dev/null

    # spicetify starts Spotify itself after an apply, without the wrapper that reads
    # spotify-flags.conf: without the same flags Spotify would come back under XWayland
    set_key spotify_launch_flags "$(grep -vE '^(#|$)' "${XDG_CONFIG_HOME:-$HOME/.config}/spotify-flags.conf" 2> /dev/null | paste -sd '|')"

    set_key extensions "$(installed -e "${extensions[@]}")"
    set_key custom_apps "$(installed -a "${custom_apps[@]}")"
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

cat > "$spicetify_dir/Themes/omarchy/color.ini" << EOF
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

# Where spicetify keeps its config and themes (~/.config/spicetify unless told otherwise)
spicetify_dir=$(dirname "$(spicetify -c)")

create_spicetify_styling
create_dynamic_theme
configure_spicetify

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
# Spotify or spicetify, or a switch finds it unthemed or this file changed) waits for
# the result; a theme switch doesn't
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
