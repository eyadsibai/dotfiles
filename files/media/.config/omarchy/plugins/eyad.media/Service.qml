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

  function openRemote() {
    Quickshell.execDetached(["setsid", "uwsm-app", "--", "xdg-terminal-exec",
      "--app-id=org.omarchy.terminal", "--title=TV remote", "-e", "media", "tv", "remote"])
  }
  function openCaster() { run(["gui"], "Opening go2tv") }

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
