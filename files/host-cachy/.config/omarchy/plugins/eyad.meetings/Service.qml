import QtQuick
import Quickshell
import Quickshell.Io
import "lib/Meetings.js" as Meetings

// One per shell: follows Voxtype's meeting state, runs meeting commands, and
// saves notes when a meeting ends. The bar widgets (one per monitor) render
// what this exposes. Every Voxtype and PipeWire call goes through bin/meetings.
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

  // Voxtype's view of the meeting.
  property string meetingState: "idle"     // idle | recording | paused
  property string meetingId: ""
  property var current: null               // { id, title, startedMs }
  property double pausedMs: 0
  property double pauseStartMs: 0
  // A meeting that stopped and is still being transcribed.
  property var processing: null            // { id, title }

  property var recent: []
  property var audio: null
  property double nowMs: Date.now()
  property int popupsOpen: 0
  property string summarizingId: ""
  property string lastError: ""
  property var pendingStart: null          // { title, at }

  readonly property bool active: meetingState === "recording" || meetingState === "paused"
  readonly property var info: Meetings.barInfo({ state: meetingState, current: current, pausedMs: pausedMs, pauseStartMs: pauseStartMs, processing: processing }, nowMs)
  readonly property var issues: Meetings.audioIssues(audio, active)

  // ----------------------------------------------------------- meeting state

  function applyMeetingState(text) {
    var parsed = Meetings.parseMeetingState(text)
    var was = meetingState, wasId = meetingId, wasCurrent = current

    if (parsed.state === "paused" && was !== "paused") pauseStartMs = Date.now()
    if (parsed.state !== "paused" && was === "paused" && pauseStartMs) {
      pausedMs += Date.now() - pauseStartMs
      pauseStartMs = 0
    }

    meetingState = parsed.state
    meetingId = parsed.id

    if (parsed.id && parsed.id !== wasId) {
      pausedMs = 0
      pauseStartMs = parsed.state === "paused" ? Date.now() : 0
      current = { id: parsed.id, title: pendingStart ? pendingStart.title : "Meeting", startedMs: Date.now() }
      pendingStart = null
      lastError = ""
      run(["info", parsed.id], function(ok, out) {
        if (!ok || root.meetingId !== parsed.id) return
        var meta = parseJson(out)
        if (meta) root.current = { id: meta.id, title: meta.title, startedMs: Meetings.parseTime(meta.startedAt) || root.current.startedMs }
      })
      refreshRecent()
    }

    if (parsed.state === "idle" && wasId) {
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
        notify("Meeting notes failed", err || "Voxtype did not finish the transcript", "normal", [])
        return
      }
      var meeting = parseJson(out)
      if (!meeting) return
      if (meeting.words === 0) {
        notify("No speech in “" + meeting.title + "”",
          "Nothing was transcribed. Check that the microphone isn't muted and that Voxtype records the output you listen on.", "normal", [])
        return
      }
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
    run(["--voxtype", "meeting", "start", "--title", name], function(ok, out, err) {
      if (!ok) {
        root.pendingStart = null
        root.lastError = err || "Voxtype couldn't start the meeting"
        notify("Couldn't start recording", root.lastError, "normal", [])
      }
    })
    startCheck.restart()
  }

  function stop() { if (active) run(["--voxtype", "meeting", "stop"], reportFailure("stop")) }
  function pause() { if (meetingState === "recording") run(["--voxtype", "meeting", "pause"], reportFailure("pause")) }
  function resume() { if (meetingState === "paused") run(["--voxtype", "meeting", "resume"], reportFailure("resume")) }
  function togglePause() { if (meetingState === "paused") resume(); else pause() }
  function toggle(title) { if (active) stop(); else start(title) }

  function reportFailure(verb) {
    return function(ok, out, err) { if (!ok) notify("Couldn't " + verb + " the meeting", err, "normal", []) }
  }

  function openNotes(meeting) {
    run(["notes", meeting.id, notesDir], function(ok, out, err) {
      if (!ok) { notify("Couldn't export notes", err, "normal", []); return }
      openFile(out.trim())
      refreshRecent()
    })
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
      notify("Meeting summary ready", out.trim().replace(/^.*\//, "").replace(/\.summary\.md$/, ""), "low", ["open-summary"], { summary: out.trim() })
    }, 600 * 1000)
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

  function refreshRecent() { run(["list", String(settings.recentCount || 6), notesDir], function(ok, out) { if (ok) root.recent = parseJson(out) || [] }) }
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
    if (meeting && actions.indexOf("open") !== -1 && meeting.notes) args.push("--open", meeting.notes)
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
    var command = args[0] === "--voxtype" ? ["voxtype"].concat(args.slice(1)) : [helper].concat(args)
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

  // Voxtype acknowledges `meeting start` before the daemon acts on it.
  Timer {
    id: startCheck
    interval: 6000
    onTriggered: {
      if (root.pendingStart && !root.active) {
        root.pendingStart = null
        root.refreshAudio()
        root.lastError = "Voxtype didn't start recording. Is the daemon running with meeting mode enabled?"
        root.notify("Recording didn't start", root.lastError, "normal", [])
      }
    }
  }

  FileView {
    id: stateFile
    path: root.runtimeDir + "/voxtype/meeting_state"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.applyMeetingState(text())
    onLoadFailed: root.applyMeetingState("idle")
  }

  // The daemon may replace the file rather than write it in place, which a
  // watch can miss; a slow poll keeps the state honest.
  Timer {
    interval: root.active || root.popupsOpen > 0 ? 1000 : 3000
    running: true
    repeat: true
    onTriggered: {
      root.nowMs = Date.now()
      stateFile.reload()
    }
  }

  Timer {
    interval: 5000
    running: root.popupsOpen > 0
    repeat: true
    onTriggered: root.refreshAudio()
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
    function popup(): void {
      var bar = root.shell ? root.shell.bar : null
      if (!bar || typeof bar.isBarWidgetOpen !== "function") return
      if (bar.isBarWidgetOpen(root.pluginId)) bar.hideBarWidget(root.pluginId)
      else bar.summonBarWidget(root.pluginId)
    }
    function status(): string {
      return JSON.stringify({ state: root.meetingState, id: root.meetingId, title: root.current ? root.current.title : "",
        elapsed: root.info.text, processing: root.processing ? root.processing.title : "", suggestion: root.suggestedTitle(),
        akiflow: !!(root.shell && root.shell.serviceFor && root.shell.serviceFor("eyad.akiflow")),
        issues: root.issues.map(function(i) { return i.text }) })
    }
  }
}
