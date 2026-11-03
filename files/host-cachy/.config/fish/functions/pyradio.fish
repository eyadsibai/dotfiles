function pyradio --wraps pyradio --description 'PyRadio, using the terminal palette instead of its own theme'
    # --no-themes puts PyRadio in "no theme mode", where every color pair is a
    # bare ANSI constant (COLOR_CYAN, COLOR_BLACK, ...) resolved by the terminal.
    # That makes it follow whatever palette omarchy has set for kitty, live.
    #
    # The documented alternative (~/.config/pyradio/no-themes-terminals) does not
    # work here: PyRadio's XDG migration relocates any file in ~/.config/pyradio
    # that isn't *-theme, *.csv, config, or radio-browser.conf.
    command pyradio --no-themes $argv
end
