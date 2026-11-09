import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The living-room remote: TV power, Sonos volume, scenes, then two tabs. Remote
// is a touchpad for the TV's pointer, remote buttons, and a text box that types
// into the TV's keyboard. Cast is what's playing and the video library.
//
// A floating window (Hyprland's rule puts it bottom-right and pins it): move it
// with Super+drag or by dragging its header; Super+W closes it.
//
// It holds one `media tv pipe` connection open while shown, so pointer moves
// don't start a process each.
FloatingWindow {
  id: win
  title: "TV remote"
  color: background
  implicitWidth: 460
  implicitHeight: 780
  minimumSize: Qt.size(400, 680)

  required property var svc       // the panel's Service: TV and Sonos state, casting
  signal closeRequested()
  signal openCasterRequested()

  // Super+W (or any close by the compositor) hides the window; let Panel unload it.
  onVisibleChanged: if (!visible) { padOn = false; closeYouTube(); closeRequested() }

  readonly property color foreground: Commons.Color.foreground
  readonly property color background: Commons.Color.background
  readonly property color accent: Commons.Color.accent
  readonly property color urgent: Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color faint: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)
  readonly property string fontFamily: Style.font.family

  property string tab: "remote"   // "remote" or "cast"

  property bool connected: false
  property bool tvKeyboard: false
  property string tvGrid: ""      // "Prime Video" or "Shahid" while that app is on screen
  property string gridError: ""
  readonly property bool typingToGrid: tvGrid !== "" && !tvKeyboard
  property string error: ""
  property string sentText: ""   // what the text box has already typed on the TV
  // With the touchpad on (c), plain mouse movement over it moves the TV's
  // pointer; no button needs holding. Off, it moves only while dragging.
  property bool padOn: false
  onPadOnChanged: pad.primed = false

  // Pointer moves are summed and flushed every 30 ms. Slow drags move the
  // pointer about 1:1 for small targets; fast flicks cross the screen. The
  // speed ([ and ]) scales both; Panel keeps it between openings.
  property real pendingX: 0
  property real pendingY: 0
  readonly property var speeds: [0.6, 1, 1.5, 2.2, 3]
  property real speed: 1
  function stepSpeed(dir) {
    var i = speeds.indexOf(speed)
    if (i < 0) i = 1
    speed = speeds[Math.max(0, Math.min(speeds.length - 1, i + dir))]
  }
  function pointerGain(pxPerMs) { return speed * (0.9 + 2.4 * Math.min(pxPerMs, 1.5)) }

  // The TV's power state, from the pipe. With Quick Start+ an off TV still
  // answers ("Active Standby", "Suspend", "Screen Off") but ignores the remote,
  // so opening the remote then wakes it: Wake-on-LAN, or the screen back on.
  property string power: ""
  readonly property bool tvOff: power !== "" && power !== "Active"
  property bool everConnected: false
  property bool waking: false     // a wake was sent since the remote opened
  property bool restarting: false
  function wakeTv() {
    waking = true
    wakeGiveUp.restart()
    run(["media", "tv", "on"])
    send("wake")
  }
  // If it isn't up in 40 s (Wake-on-LAN off in the TV's settings, say), stop
  // claiming it's coming and offer the switch again.
  Timer { id: wakeGiveUp; interval: 40000; onTriggered: win.waking = false }

  readonly property bool tvUp: connected && !tvOff
  function togglePower() { if (tvUp) svc.setTvPower(false); else wakeTv() }

  // A pasted link plays on the TV instead of being typed into it.
  readonly property string typed: typeBox.text.trim()
  readonly property bool typedIsLink: /^https?:\/\/\S+$/i.test(typed)
  readonly property bool typedIsYouTube: typedIsLink && /(youtube\.com|youtu\.be)\//i.test(typed)

  function run(args) { Quickshell.execDetached(args) }
  function playLink(add) {
    if (!typedIsLink) return
    if (typedIsYouTube && !add) run(["media", "tv", "youtube", typed])
    else run(["cast", add ? "add" : "play", typed])
    sentText = ""
    typeBox.text = ""
  }

  // YouTube draws its own letter grid, which typing can't reach, so search from
  // here (yt-dlp) and send the pick to the TV's YouTube app.
  property string ytQuery: ""     // non-empty while the results replace the touchpad
  property var ytResults: []
  property int ytIndex: 0
  property string ytStatus: ""
  property bool ytFailed: false
  readonly property bool ytShown: ytQuery !== ""

  function searchYouTube(q) {
    ytSearch.running = false
    ytQuery = q
    ytResults = []
    ytIndex = 0
    ytFailed = false
    ytStatus = "Searching YouTube…"
    ytSearch.command = ["media", "tv", "ytsearch", q]
    ytSearch.running = true
    leaveTextBox()
  }
  function playYouTube(v) {
    if (!v) return
    ytFailed = false
    ytStatus = "Starting “" + v.title + "” on the TV… (a few seconds if YouTube wasn't open)"
    ytPlay.running = false
    ytPlay.command = ["media", "tv", "youtube", v.id]
    ytPlay.running = true
  }
  // Focusing the scope alone would hand focus straight back to a text box,
  // its remembered focus child.
  function leaveTextBox() {
    typeBox.focus = false
    videoSearch.focus = false
    scope.forceActiveFocus()
  }
  function closeYouTube() {
    ytSearch.running = false
    ytQuery = ""
    ytResults = []
    ytStatus = ""
  }
  function formatDuration(sec) {
    if (!sec) return ""
    sec = Math.round(sec)
    var h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), s = sec % 60
    var mm = h > 0 && m < 10 ? "0" + m : "" + m
    return (h > 0 ? h + ":" : "") + mm + ":" + (s < 10 ? "0" : "") + s
  }
  function formatViews(n) {
    if (!n) return ""
    if (n >= 1e9) return (n / 1e9).toFixed(1).replace(/\.0$/, "") + "B views"
    if (n >= 1e6) return (n / 1e6).toFixed(1).replace(/\.0$/, "") + "M views"
    if (n >= 1e3) return Math.round(n / 1e3) + "K views"
    return n + " views"
  }

  // Videos matching the cast search, newest first. Every word must appear in the name or folder.
  readonly property var videoMatches: {
    var words = videoSearch.text.toLowerCase().split(/\s+/).filter(function(w) { return w !== "" })
    var out = []
    var all = svc.videos || []
    for (var i = 0; i < all.length && out.length < 40; i++) {
      var v = all[i]
      var hay = (String(v.name) + " " + String(v.folder)).toLowerCase()
      if (words.every(function(w) { return hay.indexOf(w) >= 0 })) out.push(v)
    }
    return out
  }

  readonly property string volumeGlyph: svc.sonosMuted ? "󰝟" : (svc.volume < 34 ? "󰕿" : (svc.volume < 67 ? "󰖀" : "󰕾"))

  Process {
    id: ytSearch
    stdout: SplitParser {
      onRead: function(line) {
        try { win.ytResults = win.ytResults.concat([JSON.parse(line)]) } catch (e) {}
      }
    }
    stderr: StdioCollector { id: ytSearchErr; waitForEnd: true }
    onExited: function(code) {
      var lines = String(ytSearchErr.text || "").trim().split("\n")
      win.ytFailed = code !== 0
      win.ytStatus = code !== 0 ? (lines[lines.length - 1] || "YouTube search failed")
                   : win.ytResults.length === 0 ? "Nothing found" : ""
    }
  }
  Process {
    id: ytPlay
    stderr: StdioCollector { id: ytPlayErr; waitForEnd: true }
    onExited: function(code) {
      var lines = String(ytPlayErr.text || "").trim().split("\n")
      win.ytFailed = code !== 0
      win.ytStatus = code !== 0 ? (lines[lines.length - 1] || "Couldn't start the video") : "Playing on the TV"
    }
  }

  function send(line) {
    if (pipe.running) pipe.write(line + "\n")
  }
  function key(name) { send("key " + name) }

  // One play/pause button. The TV doesn't report what's playing, so this
  // remembers the last one sent; if it guesses wrong, a second press fixes it.
  property bool paused: false
  function playPause() { key(paused ? "PLAY" : "PAUSE"); paused = !paused }

  // Type the difference between what the TV has and what the box holds now.
  function syncText(now) {
    if (/^https?:\/\/\S+$/i.test(now.trim())) now = ""  // a link: take back anything typed
    var common = 0
    while (common < now.length && common < sentText.length && now[common] === sentText[common]) common++
    var removed = sentText.length - common
    if (removed > 0) send("del " + removed)
    var added = now.slice(common).replace(/\n/g, " ")
    if (added !== "") send("text " + added)
    sentText = now
  }

  Component.onCompleted: {
    svc.refreshVideos()
    Qt.callLater(function() { scope.forceActiveFocus() })
  }

  Process {
    id: pipe
    command: ["media", "tv", "pipe"]
    running: win.visible
    stdinEnabled: true
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var m = JSON.parse(line)
          if (m.ready) { win.connected = true; win.everConnected = true; win.error = "" }
          if (m.power !== undefined) {
            var wasOff = win.tvOff
            win.power = m.power
            if (win.tvOff && !win.waking) win.wakeTv()
            // Back on: a pointer socket opened in standby is dead, so start afresh
            if (wasOff && !win.tvOff) { win.waking = false; wakeGiveUp.stop(); win.restarting = true; pipe.running = false }
          }
          if (m.keyboard !== undefined) win.tvKeyboard = m.keyboard === true
          if (m.grid !== undefined) { win.tvGrid = m.grid || ""; win.gridError = "" }
          if (m.grid_error !== undefined) win.gridError = m.grid_error || ""
        } catch (e) {}
      }
    }
    stderr: StdioCollector { id: pipeErr; waitForEnd: true }
    onRunningChanged: if (running) win.error = ""
    onExited: function(code) {
      win.connected = false
      win.tvKeyboard = false
      win.tvGrid = ""
      if (win.restarting) { win.restarting = false; if (win.visible) pipe.running = true; return }
      if (code !== 0) {
        var lines = String(pipeErr.text || "").trim().split("\n")
        win.error = lines[lines.length - 1] || "Lost the TV"
        // Unreachable from the start: most likely off, so wake it
        if (!win.everConnected && !win.waking && win.visible) win.wakeTv()
      }
      if (win.visible) reconnect.restart()
    }
  }
  Timer { id: reconnect; interval: 3000; onTriggered: if (win.visible) pipe.running = true }

  Timer {
    id: moveFlush
    interval: 30
    repeat: true
    running: win.pendingX !== 0 || win.pendingY !== 0
    onTriggered: {
      var dx = Math.round(win.pendingX), dy = Math.round(win.pendingY)
      if (dx !== 0 || dy !== 0) win.send("move " + dx + " " + dy)
      win.pendingX -= dx
      win.pendingY -= dy
    }
  }

  // ---- the card ----
  Rectangle {
    anchors.fill: parent
    color: win.background

    FocusScope {
      id: scope
      anchors.fill: parent
      focus: true

      // Keys while no text box has focus act like the remote.
      Keys.onPressed: function(event) {
        var k = event.key
        if (k === Qt.Key_Tab) { win.tab = win.tab === "remote" ? "cast" : "remote"; event.accepted = true; return }
        if (k === Qt.Key_Escape) {
          if (win.ytShown) win.closeYouTube()
          else if (win.padOn) win.padOn = false
          else win.closeRequested()
          event.accepted = true
          return
        }
        if (event.text === "p") { win.togglePower(); event.accepted = true; return }
        if (event.text === "m") { win.svc.toggleMute(); event.accepted = true; return }
        if (event.text === "+" || event.text === "=") { win.svc.nudgeVolume(5); event.accepted = true; return }
        if (event.text === "-") { win.svc.nudgeVolume(-5); event.accepted = true; return }
        if (win.tab === "cast") {
          if (event.text === "/" || event.text === "t") { videoSearch.forceActiveFocus(); event.accepted = true }
          return
        }
        var map = {}
        map[Qt.Key_Up] = "UP"; map[Qt.Key_Down] = "DOWN"; map[Qt.Key_Left] = "LEFT"; map[Qt.Key_Right] = "RIGHT"
        map[Qt.Key_Return] = "ENTER"; map[Qt.Key_Enter] = "ENTER"; map[Qt.Key_Backspace] = "BACK"
        map[Qt.Key_Home] = "HOME"
        if (win.ytShown) {  // the results take arrows and Enter
          var n = win.ytResults.length
          if (k === Qt.Key_Down && n) { win.ytIndex = Math.min(n - 1, win.ytIndex + 1); event.accepted = true; return }
          if (k === Qt.Key_Up && n) { win.ytIndex = Math.max(0, win.ytIndex - 1); event.accepted = true; return }
          if ((k === Qt.Key_Return || k === Qt.Key_Enter) && n) { win.playYouTube(win.ytResults[win.ytIndex]); event.accepted = true; return }
        }
        if (k === Qt.Key_Space) { win.playPause(); event.accepted = true }
        else if (event.text === "c") { win.padOn = !win.padOn; event.accepted = true }
        else if (map[k] !== undefined) { win.key(map[k]); event.accepted = true }
        else if (event.text === "/" || event.text === "t") { typeBox.forceActiveFocus(); event.accepted = true }
        else if (event.text === "h") { win.key("HOME"); event.accepted = true }
        else if (event.text === "]") { win.stepSpeed(1); event.accepted = true }
        else if (event.text === "[") { win.stepSpeed(-1); event.accepted = true }
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.space(18)
        spacing: Style.space(10)

        // ---- header: drag it to move the remote ----
        Item {
          Layout.fillWidth: true
          implicitHeight: headerRow.implicitHeight

          // Dragging the header moves the window, as a title bar would.
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.OpenHandCursor
            onPressed: function(mouse) {
              win.leaveTextBox()
              if (!parent.Window.window || !parent.Window.window.startSystemMove()) mouse.accepted = false
            }
          }

          RowLayout {
            id: headerRow
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Style.space(12)
            Text {
              textFormat: Text.PlainText
              text: "󰔂"
              color: win.foreground
              opacity: win.tvUp ? 1 : 0.5
              font.family: win.fontFamily
              font.pixelSize: Style.font.display
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0
              Text {
                textFormat: Text.PlainText
                text: "Living room"
                color: win.foreground
                font.family: win.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
              Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: win.waking && (win.tvOff || !win.connected) ? "Turning the TV on…"
                    : win.tvOff ? "The TV is off (" + win.power + ")"
                    : win.error !== "" ? win.error
                    : win.svc.lastError !== "" ? win.svc.lastError
                    : win.svc.actionStatus !== "" ? win.svc.actionStatus
                    : win.connected ? (win.svc.appName ? "TV on · " + win.svc.appName : "TV on")
                    : "Connecting…"
                color: win.waking && (win.tvOff || !win.connected) ? win.accent
                     : win.error !== "" || win.tvOff || win.svc.lastError !== "" ? win.urgent : win.dim
                font.family: win.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
            ToggleSwitch {
              id: powerSwitch
              checked: win.tvUp
              busy: win.waking || (win.svc.busy && win.svc.runningLabel.indexOf("Turning") === 0)
              foreground: win.foreground
              onToggled: win.togglePower()
              PanelToolTip {
                visible: powerSwitch.containsMouse
                text: win.tvUp ? "Turn the TV off (p)" : "Turn the TV on (p)"
                fontFamily: win.fontFamily
              }
            }
            Button {
              iconText: "󰅖"
              tooltipText: "Close (Esc)"
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.closeRequested()
            }
          }
        }

        // ---- Sonos volume ----
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(10)
          enabled: win.svc.sonosReachable
          opacity: enabled ? 1.0 : 0.5
          PanelActionButton {
            iconText: win.volumeGlyph
            tooltipText: (win.svc.sonosMuted ? "Unmute" : "Mute") + " the Sonos (m)"
            foreground: win.foreground
            fontFamily: win.fontFamily
            Layout.alignment: Qt.AlignVCenter
            onClicked: win.svc.toggleMute()
          }
          PanelSlider {
            Layout.fillWidth: true
            minimum: 0
            maximum: 100
            step: 2
            integer: true
            value: win.svc.volume
            opacity: win.svc.sonosMuted ? 0.5 : 1.0
            onReleased: function(v) { win.svc.setVolume(v) }
            onRightClicked: win.svc.toggleMute()
          }
          Text {
            textFormat: Text.PlainText
            text: win.svc.sonosReachable ? String(win.svc.volume) : "—"
            color: win.foreground
            font.family: win.fontFamily
            font.pixelSize: Style.font.bodySmall
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Style.space(26)
            Layout.alignment: Qt.AlignVCenter
          }
        }

        // ---- scenes ----
        RowLayout {
          visible: win.svc.scenes.length > 0
          Layout.fillWidth: true
          spacing: Style.space(4)
          Repeater {
            model: win.svc.scenes
            Button {
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              text: modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)
              iconText: modelData.name === "off" ? "󰐥" : (modelData.name === "night" ? "󰖔" : (modelData.name === "movie" ? "󰿎" : "󰐊"))
              tooltipText: modelData.description || ""
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.svc.runScene(modelData.name)
            }
          }
        }

        // ---- tabs ----
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(4)
          Repeater {
            model: [
              { id: "remote", label: "Remote", glyph: "󰑔" },
              { id: "cast", label: "Cast", glyph: "󰐾" }
            ]
            Button {
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredWidth: 1
              text: modelData.label
              iconText: modelData.glyph
              tooltipText: "Tab switches"
              selected: win.tab === modelData.id
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: { win.tab = modelData.id; win.leaveTextBox() }
            }
          }
        }

        // ================= Remote tab =================
        ColumnLayout {
          visible: win.tab === "remote"
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: Style.space(10)

          TextField {
            id: typeBox
            Layout.fillWidth: true
            foreground: win.foreground
            font.family: win.fontFamily
            font.pixelSize: Style.font.body
            placeholderText: win.typingToGrid ? "Search " + win.tvGrid : "Search YouTube, type on the TV, or paste a link"
            onTextChanged: win.syncText(text)
            onAccepted: {
              if (win.typedIsLink) { win.playLink(false); return }
              if (win.typingToGrid) {  // the app searches as you type: just start afresh
                win.sentText = ""
                text = ""
                return
              }
              if (!win.tvKeyboard && win.typed !== "") {
                var q = win.typed
                win.sentText = ""
                text = ""
                win.searchYouTube(q)
                return
              }
              win.send("enter")
              win.sentText = ""
              text = ""
            }
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                win.sentText = ""
                text = ""
                win.leaveTextBox()
                event.accepted = true
              }
            }
          }
          RowLayout {
            visible: win.typedIsLink
            Layout.fillWidth: true
            spacing: Style.space(8)
            Text {
              textFormat: Text.PlainText
              Layout.fillWidth: true
              elide: Text.ElideRight
              text: win.typedIsYouTube ? "󰗃  A YouTube link: open it in the TV's YouTube app" : "󰌹  A link: play it on the TV (via yt-dlp)"
              color: win.foreground
              font.family: win.fontFamily
              font.pixelSize: Style.font.caption
            }
            Button {
              text: "Play on TV"
              iconText: "󰐊"
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.playLink(false)
            }
            Button {
              visible: !win.typedIsYouTube
              text: "Queue"
              iconText: "󰐕"
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.playLink(true)
            }
          }
          Text {
            visible: !win.typedIsLink && (typeBox.activeFocus || win.tvKeyboard || win.typingToGrid)
            textFormat: Text.PlainText
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: win.tvKeyboard
              ? "󰌌  The TV keyboard is open: what you type goes straight in, Enter submits."
              : win.typingToGrid && win.gridError !== "" ? "󰀦  " + win.gridError
              : win.typingToGrid ? "󰌌  Typing walks " + win.tvGrid + "'s letters on the TV (arrows and OK). Have its search open."
              : "Enter searches YouTube; pick a video to play it on the TV. In Plex, Prime or Shahid, open their search and type here."
            color: win.typingToGrid && win.gridError !== "" ? win.urgent
                 : win.tvKeyboard || win.typingToGrid ? win.accent : win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.caption
          }

          // ---- YouTube results (in the touchpad's place) ----
          ColumnLayout {
            visible: win.ytShown
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Style.space(140)
            spacing: Style.space(6)

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(8)
              Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: "󰗃  " + win.ytQuery
                color: win.foreground
                font.family: win.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }
              Button {
                iconText: "󰅖"
                tooltipText: "Back to the touchpad (Esc)"
                foreground: win.foreground
                fontFamily: win.fontFamily
                onClicked: win.closeYouTube()
              }
            }
            Text {
              visible: win.ytStatus !== ""
              textFormat: Text.PlainText
              Layout.fillWidth: true
              wrapMode: Text.Wrap
              text: win.ytStatus
              color: win.ytFailed ? win.urgent : win.dim
              font.family: win.fontFamily
              font.pixelSize: Style.font.caption
            }
            ListView {
              id: ytList
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              spacing: Style.space(2)
              model: win.ytResults
              currentIndex: win.ytIndex
              boundsBehavior: Flickable.StopAtBounds
              ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
              onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

              delegate: CursorSurface {
                id: ytRow
                required property var modelData
                required property int index
                width: ytList.width
                implicitHeight: ytLayout.implicitHeight + Style.spacing.rowPaddingX
                foreground: win.foreground
                hasCursor: ytHover.hovered || index === win.ytIndex

                HoverHandler { id: ytHover; cursorShape: Qt.PointingHandCursor }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: { win.ytIndex = ytRow.index; win.playYouTube(ytRow.modelData) }
                }

                RowLayout {
                  id: ytLayout
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(6)
                  anchors.rightMargin: Style.space(6)
                  spacing: Style.space(10)

                  Image {
                    Layout.preferredWidth: Style.space(96)
                    Layout.preferredHeight: Style.space(54)
                    source: "https://i.ytimg.com/vi/" + ytRow.modelData.id + "/mqdefault.jpg"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 192
                  }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(1)
                    Text {
                      textFormat: Text.PlainText
                      Layout.fillWidth: true
                      text: ytRow.modelData.title
                      color: win.foreground
                      font.family: win.fontFamily
                      font.pixelSize: Style.font.bodySmall
                      wrapMode: Text.Wrap
                      maximumLineCount: 2
                      elide: Text.ElideRight
                    }
                    Text {
                      textFormat: Text.PlainText
                      Layout.fillWidth: true
                      text: {
                        var v = ytRow.modelData
                        var bits = [v.channel, v.live ? "LIVE" : win.formatDuration(v.duration), win.formatViews(v.views)]
                        return bits.filter(function(b) { return b }).join(" · ")
                      }
                      color: ytRow.modelData.live ? win.urgent : win.dim
                      font.family: win.fontFamily
                      font.pixelSize: Style.font.caption
                      elide: Text.ElideRight
                    }
                  }
                }
              }
            }
          }

          // ---- touchpad ----
          Rectangle {
            visible: !win.ytShown
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Style.space(140)
            color: pad.pressed || win.padOn ? Qt.rgba(win.foreground.r, win.foreground.g, win.foreground.b, 0.08)
                               : Qt.rgba(win.foreground.r, win.foreground.g, win.foreground.b, 0.04)
            border.width: win.padOn ? 2 : 1
            border.color: win.padOn || pad.containsMouse ? win.accent : win.faint
            radius: Style.cornerRadius

            Text {
              anchors.centerIn: parent
              width: parent.width - Style.space(24)
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
              textFormat: Text.PlainText
              text: (win.padOn
                ? "Touchpad on\nmove to move the pointer · click to click · c or Esc to stop"
                : "Touchpad\ndrag to move the pointer · click to click · scroll to scroll\nc: move without holding")
                + "\nspeed " + win.speed + "× ( [ and ] ) · endless: the edges wrap to the middle"
              color: win.padOn ? win.accent : win.dim
              font.family: win.fontFamily
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              id: pad
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              cursorShape: Qt.CrossCursor
              property real lastX: 0
              property real lastY: 0
              property real lastT: 0
              property real travelled: 0
              property bool primed: false   // lastX/lastY hold a real position

              // Endless pad: near an edge the cursor is put back in the middle
              // (Hyprland), so one long swipe can cross the whole TV. Motion until
              // the cursor lands there is the warp itself, not the user, so it's skipped.
              readonly property real edge: Math.min(28, width / 8, height / 8)
              property bool warping: false
              function recentre(mouse) {
                var cx = width / 2, cy = height / 2
                warping = true
                warpGuard.restart()
                win.run(["sh", "-c",
                  "p=$(hyprctl cursorpos) && x=${p%,*} && y=${p#*, } && " +
                  "hyprctl eval \"hl.dispatch(hl.dsp.cursor.move({ x = $((x + $1)), y = $((y + $2)) }))\"",
                  "sh", String(Math.round(cx - mouse.x)), String(Math.round(cy - mouse.y))])
              }
              Timer { id: warpGuard; interval: 250; onTriggered: { pad.warping = false; pad.primed = false } }

              onExited: primed = false

              onPressed: function(mouse) {
                win.leaveTextBox()
                lastX = mouse.x; lastY = mouse.y; lastT = Date.now(); travelled = 0; primed = true
              }
              onPositionChanged: function(mouse) {
                if (!pressed && !win.padOn) return
                var now = Date.now()
                if (warping) {
                  if (Math.abs(mouse.x - width / 2) < 40 && Math.abs(mouse.y - height / 2) < 40) {
                    warping = false
                    warpGuard.stop()
                    lastX = mouse.x; lastY = mouse.y; lastT = now; primed = true
                  }
                  return
                }
                if (!primed) { lastX = mouse.x; lastY = mouse.y; lastT = now; primed = true; return }
                var dx = mouse.x - lastX, dy = mouse.y - lastY
                var dt = Math.max(1, now - lastT)
                lastX = mouse.x; lastY = mouse.y; lastT = now
                travelled += Math.abs(dx) + Math.abs(dy)
                var gain = win.pointerGain(Math.sqrt(dx * dx + dy * dy) / dt)
                win.pendingX += dx * gain
                win.pendingY += dy * gain
                if (mouse.x < edge || mouse.y < edge || mouse.x > width - edge || mouse.y > height - edge)
                  recentre(mouse)
              }
              onReleased: function(mouse) {
                if (travelled > 6) return
                if (mouse.button === Qt.RightButton) win.key("BACK")
                else win.send("click")
              }
              onWheel: function(wheel) {
                var steps = Math.round(-wheel.angleDelta.y / 120) || (wheel.angleDelta.y > 0 ? -1 : 1)
                win.send("scroll " + steps)
              }
            }
          }

          // ---- apps: equal widths across the card ----
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(4)
            Repeater {
              model: [
                { label: "Plex", glyph: "󰚺", app: "plex" },
                { label: "YouTube", glyph: "󰗃", app: "youtube" },
                { label: "Prime", glyph: "", app: "prime video" },
                { label: "Shahid", glyph: "󰕼", app: "shahid" }
              ]
              Button {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: modelData.label
                iconText: modelData.glyph
                tooltipText: "Open " + modelData.label + " on the TV"
                bordered: true
                foreground: win.foreground
                fontFamily: win.fontFamily
                onClicked: win.run(["media", "tv", "app", modelData.app])
              }
            }
          }

          // ---- buttons ----
          GridLayout {
            Layout.alignment: Qt.AlignHCenter
            columns: 3
            rowSpacing: Style.space(4)
            columnSpacing: Style.space(4)

            Repeater {
              model: [
                { glyph: "󰁮", key: "BACK", tip: "Back (Backspace)" },
                { glyph: "󰁝", key: "UP", tip: "Up" },
                { glyph: "󰋜", key: "HOME", tip: "Home (h)" },
                { glyph: "󰁍", key: "LEFT", tip: "Left" },
                { glyph: "󰄬", key: "ENTER", tip: "OK (Enter)" },
                { glyph: "󰁔", key: "RIGHT", tip: "Right" },
                { glyph: "󰒓", key: "MENU", tip: "Settings" },
                { glyph: "󰁅", key: "DOWN", tip: "Down" },
                { glyph: "󰋽", key: "INFO", tip: "Info" }
              ]
              Button {
                required property var modelData
                Layout.preferredWidth: Style.space(64)
                iconText: modelData.glyph
                iconSize: Style.font.title
                tooltipText: modelData.tip
                bordered: true
                foreground: win.foreground
                fontFamily: win.fontFamily
                onClicked: win.key(modelData.key)
              }
            }
          }

          // TV volume together on the left, playback on the right; every
          // button the same size.
          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(12)
            Repeater {
              model: [
                [
                  { glyph: "󰝞", tip: "TV volume down", key: "VOLUMEDOWN" },
                  { glyph: "󰝟", tip: "TV mute", key: "MUTE" },
                  { glyph: "󰝝", tip: "TV volume up", key: "VOLUMEUP" }
                ],
                [
                  { glyph: "󰑟", tip: "Rewind", tv: "rew" },
                  { glyph: "", tip: "", play: true },
                  { glyph: "󰈑", tip: "Fast forward", tv: "ff" },
                  { glyph: "󰓛", tip: "Stop", tv: "stop" }
                ]
              ]
              RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: modelData.length
                spacing: Style.space(4)
                Repeater {
                  model: parent.modelData
                  Button {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    iconText: modelData.play ? (win.paused ? "󰐊" : "󰏤") : modelData.glyph
                    tooltipText: modelData.play ? (win.paused ? "Play" : "Pause") + " (space)" : modelData.tip
                    bordered: true
                    foreground: win.foreground
                    fontFamily: win.fontFamily
                    onClicked: {
                      if (modelData.play) win.playPause()
                      else if (modelData.tv) win.svc.tvKey(modelData.tv)
                      else win.key(modelData.key)
                    }
                  }
                }
              }
            }
          }
        }

        // ================= Cast tab =================
        ColumnLayout {
          visible: win.tab === "cast"
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: Style.space(8)

          // What's playing: name, progress (drag to seek), play/pause, next, stop.
          ColumnLayout {
            visible: win.svc.casting || win.svc.castState === "failed"
            Layout.fillWidth: true
            spacing: Style.space(6)

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.space(8)
              Text {
                textFormat: Text.PlainText
                text: win.svc.castState === "paused" ? "󰏤" : (win.svc.castState === "starting" ? "󰑓" : "󰐊")
                color: win.foreground
                font.family: win.fontFamily
                font.pixelSize: Style.font.icon
                Layout.alignment: Qt.AlignVCenter
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.space(1)
                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: win.svc.castName
                  color: win.foreground
                  font.family: win.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideMiddle
                }
                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: {
                    var s = win.svc
                    var st = s.castState === "starting" ? (s.castMessage || "Starting on the TV…")
                      : s.castState === "paused" ? "Paused"
                      : s.castState === "failed" ? (s.castMessage || "Didn't play")
                      : "Playing on the TV"
                    if (s.queueLength > 1) st += " · " + (s.cs.index + 1) + " of " + s.queueLength
                    return s.castSubtitles ? st + " · subtitles" : st
                  }
                  color: win.dim
                  font.family: win.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
              PanelActionButton {
                visible: win.svc.casting
                iconText: win.svc.castState === "playing" ? "󰏤" : "󰐊"
                tooltipText: win.svc.castState === "playing" ? "Pause" : "Play"
                foreground: win.foreground
                fontFamily: win.fontFamily
                onClicked: win.svc.toggleCast()
              }
              PanelActionButton {
                visible: win.svc.casting && win.svc.hasNext
                iconText: "󰒭"
                tooltipText: "Next in the queue"
                foreground: win.foreground
                fontFamily: win.fontFamily
                onClicked: win.svc.nextCast()
              }
              PanelActionButton {
                visible: win.svc.casting
                iconText: "󰓛"
                tooltipText: "Stop casting"
                foreground: win.foreground
                fontFamily: win.fontFamily
                onClicked: win.svc.stopCast()
              }
            }
            RowLayout {
              visible: win.svc.casting && win.svc.castDuration > 0
              Layout.fillWidth: true
              spacing: Style.space(8)
              Text {
                textFormat: Text.PlainText
                text: win.svc.formatTime(win.svc.castPosition)
                color: win.dim
                font.family: win.fontFamily
                font.pixelSize: Style.font.caption
              }
              PanelSlider {
                Layout.fillWidth: true
                minimum: 0
                maximum: Math.max(1, win.svc.castDuration)
                step: 5
                integer: true
                value: Math.max(0, win.svc.castPosition)
                onReleased: function(v) { win.svc.seekCast(v) }
              }
              Text {
                textFormat: Text.PlainText
                text: win.svc.formatTime(win.svc.castDuration)
                color: win.dim
                font.family: win.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }

          TextField {
            id: videoSearch
            Layout.fillWidth: true
            foreground: win.foreground
            font.family: win.fontFamily
            placeholderText: (win.svc.videos || []).length > 0
              ? "Search " + win.svc.videos.length + " videos (/)"
              : "No videos in ~/Videos, ~/Downloads or ~/Movies"
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                if (text !== "") text = ""
                else win.leaveTextBox()
                event.accepted = true
              }
            }
            onAccepted: if (win.videoMatches.length > 0) win.svc.cast(win.videoMatches[0].path)
          }

          ListView {
            id: videoList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Style.space(2)
            model: win.videoMatches
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            delegate: ActionRow {
              required property var modelData
              required property int index
              width: videoList.width
              glyph: modelData.path === win.svc.castPath && win.svc.casting ? "󰐊" : "󰕧"
              label: modelData.name
              detail: modelData.folder + " · " + win.svc.formatSize(modelData.size)
                + (modelData.subtitles ? " · subtitles" : "")
                + (index === 0 && videoSearch.activeFocus && videoSearch.text !== "" ? " · Enter" : "")
              onActivated: win.svc.cast(modelData.path)
            }
          }
          Text {
            textFormat: Text.PlainText
            visible: videoSearch.text !== "" && win.videoMatches.length === 0
            Layout.fillWidth: true
            text: "No video matches"
            color: win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(4)
            Button {
              Layout.fillWidth: true
              text: "Caster…"
              iconText: "󰐾"
              tooltipText: "Queue, whole folders, links, continue where you left off"
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.openCasterRequested()
            }
            Button {
              Layout.fillWidth: true
              text: "Browse…"
              iconText: "󰉋"
              tooltipText: "Pick a video anywhere on this machine"
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.svc.browseVideo()
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
          text: win.tab === "remote"
            ? "arrows · ⏎ OK · ⌫ back · c touchpad · [ ] speed · / type · space play/pause · p power · m mute · Tab cast · Esc close"
            : "/ search · ⏎ cast the first · p power · m mute · +/- Sonos · Tab remote · Esc close"
          color: win.dim
          font.family: win.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  component ActionRow: CursorSurface {
    id: row
    property string glyph: ""
    property string label: ""
    property string detail: ""
    signal activated()

    hasCursor: rowMouse.containsMouse
    foreground: win.foreground
    implicitHeight: rowLayout.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row.activated()
    }

    RowLayout {
      id: rowLayout
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(10)
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: row.glyph
        color: win.foreground
        font.family: win.fontFamily
        font.pixelSize: Style.font.icon
        Layout.alignment: Qt.AlignVCenter
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)
        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: row.label
          color: win.foreground
          font.family: win.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }
        Text {
          textFormat: Text.PlainText
          visible: text !== ""
          Layout.fillWidth: true
          text: row.detail
          color: win.dim
          font.family: win.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
