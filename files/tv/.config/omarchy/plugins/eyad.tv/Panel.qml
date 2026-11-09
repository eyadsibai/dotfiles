import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Bar icon + popup for the tv app, shown only while it runs. The popup searches
// every channel and lists favorites and recent ones; picking one switches TV to
// it. Scroll changes channel, middle-click goes back to the last one,
// right-click opens TV's own channel menu.
//
// tv.lua writes what this shows ($XDG_RUNTIME_DIR/tv/now.json, channels.json);
// commands go back through `tv --ctl`.
Panel {
  id: root
  moduleName: "eyad.tv"
  ipcTarget: "eyad.tv"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string tvGlyph: "\u{f07f4}"   // television-classic; the living room's is the flat TV
  readonly property string runDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/tv"

  property var now: null          // the playing channel, from `tv --bar`; null: TV isn't running
  property var lists: ({ channels: [], favorites: [], recent: [] })
  readonly property bool running: now !== null
  readonly property int resultLimit: 12

  function ctl(args) { Quickshell.execDetached(["tv", "--ctl"].concat(args)) }
  function play(n) { ctl(["play", String(n)]); root.close() }

  function channel(n) { return lists.channels[n - 1] || null }
  function numbers(ns) {
    var out = []
    for (var i = 0; i < ns.length; i++) {
      var c = channel(ns[i])
      if (c && (!now || c.n !== now.number)) out.push(c)
    }
    return out
  }
  readonly property var favoriteChannels: numbers(lists.favorites || [])
  readonly property var recentChannels: numbers(lists.recent || [])
  // Every word must appear in the name, category or language; a number matches the channel number.
  readonly property var results: {
    var q = search.text.toLowerCase().trim()
    if (q === "") return []
    var words = q.split(/\s+/)
    var out = []
    var all = lists.channels || []
    for (var i = 0; i < all.length && out.length < resultLimit; i++) {
      var c = all[i]
      var hay = (c.name + " " + c.category + " " + c.language).toLowerCase()
      if (String(c.n) === q || words.every(function(w) { return hay.indexOf(w) >= 0 })) out.push(c)
    }
    return out
  }

  visible: running
  implicitWidth: running ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    search.text = ""
    channelsFile.reload()
    Qt.callLater(function() { search.forceActiveFocus() })
  }

  // Is TV running, and on what? `tv --bar` checks the player is alive.
  Process {
    id: poll
    command: ["tv", "--bar"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.now = text.trim() === "" ? null : JSON.parse(text) } catch (e) { root.now = null }
      }
    }
  }
  Timer {
    interval: root.opened ? 1000 : 3000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: if (!poll.running) poll.running = true
  }

  FileView {
    id: channelsFile
    path: root.runDir + "/channels.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try { root.lists = JSON.parse(text()) } catch (e) {}
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  // Room for a three-digit channel number whatever is playing, so the widget
  // keeps its width and a gap to its neighbours on both sides.
  TextMetrics {
    id: numberMetrics
    font.family: root.fontFamily
    font.pixelSize: Style.bar.iconFont
    text: "000"
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fixedWidth: root.bar && root.bar.vertical ? -1
      : Style.bar.iconSlot + Math.ceil(numberMetrics.advanceWidth) + Style.space(4) + Style.space(10)
    text: root.tvGlyph
    labelText: root.now ? String(root.now.number) : ""
    active: root.opened
    tooltipText: root.opened || !root.now ? "" : root.now.tooltip
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.ctl(["last"])
      else if (b === Qt.RightButton) root.ctl(["menu"])
      else root.toggle()
    }
    onWheelMoved: function(delta) { root.ctl([delta > 0 ? "prev" : "next"]) }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: search
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(620))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: search.activeFocus
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === "/") search.forceActiveFocus()
        else if (t === "s") root.ctl(["star"])
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
          spacing: Style.space(10)

          PanelHero {
            id: hero
            width: parent.width
            title: root.now ? root.now.number + "  " + root.now.name : "Live TV"
            meta: root.now ? root.now.category + (root.now.language ? " · " + root.now.language : "") : ""
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconComponent: Component {
              Text {
                text: root.tvGlyph
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
            trailingControl: Component {
              PanelActionButton {
                iconText: root.now && root.now.favorite ? "★" : "☆"
                tooltipText: root.now && root.now.favorite ? "Unstar this channel (s)" : "Star this channel (s)"
                foreground: hero.foreground
                fontFamily: hero.fontFamily
                onClicked: root.ctl(["star"])
              }
            }
          }

          TextField {
            id: search
            width: parent.width
            foreground: root.foreground
            font.family: root.fontFamily
            placeholderText: "Search " + (root.lists.channels || []).length + " channels"
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                if (text !== "") text = ""
                else root.close()
                event.accepted = true
              }
            }
            onAccepted: if (root.results.length > 0) root.play(root.results[0].n)
          }

          // ---- search results ----
          Column {
            visible: search.text.trim() !== ""
            width: parent.width
            spacing: Style.space(2)
            Repeater {
              model: root.results
              ChannelRow {
                required property var modelData
                required property int index
                width: parent.width
                channel: modelData
                enterHint: index === 0
              }
            }
            Text {
              visible: root.results.length === 0
              textFormat: Text.PlainText
              width: parent.width
              text: "No channel matches"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          // ---- favorites and recent, while not searching ----
          PanelSectionHeader {
            visible: search.text.trim() === "" && root.favoriteChannels.length > 0
            text: "FAVORITES"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          Column {
            visible: search.text.trim() === ""
            width: parent.width
            spacing: Style.space(2)
            Repeater {
              model: root.favoriteChannels
              ChannelRow {
                required property var modelData
                width: parent.width
                channel: modelData
              }
            }
          }
          PanelSectionHeader {
            visible: search.text.trim() === "" && root.recentChannels.length > 0
            text: "RECENT"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }
          Column {
            visible: search.text.trim() === ""
            width: parent.width
            spacing: Style.space(2)
            Repeater {
              model: root.recentChannels.slice(0, 8)
              ChannelRow {
                required property var modelData
                width: parent.width
                channel: modelData
              }
            }
          }
          Text {
            visible: search.text.trim() === "" && root.favoriteChannels.length === 0
            textFormat: Text.PlainText
            width: parent.width
            wrapMode: Text.Wrap
            text: "Star channels with s (here or in TV) to keep them at the top."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }

  component ChannelRow: CursorSurface {
    id: row
    property var channel: ({})
    property bool enterHint: false

    hasCursor: rowMouse.containsMouse
    foreground: root.foreground
    implicitHeight: rowLayout.implicitHeight + Style.spacing.rowPaddingX

    MouseArea {
      id: rowMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.play(row.channel.n)
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
        text: String(row.channel.n)
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: Style.space(30)
        Layout.alignment: Qt.AlignVCenter
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.space(1)
        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: (row.channel.favorite ? "★ " : "") + row.channel.name
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          elide: Text.ElideRight
        }
        Text {
          textFormat: Text.PlainText
          Layout.fillWidth: true
          text: [row.channel.category, row.channel.language, row.channel.tags].filter(function(b) { return b }).join(" · ")
                + (row.enterHint ? " · Enter" : "")
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
