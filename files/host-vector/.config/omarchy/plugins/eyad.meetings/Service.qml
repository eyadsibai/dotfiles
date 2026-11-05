import QtQuick
import Quickshell
import Quickshell.Io
import "lib/Meetings.js" as Meetings

// One per shell: follows the recorder's state (omarchy-meetings), runs meeting
// commands, and saves notes when a meeting ends. The bar widgets (one per
// monitor) render what this exposes. Every engine and PipeWire call goes
// through bin/meetings.
Item {
  id: root
  visible: false

  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest && manifest.id ? manifest.id : "eyad.meetings"
  readonly property string pluginDir: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string helper: pluginDir + "/bin/meetings"
  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/run/user/1000"
  readonly property string glyph: "\uf2ce" // nf-fa-podcast

  readonly property var settings: Meetings.withDefaults(shell ? Meetings.findEntry(shell.shellConfig, pluginId) : null)
  readonly property string notesDir: String(settings.notesDir || "~/Documents/Meetings")

  // The recorder's view of the meeting.
  property string meetingState: "idle"     // idle | recording | paused
  property string meetingId: ""
  property var current: null               // { id, title, startedMs }
  property double pausedMs: 0
  property double pauseStartMs: 0
  // A meeting that stopped and is still being transcribed.
  property var processing: null            // { id, title }

  // Levels (0..1) of the microphone and the computer audio: from the recorder
  // while recording, from `meetings levels` while the popup is open before it.
  property var levels: ({ mic: 0, system: 0 })
  property var liveLines: []
  property string notesText: ""

  property var recent: []
  property var audio: null
  property double nowMs: Date.now()
  property int popupsOpen: 0
  property string summarizingId: ""
  property string lastError: ""
  property var pendingStart: null          // { title, at }
  // The meeting that just finished transcribing, for the popup's "Ready" card.
  property var justFinished: null
  // Theme colours beyond the shell's Color singleton (speakers, call audio).
  property var themeColors: Meetings.parsePalette("")

  readonly property bool active: meetingState === "recording" || meetingState === "paused"
  readonly property var info: Meetings.barInfo({ state: meetingState, current: current, pausedMs: pausedMs, pauseStartMs: pauseStartMs, processing: processing }, nowMs)
  readonly property var issues: Meetings.audioIssues(audio, active)

  // ----------------------------------------------------------- meeting state

  // state.json is written by the recorder four times a second while it runs
  // and removed when it ends. Elapsed time comes from the recorder, so pauses
  // are counted there, not here.
  function applyMeetingState(text) {
    var st = parseJson(text) || { state: "idle" }
    var state = st.state === "finalising" ? "recording" : st.state
    if (state !== "recording" && state !== "paused") state = "idle"
    var id = state === "idle" ? "" : String(st.id || "")
    var wasId = meetingId, wasCurrent = current
    var now = Date.now()

    meetingState = state
    meetingId = id
    if (id) {
      if (id !== wasId) {
        pendingStart = null
        lastError = ""
        notesText = ""
        refreshRecent()
      }
      if (st.folder && notesFile.path !== st.folder + "/notes.md") notesFile.path = st.folder + "/notes.md"
      if (st.levels) levels = { mic: Number(st.levels.mic) || 0, system: Number(st.levels.system) || 0 }
      liveLines = st.live || []
      var startedMs = now - (Number(st.elapsed) || 0) * 1000
      current = { id: id, title: st.title || "Meeting", startedMs: startedMs }
      pausedMs = 0
      pauseStartMs = state === "paused" ? now : 0
    }

    if (state === "idle" && wasId) {
      pausedMs = 0
      pauseStartMs = 0
      current = null
      finish(wasId, wasCurrent ? wasCurrent.title : "Meeting")
    }
  }

  function finish(id, title) {
    processing = { id: id, title: title }
    refreshRecent()
    run(["finish", id, notesDir], function(ok, out, err) {
      if (root.processing && root.processing.id === id) root.processing = null
      refreshRecent()
      if (!ok) {
        notify("Meeting notes failed", err || "The transcript could not be made; run `meetings retry` later", "normal", [])
        return
      }
      var meeting = parseJson(out)
      if (!meeting) return
      if (meeting.words === 0) {
        notify("No speech in “" + meeting.title + "”",
          "Nothing was transcribed. Check that the microphone isn't muted and that the output you listen on is recorded.", "normal", [])
        return
      }
      root.justFinished = meeting
      notify("Meeting notes saved", meeting.title + " · " + Meetings.fmtDuration(meeting.durationSecs) + " · " + Meetings.fmtWords(meeting.words),
        "low", ["open"], meeting)
      if (settings.autoSummarize) summarize(meeting.id)
    }, 1900 * 1000)
  }

  // ----------------------------------------------------------------- actions

  function start(title) {
    if (active) return
    var name = String(title || "").trim() || suggestedTitle() || Meetings.defaultTitle(Date.now())
    pendingStart = { title: name, at: Date.now() }
    lastError = ""
    justFinished = null
    run(["start", name], function(ok, out, err) {
      if (!ok) {
        root.pendingStart = null
        root.lastError = err || "The recorder couldn't start"
        notify("Couldn't start recording", root.lastError, "normal", [])
      } else if (settings.autoOpenLive !== false) {
        root.openLive()
      }
    })
    startCheck.restart()
  }

  function stop() {
    if (!active) return
    if (notesBusy || notesQueued !== null) { stopAfterNotes = true; return }  // notes reach the recorder first
    run(["stop"], reportFailure("stop"), 600 * 1000)
  }
  function pause() { if (meetingState === "recording") run(["pause"], reportFailure("pause")) }
  function resume() { if (meetingState === "paused") run(["resume"], reportFailure("resume")) }
  function togglePause() { if (meetingState === "paused") resume(); else pause() }
  function toggle(title) { if (active) stop(); else start(title) }

  function reportFailure(verb) {
    return function(ok, out, err) { if (!ok) notify("Couldn't " + verb + " the meeting", err, "normal", []) }
  }

  // Opens the meeting in the Meetings app (the web viewer).
  function openViewer(id) {
    run(["view", id || "last"], function(ok, out, err) { if (!ok) notify("Couldn't open the meeting", err, "normal", []) })
  }
  function openNotes(meeting) { openViewer(meeting.id) }

  // The Meetings app (the web viewer): the list, or one meeting with openViewer().
  function openApp() {
    run(["recorder-window"], function(ok, out, err) { if (!ok) notify("Couldn't open Meetings", err, "normal", []) })
  }
  function openRecorder() { openApp() }
  function dismissFinished() { justFinished = null }

  function openLive() {
    run(["live-window"], function(ok, out, err) { if (!ok) notify("Couldn't open live transcript", err, "normal", []) })
  }

  function openSummary(meeting) {
    if (meeting.hasSummary) openFile(meeting.summary)
    else summarize(meeting.id)
  }

  function openFile(path) {
    if (!path) return
    Quickshell.execDetached([helper, "open", settings.openWith === "editor" ? "editor" : "default", path])
  }

  function openFolder() {
    Quickshell.execDetached(["sh", "-c", 'dir="$1"; dir="${dir/#\\~/$HOME}"; mkdir -p "$dir" && xdg-open "$dir"', "_", notesDir])
  }

  function copyTranscript(meeting) {
    run(["copy", meeting.id], function(ok, out, err) {
      if (ok) notify("Transcript copied", meeting.title, "low", [])
      else notify("Couldn't copy the transcript", err, "normal", [])
    })
  }

  function summarize(id) {
    if (summarizingId) return
    summarizingId = id
    run(["summarize", id, notesDir], function(ok, out, err) {
      root.summarizingId = ""
      refreshRecent()
      if (!ok) { notify("Summary failed", err, "normal", []); return }
      notify("Meeting summary ready", out.trim().split("/").slice(-2, -1)[0] || "Meeting", "low", ["open-summary"], { summary: out.trim() })
    }, 600 * 1000)
  }

  // Notes typed in the popup during a recording; the recorder timestamps each paragraph.
  property bool notesBusy: false
  property var notesQueued: null
  property bool stopAfterNotes: false
  function saveNotes(text) {
    notesText = text
    if (!active) return
    if (notesBusy) { notesQueued = text; return }  // one save at a time; the latest text wins
    notesBusy = true
    run(["note", text], function(ok, out, err) {
      notesBusy = false
      if (!ok) root.lastError = err
      if (notesQueued !== null) { const next = notesQueued; notesQueued = null; saveNotes(next) }
      else if (stopAfterNotes) { stopAfterNotes = false; stop() }
    })
  }

  function deleteMeeting(meeting) {
    run(["delete", meeting.id], function(ok, out, err) {
      if (!ok) notify("Couldn't delete the recording", err, "normal", [])
      refreshRecent()
    })
  }

  function fixAudio(action) {
    if (!action) return
    run([action], function(ok, out, err) {
      if (!ok) notify("Couldn't fix audio", err, "normal", [])
      refreshAudio()
    })
  }

  function suggestedTitle() {
    if (!settings.useAkiflowTitle || !shell) return ""
    var akiflow = shell.serviceFor ? shell.serviceFor("eyad.akiflow") : null
    var hit = akiflow ? Meetings.akiflowSuggestion(akiflow.agenda, Date.now(), 15 * 60) : null
    return hit ? hit.title : ""
  }

  function refreshRecent() { run(["list", "0", notesDir], function(ok, out) { if (ok) root.recent = parseJson(out) || [] }) }
  function refreshAudio() { run(["audio"], function(ok, out) { if (ok) root.audio = parseJson(out) }) }

  function popupOpened() {
    popupsOpen++
    nowMs = Date.now()
    refreshAudio()
    refreshRecent()
  }
  function popupClosed() { popupsOpen = Math.max(0, popupsOpen - 1) }

  function notify(title, body, urgency, actions, meeting) {
    var args = [helper, "notify", "--title", title, "--body", body || "", "--urgency", urgency || "normal", "--glyph", glyph]
    if (meeting && actions.indexOf("open") !== -1 && meeting.id) args.push("--open", "view:" + meeting.id)
    if (meeting && actions.indexOf("open-summary") !== -1 && meeting.summary) args.push("--open", meeting.summary)
    if (meeting && actions.indexOf("open") !== -1 && meeting.id) args.push("--summarize", meeting.id, "--notes-dir", notesDir)
    args.push("--opener", settings.openWith === "editor" ? "editor" : "default")
    Quickshell.execDetached(args)
  }

  function parseJson(text) {
    try { return JSON.parse(String(text || "")) } catch (e) { return null }
  }

  // ------------------------------------------------------------ processes

  // A Process per call, so a slow summary never blocks a pause.
  property int jobCount: 0
  function run(args, done, timeoutMs) {
    var command = [helper].concat(args)
    var job = jobComponent.createObject(root, { command: command, done: done || null, timeoutMs: timeoutMs || 60000 })
    jobCount++
    job.running = true
  }

  Component {
    id: jobComponent
    Process {
      id: job
      property var done: null
      property int timeoutMs: 60000
      property int code: -1
      property bool outDone: false
      property bool errDone: false
      property bool reported: false

      function report() {
        if (reported || code === -1 || !outDone || !errDone) return
        reported = true
        root.jobCount--
        var err = String(errText.text || "").trim().split("\n").filter(function(l) { return l !== "" }).pop() || ""
        if (done) done(code === 0, String(outText.text || ""), err)
        job.destroy()
      }

      stdout: StdioCollector { id: outText; waitForEnd: true; onStreamFinished: { job.outDone = true; job.report() } }
      stderr: StdioCollector { id: errText; waitForEnd: true; onStreamFinished: { job.errDone = true; job.report() } }
      onExited: function(exitCode) { job.code = exitCode; job.report() }
      onRunningChanged: {
        if (running) killTimer.start()
        // A binary that fails to start never reports an exit code.
        else if (code === -1) Qt.callLater(function() {
          if (job.code === -1) { job.code = 127; job.outDone = true; job.errDone = true; job.report() }
        })
      }

      property Timer killTimer: Timer {
        interval: job.timeoutMs
        onTriggered: if (job.running) job.signal(15)
      }
    }
  }

  // Catches a start that never shows up in state.json.
  Timer {
    id: startCheck
    interval: 6000
    onTriggered: {
      if (root.pendingStart && !root.active) {
        root.pendingStart = null
        root.refreshAudio()
        root.lastError = "The recorder didn't start. Run `meetings record` in a terminal to see why."
        root.notify("Recording didn't start", root.lastError, "normal", [])
      }
    }
  }

  FileView {
    id: stateFile
    path: root.runtimeDir + "/meetings/state.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyMeetingState(text())
    onLoadFailed: root.applyMeetingState("idle")
  }

  // The running meeting's notes, e.g. written from another device or the terminal.
  FileView {
    id: notesFile
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: if (root.active) root.notesText = text()
  }

  // A meeting still being transcribed after the recorder stopped (also after a
  // shell restart).
  FileView {
    id: processingFile
    path: root.runtimeDir + "/meetings/processing.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var p = root.parseJson(text())
      if (p && p.id && !(root.processing && root.processing.id === p.id)) root.processing = { id: p.id, title: p.title, announced: true }
      else if (!(p && p.id)) root.announcedDone()
    }
    onLoadFailed: root.announcedDone()
  }

  // A transcription started elsewhere ("Transcribe again", `meetings retry`) took
  // its notice down: it finished. One the recorder hands this shell is cleared by finish().
  function announcedDone() {
    if (!(processing && processing.announced)) return
    processing = null
    refreshRecent()
  }

  FileView {
    id: themeFile
    path: (Quickshell.env("HOME") || "") + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var next = Meetings.parsePalette(text())
      if (JSON.stringify(next) !== JSON.stringify(root.themeColors)) root.themeColors = next
    }
  }

  // The recorder replaces the file rather than writing it in place, which a
  // watch can miss; a poll keeps the state honest.
  Timer {
    interval: root.active || root.popupsOpen > 0 ? 1000 : 3000
    running: true
    repeat: true
    onTriggered: {
      root.nowMs = Date.now()
      stateFile.reload()
      processingFile.reload()
      if (root.popupsOpen > 0) themeFile.reload()  // a theme switch replaces the file
    }
  }

  Timer {
    interval: 5000
    running: root.popupsOpen > 0
    repeat: true
    onTriggered: root.refreshAudio()
  }

  // Meters before recording starts: only while the popup is open.
  Process {
    id: levelsProc
    command: [root.helper, "levels"]
    running: root.popupsOpen > 0 && !root.active
    stdout: SplitParser {
      onRead: function(line) {
        var l = root.parseJson(line)
        if (l) root.levels = { mic: Number(l.mic) || 0, system: Number(l.system) || 0 }
      }
    }
  }

  Component.onCompleted: {
    refreshRecent()
    refreshAudio()
  }

  // `omarchy-shell meetings <method>`
  IpcHandler {
    target: "meetings"

    function toggle(): void { root.toggle("") }
    function start(title: string): void { root.start(title) }
    function stop(): void { root.stop() }
    function pause(): void { root.togglePause() }
    function view(id: string): void { root.openViewer(id) }
    function popup(): void {
      Quickshell.execDetached(["omarchy-shell", "shell", "toggle", root.pluginId, "{}"])
    }
    function status(): string {
      return JSON.stringify({ state: root.meetingState, id: root.meetingId, title: root.current ? root.current.title : "",
        elapsed: root.info.text, processing: root.processing ? root.processing.title : "", suggestion: root.suggestedTitle(),
        akiflow: !!(root.shell && root.shell.serviceFor && root.shell.serviceFor("eyad.akiflow")),
        issues: root.issues.map(function(i) { return i.text }) })
    }
  }
}
