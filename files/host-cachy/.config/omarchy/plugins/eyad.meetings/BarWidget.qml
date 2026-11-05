import QtQuick
import qs.Commons
import qs.Ui
import "lib/Meetings.js" as Meetings

// Bar pill and popup for Voxtype meeting transcription. Click to name and
// start a recording; while it runs the pill shows the elapsed time, and the
// popup pauses or stops it. Past meetings open as Markdown notes.
//
// Left click: popup. Middle click: stop. Right click: start right away with
// the Akiflow meeting title (or "Meeting HH:MM"), or stop.
BarWidget {
  id: root
  moduleName: "eyad.meetings"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var info: service ? service.info : ({ text: "", tooltip: "Meeting notes", active: false, state: "idle", icon: Meetings.barIcon("idle") })
  readonly property bool recording: !!service && service.active

  readonly property string barText: {
    if (vertical || info.state === "idle") return info.icon
    if (info.state === "processing") return info.icon + "  …"
    return info.icon + "  " + info.text
  }

  property bool popupOpen: false
  readonly property bool opened: popupOpen
  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { if (popupOpen) close(); else open() }

  property string suggestion: ""
  property string confirmDeleteId: ""

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(fg, 1.45)
  readonly property color faint: Qt.darker(fg, 1.9)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function startFromField() {
    if (!service) return
    service.start(titleField.text)
    close()
  }

  onPopupOpenChanged: {
    confirmDeleteId = ""
    if (!service) return
    if (popupOpen) {
      service.popupOpened()
      if (!recording) {
        suggestion = service.suggestedTitle()
        titleField.text = suggestion
        titleField.selectAll()
      }
    } else {
      service.popupClosed()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    active: root.info.active
    horizontalMargin: 8.75
    verticalPadding: 8.75
    tooltipText: root.info.tooltip
    onPressed: function(b) {
      if (!root.service) return
      if (b === Qt.MiddleButton) root.service.stop()
      else if (b === Qt.RightButton) root.service.toggle("")
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    focusTarget: root.recording ? keys : titleField
    contentWidth: popup.fittedContentWidth(Style.space(380))
    contentHeight: popup.fittedContentHeight(column.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (!root.service) return
        if (t === " " || t === "p") root.service.togglePause()
        else if (t === "s") { root.service.stop(); root.close() }
      }
      onActivateRequested: if (root.service && root.recording) root.service.togglePause()

      Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: column
          width: flick.width
          spacing: Style.space(8)

          // ---- Header
          Item {
            width: parent.width
            height: Math.max(headerTitle.implicitHeight, folderButton.height)

            Text {
              id: headerTitle
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Meeting notes"
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
            PanelActionButton {
              id: folderButton
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              iconText: "\uf07c"
              tooltipText: "Open notes folder"
              foreground: root.fg
              fontSize: Style.font.bodySmall
              onClicked: { root.service.openFolder(); root.close() }
            }
          }

          // ---- New recording
          Column {
            visible: !root.recording
            width: parent.width
            spacing: Style.space(6)

            TextField {
              id: titleField
              width: parent.width
              placeholderText: Meetings.defaultTitle(root.service ? root.service.nowMs : Date.now())
              foreground: root.fg
              font.family: root.fontFamily
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.startFromField(); event.accepted = true }
              }
            }

            Item {
              width: parent.width
              height: recordButton.height

              Button {
                id: recordButton
                anchors.left: parent.left
                text: "Record"
                iconText: "\uf111"
                foreground: root.fg
                accent: Color.urgent
                selected: true
                tooltipText: "Start transcribing (Enter)"
                onClicked: root.startFromField()
              }
              Text {
                anchors.left: recordButton.right
                anchors.leftMargin: Style.space(8)
                anchors.right: parent.right
                anchors.verticalCenter: recordButton.verticalCenter
                visible: root.suggestion !== ""
                text: titleField.text === root.suggestion ? "Title from Akiflow" : "Akiflow: " + root.suggestion
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                elide: Text.ElideRight
                MouseArea {
                  anchors.fill: parent
                  enabled: titleField.text !== root.suggestion
                  cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                  onClicked: { titleField.text = root.suggestion; titleField.forceActiveFocus() }
                }
              }
            }
          }

          // ---- Recording in progress
          Rectangle {
            visible: root.recording
            width: parent.width
            height: visible ? liveCol.implicitHeight + Style.space(16) : 0
            radius: Style.cornerRadius
            readonly property bool paused: root.info.state === "paused"
            color: Util.alpha(paused ? root.fg : Color.urgent, paused ? 0.06 : 0.12)
            border.color: Util.alpha(paused ? root.fg : Color.urgent, 0.35)
            border.width: 1

            Column {
              id: liveCol
              anchors.fill: parent
              anchors.margins: Style.space(8)
              spacing: Style.space(6)

              Row {
                spacing: Style.space(6)
                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(8)
                  height: width
                  radius: width / 2
                  color: root.info.state === "paused" ? root.dim : Color.urgent
                  SequentialAnimation on opacity {
                    running: root.popupOpen && root.info.state === "recording"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
                    onRunningChanged: if (!running) parent.opacity = 1
                  }
                }
                Text {
                  text: (root.info.state === "paused" ? "PAUSED" : "RECORDING") + " · " + root.info.text
                  color: root.info.state === "paused" ? root.dim : Color.urgent
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                  font.features: { "tnum": 1 }
                }
              }
              Text {
                width: parent.width
                text: root.service && root.service.current ? root.service.current.title : ""
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.subtitle
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }
              Row {
                spacing: Style.space(6)
                Button {
                  text: root.info.state === "paused" ? "Resume" : "Pause"
                  iconText: root.info.state === "paused" ? "\uf04b" : "\uf04c"
                  foreground: root.fg
                  tooltipText: "Space"
                  onClicked: root.service.togglePause()
                }
                Button {
                  text: "Stop and save"
                  iconText: "\uf04d"
                  foreground: root.fg
                  selected: true
                  tooltipText: "s"
                  onClicked: { root.service.stop(); root.close() }
                }
              }
              Text {
                width: parent.width
                text: "The transcript appears a few seconds after you stop."
                color: root.faint
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }

          // ---- Audio problems
          Repeater {
            model: root.service ? root.service.issues : []
            delegate: Rectangle {
              id: issue
              required property var modelData
              width: column.width
              height: issueRow.implicitHeight + Style.space(12)
              radius: Style.cornerRadius
              readonly property color tone: modelData.severity === "error" ? Color.urgent : Color.accent
              color: Util.alpha(tone, 0.10)
              border.color: Util.alpha(tone, 0.4)
              border.width: 1

              Item {
                id: issueRow
                anchors.fill: parent
                anchors.margins: Style.space(6)
                implicitHeight: Math.max(issueText.implicitHeight, issueButton.visible ? issueButton.height : 0)

                Text {
                  id: issueText
                  anchors.left: parent.left
                  anchors.right: issueButton.visible ? issueButton.left : parent.right
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  text: (issue.modelData.severity === "error" ? "\uf06a  " : "\uf071  ") + issue.modelData.text
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  wrapMode: Text.WordWrap
                }
                Button {
                  id: issueButton
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  visible: issue.modelData.action !== ""
                  text: issue.modelData.actionText
                  foreground: root.fg
                  onClicked: root.service.fixAudio(issue.modelData.action)
                }
              }
            }
          }

          Text {
            visible: !!root.service && root.service.lastError !== "" && !root.recording
            width: parent.width
            text: root.service ? root.service.lastError : ""
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          Text {
            visible: !root.service
            width: parent.width
            text: "Meeting notes service is not running"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          // ---- Audio sources, when nothing is wrong
          Text {
            visible: !!root.service && !!root.service.audio && root.service.issues.length === 0 && !!root.service.audio.mic
            width: parent.width
            text: {
              var a = root.service ? root.service.audio : null
              if (!a || !a.mic) return ""
              return "\uf130  " + Meetings.shortDevice(a.mic.description) + "    \uf028  " + (a.output ? Meetings.shortDevice(a.output.description) : "default output")
            }
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          PanelSeparator { width: parent.width; foreground: root.fg }

          // ---- Recent meetings
          Text {
            text: "RECENT"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 0.6
          }

          Text {
            visible: !!root.service && root.service.recent.length === 0
            width: parent.width
            text: "No meetings yet"
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.service ? root.service.recent : []

            delegate: Item {
              id: row
              required property var modelData
              readonly property bool live: !!root.service && root.service.meetingId === modelData.id
              readonly property bool transcribing: !live && (!modelData.transcribed || (!!root.service.processing && root.service.processing.id === modelData.id))
              readonly property bool hasSpeech: modelData.transcribed && modelData.words > 0
              readonly property bool summarizing: !!root.service && root.service.summarizingId === modelData.id
              readonly property bool confirming: root.confirmDeleteId === modelData.id

              width: column.width
              height: Style.space(42)

              Rectangle {
                anchors.fill: parent
                radius: Style.cornerRadius
                color: Style.hoverFill
                visible: rowMouse.containsMouse && row.hasSpeech
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.hasSpeech ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (row.hasSpeech) { root.service.openNotes(row.modelData); root.close() }
              }

              Column {
                anchors.left: parent.left
                anchors.leftMargin: Style.space(6)
                anchors.right: actions.left
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(2)

                Text {
                  width: parent.width
                  text: row.modelData.title
                  color: row.hasSpeech || row.live || row.transcribing ? root.fg : root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  horizontalAlignment: Text.AlignLeft
                  elide: Text.ElideRight
                }
                Text {
                  width: parent.width
                  text: row.live ? "Recording now"
                    : row.transcribing ? Meetings.fmtWhen(Meetings.parseTime(row.modelData.startedAt), root.service.nowMs) + " · transcribing…"
                    : row.summarizing ? Meetings.meetingMeta(row.modelData, root.service.nowMs) + " · summarizing…"
                    : Meetings.meetingMeta(row.modelData, root.service.nowMs)
                  color: row.live ? Color.urgent : root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }

              Row {
                id: actions
                anchors.right: parent.right
                anchors.rightMargin: Style.space(2)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                visible: !row.live && !row.transcribing

                PanelActionButton {
                  visible: row.hasSpeech
                  iconText: row.summarizing ? "\uf110" : (row.modelData.hasSummary ? "\uf15c" : "\uf0d0")
                  tooltipText: row.summarizing ? "Summarizing…" : row.modelData.hasSummary ? "Open summary" : "Summarize with Claude"
                  foreground: row.modelData.hasSummary ? Color.accent : root.dim
                  fontSize: Style.font.bodySmall
                  onClicked: {
                    if (row.summarizing) return
                    root.service.openSummary(row.modelData)
                    if (row.modelData.hasSummary) root.close()
                  }
                }
                PanelActionButton {
                  visible: row.hasSpeech
                  iconText: "\uf0c5"
                  tooltipText: "Copy transcript"
                  foreground: root.dim
                  fontSize: Style.font.bodySmall
                  onClicked: root.service.copyTranscript(row.modelData)
                }
                PanelActionButton {
                  iconText: "\uf1f8"
                  tooltipText: row.confirming ? "Click again to delete the recording (notes files stay)" : "Delete recording"
                  foreground: row.confirming ? Color.urgent : root.faint
                  fontSize: Style.font.bodySmall
                  onClicked: {
                    if (row.confirming) {
                      root.confirmDeleteId = ""
                      root.service.deleteMeeting(row.modelData)
                    } else {
                      root.confirmDeleteId = row.modelData.id
                      confirmReset.restart()
                    }
                  }
                }
              }
            }
          }

          Text {
            width: parent.width
            text: root.recording ? "space pause · s stop · esc close" : "enter record · esc close · right-click the pill to record instantly"
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  Timer {
    id: confirmReset
    interval: 4000
    onTriggered: root.confirmDeleteId = ""
  }
}
