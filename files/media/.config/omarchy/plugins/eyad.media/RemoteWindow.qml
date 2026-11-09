import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The TV remote: a touchpad for the TV's pointer, remote buttons, and a text box
// that types into the TV's system keyboard. It holds one `media tv pipe`
// connection open while visible, so pointer moves don't start a process each.
FloatingWindow {
  id: win
  title: "TV remote"
  color: background
  implicitWidth: 460
  implicitHeight: 640
  minimumSize: Qt.size(380, 540)

  signal closeRequested()

  readonly property color foreground: Commons.Color.foreground
  readonly property color background: Commons.Color.background
  readonly property color accent: Commons.Color.accent
  readonly property color urgent: Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color faint: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)
  readonly property string fontFamily: Style.font.family

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
  // pointer about 1:1 for small targets; fast flicks cross the screen.
  property real pendingX: 0
  property real pendingY: 0
  function pointerGain(pxPerMs) { return 0.9 + 2.4 * Math.min(pxPerMs, 1.5) }

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
  // Focusing the scope alone would hand focus straight back to the text box,
  // its remembered focus child.
  function leaveTextBox() {
    typeBox.focus = false
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

  onVisibleChanged: {
    if (visible) Qt.callLater(function() { scope.forceActiveFocus() })
    else { padOn = false; closeYouTube(); closeRequested() }
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
          if (m.ready) { win.connected = true; win.error = "" }
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
      if (code !== 0) {
        var lines = String(pipeErr.text || "").trim().split("\n")
        win.error = lines[lines.length - 1] || "Lost the TV"
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

  FocusScope {
    id: scope
    anchors.fill: parent
    focus: true

    // Keys while the text box doesn't have focus act like the remote.
    Keys.onPressed: function(event) {
      var k = event.key
      var map = {}
      map[Qt.Key_Up] = "UP"; map[Qt.Key_Down] = "DOWN"; map[Qt.Key_Left] = "LEFT"; map[Qt.Key_Right] = "RIGHT"
      map[Qt.Key_Return] = "ENTER"; map[Qt.Key_Enter] = "ENTER"; map[Qt.Key_Backspace] = "BACK"
      map[Qt.Key_Home] = "HOME"
      if (win.ytShown) {  // the results take arrows, Enter and Esc
        var n = win.ytResults.length
        if (k === Qt.Key_Escape) { win.closeYouTube(); event.accepted = true; return }
        if (k === Qt.Key_Down && n) { win.ytIndex = Math.min(n - 1, win.ytIndex + 1); event.accepted = true; return }
        if (k === Qt.Key_Up && n) { win.ytIndex = Math.max(0, win.ytIndex - 1); event.accepted = true; return }
        if ((k === Qt.Key_Return || k === Qt.Key_Enter) && n) { win.playYouTube(win.ytResults[win.ytIndex]); event.accepted = true; return }
      }
      if (k === Qt.Key_Escape) { if (win.padOn) win.padOn = false; else win.closeRequested(); event.accepted = true }
      else if (k === Qt.Key_Space) { win.playPause(); event.accepted = true }
      else if (event.text === "c") { win.padOn = !win.padOn; event.accepted = true }
      else if (map[k] !== undefined) { win.key(map[k]); event.accepted = true }
      else if (event.text === "/" || event.text === "t") { typeBox.forceActiveFocus(); event.accepted = true }
      else if (event.text === "+" || event.text === "=") { win.key("VOLUMEUP"); event.accepted = true }
      else if (event.text === "-") { win.key("VOLUMEDOWN"); event.accepted = true }
      else if (event.text === "m") { win.key("MUTE"); event.accepted = true }
      else if (event.text === "h") { win.key("HOME"); event.accepted = true }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(18)
      spacing: Style.space(12)

      // ---- header ----
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(12)
        Text {
          textFormat: Text.PlainText
          text: "󰑔"
          color: win.foreground
          font.family: win.fontFamily
          font.pixelSize: Style.font.display
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0
          Text {
            textFormat: Text.PlainText
            text: "Remote"
            color: win.foreground
            font.family: win.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: win.error !== "" ? win.error : (win.connected ? "Connected to the TV" : "Connecting…")
            color: win.error !== "" ? win.urgent : win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      // ---- typing ----
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
        visible: !win.typedIsLink
        textFormat: Text.PlainText
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: win.tvKeyboard
          ? "󰌌  The TV keyboard is open: what you type goes straight in, Enter submits."
          : win.typingToGrid && win.gridError !== "" ? "󰀦  " + win.gridError
          : win.typingToGrid ? "󰌌  Typing walks " + win.tvGrid + "'s letters on the TV (arrows and OK). Have its search open."
          : "Enter searches YouTube; pick a video to play it on the TV. Plex: click its letters with the touchpad."
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
        Layout.minimumHeight: Style.space(160)
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
        Layout.minimumHeight: Style.space(160)
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
          text: win.padOn
            ? "Touchpad on\nmove to move the pointer · click to click · c or Esc to stop"
            : "Touchpad\ndrag to move the pointer · click to click · scroll to scroll\nc: move without holding"
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

          onExited: primed = false

          onPressed: function(mouse) {
            win.leaveTextBox()
            lastX = mouse.x; lastY = mouse.y; lastT = Date.now(); travelled = 0; primed = true
          }
          onPositionChanged: function(mouse) {
            if (!pressed && !win.padOn) return
            var now = Date.now()
            if (!primed) { lastX = mouse.x; lastY = mouse.y; lastT = now; primed = true; return }
            var dx = mouse.x - lastX, dy = mouse.y - lastY
            var dt = Math.max(1, now - lastT)
            lastX = mouse.x; lastY = mouse.y; lastT = now
            travelled += Math.abs(dx) + Math.abs(dy)
            var gain = win.pointerGain(Math.sqrt(dx * dx + dy * dy) / dt)
            win.pendingX += dx * gain
            win.pendingY += dy * gain
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

      // ---- apps ----
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
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

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Style.space(4)
        Repeater {
          model: [
            { glyph: "󰝞", key: "VOLUMEDOWN", tip: "Volume down (-)" },
            { glyph: "󰝟", key: "MUTE", tip: "Mute (m)" },
            { glyph: "󰝝", key: "VOLUMEUP", tip: "Volume up (+)" }
          ]
          Button {
            required property var modelData
            iconText: modelData.glyph
            tooltipText: modelData.tip
            foreground: win.foreground
            fontFamily: win.fontFamily
            onClicked: win.key(modelData.key)
          }
        }
        Button {
          iconText: win.paused ? "󰐊" : "󰏤"
          tooltipText: (win.paused ? "Play" : "Pause") + " (space)"
          foreground: win.foreground
          fontFamily: win.fontFamily
          onClicked: win.playPause()
        }
      }

      Text {
        textFormat: Text.PlainText
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: "arrows · ⏎ OK · ⌫ back · c touchpad · / type · space play/pause · +/- volume · Esc close"
        color: win.dim
        font.family: win.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
