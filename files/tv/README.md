# tv

Live TV in mpv, opened from the `TV` launcher entry or the `tv` command.

```
tv                  resume the last channel (or channel 1)
tv 12 | tv mbc      start on a channel number or name
tv --list [query]   list channels
tv --check          probe the channels; --prune hides dead ones, --revive brings them back
```

While watching: `ENTER`/`c` opens the channel menu (Favorites, Recent, then categories; type to search), `0-9` jumps to a channel, `PGUP`/`PGDN` changes channel, `TAB` goes back to the last one, `s` stars the channel (`Ctrl+S` on a menu row), `/` or `Shift+ENTER` lists every channel with the search open, `-`/`+` changes volume, `m`/`M` mutes, and `r` reloads it. These keys are bound in `tv.lua`, so they only apply inside TV and need no `input.conf`.

The menu files channels under categories (News, General, Series & Drama, Movies, Kids & Family, Sports, Documentary, Music & Radio, Religious, Other) taken from the `<source> - <kind>` group-titles, with the source as a language; names drop `(1080p)`, and `[Geo-blocked]`/`[Not 24/7]` become tags. `tv.m3u` keeps its own groups. A banner shows each channel: its `tvg-logo` (cached in `~/.cache/tv/logos`) or initials, number, name, category, language, and the channel `TAB` returns to.

Colours follow the Omarchy theme (`~/.local/state/omarchy/current/theme/colors.toml`) for uosc and the banner, re-read while playing, and the menus use the Omarchy font (`omarchy-font-current`; `$TV_FONT` overrides).

## Two channels at once

`tv --pip <channel>` opens a second TV: small, muted, floating and pinned top-right on every workspace (the `hypr` package's `mpv-tv-pip` rule), for keeping an eye on a news channel while watching another. In either window `a` takes the sound and mutes the other, and `x` swaps their channels; the bar's popup does the same and closes it. `tv --pip <channel>` again switches the open one. It has its own socket (`pip.sock`) and state file (`pip.json`) and never touches the main TV's last channel, recent list or bar files. `tv --pip-ctl <action>` sends it the same actions as `tv --ctl`.

## The bar

While TV runs, the Omarchy bar shows it (the `eyad.tv` plugin, `.config/omarchy/plugins/eyad.tv`): click for a popup that searches every channel and lists favorites and recent ones (each row can also open its channel in the corner TV); scroll changes channel, middle-click goes back, right-click opens TV's own menu. It reads `$XDG_RUNTIME_DIR/tv/now.json` and `channels.json`, written by `tv.lua`, and talks back through `tv --ctl menu|next|prev|last|star|play <N>` (mpv's IPC socket, `$XDG_RUNTIME_DIR/tv/mpv.sock`). `tv --bar` prints the playing channel as JSON.

## Files

| Path | Role |
|---|---|
| `.local/bin/tv` | Launcher. Rebuilds the channel list (`tv-check --sync`), numbers channels and resumes the last one |
| `.local/bin/tv-check` | `uv` script. Probes every channel with ffprobe, keeps failure and success streaks, prunes channels dead 2+ runs and revives pruned ones live 2+ runs, and builds the channel list the player plays |
| `.config/mpv/tv/tv.conf` | The `[tv]` mpv profile. The launcher loads it with `--include`, so `~/.config/mpv/mpv.conf` stays untouched |
| `.config/mpv/tv/tv.lua` | Per-channel HTTP headers and signed-link resolving from the m3u, uosc channel menu by category with favorites and recent, channel banner, Omarchy theme, digit entry, auto-reconnect, dead-channel guard, state for the bar |
| `.config/omarchy/plugins/eyad.tv` | The Omarchy bar widget |
| `.local/share/applications/TV.desktop` | App launcher entry (runs `tv` from `PATH`) |
| `.local/share/icons/hicolor/scalable/apps/tv.svg` | Its icon |
| `.config/tv/tv.m3u` | The channel playlist (or `$TV_M3U`). Yours to edit; the tools only read it |
| `.config/systemd/user/tv-check.{service,timer}` | Weekly check that prunes and revives channels |
| `tests/parsers.sh` | Checks that tv, tv-check and tv.lua parse the playlist the same way (not stowed) |
| `tests/test_tv.py` | Offline regression tests for playlist updates, concurrent checks, launcher arguments and mpv state (not stowed) |

## Signed links

Some channels (Al Kass) only play with a short-lived token. Their entry keeps the bare URL and adds `tv-resolve="<m3u url>"`; each time the channel opens or reconnects, tv.lua fetches that m3u and plays its line whose URL minus the `?query` matches, and tv-check probes the same way. The Al Kass links come from a third-party relay, `alkass.aboozayed.web.id`, and only play from a Gulf IP (e.g. a Tailscale exit node in Saudi Arabia), so they are tagged `[Geo-blocked]`.

## Not in the package

- `${XDG_STATE_HOME:-~/.local/state}/tv/`: last channel, `favorites`, `recent`, `health.json`, the pruned channels (`offline.m3u`) and the channel list the player plays (`playing.m3u`).
- The Hyprland window rule that tiles `mpv-tv` at full opacity. It lives in the `hypr` package.

## Needs

`mpv`, uosc for the grouped channel menu (Arch: `mpv-uosc`; without it the menu is mpv's flat playlist picker), `ffmpeg`, `uv`, and `stow` to install.

TV uses uosc whether or not the rest of mpv does. If the mpv config autoloads uosc (`scripts/uosc.lua` or `scripts/uosc/`), TV uses that copy. Otherwise `tv` loads the installed one for TV only (`$TV_UOSC`, default `/usr/share/mpv/scripts/uosc`) and turns off mpv's OSC and OSD bar, which uosc replaces. When uosc's icon font isn't in `~/.config/mpv/fonts`, `tv` points mpv at the package's fonts; without them every icon is drawn as its name (`chevron_right`).

## Install

`tv` is a stow package like the others in this repo, linked from `~/dotfiles`. `.stow-local-ignore` keeps this README, `ruff.toml` and `tests/` out of `~`.

```sh
cd ~/dotfiles
stow -n -v tv    # dry run
stow tv          # link
stow -D tv       # unlink
stow -R tv       # after pulling: links new files, drops links to moved/deleted ones
systemctl --user enable --now tv-check.timer   # optional weekly prune and revive
```

Nothing writes to `tv.m3u`; add, edit or remove channels there and commit. The player plays `~/.local/state/tv/playing.m3u` instead: `tv.m3u` minus the pruned channels listed in `~/.local/state/tv/offline.m3u`. `tv` rebuilds it on every start, so edits to `tv.m3u` show up the next time you open TV. The weekly timer runs the same thing as:

```sh
tv --check --prune --revive
```

A channel is pruned after failing 2 runs in a row. It is revived, back at its place in `tv.m3u`, after working 2 runs in a row. Channel numbers follow `playing.m3u`, so they shift when a channel is pruned or revived. Remove a channel from `tv.m3u` and its `offline.m3u` entry no longer counts. `--prune` does nothing when over half the channels are dead, since that's the network rather than the channels. Note that 35 channels are plain `http://`, unencrypted.

All three tools honor `XDG_STATE_HOME`. Custom playlists selected with `TV_M3U` or `tv-check -p` keep their `offline.m3u` and `playing.m3u` in `tv/playlists/<path-hash>/`; the hash uses the resolved playlist path, so symlink aliases share them. Health records are shared by URL, and checking another playlist preserves existing records.

Only one `tv-check` check runs at a time; an overlapping one exits with an error. `--sync` doesn't wait for a running check, only for its final write. Edits to `tv.m3u` during a check are picked up when it rebuilds `playing.m3u`; a hand edit to `offline.m3u` during a check stops its update. If writing `playing.m3u` fails, the next `tv` start rebuilds it.

## Development

The checks live at the repo root (`.pre-commit-config.yaml`, `.github/workflows/tv.yml`) and only look at `tv/`. From `~/dotfiles`:

```sh
uvx pre-commit install     # shellcheck, ruff, parser and regression tests on every commit
uvx pre-commit run -a      # same checks by hand (CI runs these too)
uv run --no-project --python '>=3.12' python -B -m unittest discover -s tv/tests -v
```

Regression tests use temporary directories and a fake `ffprobe`; they never probe live streams. With mpv installed, they also exercise Lua state handling using local audio. CI installs mpv so these integration tests run there too.
