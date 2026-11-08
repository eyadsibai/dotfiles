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
  property string error: ""
  property string sentText: ""   // what the text box has already typed on the TV

  // Pointer moves are summed and flushed every 30 ms.
  property real pendingX: 0
  property real pendingY: 0
  readonly property real pointerSpeed: 1.6

  function send(line) {
    if (pipe.running) pipe.write(line + "\n")
  }
  function key(name) { send("key " + name) }

  // Type the difference between what the TV has and what the box holds now.
  function syncText(now) {
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
    else closeRequested()
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
        } catch (e) {}
      }
    }
    stderr: StdioCollector { id: pipeErr; waitForEnd: true }
    onRunningChanged: if (running) win.error = ""
    onExited: function(code) {
      win.connected = false
      win.tvKeyboard = false
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
      map[Qt.Key_Space] = "PAUSE"; map[Qt.Key_Home] = "HOME"
      if (k === Qt.Key_Escape) { win.closeRequested(); event.accepted = true }
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
        placeholderText: "Type on the TV"
        onTextChanged: win.syncText(text)
        onAccepted: {
          win.send("enter")
          win.sentText = ""
          text = ""
        }
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            win.sentText = ""
            text = ""
            scope.forceActiveFocus()
            event.accepted = true
          }
        }
      }
      Text {
        textFormat: Text.PlainText
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        text: win.tvKeyboard
          ? "󰌌  The TV keyboard is open: what you type goes straight in, Enter submits."
          : "Typing reaches the TV's own keyboard (browser, home search). Plex, YouTube and Netflix draw their own letter grid: click the letters with the touchpad."
        color: win.tvKeyboard ? win.accent : win.dim
        font.family: win.fontFamily
        font.pixelSize: Style.font.caption
      }

      // ---- touchpad ----
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Style.space(160)
        color: pad.pressed ? Qt.rgba(win.foreground.r, win.foreground.g, win.foreground.b, 0.08)
                           : Qt.rgba(win.foreground.r, win.foreground.g, win.foreground.b, 0.04)
        border.width: 1
        border.color: pad.containsMouse ? win.accent : win.faint
        radius: Style.cornerRadius

        Text {
          anchors.centerIn: parent
          width: parent.width - Style.space(24)
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
          textFormat: Text.PlainText
          text: "Touchpad\ndrag to move the pointer · click to click · scroll to scroll"
          color: win.dim
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
          property real travelled: 0

          onPressed: function(mouse) {
            scope.forceActiveFocus()
            lastX = mouse.x; lastY = mouse.y; travelled = 0
          }
          onPositionChanged: function(mouse) {
            if (!pressed) return
            var dx = mouse.x - lastX, dy = mouse.y - lastY
            lastX = mouse.x; lastY = mouse.y
            travelled += Math.abs(dx) + Math.abs(dy)
            win.pendingX += dx * win.pointerSpeed
            win.pendingY += dy * win.pointerSpeed
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
            { glyph: "󰝝", key: "VOLUMEUP", tip: "Volume up (+)" },
            { glyph: "󰐊", key: "PLAY", tip: "Play" },
            { glyph: "󰏤", key: "PAUSE", tip: "Pause (space)" }
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
      }

      Text {
        textFormat: Text.PlainText
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: "arrows · ⏎ OK · ⌫ back · / type · +/- volume · Esc close"
        color: win.dim
        font.family: win.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }
}
