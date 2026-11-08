import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The caster: a window for the `cast` service (~/.local/bin/cast). Library on the
// left (search, or paste a link), what's playing and the queue on the right.
// Everything goes through the cast command; the window only shows its state, so
// closing it never stops playback.
FloatingWindow {
  id: win
  title: "Cast"
  color: background
  implicitWidth: 1000
  implicitHeight: 660
  minimumSize: Qt.size(760, 480)

  signal closeRequested()

  readonly property color foreground: Commons.Color.foreground
  readonly property color background: Commons.Color.background
  readonly property color accent: Commons.Color.accent
  readonly property color urgent: Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: Style.font.family
  readonly property var fakeBar: QtObject {
    readonly property color foreground: win.foreground
    readonly property color background: win.background
    readonly property color urgent: win.urgent
  }

  // ---- cast state (from `cast watch`) ----
  property var cs: ({ state: "idle", queue: [], index: -1, position: 0, duration: 0 })
  property var videos: []
  property int libIndex: 0
  property int seekPreview: -1
  readonly property bool active: ["preparing", "starting", "playing", "paused"].indexOf(cs.state) >= 0
  readonly property bool playing: cs.state === "playing"
  readonly property string query: search.text.trim()
  readonly property bool queryIsLink: /^https?:\/\/\S+$/i.test(query)

  readonly property var matches: {
    if (queryIsLink) return []
    var words = query.toLowerCase().split(/\s+/).filter(function(w) { return w !== "" })
    var out = []
    for (var i = 0; i < videos.length && out.length < 300; i++) {
      var v = videos[i]
      var hay = (String(v.name) + " " + String(v.folder)).toLowerCase()
      if (words.every(function(w) { return hay.indexOf(w) >= 0 })) out.push(v)
    }
    return out
  }
  onMatchesChanged: libIndex = Math.max(0, Math.min(libIndex, matches.length - 1))

  function cast(args) { Quickshell.execDetached(["cast"].concat(args)) }
  function playVideo(v, folder) { cast(folder ? ["play", "--folder", v.path] : ["play", v.path]) }
  function queueVideo(v) { cast(["add", v.path]) }
  function playLink(add) {
    if (!queryIsLink) return
    cast([add ? "add" : "play", query])
    search.text = ""
  }

  function formatTime(secs) {
    secs = Math.max(0, Math.floor(secs || 0))
    var h = Math.floor(secs / 3600), m = Math.floor(secs / 60) % 60, s = secs % 60
    return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s
  }
  function formatSize(bytes) {
    if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB"
    if (bytes >= 1048576) return Math.round(bytes / 1048576) + " MB"
    return Math.max(1, Math.round(bytes / 1024)) + " KB"
  }
  function stateText() {
    switch (cs.state) {
    case "preparing": return cs.message || "Getting ready…"
    case "starting": return cs.message || "Starting on the TV…"
    case "playing": return "Playing on the TV"
    case "paused": return "Paused"
    case "stopped": return cs.message || "Stopped"
    case "error": return cs.message || "Something went wrong"
    default: return cs.message === "Finished" ? "Finished" : (cs.queue && cs.queue.length ? "Ready" : "Nothing playing")
    }
  }

  onVisibleChanged: {
    if (visible) {
      videosProc.running = true
      Qt.callLater(function() { search.forceActiveFocus() })
    } else {
      closeRequested()
    }
  }

  Process {
    id: watchProc
    command: ["cast", "watch"]
    running: win.visible
    stdout: SplitParser {
      onRead: function(line) {
        try { win.cs = JSON.parse(line) } catch (e) {}
      }
    }
    onExited: if (win.visible) restartWatch.restart()
  }
  Timer { id: restartWatch; interval: 2000; onTriggered: if (win.visible) watchProc.running = true }

  Process {
    id: videosProc
    command: ["cast", "videos"]
    stdout: StdioCollector { id: videosOut; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) return
      try {
        var rows = JSON.parse(videosOut.text)
        win.videos = Array.isArray(rows) ? rows : []
      } catch (e) {}
    }
  }
  // Positions change as things play; refresh the library when playback stops.
  onActiveChanged: if (!active && visible) videosProc.running = true

  FocusScope {
    id: scope
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (search.activeFocus) return
      var k = event.key
      if (k === Qt.Key_Escape) { win.closeRequested(); event.accepted = true }
      else if (k === Qt.Key_Slash) { search.forceActiveFocus(); event.accepted = true }
      else if (k === Qt.Key_Space) { win.cast(["toggle"]); event.accepted = true }
      else if (k === Qt.Key_Left) { win.cast(["seek", "-10"]); event.accepted = true }
      else if (k === Qt.Key_Right) { win.cast(["seek", "+10"]); event.accepted = true }
      else if (event.text === "n") { win.cast(["next"]); event.accepted = true }
      else if (event.text === "p") { win.cast(["prev"]); event.accepted = true }
      else if (event.text === "s") { win.cast(["stop"]); event.accepted = true }
      else if (k === Qt.Key_Down || event.text === "j") { win.libIndex = Math.min(win.libIndex + 1, win.matches.length - 1); event.accepted = true }
      else if (k === Qt.Key_Up || event.text === "k") {
        if (win.libIndex === 0) search.forceActiveFocus()
        else win.libIndex = Math.max(0, win.libIndex - 1)
        event.accepted = true
      }
      else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
        if (win.matches.length) win.playVideo(win.matches[win.libIndex], false)
        event.accepted = true
      }
      else if (event.text === "a") { if (win.matches.length) win.queueVideo(win.matches[win.libIndex]); event.accepted = true }
      else if (event.text === "f") { if (win.matches.length) win.playVideo(win.matches[win.libIndex], true); event.accepted = true }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.space(20)
      spacing: Style.space(14)

      // ---- header ----
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(12)

        Text {
          textFormat: Text.PlainText
          text: "󰐾"
          color: win.foreground
          font.family: win.fontFamily
          font.pixelSize: Style.font.display
        }
        ColumnLayout {
          spacing: 0
          Layout.fillWidth: true
          Text {
            textFormat: Text.PlainText
            text: "Cast"
            color: win.foreground
            font.family: win.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            textFormat: Text.PlainText
            text: "Living-room TV · " + win.stateText()
            color: win.cs.state === "error" ? win.urgent : win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }
        Text {
          textFormat: Text.PlainText
          text: "/ search · ↑↓ ⏎ play · a queue · f folder · space pause · ←→ seek · n/p next/prev"
          color: win.dim
          font.family: win.fontFamily
          font.pixelSize: Style.font.caption
          Layout.alignment: Qt.AlignBottom
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.space(20)

        // ---- library ----
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: Style.space(10)

          TextField {
            id: search
            Layout.fillWidth: true
            foreground: win.foreground
            font.family: win.fontFamily
            font.pixelSize: Style.font.body
            placeholderText: "Search " + win.videos.length + " videos, or paste a link"
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                if (text !== "") text = ""
                else scope.forceActiveFocus()
                event.accepted = true
              } else if (event.key === Qt.Key_Down) {
                win.libIndex = 0
                scope.forceActiveFocus()
                event.accepted = true
              }
            }
            onAccepted: {
              if (win.queryIsLink) win.playLink(false)
              else if (win.matches.length) win.playVideo(win.matches[0], false)
            }
          }

          // A pasted link
          RowLayout {
            visible: win.queryIsLink
            Layout.fillWidth: true
            spacing: Style.space(8)
            Text {
              textFormat: Text.PlainText
              text: "󰌹  Play this link on the TV (YouTube and most video sites, via yt-dlp)"
              color: win.foreground
              font.family: win.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
            Button {
              text: "Play"
              iconText: "󰐊"
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.playLink(false)
            }
            Button {
              text: "Add to queue"
              iconText: "󰐕"
              bordered: true
              foreground: win.foreground
              fontFamily: win.fontFamily
              onClicked: win.playLink(true)
            }
          }

          ListView {
            id: libList
            visible: !win.queryIsLink
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Style.space(2)
            model: win.matches
            currentIndex: win.libIndex
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: CursorSurface {
              id: libRow
              required property var modelData
              required property int index
              width: libList.width
              implicitHeight: libLayout.implicitHeight + Style.spacing.rowPaddingX
              foreground: win.foreground
              hasCursor: libHover.hovered || (index === win.libIndex && !search.activeFocus)
              readonly property bool nowPlaying: win.active && modelData.path === win.cs.src

              // Hover comes from a HoverHandler, not the MouseArea: the action buttons
              // have mouse areas of their own that would take the hover, hide
              // themselves, hand it back, and so on (a flickering cursor).
              HoverHandler { id: libHover; cursorShape: Qt.PointingHandCursor }

              MouseArea {
                id: libMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { win.libIndex = libRow.index; win.playVideo(libRow.modelData, false) }
              }

              RowLayout {
                id: libLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(6)
                spacing: Style.space(10)

                Text {
                  textFormat: Text.PlainText
                  text: libRow.nowPlaying ? "󰐊" : "󰕧"
                  color: win.foreground
                  font.family: win.fontFamily
                  font.pixelSize: Style.font.icon
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Style.space(1)
                  Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: libRow.modelData.name
                    color: win.foreground
                    font.family: win.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignLeft
                  }
                  Text {
                    textFormat: Text.PlainText
                    Layout.fillWidth: true
                    text: {
                      var v = libRow.modelData
                      var bits = [v.folder, win.formatSize(v.size)]
                      if (v.subtitles) bits.push("subtitles")
                      if (v.position > 0) bits.push("continue at " + win.formatTime(v.position))
                      return bits.join(" · ")
                    }
                    color: win.dim
                    font.family: win.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }
                Row {
                  visible: libRow.hasCursor
                  spacing: Style.space(2)
                  PanelActionButton {
                    iconText: "󰐊"
                    tooltipText: "Play (Enter)"
                    foreground: win.foreground
                    fontFamily: win.fontFamily
                    onClicked: win.playVideo(libRow.modelData, false)
                  }
                  PanelActionButton {
                    iconText: "󰐕"
                    tooltipText: "Add to queue (a)"
                    foreground: win.foreground
                    fontFamily: win.fontFamily
                    onClicked: win.queueVideo(libRow.modelData)
                  }
                  PanelActionButton {
                    iconText: "󰉋"
                    tooltipText: "Play the folder from here (f)"
                    foreground: win.foreground
                    fontFamily: win.fontFamily
                    onClicked: win.playVideo(libRow.modelData, true)
                  }
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: !win.queryIsLink && win.matches.length === 0
            text: win.videos.length === 0 ? "No videos in ~/Videos, ~/Downloads or ~/Movies" : "No video matches"
            color: win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }

        Rectangle {
          Layout.fillHeight: true
          width: 1
          color: Qt.rgba(win.foreground.r, win.foreground.g, win.foreground.b, 0.12)
        }

        // ---- now playing + queue ----
        ColumnLayout {
          Layout.preferredWidth: Math.max(Style.space(320), win.width * 0.36)
          Layout.maximumWidth: Style.space(420)
          Layout.fillHeight: true
          spacing: Style.space(10)

          PanelSectionHeader {
            text: "NOW PLAYING"
            foreground: win.foreground
            fontFamily: win.fontFamily
          }

          Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            text: win.cs.title || "Nothing yet. Pick a video or paste a link."
            color: win.cs.title ? win.foreground : win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.heading
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
          }

          Text {
            textFormat: Text.PlainText
            Layout.fillWidth: true
            visible: text !== ""
            text: {
              if (!win.cs.title) return ""
              var bits = [win.stateText()]
              if (win.cs.mode === "stream") bits.push(win.cs.kind === "url" ? "streaming the link" : "converting on the fly")
              if (win.cs.subtitles) bits.push("subtitles")
              return bits.join(" · ")
            }
            color: win.cs.state === "error" ? win.urgent : win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
          }

          RowLayout {
            Layout.fillWidth: true
            visible: win.cs.resumed_from > 0 && win.active
            spacing: Style.space(8)
            Text {
              textFormat: Text.PlainText
              text: "Continued from " + win.formatTime(win.cs.resumed_from)
              color: win.dim
              font.family: win.fontFamily
              font.pixelSize: Style.font.caption
              Layout.fillWidth: true
            }
            Button {
              text: "Start over"
              foreground: win.foreground
              fontFamily: win.fontFamily
              fontSize: Style.font.caption
              onClicked: win.cast(["restart"])
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.space(8)
            enabled: win.active && win.cs.duration > 0
            opacity: enabled ? 1 : 0.4
            Text {
              textFormat: Text.PlainText
              text: win.formatTime(win.seekPreview >= 0 ? win.seekPreview : win.cs.position)
              color: win.dim
              font.family: win.fontFamily
              font.pixelSize: Style.font.caption
            }
            PanelSlider {
              bar: win.fakeBar
              Layout.fillWidth: true
              minimum: 0
              maximum: Math.max(1, win.cs.duration)
              step: 5
              integer: true
              value: win.cs.position
              onMoved: function(v) { win.seekPreview = v }
              onReleased: function(v) { win.seekPreview = -1; win.cast(["seek", String(Math.round(v))]) }
            }
            Text {
              textFormat: Text.PlainText
              text: win.formatTime(win.cs.duration)
              color: win.dim
              font.family: win.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.space(6)
            PanelActionButton {
              iconText: "󰒮"; tooltipText: "Previous (p)"
              foreground: win.foreground; fontFamily: win.fontFamily
              enabled: win.cs.index > 0 || win.cs.position > 10
              onClicked: win.cast(["prev"])
            }
            PanelActionButton {
              iconText: "󰴪"; tooltipText: "Back 10s (←)"
              foreground: win.foreground; fontFamily: win.fontFamily
              enabled: win.active
              onClicked: win.cast(["seek", "-10"])
            }
            PanelActionButton {
              iconText: win.playing ? "󰏤" : "󰐊"
              tooltipText: win.playing ? "Pause (space)" : "Play (space)"
              fontSize: Style.font.display
              bordered: true
              foreground: win.foreground; fontFamily: win.fontFamily
              enabled: win.cs.queue && win.cs.queue.length > 0
              onClicked: win.cast(["toggle"])
            }
            PanelActionButton {
              iconText: "󰵱"; tooltipText: "Forward 10s (→)"
              foreground: win.foreground; fontFamily: win.fontFamily
              enabled: win.active
              onClicked: win.cast(["seek", "+10"])
            }
            PanelActionButton {
              iconText: "󰒭"; tooltipText: "Next (n)"
              foreground: win.foreground; fontFamily: win.fontFamily
              enabled: win.cs.queue && win.cs.index + 1 < win.cs.queue.length
              onClicked: win.cast(["next"])
            }
            PanelActionButton {
              iconText: "󰓛"; tooltipText: "Stop (s)"
              foreground: win.foreground; fontFamily: win.fontFamily
              enabled: win.active
              onClicked: win.cast(["stop"])
            }
          }

          PanelSeparator { foreground: win.foreground; Layout.fillWidth: true }

          RowLayout {
            Layout.fillWidth: true
            PanelSectionHeader {
              text: win.cs.queue && win.cs.queue.length ? "QUEUE · " + win.cs.queue.length : "QUEUE"
              foreground: win.foreground
              fontFamily: win.fontFamily
              Layout.fillWidth: true
            }
            Button {
              visible: win.cs.queue && win.cs.queue.length > 0
              text: "Clear"
              foreground: win.foreground
              fontFamily: win.fontFamily
              fontSize: Style.font.caption
              onClicked: win.cast(["clear"])
            }
          }

          ListView {
            id: queueList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Style.space(2)
            model: win.cs.queue || []
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: CursorSurface {
              id: qRow
              required property var modelData
              required property int index
              width: queueList.width
              implicitHeight: qLayout.implicitHeight + Style.spacing.rowPaddingX
              foreground: win.foreground
              current: index === win.cs.index
              hasCursor: qHover.hovered

              HoverHandler { id: qHover; cursorShape: Qt.PointingHandCursor }

              MouseArea {
                id: qMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: win.cast(["jump", String(qRow.index + 1)])
              }

              RowLayout {
                id: qLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Style.space(10)
                anchors.rightMargin: Style.space(4)
                spacing: Style.space(8)

                Text {
                  textFormat: Text.PlainText
                  text: qRow.current ? (win.playing ? "󰐊" : (win.cs.state === "paused" ? "󰏤" : "•")) : String(qRow.index + 1)
                  color: qRow.current ? win.foreground : win.dim
                  font.family: win.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  Layout.preferredWidth: Style.space(18)
                  horizontalAlignment: Text.AlignHCenter
                }
                Text {
                  textFormat: Text.PlainText
                  text: (qRow.modelData.kind === "url" ? "󰌹 " : "") + qRow.modelData.title
                  color: win.foreground
                  font.family: win.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  elide: Text.ElideMiddle
                  Layout.fillWidth: true
                }
                Text {
                  textFormat: Text.PlainText
                  visible: qRow.modelData.duration > 0 && !qRow.hasCursor
                  text: win.formatTime(qRow.modelData.duration)
                  color: win.dim
                  font.family: win.fontFamily
                  font.pixelSize: Style.font.caption
                }
                Row {
                  visible: qRow.hasCursor
                  spacing: 0
                  PanelActionButton {
                    iconText: "󰁝"; tooltipText: "Move up"
                    foreground: win.foreground; fontFamily: win.fontFamily
                    fontSize: Style.font.bodySmall
                    enabled: qRow.index > 0
                    onClicked: win.cast(["move", String(qRow.index + 1), String(qRow.index)])
                  }
                  PanelActionButton {
                    iconText: "󰅖"; tooltipText: "Remove"
                    foreground: win.foreground; fontFamily: win.fontFamily
                    fontSize: Style.font.bodySmall
                    onClicked: win.cast(["remove", String(qRow.index + 1)])
                  }
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: !win.cs.queue || win.cs.queue.length === 0
            text: "Queue videos with + or a, or play a whole folder with f."
            color: win.dim
            font.family: win.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.Wrap
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
