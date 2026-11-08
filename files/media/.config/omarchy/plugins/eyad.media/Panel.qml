import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar icon + popup for the living room. Click opens the panel, scroll changes
// the Sonos volume, middle-click mutes it, right-click refreshes.
Panel {
  id: root
  moduleName: "eyad.media"
  ipcTarget: "eyad.media"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string title: String(setting("title", "Living room"))
  readonly property bool hideWhenUnreachable: setting("hideWhenUnreachable", false) === true
  readonly property string tvGlyph: "󰔂"
  readonly property int videoLimit: 6
  // Videos matching the search box, newest first. Every word must appear in the name or folder.
  readonly property var videoMatches: {
    var words = videoSearch.text.toLowerCase().split(/\s+/).filter(function(w) { return w !== "" })
    var out = []
    for (var i = 0; i < media.videos.length && out.length < videoLimit; i++) {
      var v = media.videos[i]
      var hay = (String(v.name) + " " + String(v.folder)).toLowerCase()
      if (words.every(function(w) { return hay.indexOf(w) >= 0 })) out.push(v)
    }
    return out
  }
  readonly property string volumeGlyph: media.sonosMuted ? "󰝟" : (media.volume < 34 ? "󰕿" : (media.volume < 67 ? "󰖀" : "󰕾"))

  visible: !(hideWhenUnreachable && media.loaded && !media.anyReachable)
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    media.fastPolling = opened
    media.watchCast = opened
    if (opened) {
      media.refresh()
      media.refreshVideos()
      videoSearch.text = ""
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }
  }

  Service {
    id: media
    settings: root.settings
  }

  // The caster window (CastWindow.qml): library, links, now playing and the queue.
  function openCaster() {
    root.close()
    casterLoader.active = true
  }

  LazyLoader {
    id: casterLoader
    active: false
    CastWindow {
      visible: true
      onCloseRequested: casterLoader.active = false
    }
  }

  // The remote window (RemoteWindow.qml): touchpad, buttons, typing on the TV.
  function openRemote() {
    root.close()
    remoteLoader.active = true
  }

  LazyLoader {
    id: remoteLoader
    active: false
    RemoteWindow {
      visible: true
      onCloseRequested: remoteLoader.active = false
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function remote(): void { root.openRemote() }
    function refresh(): string { media.refresh(); return "ok" }
    function status(): string { return media.summary }
    function scene(name: string): string { media.runScene(name); return "ok" }
    function volumeUp(): void { media.nudgeVolume(5) }
    function volumeDown(): void { media.nudgeVolume(-5) }
    function toggleMute(): void { media.toggleMute() }
    function togglePower(): void { media.toggleTvPower() }
    function caster(): void { root.openCaster() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.tvGlyph
    opacity: media.tvOn ? 1.0 : 0.55
    active: media.tvOn && media.playing
    tooltipText: root.opened ? "" : media.summary
    onPressed: function(b) {
      if (b === Qt.MiddleButton) media.toggleMute()
      else if (b === Qt.RightButton) media.refresh()
      else root.toggle()
    }
    onWheelMoved: function(delta) { media.nudgeVolume(delta > 0 ? 2 : -2) }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(600))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: videoSearch.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) media.nudgeVolume(dx * 5)
      }
      onTextKey: function(t) {
        var k = t.toLowerCase()
        if (k === "r") media.refresh()
        else if (k === "m") media.toggleMute()
        else if (k === "p") media.toggleTvPower()
        else if (k === "+" || k === "=") media.nudgeVolume(5)
        else if (k === "-") media.nudgeVolume(-5)
        else if (k === "/" || k === "c") videoSearch.forceActiveFocus()
      }

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: flick.width
          spacing: Style.space(12)

          PanelHero {
            id: hero
            width: parent.width
            title: root.title
            meta: !media.loaded ? "Checking…"
                : !media.tvReachable ? "TV off"
                : media.tvOn ? (media.appName ? "TV on · " + media.appName : "TV on")
                : "TV in standby"
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: media.tvOn ? 1.0 : 0.5
            iconComponent: Component {
              Text {
                text: root.tvGlyph
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
            trailingControl: Component {
              ToggleSwitch {
                id: powerSwitch
                checked: media.tvOn
                busy: media.busy && media.runningLabel.indexOf("Turning") === 0
                foreground: hero.foreground
                onToggled: media.toggleTvPower()

                PanelToolTip {
                  visible: powerSwitch.containsMouse
                  text: media.tvOn ? "Turn the TV off (p)" : "Turn the TV on (p)"
                  fontFamily: hero.fontFamily
                }
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: text !== ""
            width: parent.width
            text: media.lastError !== "" ? media.lastError : media.actionStatus
            color: media.lastError !== "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          PanelSectionHeader {
            text: media.sonosReachable && media.sonos.playback ? "SONOS · " + String(media.sonos.playback).replace("_", " ") : "SONOS"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(10)
            enabled: media.sonosReachable
            opacity: enabled ? 1.0 : 0.5

            PanelActionButton {
              iconText: root.volumeGlyph
              tooltipText: media.sonosMuted ? "Unmute (m)" : "Mute (m)"
              foreground: root.foreground
              fontFamily: root.fontFamily
              Layout.alignment: Qt.AlignVCenter
              onClicked: media.toggleMute()
            }

            PanelSlider {
              bar: root.bar
              Layout.fillWidth: true
              minimum: 0
              maximum: 100
              step: 2
              integer: true
              value: media.volume
              opacity: media.sonosMuted ? 0.5 : 1.0
              onReleased: function(v) { media.setVolume(v) }
              onRightClicked: media.toggleMute()
            }

            Text {
              textFormat: Text.PlainText
              text: media.sonosReachable ? String(media.volume) : "—"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              horizontalAlignment: Text.AlignRight
              Layout.preferredWidth: Style.space(26)
              Layout.alignment: Qt.AlignVCenter
            }
          }

          PanelSectionHeader {
            text: "TV"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          RowLayout {
            width: parent.width
            spacing: Style.space(6)
            enabled: media.tvOn
            opacity: enabled ? 1.0 : 0.5

            Repeater {
              model: [
                { glyph: "󰑟", action: "rew", tip: "Rewind" },
                { glyph: "󰐊", action: "play", tip: "Play" },
                { glyph: "󰏤", action: "pause", tip: "Pause" },
                { glyph: "󰓛", action: "stop", tip: "Stop" },
                { glyph: "󰈑", action: "ff", tip: "Fast forward" }
              ]
              PanelActionButton {
                required property var modelData
                iconText: modelData.glyph
                tooltipText: modelData.tip
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: media.tvKey(modelData.action)
              }
            }

            Item { Layout.fillWidth: true; height: 1 }

            PanelActionButton {
              iconText: "󰑔"
              tooltipText: "Remote: touchpad, buttons, typing"
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.openRemote()
            }
          }

          PanelSeparator {
            visible: media.scenes.length > 0
            foreground: root.foreground
          }

          PanelSectionHeader {
            visible: media.scenes.length > 0
            text: "SCENES"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Column {
            visible: media.scenes.length > 0
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: media.scenes
              ActionRow {
                required property var modelData
                width: parent.width
                glyph: modelData.name === "off" ? "󰐥" : (modelData.name === "night" ? "󰖔" : (modelData.name === "movie" ? "󰿎" : "󰐊"))
                label: modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)
                detail: modelData.description || ""
                onActivated: media.runScene(modelData.name)
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          PanelSectionHeader {
            text: "CAST"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          // What's playing: name, progress (drag to seek) and stop.
          Column {
            visible: media.casting || media.castState === "failed"
            width: parent.width
            spacing: Style.space(6)

            RowLayout {
              width: parent.width
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: media.castState === "paused" ? "󰏤" : (media.castState === "starting" ? "󰑓" : "󰐊")
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.icon
                Layout.alignment: Qt.AlignVCenter
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.space(1)

                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: media.castName
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  elide: Text.ElideMiddle
                }

                Text {
                  textFormat: Text.PlainText
                  Layout.fillWidth: true
                  text: {
                    var st = media.castState === "starting" ? (media.castMessage || "Starting on the TV…")
                      : media.castState === "paused" ? "Paused"
                      : media.castState === "failed" ? (media.castMessage || "Didn't play")
                      : "Playing on the TV"
                    if (media.queueLength > 1) st += " · " + (media.cs.index + 1) + " of " + media.queueLength
                    return media.castSubtitles ? st + " · subtitles" : st
                  }
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              PanelActionButton {
                visible: media.casting
                iconText: media.castState === "playing" ? "󰏤" : "󰐊"
                tooltipText: media.castState === "playing" ? "Pause" : "Play"
                foreground: root.foreground
                fontFamily: root.fontFamily
                Layout.alignment: Qt.AlignVCenter
                onClicked: media.toggleCast()
              }

              PanelActionButton {
                visible: media.casting && media.hasNext
                iconText: "󰒭"
                tooltipText: "Next in the queue"
                foreground: root.foreground
                fontFamily: root.fontFamily
                Layout.alignment: Qt.AlignVCenter
                onClicked: media.nextCast()
              }

              PanelActionButton {
                visible: media.casting
                iconText: "󰓛"
                tooltipText: "Stop casting"
                foreground: root.foreground
                fontFamily: root.fontFamily
                Layout.alignment: Qt.AlignVCenter
                onClicked: media.stopCast()
              }
            }

            RowLayout {
              visible: media.casting && media.castDuration > 0
              width: parent.width
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: media.formatTime(media.castPosition)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.alignment: Qt.AlignVCenter
              }

              PanelSlider {
                bar: root.bar
                Layout.fillWidth: true
                minimum: 0
                maximum: Math.max(1, media.castDuration)
                step: 5
                integer: true
                value: Math.max(0, media.castPosition)
                onReleased: function(v) { media.seekCast(v) }
              }

              Text {
                textFormat: Text.PlainText
                text: media.formatTime(media.castDuration)
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                Layout.alignment: Qt.AlignVCenter
              }
            }
          }

          TextField {
            id: videoSearch
            width: parent.width
            foreground: root.foreground
            font.family: root.fontFamily
            placeholderText: media.videos.length > 0
              ? "Search " + media.videos.length + " videos (/)"
              : "No videos in ~/Videos, ~/Downloads or ~/Movies"
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                if (text !== "") text = ""
                else keyCatcher.forceActiveFocus()
                event.accepted = true
              } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                keyCatcher.forceActiveFocus()
                event.accepted = true
              }
            }
            onAccepted: if (root.videoMatches.length > 0) media.cast(root.videoMatches[0].path)
          }

          Column {
            width: parent.width
            spacing: Style.space(4)

            Repeater {
              model: root.videoMatches
              ActionRow {
                required property var modelData
                required property int index
                width: parent.width
                glyph: modelData.path === media.castPath && media.casting ? "󰐊" : "󰕧"
                label: modelData.name
                detail: modelData.folder + " · " + media.formatSize(modelData.size)
                  + (modelData.subtitles ? " · subtitles" : "")
                  + (index === 0 && videoSearch.activeFocus && videoSearch.text !== "" ? " · Enter" : "")
                onActivated: media.cast(modelData.path)
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            visible: videoSearch.text !== "" && root.videoMatches.length === 0
            width: parent.width
            text: "No video matches"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          ActionRow {
            width: parent.width
            glyph: "󰐾"
            label: "Open the caster…"
            detail: "Queue, whole folders, links, continue where you left off"
            onActivated: root.openCaster()
          }

          ActionRow {
            width: parent.width
            glyph: "󰉋"
            label: "Browse for a video…"
            detail: "Anywhere on this machine"
            onActivated: media.browseVideo()
          }
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
    foreground: root.foreground
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
        color: root.foreground
        font.family: root.fontFamily
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
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }

        Text {
          textFormat: Text.PlainText
          visible: text !== ""
          Layout.fillWidth: true
          text: row.detail
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
