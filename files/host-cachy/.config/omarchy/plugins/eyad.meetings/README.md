# Meeting notes for Omarchy

A bar widget for [Voxtype](https://github.com/peteonrails/voxtype)'s meeting
mode. Click it, name the meeting (prefilled from your Akiflow calendar when the
Akiflow plugin is on), and record. Transcription runs locally with Whisper, on
your microphone ("You") and the audio you hear ("Remote"). When you stop, the
transcript is saved as Markdown, and Claude can turn it into a summary with
decisions and action items.

## Install

```sh
just install    # tests, copy to ~/.config/omarchy/plugins/eyad.meetings, restart the shell, enable
```

Needs `voxtype` with `[meeting] enabled = true`, plus `jq`, `pactl`, `notify-send` and `rsync`.
Summaries need the `claude` CLI.

## Use

| Where | What |
| --- | --- |
| Pill | Podcast icon when idle; a red speaking-person icon and `12:34` while recording, `⏸ 12:34` paused, a document-edit icon and `…` while the transcript is saved |
| Left click | Popup: title field, Record, audio checks, recent meetings |
| Middle click | Stop |
| Right click | Start immediately (Akiflow title or "Meeting HH:MM"), or stop |

In the popup, Enter starts recording; while recording, Space pauses and `s`
stops. Click a past meeting to open its notes. The row buttons summarize (or
open the summary), copy the transcript, and delete the recording (click twice;
notes files stay).

Before you record, the popup checks for problems that would give an empty or
one-sided transcript:

- **Muted microphone.** Offers Unmute.
- **Remote audio from the wrong output.** Voxtype's `loopback_device = "auto"`
  records the first output it finds, not the one you listen on, so with a
  headset or a Bluetooth speakerphone the other side of the call is missing.
  Fix sets `loopback_device = "@DEFAULT_MONITOR@"` in
  `~/.config/voxtype/config.toml` (backup kept) and restarts Voxtype.
- **Voxtype not running**, or its config changed since it started. Offers
  Start or Restart.

IPC for bindings and scripts:

```sh
omarchy-shell meetings toggle          # start with the suggested title, or stop
omarchy-shell meetings start "Title"
omarchy-shell meetings stop
omarchy-shell meetings pause           # pause or resume
omarchy-shell meetings popup
omarchy-shell meetings status
```

## Files

Notes: `~/Documents/Meetings/2026-09-14 15.43 Weekly sync.md`, and
`… Weekly sync.summary.md` once summarized. Recordings and transcripts stay in
Voxtype's store (`~/.local/share/voxtype/meetings`); audio is not kept.

Summaries send the transcript text to Anthropic through the `claude` CLI with
no tools enabled and no saved session. Nothing else leaves the machine.

## Settings

| Key | Default | |
| --- | --- | --- |
| `notesDir` | `~/Documents/Meetings` | Where notes and summaries are written |
| `openWith` | `default` | `default` (the app for Markdown) or `editor` (Omarchy editor) |
| `useAkiflowTitle` | true | Prefill the title from the current or next Akiflow meeting |
| `autoSummarize` | false | Summarize every meeting when it ends |
| `recentCount` | 6 | Past meetings listed in the popup |

## Known Voxtype limits

- Nothing is written while recording; the transcript appears a few seconds
  after stopping (longer for long meetings).
- A few words can go missing at each 30-second chunk boundary.
- Names and jargon are often misheard. `[text] replacements` in Voxtype's
  config can fix recurring ones, for example `{ "amarky" = "Omarchy" }`.

## Development

```sh
just test   # node --test lib/
just lint   # bash -n, shellcheck if installed, qmllint
just logs
```

`bin/meetings` does all Voxtype and PipeWire work and prints JSON;
`lib/Meetings.js` holds the logic the tests cover; `Service.qml` follows
`$XDG_RUNTIME_DIR/voxtype/meeting_state`; `BarWidget.qml` renders.
