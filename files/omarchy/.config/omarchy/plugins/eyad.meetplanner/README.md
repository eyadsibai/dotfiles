# Meeting Planner

A bar icon that opens a worldtimebuddy-style hour grid for **Elsewhen's
cities**: one 24-hour strip per city, all aligned on the same instant, with
working hours shaded and today's windows that suit everyone. Elsewhen
(`omarchy.elsewhen`) keeps the clocks and the city list; this plugin only adds
working hours and the overlap. Started from Simon Späti's
[omarchy-timezones-plugin](https://github.com/sspaeti/omarchy-timezones-plugin) (MIT).

- **Home** is the city on the system timezone (Elsewhen's "here" name when it
  has one); if no city matches, the system's city is added at the top.
- **UTC / Etc/GMT±N** rows are references: shown, never counted for overlap.
- **Hover** a column to read that moment in every city; **click** to pin it.
- **Overlap** buttons pick the first slot of each shared window (home time).
- **Copy** puts the pinned meeting as text (UTC plus each city's local times).
- Clicks: left opens, middle refreshes. Keys: `h`/`l` or arrows move the
  pinned hour, `n` back to now, `c` copy, `r` refresh, `Esc` close.
- 12h/24h follows Elsewhen's `hour24`, else the locale.

## Settings

All optional, on the widget's entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "eyad.meetplanner",
  "meetingMinutes": 60,
  "hours": {
    "Europe/London": { "days": [1, 2, 3, 4, 5], "start": "10:00", "end": "18:00" },
    "Europe/Istanbul": false
  }
}
```

- `hours` — keyed by timezone. Defaults: Mon–Fri 09:00–17:00 (Sun–Thu for
  Asia/Riyadh). `days` are 0 (Sunday) to 6; `end` may be `24:00` and may be
  before `start` for an overnight shift. `false` leaves a city out of the overlap.
- `meetingMinutes` — 15 to 240; the popup's duration picker saves it.
- `cities` — `[{ "name", "zone" }]` to plan across a list of your own instead
  of Elsewhen's.
- `hour24`, `icon` — override the clock format and the bar glyph.

IPC: `omarchy-shell eyad.meetplanner toggle|open|close|refresh|copyTimes`.

## Tests

From this folder (they are repo-only and not linked into `~`):

```sh
python3 -B -m unittest discover -s tests   # helper
node --test tests/                          # model
python3 tests/test_panel.py                 # real popup in headless Quickshell
```
