// Pure helpers for the Meeting notes widget. QML imports this file as-is, so
// there is no module.exports; lib/load.js wraps it for node tests.

function defaults() {
  return {
    notesDir: "~/Documents/Meetings",
    openWith: "default",
    useAkiflowTitle: true,
    autoSummarize: false,
    recentCount: 6
  }
}

function withDefaults(settings) {
  var out = defaults()
  if (settings && typeof settings === "object") {
    for (var k in settings) {
      if (k !== "id" && settings[k] !== undefined && settings[k] !== null && settings[k] !== "") out[k] = settings[k]
    }
  }
  return out
}

// Settings live inline on the plugin's bar layout entry in shell.json.
function findEntry(config, id) {
  var layout = config && config.bar && config.bar.layout
  if (layout) {
    var sections = ["left", "center", "right"]
    for (var i = 0; i < sections.length; i++) {
      var list = layout[sections[i]] || []
      for (var j = 0; j < list.length; j++) {
        var entry = list[j]
        if (entry && typeof entry === "object" && entry.id === id) return entry
        if (entry === id) return { id: id }
      }
    }
  }
  var plugins = (config && config.plugins) || []
  for (var p = 0; p < plugins.length; p++) {
    if (plugins[p] && plugins[p].id === id) return plugins[p]
  }
  return null
}

// $XDG_RUNTIME_DIR/voxtype/meeting_state: "idle", or "recording"/"paused"
// followed by the meeting id on the next line.
function parseMeetingState(text) {
  var lines = String(text || "").split("\n").map(function(l) { return l.trim() }).filter(function(l) { return l !== "" })
  var state = lines[0] || "idle"
  if (state !== "recording" && state !== "paused") return { state: "idle", id: "" }
  return { state: state, id: lines[1] || "" }
}

function pad2(n) { return (n < 10 ? "0" : "") + n }

// Running clock: 4:05, 1:02:03.
function fmtElapsed(secs) {
  secs = Math.max(0, Math.floor(secs || 0))
  var h = Math.floor(secs / 3600), m = Math.floor(secs / 60) % 60, s = secs % 60
  return h > 0 ? h + ":" + pad2(m) + ":" + pad2(s) : m + ":" + pad2(s)
}

// Length of a finished meeting: 42s, 23m, 1h 5m.
function fmtDuration(secs) {
  secs = Math.max(0, Math.round(secs || 0))
  if (secs < 60) return secs + "s"
  var m = Math.round(secs / 60)
  if (m < 60) return m + "m"
  return Math.floor(m / 60) + "h" + (m % 60 ? " " + (m % 60) + "m" : "")
}

function fmtWords(n) {
  n = n || 0
  if (n === 0) return "no speech"
  if (n === 1) return "1 word"
  if (n < 1000) return n + " words"
  return (Math.round(n / 100) / 10).toString().replace(/\.0$/, "") + "k words"
}

function startOfDay(ms) {
  var d = new Date(ms)
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
}

// Today 15:43, Yesterday 09:00, Mon 14 Sep, 3 Feb 2025.
function fmtWhen(ms, nowMs) {
  if (!ms) return ""
  var d = new Date(ms)
  var time = pad2(d.getHours()) + ":" + pad2(d.getMinutes())
  var days = Math.round((startOfDay(nowMs) - startOfDay(ms)) / 86400000)
  if (days === 0) return "Today " + time
  if (days === 1) return "Yesterday " + time
  var names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  if (days > 1 && days < 7) return names[d.getDay()] + " " + time
  var sameYear = d.getFullYear() === new Date(nowMs).getFullYear()
  return (days > 0 && days < 180 && sameYear ? names[d.getDay()] + " " : "") + d.getDate() + " " + months[d.getMonth()] + (sameYear ? "" : " " + d.getFullYear())
}

// Voxtype stores nanosecond RFC 3339 timestamps; Date only takes milliseconds.
function parseTime(iso) {
  if (!iso) return 0
  var trimmed = String(iso).replace(/(\.\d{3})\d+/, "$1")
  var ms = Date.parse(trimmed)
  return isNaN(ms) ? 0 : ms
}

function defaultTitle(nowMs) {
  var d = new Date(nowMs)
  return "Meeting " + pad2(d.getHours()) + ":" + pad2(d.getMinutes())
}

// Title from the Akiflow plugin's agenda: the meeting in progress, else one
// starting within `aheadSecs`. Returns { title, eventId } or null.
function akiflowSuggestion(agenda, nowMs, aheadSecs) {
  if (!agenda || !agenda.timeline) return null
  var nowSec = Math.floor(nowMs / 1000)
  var current = null, next = null
  for (var i = 0; i < agenda.timeline.length; i++) {
    var it = agenda.timeline[i]
    if (it.kind !== "event" || it.allDay || it.declined) continue
    if (it.startTs <= nowSec && nowSec < it.endTs) { if (!current) current = it }
    else if (it.startTs > nowSec && it.startTs - nowSec <= aheadSecs) { if (!next || it.startTs < next.startTs) next = it }
  }
  // Right before a back-to-back meeting, the next one is the one to record.
  var pick = current && next && next.startTs - nowSec <= 5 * 60 ? next : (current || next)
  if (!pick) return null
  return { title: pick.label || pick.title, eventId: pick.id || "" }
}

function shortDevice(description) {
  return String(description || "").replace(/^Monitor of /, "").replace(/\s*\[[^\]]*\]\s*$/, "").trim()
}

// Problems that would make a recording come out empty or one-sided, each
// with the action the widget offers for it.
function audioIssues(audio, recording) {
  var out = []
  if (!audio) return out
  if (!audio.daemon) {
    out.push({ kind: "daemon", severity: "error", text: "Voxtype isn't running", action: "restart-daemon", actionText: "Start" })
    return out
  }
  if (audio.meetingEnabled === false) {
    out.push({ kind: "disabled", severity: "error", text: "Meeting mode is off in Voxtype's config ([meeting] enabled = false)", action: "", actionText: "" })
  }
  if (!audio.mic) {
    out.push({ kind: "mic", severity: "error", text: "No microphone found", action: "", actionText: "" })
  } else if (audio.mic.muted) {
    out.push({ kind: "mic", severity: "error", text: shortDevice(audio.mic.description) + " microphone is muted", action: "unmute", actionText: "Unmute" })
  }
  if (!audio.followsOutput) {
    out.push({ kind: "loopback", severity: "warning",
      text: "Other people's voices may not be recorded: Voxtype picks an output on its own instead of the one you use",
      action: recording ? "" : "fix-loopback", actionText: "Fix" })
  } else if (audio.configPending) {
    out.push({ kind: "loopback", severity: "warning", text: "Voxtype needs a restart to use its new audio settings",
      action: recording ? "" : "restart-daemon", actionText: "Restart" })
  }
  return out
}

// Pill text and tooltip.
// Nerd Font glyphs, one per bar state. The dictation indicator already uses
// the microphone and the hourglass, so these stay clear of both.
function barIcon(state) {
  if (state === "recording") return "\udb81\uddcb" // nf-md-account_voice
  if (state === "paused") return "\uf04c" // nf-fa-pause
  if (state === "processing") return "\udb83\uddc8" // nf-md-file_document_edit
  return "\uf2ce" // nf-fa-podcast
}

function barInfo(status, nowMs) {
  if (status.processing) {
    return { text: "Transcribing", tooltip: "Transcribing “" + status.processing.title + "”", active: false, state: "processing", icon: barIcon("processing") }
  }
  if (status.state === "recording" || status.state === "paused") {
    var elapsed = fmtElapsed(elapsedSecs(status, nowMs))
    var title = status.current ? status.current.title : "Meeting"
    return {
      text: elapsed,
      tooltip: (status.state === "paused" ? "Paused · " : "Recording · ") + title + " · middle-click to stop",
      active: status.state === "recording",
      state: status.state,
      icon: barIcon(status.state)
    }
  }
  return { text: "", tooltip: "Meeting notes · click to record", active: false, state: "idle", icon: barIcon("idle") }
}

// Seconds recorded, not counting pauses seen by this shell.
function elapsedSecs(status, nowMs) {
  if (!status.current || !status.current.startedMs) return 0
  var paused = status.pausedMs || 0
  if (status.state === "paused" && status.pauseStartMs) paused += nowMs - status.pauseStartMs
  return Math.max(0, (nowMs - status.current.startedMs - paused) / 1000)
}

function meetingMeta(meeting, nowMs) {
  var parts = [fmtWhen(parseTime(meeting.startedAt), nowMs)]
  if (meeting.durationSecs) parts.push(fmtDuration(meeting.durationSecs))
  if (meeting.status === "active") parts.push("in progress")
  else if (!meeting.transcribed) parts.push("transcribing")
  else parts.push(fmtWords(meeting.words))
  return parts.join(" · ")
}
