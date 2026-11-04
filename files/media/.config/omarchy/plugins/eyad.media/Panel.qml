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
  readonly property string volumeGlyph: media.sonosMuted ? "󰝟" : (media.volume < 34 ? "󰕿" : (media.volume < 67 ? "󰖀" : "󰕾"))

  visible: !(hideWhenUnreachable && media.loaded && !media.anyReachable)
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    media.fastPolling = opened
    if (opened) {
      media.refresh()
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }
  }

  Service {
    id: media
    settings: root.settings
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { media.refresh(); return "ok" }
    function status(): string { return media.summary }
    function scene(name: string): string { media.runScene(name); return "ok" }
    function volumeUp(): void { media.nudgeVolume(5) }
    function volumeDown(): void { media.nudgeVolume(-5) }
    function toggleMute(): void { media.toggleMute() }
    function togglePower(): void { media.toggleTvPower() }
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
              tooltipText: "Remote in a terminal"
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: { root.close(); media.openRemote() }
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

          ActionRow {
            width: parent.width
            glyph: "󰐾"
            label: "Cast a video…"
            detail: "Open go2tv, with subtitles and playlists"
            onActivated: { root.close(); media.openCaster() }
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
