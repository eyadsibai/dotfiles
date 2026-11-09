import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar icon + popup for the living room: TV power, Sonos volume and the way into
// the remote, which holds the rest. Click opens the panel, scroll changes the
// Sonos volume, middle-click mutes it, right-click refreshes.
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

  // Poll fast and follow casting while the panel or the remote is showing.
  readonly property bool watching: opened || remoteLoader.active
  onWatchingChanged: {
    media.fastPolling = watching
    media.watchCast = watching
    if (watching) media.refresh()
  }
  onOpenedChanged: if (opened) Qt.callLater(function() { keyCatcher.forceActiveFocus() })

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

  // The remote (RemoteWindow.qml), a floating window holding everything but power
  // and volume: touchpad, buttons, typing and YouTube search, scenes, casting. Its
  // touchpad speed is kept in a small state file.
  FileView {
    id: remoteState
    path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/eyad-media-remote.json"
    blockLoading: true
    printErrors: false
  }
  property var remoteSaved: {
    try { return JSON.parse(remoteState.text()) } catch (e) { return {} }
  }
  function saveRemote(changes) {
    var next = Object.assign({}, remoteSaved, changes)
    remoteSaved = next
    remoteState.setText(JSON.stringify(next) + "\n")
  }
  function openRemote() {
    root.close()
    remoteLoader.active = true
  }
  function toggleRemote() {
    if (remoteLoader.active) remoteLoader.active = false
    else openRemote()
  }

  LazyLoader {
    id: remoteLoader
    active: false
    RemoteWindow {
      visible: true
      svc: media
      speed: root.remoteSaved.speed || 1
      onSpeedChanged: if (speed !== (root.remoteSaved.speed || 1)) root.saveRemote({ speed: speed })
      onOpenCasterRequested: root.openCaster()
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
    function remote(): void { root.toggleRemote() }
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
      onCloseRequested: root.close()
      onReturnRequested: root.openRemote()
      onActivateRequested: root.openRemote()
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
        else if (k === "o") root.openRemote()
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

          PanelSeparator { foreground: root.foreground }

          ActionRow {
            width: parent.width
            glyph: "󰑔"
            label: "Remote (Enter)"
            detail: "Touchpad and buttons, typing and YouTube, scenes, casting"
            onActivated: root.openRemote()
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
