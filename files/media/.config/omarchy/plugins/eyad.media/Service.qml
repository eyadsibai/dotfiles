import QtQuick
import Quickshell
import Quickshell.Io

// State and actions for the living-room widget. Everything goes through the
// `media` command (~/.local/bin/media), so the widget follows MEDIA_TV and the
// Sonos address in ~/.config/media/config like the terminal does.
Item {
  id: root

  property var settings: ({})

  property bool loaded: false
  property var tv: ({})
  property var sonos: ({})
  property var scenes: []
  property string lastError: ""
  property string actionStatus: ""

  // Optimistic values so controls react immediately; -1 / "" means "follow
  // the last status".
  property int _volume: -1
  property int _tvPower: -1

  readonly property bool tvReachable: tv.reachable === true
  readonly property bool tvOn: _tvPower === -1 ? tv.on === true : _tvPower === 1
  readonly property bool sonosReachable: sonos.reachable === true
  readonly property bool sonosMuted: sonos.muted === true
  readonly property int volume: _volume >= 0 ? _volume : (sonos.volume === undefined || sonos.volume === null ? 0 : sonos.volume)
  readonly property bool anyReachable: tvReachable || sonosReachable
  readonly property string appName: prettyApp(tv.app)
  readonly property bool busy: actionProcess.running
  readonly property bool playing: String(sonos.playback || "") === "PLAYING"
  property string runningLabel: ""

  // Casting goes through the cast service (~/.local/bin/cast), which keeps playing
  // when the panel closes. `cast watch` streams its state while the panel is open.
  property var videos: []
  property var cs: ({ state: "idle", queue: [], index: -1, position: 0, duration: 0 })
  property bool watchCast: false
  readonly property bool casting: ["preparing", "starting", "playing", "paused"].indexOf(cs.state) >= 0
  readonly property string castPath: String(cs.src || "")
  readonly property string castName: String(cs.title || "")
  readonly property string castState: cs.state === "error" ? "failed" : (cs.state === "playing" || cs.state === "paused" ? cs.state : "starting")
  readonly property string castMessage: String(cs.message || "")
  readonly property int castPosition: cs.position || 0
  readonly property int castDuration: cs.duration || 0
  readonly property bool castSubtitles: cs.subtitles === true
  readonly property int queueLength: cs.queue ? cs.queue.length : 0
  readonly property bool hasNext: cs.index + 1 < queueLength

  readonly property int refreshIntervalSec: {
    var n = parseInt(String(settings && settings.refreshIntervalSec !== undefined ? settings.refreshIntervalSec : 30), 10)
    return isFinite(n) ? Math.max(10, Math.min(600, n)) : 30
  }
  property bool fastPolling: false

  readonly property string summary: {
    if (!loaded) return "Checking…"
    var parts = []
    if (!tvReachable) parts.push("TV off")
    else if (tvOn) parts.push(appName ? "TV on · " + appName : "TV on")
    else parts.push("TV in standby")
    if (sonosReachable) parts.push(sonosMuted ? "Sonos muted" : "Sonos " + volume)
    else parts.push("Sonos not found")
    return parts.join(" · ")
  }

  function prettyApp(id) {
    var s = String(id || "")
    if (s === "" || s === "?") return ""
    var known = {
      "youtube.leanback.v4": "YouTube",
      "netflix": "Netflix",
      "amazon": "Prime Video",
      "com.disney.disneyplus-prod": "Disney+",
      "com.apple.appletv": "Apple TV",
      "spotify-beehive": "Spotify",
      "com.webos.app.livetv": "Live TV",
      "com.webos.app.home": "Home",
      "com.webos.app.browser": "Browser",
      "com.webos.app.photovideo": "Photos & videos",
      "com.webos.app.mediadiscovery": "Media player",
      "com.webos.app.dlnadmr": "Casting"
    }
    if (known[s]) return known[s]
    var hdmi = s.match(/hdmi(\d)/i)
    if (hdmi) return "HDMI " + hdmi[1]
    var last = s.split(".").pop()
    return last.charAt(0).toUpperCase() + last.slice(1)
  }

  function refresh() {
    if (statusProcess.running) return
    statusProcess.running = true
  }

  function applyStatus(text) {
    var parsed
    try { parsed = JSON.parse(text) } catch (e) {
      lastError = "Couldn't read media status"
      return
    }
    tv = parsed.tv || {}
    sonos = parsed.sonos || {}
    scenes = parsed.scenes || []
    loaded = true
    if (_volume >= 0 && !volumeProcess.running && !volumeDebounce.running) _volume = -1
    if (_tvPower !== -1 && (tv.on === true) === (_tvPower === 1)) _tvPower = -1
    if (!actionProcess.running && !volumeProcess.running) lastError = ""
  }

  // Long-running actions (power, scenes, playback): one at a time.
  function run(args, label) {
    if (actionProcess.running) {
      actionStatus = runningLabel + " still running…"
      statusClear.restart()
      return
    }
    runningLabel = label || args.join(" ")
    actionStatus = runningLabel + "…"
    lastError = ""
    actionProcess.command = ["media"].concat(args)
    actionProcess.running = true
  }

  function setTvPower(on) {
    _tvPower = on ? 1 : 0
    powerSettle.restart()
    run(["tv", on ? "on" : "off"], on ? "Turning the TV on" : "Turning the TV off")
  }
  function toggleTvPower() { setTvPower(!tvOn) }
  function runScene(name) { run([name], "Scene: " + name) }
  function tvKey(action) { run(["tv", action], action.charAt(0).toUpperCase() + action.slice(1)) }

  // Volume/mute have their own process so they work while a scene runs.
  function setVolume(v) {
    _volume = Math.max(0, Math.min(100, Math.round(v)))
    volumeDebounce.restart()
  }
  function nudgeVolume(delta) { setVolume(volume + delta) }
  function toggleMute() {
    sonos = Object.assign({}, sonos, { muted: !sonosMuted })
    runVolume([sonosMuted ? "mute" : "unmute"])
  }
  function runVolume(args) {
    if (volumeProcess.running) { _pendingVolume = args; return }
    volumeProcess.command = ["media"].concat(args)
    volumeProcess.running = true
  }
  property var _pendingVolume: null

  function refreshVideos() {
    if (!videosProcess.running) videosProcess.running = true
  }

  function castCmd(args) { Quickshell.execDetached(["cast"].concat(args)) }
  function cast(path) { if (path) castCmd(["play", path]) }
  function stopCast() { castCmd(["stop"]) }
  function seekCast(secs) { castCmd(["seek", String(Math.max(0, Math.round(secs)))]) }
  function toggleCast() { castCmd(["toggle"]) }
  function nextCast() { castCmd(["next"]) }

  function browseVideo() {
    if (!browseProcess.running) browseProcess.running = true
  }

  function formatTime(secs) {
    if (secs < 0) return "–:––"
    var h = Math.floor(secs / 3600), m = Math.floor(secs / 60) % 60, s = secs % 60
    var mm = h > 0 && m < 10 ? "0" + m : String(m)
    return (h > 0 ? h + ":" : "") + mm + ":" + (s < 10 ? "0" : "") + s
  }

  function formatSize(bytes) {
    if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB"
    if (bytes >= 1048576) return Math.round(bytes / 1048576) + " MB"
    return Math.max(1, Math.round(bytes / 1024)) + " KB"
  }

  function openRemote() {
    Quickshell.execDetached(["setsid", "uwsm-app", "--", "xdg-terminal-exec",
      "--app-id=org.omarchy.terminal", "--title=TV remote", "-e", "media", "tv", "remote"])
  }

  Timer {
    interval: (root.fastPolling ? 5 : root.refreshIntervalSec) * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: volumeDebounce
    interval: 150
    onTriggered: root.runVolume(["vol", String(root._volume)])
  }

  // The TV takes a while to wake or sleep; stop pretending after 45s.
  Timer {
    id: powerSettle
    interval: 45000
    onTriggered: { root._tvPower = -1; root.refresh() }
  }

  Process {
    id: videosProcess
    command: ["cast", "videos"]
    stdout: StdioCollector { id: videosOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) return
      try {
        var rows = JSON.parse(videosOut.text)
        root.videos = Array.isArray(rows) ? rows.slice(0, 500) : []
      } catch (e) {
        root.videos = []
      }
    }
  }

  Process {
    id: castWatch
    command: ["cast", "watch"]
    running: root.watchCast
    stdout: SplitParser {
      onRead: function(line) {
        try { root.cs = JSON.parse(line) } catch (e) {}
      }
    }
  }

  // GTK file chooser for videos outside the usual folders.
  Process {
    id: browseProcess
    command: ["zenity", "--file-selection", "--title=Cast a video",
      "--file-filter=Videos | *.mp4 *.mkv *.webm *.mov *.m4v *.avi *.ts *.MP4 *.MKV *.MOV",
      "--file-filter=All files | *"]
    stdout: StdioCollector { id: browseOut; waitForEnd: true }
    onExited: function(code) {
      var path = String(browseOut.text || "").trim()
      if (code === 0 && path !== "") root.cast(path)
    }
  }

  Timer { id: statusClear; interval: 3000; onTriggered: root.actionStatus = "" }
  Timer { id: delayedRefresh; interval: 1500; onTriggered: root.refresh() }

  Process {
    id: statusProcess
    command: ["media", "status", "--json"]
    stdout: StdioCollector { id: statusOut; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) root.applyStatus(statusOut.text)
      else root.lastError = "media status failed (is ~/.local/bin/media installed?)"
    }
  }

  Process {
    id: actionProcess
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: actionErr; waitForEnd: true }
    onExited: function(code) {
      if (code === 0) {
        root.actionStatus = ""
      } else {
        var lines = String(actionErr.text || "").trim().split("\n")
        root.lastError = lines[lines.length - 1] || (root.runningLabel + " failed")
        root.actionStatus = ""
        root._tvPower = -1
      }
      delayedRefresh.restart()
    }
  }

  Process {
    id: volumeProcess
    stderr: StdioCollector { id: volumeErr; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) {
        var lines = String(volumeErr.text || "").trim().split("\n")
        root.lastError = lines[lines.length - 1] || "Sonos didn't answer"
      }
      if (root._pendingVolume) {
        var next = root._pendingVolume
        root._pendingVolume = null
        root.runVolume(next)
      } else {
        delayedRefresh.restart()
      }
    }
  }
}
