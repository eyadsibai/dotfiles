import QtQuick
import qs.Commons
import qs.Ui
import "lib/Meetings.js" as Meetings

// Bar pill and popup for the meeting recorder (omarchy-meetings), in the same
// design as the Meetings app: a title and Record when idle; a red card with the
// clock, levels, latest caption, pause/stop and notes while recording; then the
// meeting being transcribed and a "Ready" card; recent meetings with a strip of
// who spoke when. Colours come from the Omarchy theme.
//
// Left click: popup. Middle click: stop. Right click: start right away with
// the Akiflow meeting title (or "Meeting HH:MM"), or stop.
BarWidget {
  id: root
  moduleName: "eyad.meetings"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var info: service ? service.info : ({ text: "", tooltip: "Meetings", active: false, state: "idle", icon: Meetings.barIcon("idle") })
  readonly property bool recording: !!service && service.active
  readonly property bool paused: info.state === "paused"

  // While recording the pill is the compact view: clock and one level glyph for
  // each side (your microphone, then the computer audio).
  readonly property string barText: {
    if (vertical || info.state === "idle") return info.icon
    if (info.state === "processing") return info.icon + "  Transcribing…"
    var lv = service ? service.levels : { mic: 0, system: 0 }
    var waves = info.state === "recording" ? "  " + Meetings.levelGlyph(lv.mic) + Meetings.levelGlyph(lv.system) : ""
    return info.icon + "  " + info.text + waves
  }

  property bool popupOpen: false
  readonly property bool opened: popupOpen
  function open() { popupOpen = true }
  function close() { popupOpen = false }
  // Notes still waiting for their save timer go to the recorder before it stops.
  function stopRecording() {
    if (!root.service) return
    if (notesSave.running) { notesSave.stop(); root.service.saveNotes(notesEdit.text) }
    root.service.stop()
  }
  function toggle() { if (popupOpen) close(); else open() }

  property string suggestion: ""
  property string confirmDeleteId: ""
  readonly property var library: Meetings.filterMeetings(service ? service.recent : [], librarySearch.text)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(fg, 1.45)
  readonly property color faint: Qt.darker(fg, 1.9)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  // Theme colours shared with the web app: you (accent), the call (blue), speakers.
  readonly property var tc: service && service.themeColors ? service.themeColors : Meetings.parsePalette("")
  readonly property color micColor: Color.accent
  readonly property color callColor: tc.call
  readonly property color amber: tc.amber
  readonly property real gap: Style.space(8)

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
      if (b === Qt.MiddleButton) root.stopRecording()
      else if (b === Qt.RightButton) root.service.toggle("")
      else root.toggle()
    }
  }

  // A level meter: a rounded track and a bar in the source's colour.
  component Meter: Item {
    id: meter
    property string label: ""
    property color tone: root.fg
    property real level: 0
    width: parent ? parent.width : 0
    height: Math.max(meterLabel.implicitHeight, Style.space(8))
    Text {
      id: meterLabel
      width: Style.space(112)
      anchors.verticalCenter: parent.verticalCenter
      text: meter.label
      color: meter.tone
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
    Rectangle {
      anchors.left: meterLabel.right
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      height: Style.space(6)
      radius: height / 2
      color: Util.alpha(root.fg, 0.08)
      Rectangle {
        height: parent.height
        radius: parent.radius
        color: meter.tone
        width: parent.width * Math.min(1, meter.level * 1.6)
        Behavior on width { NumberAnimation { duration: 90 } }
      }
    }
  }

  // A tinted card: red while recording, the accent when ready, neutral otherwise.
  component Card: Rectangle {
    property color tone: root.fg
    property real strength: 0.06
    width: parent ? parent.width : 0
    radius: Math.max(Style.cornerRadius, Style.space(8))
    color: Util.alpha(tone, strength)
    border.color: Util.alpha(tone, strength * 3)
    border.width: 1
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.popupOpen
    focusTarget: root.recording ? keys : titleField
    contentWidth: popup.fittedContentWidth(Style.space(440))
    contentHeight: popup.fittedContentHeight(column.implicitHeight, Style.space(680))

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (!root.service) return
        if (t === " " || t === "p") root.service.togglePause()
        else if (t === "s") { root.stopRecording(); root.close() }
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
          spacing: Style.space(10)

          // ---- Header: name and the way into the app
          Item {
            width: parent.width
            height: Math.max(headerTitle.implicitHeight, appButton.height)

            Text {
              id: headerTitle
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: "Meetings"
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
            Row {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(4)
              PanelActionButton {
                anchors.verticalCenter: parent.verticalCenter
                iconText: ""
                tooltipText: "Open the notes folder"
                foreground: root.dim
                fontSize: Style.font.bodySmall
                onClicked: { root.service.openFolder(); root.close() }
              }
              Button {
                id: appButton
                text: "Open app ↗"
                foreground: root.fg
                accent: Color.accent
                tooltipText: "All meetings, playback, editing and Claude"
                onClicked: { root.service.openApp(); root.close() }
              }
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
            Text {
              width: parent.width
              visible: root.suggestion !== ""
              text: titleField.text === root.suggestion ? "From your calendar (Akiflow)" : "Calendar: " + root.suggestion + " · click to use"
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
            Column {
              width: parent.width
              spacing: Style.space(4)
              topPadding: Style.space(2)
              bottomPadding: Style.space(2)
              Meter { label: "Microphone"; tone: root.micColor; level: root.service ? root.service.levels.mic : 0 }
              Meter { label: "Computer audio"; tone: root.callColor; level: root.service ? root.service.levels.system : 0 }
            }
            Button {
              text: "Record    ⏎"
              iconText: ""
              foreground: Color.urgent
              accent: Color.urgent
              bordered: true
              tooltipText: "Start recording (Enter)"
              onClicked: root.startFromField()
            }
          }

          // ---- Recording in progress
          Card {
            visible: root.recording
            tone: root.paused ? root.amber : Color.urgent
            strength: root.paused ? 0.07 : 0.11
            height: visible ? liveCol.implicitHeight + Style.space(20) : 0

            Column {
              id: liveCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(8)

              Item {
                width: parent.width
                height: Math.max(liveTitle.implicitHeight, liveClock.implicitHeight)
                Rectangle {
                  id: liveDot
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  width: Style.space(9)
                  height: width
                  radius: width / 2
                  color: root.paused ? root.amber : Color.urgent
                  SequentialAnimation on opacity {
                    running: root.popupOpen && root.info.state === "recording"
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutQuad }
                    onRunningChanged: if (!running) liveDot.opacity = 1
                  }
                }
                Text {
                  id: liveTitle
                  anchors.left: liveDot.right
                  anchors.leftMargin: Style.space(8)
                  anchors.right: liveClock.left
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  text: root.service && root.service.current ? root.service.current.title : ""
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                  elide: Text.ElideRight
                }
                Text {
                  id: liveClock
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: (root.paused ? "  " : "") + root.info.text
                  color: root.paused ? root.amber : root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.title
                  font.features: { "tnum": 1 }
                }
              }

              Meter { label: "You"; tone: root.micColor; level: root.service ? root.service.levels.mic : 0 }
              Meter { label: "Call audio"; tone: root.callColor; level: root.service ? root.service.levels.system : 0 }

              // The latest caption the recorder heard.
              Rectangle {
                width: parent.width
                visible: !!root.service && root.service.liveLines.length > 0
                height: visible ? captionText.implicitHeight + Style.space(14) : 0
                radius: Math.max(Style.cornerRadius, Style.space(6))
                color: Util.alpha(Color.background, 0.55)
                Text {
                  id: captionText
                  anchors.fill: parent
                  anchors.margins: Style.space(7)
                  readonly property var line: root.service && root.service.liveLines.length ? root.service.liveLines[root.service.liveLines.length - 1] : null
                  text: line ? (line.source === "system" ? "Call: " : "You: ") + line.text : ""
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  wrapMode: Text.WordWrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                  horizontalAlignment: Text.AlignLeft
                }
              }

              Row {
                spacing: Style.space(6)
                Button {
                  text: root.paused ? "Resume" : "Pause"
                  iconText: root.paused ? "" : ""
                  foreground: root.fg
                  tooltipText: "Space"
                  onClicked: root.service.togglePause()
                }
                Button {
                  text: "Stop and save"
                  iconText: ""
                  foreground: Color.urgent
                  accent: Color.urgent
                  bordered: true
                  tooltipText: "s"
                  onClicked: { root.stopRecording(); root.close() }
                }
                Button {
                  text: "Live ↗"
                  foreground: root.fg
                  tooltipText: "Captions, suggested questions and notes in the app"
                  onClicked: { root.service.openLive(); root.close() }
                }
              }

              // Notes beside the recording: saved as you type, each paragraph timestamped.
              Rectangle {
                width: parent.width
                height: Math.max(Style.space(56), notesEdit.contentHeight + Style.space(14))
                radius: Math.max(Style.cornerRadius, Style.space(6))
                color: Util.alpha(Color.background, 0.55)
                border.color: notesEdit.activeFocus ? Util.alpha(Color.accent, 0.6) : Util.alpha(root.fg, 0.12)
                border.width: 1
                TextEdit {
                  id: notesEdit
                  anchors.fill: parent
                  anchors.margins: Style.space(7)
                  text: root.service ? root.service.notesText : ""
                  Connections {
                    target: root.service
                    function onNotesTextChanged() {
                      if (!notesEdit.activeFocus && notesEdit.text !== root.service.notesText) notesEdit.text = root.service.notesText
                    }
                  }
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  wrapMode: TextEdit.Wrap
                  selectByMouse: true
                  onTextChanged: if (activeFocus) notesSave.restart()
                  Keys.onEscapePressed: root.close()
                  Text {
                    visible: !notesEdit.text && !notesEdit.activeFocus
                    text: "Quick notes, stamped with the time…"
                    color: root.faint
                    font: notesEdit.font
                  }
                }
                Timer {
                  id: notesSave
                  interval: 1200
                  onTriggered: if (root.service) root.service.saveNotes(notesEdit.text)
                }
              }
            }
          }

          // ---- Just stopped: being transcribed
          Card {
            visible: !root.recording && !!root.service && !!root.service.processing
            height: visible ? procCol.implicitHeight + Style.space(20) : 0

            Column {
              id: procCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(6)

              Text {
                width: parent.width
                text: root.service && root.service.processing ? root.service.processing.title : ""
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                elide: Text.ElideRight
              }
              Rectangle {
                id: procTrack
                width: parent.width
                height: Style.space(5)
                radius: height / 2
                color: Util.alpha(root.fg, 0.08)
                clip: true
                Rectangle {
                  width: parent.width * 0.3
                  height: parent.height
                  radius: parent.radius
                  color: Color.accent
                  NumberAnimation on x {
                    running: root.popupOpen && procTrack.visible
                    from: -procTrack.width * 0.3
                    to: procTrack.width
                    duration: 1400
                    loops: Animation.Infinite
                  }
                }
              }
              Text {
                width: parent.width
                text: "Saved. Telling speakers apart and transcribing; you'll get a notification."
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
            }
          }

          // ---- Ready: the meeting that just finished
          Card {
            id: ready
            readonly property var meeting: root.service ? root.service.justFinished : null
            visible: !root.recording && !!meeting
            tone: Color.accent
            strength: 0.10
            height: visible ? readyCol.implicitHeight + Style.space(20) : 0

            Column {
              id: readyCol
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: Style.space(10)
              spacing: Style.space(6)

              Item {
                width: parent.width
                height: readyTitle.implicitHeight
                Text {
                  id: readyTitle
                  anchors.left: parent.left
                  anchors.right: dismiss.left
                  anchors.rightMargin: Style.space(8)
                  text: ready.meeting ? ready.meeting.title : ""
                  color: root.fg
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  elide: Text.ElideRight
                }
                PanelActionButton {
                  id: dismiss
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  iconText: ""
                  tooltipText: "Dismiss"
                  foreground: root.dim
                  fontSize: Style.font.caption
                  onClicked: root.service.dismissFinished()
                }
              }
              Text {
                width: parent.width
                text: {
                  var m = ready.meeting
                  if (!m) return ""
                  var parts = ["Ready", Meetings.fmtDuration(m.durationSecs), Meetings.fmtWords(m.words)]
                  if (m.speakers && m.speakers.length) parts.push(m.speakers.length + (m.speakers.length === 1 ? " speaker" : " speakers"))
                  if (m.unnamed) parts.push(m.unnamed === 1 ? "a speaker needs a name" : m.unnamed + " speakers need names")
                  return parts.join(" · ")
                }
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                wrapMode: Text.WordWrap
              }
              Row {
                spacing: Style.space(6)
                Button {
                  text: "Open"
                  foreground: root.fg
                  accent: Color.accent
                  selected: true
                  onClicked: { root.service.openViewer(ready.meeting.id); root.service.dismissFinished(); root.close() }
                }
                Button {
                  text: ready.meeting && ready.meeting.hasSummary ? "Summary" : "Summarize"
                  foreground: root.fg
                  onClicked: root.service.openSummary(ready.meeting)
                }
                Button {
                  text: "Copy"
                  foreground: root.fg
                  onClicked: root.service.copyTranscript(ready.meeting)
                }
              }
            }
          }

          // ---- Audio problems
          Repeater {
            model: root.service ? root.service.issues : []
            delegate: Card {
              id: issue
              required property var modelData
              width: column.width
              tone: modelData.severity === "error" ? Color.urgent : root.amber
              strength: 0.10
              height: issueRow.implicitHeight + Style.space(14)

              Item {
                id: issueRow
                anchors.fill: parent
                anchors.margins: Style.space(7)
                implicitHeight: Math.max(issueText.implicitHeight, issueButton.visible ? issueButton.height : 0)

                Text {
                  id: issueText
                  anchors.left: parent.left
                  anchors.right: issueButton.visible ? issueButton.left : parent.right
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  text: (issue.modelData.severity === "error" ? "  " : "  ") + issue.modelData.text
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
            text: "The Meetings service is not running"
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
              return "  " + Meetings.shortDevice(a.mic.description) + "      " + (a.output ? Meetings.shortDevice(a.output.description) : "default output")
            }
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          PanelSeparator { width: parent.width; foreground: root.fg }

          // ---- Recent meetings, including existing audio/video imports
          Item {
            width: parent.width
            height: recentLabel.implicitHeight
            Text {
              id: recentLabel
              anchors.left: parent.left
              text: "RECENT"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 0.8
            }
            Text {
              anchors.right: parent.right
              text: (root.service ? root.service.recent.length : 0) + " meetings"
              color: root.faint
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          TextField {
            id: librarySearch
            width: parent.width
            placeholderText: "Search meetings…"
            foreground: root.fg
            font.family: root.fontFamily
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) { root.close(); event.accepted = true }
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.library.length === 1) { root.service.openViewer(root.library[0].id); root.close() }
                event.accepted = true
              }
            }
          }

          Text {
            visible: !!root.service && root.library.length === 0
            width: parent.width
            text: librarySearch.text.trim() ? "No matching meetings" : "Your recordings and imported audio/video appear here."
            wrapMode: Text.WordWrap
            color: root.faint
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Repeater {
            model: root.library

            delegate: Item {
              id: row
              required property var modelData
              readonly property bool live: !!root.service && root.service.meetingId === modelData.id
              readonly property bool transcribing: !live && (modelData.status === "running" || (!!root.service.processing && root.service.processing.id === modelData.id))
              readonly property bool hasSpeech: modelData.transcribed && modelData.words > 0
              readonly property bool summarizing: !!root.service && root.service.summarizingId === modelData.id
              readonly property bool confirming: root.confirmDeleteId === modelData.id

              width: column.width
              height: rowCol.implicitHeight + Style.space(14)

              Rectangle {
                anchors.fill: parent
                radius: Math.max(Style.cornerRadius, Style.space(6))
                color: Style.hoverFill
                visible: rowMouse.containsMouse
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (row.live) root.service.openLive()
                  else root.service.openViewer(row.modelData.id)
                  root.close()
                }
              }

              Column {
                id: rowCol
                anchors.left: parent.left
                anchors.leftMargin: Style.space(8)
                anchors.right: actions.left
                anchors.rightMargin: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Style.space(3)

                Text {
                  width: parent.width
                  text: row.modelData.title
                  color: root.fg
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
                    : Meetings.meetingMeta(row.modelData, root.service.nowMs) + (row.modelData.review ? " · " + row.modelData.review + " to check" : "")
                  color: row.live ? Color.urgent : root.faint
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
                // Who spoke when, as in the app's list.
                Rectangle {
                  id: strip
                  visible: !row.live && !row.transcribing && !!row.modelData.lanes && row.modelData.lanes.length > 0
                  width: parent.width
                  height: visible ? Style.space(5) : 0
                  radius: 2
                  color: Util.alpha(root.fg, 0.06)
                  Repeater {
                    model: strip.visible ? Meetings.laneSpans(row.modelData.lanes, row.modelData.durationSecs, 60) : []
                    delegate: Rectangle {
                      required property var modelData
                      x: strip.width * modelData.x
                      width: Math.max(2, strip.width * modelData.w)
                      height: strip.height
                      radius: 1
                      color: root.tc.speakers[modelData.speaker % 8]
                    }
                  }
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
                  iconText: row.summarizing ? "" : (row.modelData.hasSummary ? "" : "")
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
                  iconText: ""
                  tooltipText: "Copy transcript"
                  foreground: root.dim
                  fontSize: Style.font.bodySmall
                  onClicked: root.service.copyTranscript(row.modelData)
                }
                PanelActionButton {
                  iconText: ""
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
            text: root.recording ? "space pause · s stop · esc close" : "enter record · esc close · right-click the bar icon to record instantly"
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
