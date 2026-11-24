hyprmoncfg's monitor profiles: one JSON per place a laptop gets plugged in, with the
`.conf` and `.lua` copies hyprmoncfg writes beside each. They are saved from its panel
in the bar (or `hyprmoncfg` in a terminal), not written by hand.

`~/.config/hyprmoncfg/profiles` is this folder (linked whole in `hosts/vector`), so a
profile saved in the panel shows up here in `git status`. Every `*.json` in it is a
candidate when the daemon picks a layout for the screens that are connected, so delete
the ones no longer wanted rather than keeping them around.
