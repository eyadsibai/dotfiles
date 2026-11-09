import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons as Commons
import qs.Ui

// A small audio visualizer for the bar: cava's bars (~/.config/cava/bar) drawn in
// the theme's accent. It shows, and cava runs, only while an MPRIS player is
// playing (Spotify, mpv, the TV, a browser), so it costs nothing when idle.
// Click opens cava full size in a terminal.
BarWidget {
  id: root
  moduleName: "eyad.cava"

  readonly property bool playing: {
    var players = Mpris.players ? Mpris.players.values : []
    for (var i = 0; i < players.length; i++)
      if (players[i].isPlaying) return true
    return false
  }
  // Keep showing for a moment after a pause, so a skip doesn't make it blink.
  property bool shown: false
  onPlayingChanged: if (playing) { idle.stop(); shown = true } else idle.restart()
  Timer { id: idle; interval: 2500; onTriggered: root.shown = root.playing }
  Component.onCompleted: shown = playing

  readonly property int bars: 10
  property var levels: []   // 0..1 per bar
  readonly property color accent: Commons.Color.accent
  readonly property real barWidth: 3
  readonly property real gap: 2
  readonly property real maxHeight: barSize * 0.55

  visible: shown && !vertical
  implicitWidth: visible ? bars * barWidth + (bars - 1) * gap + 12 : 0
  implicitHeight: barSize

  Process {
    id: cava
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/bar"]
    running: root.shown && !root.vertical
    stdout: SplitParser {
      onRead: function(line) {
        var parts = line.split(";")
        var out = []
        for (var i = 0; i < root.bars; i++) out.push(Math.min(1, (parseInt(parts[i]) || 0) / 100))
        root.levels = out
      }
    }
    onRunningChanged: if (!running) root.levels = []
  }

  Row {
    anchors.centerIn: parent
    spacing: root.gap
    height: root.maxHeight
    Repeater {
      model: root.bars
      Rectangle {
        required property int index
        anchors.bottom: parent.bottom
        width: root.barWidth
        // A floor, so silence between songs still reads as the visualizer.
        height: Math.max(2, (root.levels[index] || 0) * root.maxHeight)
        radius: 1
        color: root.accent
        opacity: 0.55 + 0.45 * (root.levels[index] || 0)
        Behavior on height { NumberAnimation { duration: 60 } }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: Quickshell.execDetached(["omarchy-launch-or-focus-tui", "cava"])
  }
}
