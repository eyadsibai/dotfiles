import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import qs.Ui as Ui
import "Model.js" as Model

// Meeting planner popup: one 24-hour strip per city, columns aligned on the
// same instant, working hours shaded, and the windows that suit everyone.
// The cities are Elsewhen's; this plugin only adds working hours.
Panel {
  id: root
  moduleName: "eyad.meetplanner"
  ipcTarget: "eyad.meetplanner"
  manageIpc: false

  property var anchorItem: null
  // The bar tracks BarWidget.qml, not this nested panel, so the popout
  // coordinator and panel switching identify the panel by that widget.
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  function open() {
    setCenterHoverRevealSuppressed(false)
    root.controller.show()
    root.syncClock()
    root.refresh()
  }

  function openFromHotkey() {
    root.controller.show()
    root.syncClock()
    root.refresh()
    // After showing: showing closes the previously open panel, which clears it.
    Qt.callLater(function() { if (root.opened) setCenterHoverRevealSuppressed(true) })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  // A third-party plugin gets a facade whose property is read-only; use its
  // setter, so close() never throws before it hides the panel.
  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && typeof root.bar.setCenterHoverRevealSuppressed === "function")
      root.bar.setCenterHoverRevealSuppressed(value)
    else if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  // ---- settings: own entry plus Elsewhen's, from the bar's layout copy
  readonly property var layout: bar && bar.layoutConfig && Object.keys(bar.layoutConfig).length ? bar.layoutConfig
    : bar && bar.shell && bar.shell.barConfig ? bar.shell.barConfig.layout : null
  readonly property bool localeHour24: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") === -1
  readonly property var plan: Model.plan(settings, layout, localeHour24)
  readonly property bool hour24: plan.hour24
  readonly property int meetingMinutes: plan.meetingMinutes
  onMeetingMinutesChanged: durationPicker.value = String(meetingMinutes)
  readonly property var durationOptions: {
    var list = [30, 45, 60, 90, 120]
    if (list.indexOf(meetingMinutes) === -1) list.push(meetingMinutes)
    return list.sort(function(a, b) { return a - b }).map(function(n) { return {value: String(n), label: n + " min"} })
  }
  readonly property string requestKey: JSON.stringify(Model.request(plan))
  onRequestKeyChanged: if (opened) Qt.callLater(root.refresh)

  // ---- snapshot from the helper
  property double nowUtc: Date.now()
  property bool clockEnabled: true
  property double lastTickMinute: -1
  property var snapshot: ({})
  property string loadedKey: ""
  property string inFlightKey: ""
  property bool refreshPending: false
  property string probeError: ""
  property int helperTimeoutMs: 10000
  property bool helperTimedOut: false
  property string statusMessage: ""
  onStatusMessageChanged: if (statusMessage !== "") statusTimer.restart()
  readonly property string helperPath: decodeURIComponent(Qt.resolvedUrl("backend.py").toString().replace(/^file:\/\//, ""))

  readonly property var zones: Array.isArray(snapshot.zones) ? snapshot.zones : []
  readonly property var homeRow: zones.find(function(zone) { return zone.home }) || null
  readonly property bool gridShown: homeRow !== null && Array.isArray(snapshot.columns)
  // The loaded snapshot answers the current settings: overlap and Copy are current.
  readonly property bool ready: gridShown && loadedKey === requestKey
  readonly property double dayStart: snapshot.dayStart || 0
  readonly property var columns: snapshot.columns || []
  readonly property string errorMessage: Model.plainText(probeError || (snapshot.errors || []).join(" "))

  property double selectedUtc: -1
  property int hoverCol: -1
  readonly property double selectedMoment: hoverCol >= 0 && columns[hoverCol] ? columns[hoverCol].start : selectedUtc >= 0 ? selectedUtc : nowUtc
  readonly property bool hasSelection: hoverCol >= 0 || selectedUtc >= 0
  readonly property int selectedColumn: hasSelection ? columns.findIndex(function(column) {
    return selectedMoment >= column.start && selectedMoment < column.start + column.minutes * 60000
  }) : -1
  readonly property var overlapWindows: Model.slotWindows((snapshot.slots || []).filter(function(slot) { return slot.start >= root.nowUtc }))
  readonly property string selectedText: ready ? Model.meetingText(zones, selectedMoment, meetingMinutes, hour24) : ""

  readonly property color fg: bar ? bar.foreground : Commons.Color.foreground
  readonly property color dim: Qt.alpha(fg, 0.6)
  readonly property string fontFam: bar ? bar.fontFamily : Style.font.family
  function homeTime(instant) { return homeRow ? Model.timeLabel(instant, Model.offsetAt(homeRow, instant), hour24) : "" }

  onOpenedChanged: if (!opened) { hoverCol = -1; selectedUtc = -1; statusMessage = ""; durationPicker.close() }

  function persistSetting(name, value) {
    var entry = Model.plainObject(root.settings)
    entry[name] = value
    var shell = root.bar ? root.bar.shell : null
    var saved = false
    try { saved = !!shell && typeof shell.updateEntryInline === "function" && shell.updateEntryInline(root.moduleName, entry) === true }
    catch (error) { saved = false }
    if (!saved) { statusMessage = "Not saved: write this widget's bar entry as {\"id\": \"" + root.moduleName + "\"}"; return false }
    root.settings = entry
    if (hostWidget) hostWidget.settings = entry
    return true
  }

  function moveHoverCol(step) {
    if (!gridShown || !columns.length) return
    var from = Math.floor((selectedMoment - dayStart) / 3600000)
    var next = Math.max(0, Math.min(columns.length - 1, from + step))
    selectedUtc = columns[next].start
    hoverCol = -1
    revealColumn(next)
  }
  // On a screen too narrow for the whole day the grid scrolls sideways;
  // keep the picked column in view next to the city names.
  function revealColumn(column) {
    var left = stripX + column * (cellW + cellGap), right = left + cellW
    if (right > gridFlick.contentX + gridFlick.width) gridFlick.contentX = right - gridFlick.width
    else if (left < gridFlick.contentX + stripX) gridFlick.contentX = Math.max(0, left - stripX)
  }

  function copyTimes() {
    if (!ready || clipboard.running) return
    clipboard.payload = selectedText
    clipboard.didStart = false
    clipboard.stdinEnabled = true
    clipboard.running = true
    clipboardWatchdog.restart()
  }
  Process {
    id: clipboard
    property string payload: ""
    property bool didStart: false
    command: ["wl-copy", "--type", "text/plain;charset=utf-8"]
    onStarted: { didStart = true; write(payload); stdinEnabled = false }
    // A program that cannot start reports only running = false.
    onRunningChanged: if (!running) {
      clipboardWatchdog.stop()
      if (!didStart) root.statusMessage = "Could not copy. Check wl-copy."
    }
    onExited: function(code, status) { root.statusMessage = code === 0 ? "Meeting times copied" : "Could not copy. Check wl-copy." }
  }
  Timer { id: clipboardWatchdog; interval: 5000; onTriggered: if (clipboard.running) clipboard.signal(9) }

  function refresh() {
    syncClock()
    if (helper.running) { refreshPending = true; return }
    refreshPending = false
    inFlightKey = requestKey
    var request = JSON.parse(requestKey)
    request.nowMs = nowUtc
    helper.payload = JSON.stringify(request)
    helper.didStart = false
    helperTimedOut = false
    helper.stdinEnabled = true
    helper.running = true
    helperWatchdog.restart()
  }
  Process {
    id: helper
    property string payload: ""
    property bool didStart: false
    command: ["python3", root.helperPath]
    onStarted: { didStart = true; write(payload); stdinEnabled = false }
    onRunningChanged: {
      if (running) return
      helperWatchdog.stop()
      if (!didStart) root.probeError = "Could not start python3."
      if (root.refreshPending) Qt.callLater(root.refresh)
    }
    onExited: function(code, status) {
      if (root.helperTimedOut) root.probeError = "The timezone helper did not answer. Press r to retry."
      else if (code !== 0) root.probeError = "The timezone helper failed (exit " + code + "). Press r to retry."
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.helperTimedOut) return
        // A run for settings changed since is dropped; the pending run follows.
        if (root.inFlightKey !== root.requestKey) { root.refreshPending = true; return }
        try {
          var result = JSON.parse(text)
          root.probeError = ""
          if (!Array.isArray(result.zones) || !result.zones.length) {
            root.probeError = (result.errors || []).join(" ") || "The timezone helper returned no cities."
            return
          }
          root.snapshot = result
          root.loadedKey = root.inFlightKey
          if (root.selectedUtc >= 0 && (root.selectedUtc < result.dayStart || root.selectedUtc >= result.dayEnd)) root.selectedUtc = -1
        } catch (error) {
          root.probeError = "Could not read the timezone helper's answer. Press r to retry."
        }
      }
    }
  }
  Timer {
    id: helperWatchdog
    interval: root.helperTimeoutMs
    onTriggered: if (helper.running) { root.helperTimedOut = true; helper.signal(9) }
  }

  // One tick a minute; the snapshot is only needed while the popup is open,
  // and anew once its home day has ended. Quickshell's SystemClock can fire
  // early or, in a DST fall-back hour, with a stale date, so its date is
  // used only near the real time and each minute is acted on once.
  function tick(reported, now) {
    var time = Math.abs(reported - now) < 30000 ? reported : now
    var minute = Math.floor(time / 60000)
    if (minute === lastTickMinute) return
    lastTickMinute = minute
    nowUtc = time
    if (opened && (!snapshot.dayEnd || time >= snapshot.dayEnd)) Qt.callLater(root.refresh)
  }
  SystemClock {
    precision: SystemClock.Minutes
    onDateChanged: if (root.clockEnabled) root.tick(date.getTime(), Date.now())
  }
  // SystemClock waits out its minute after a resume; catch up sooner.
  function syncClock() { if (clockEnabled && Math.abs(Date.now() - nowUtc) > 90000) tick(Date.now(), Date.now()) }
  Timer { interval: 10000; running: root.clockEnabled && root.opened; repeat: true; onTriggered: root.syncClock() }
  Timer { id: statusTimer; interval: 4000; onTriggered: root.statusMessage = "" }

  readonly property real baseCellW: Style.space(27)
  readonly property real cellH: Style.space(48)
  readonly property real cellGap: 1
  readonly property real headerW: Style.space(190)
  readonly property real stripX: headerW + Style.space(12)
  readonly property real dayHours: columns.length ? (snapshot.dayEnd - dayStart) / 3600000 : 24
  readonly property int columnCount: columns.length || 24
  readonly property real desiredWidth: stripX + dayHours * baseCellW + (columnCount - 1) * cellGap + panel.verticalContentInset
  readonly property real fittedWidth: panel.fittedContentWidth(desiredWidth)
  // On a narrow screen the cells shrink to a floor, then the grid scrolls.
  readonly property real cellW: fittedWidth >= desiredWidth ? baseCellW
    : Math.max(Style.space(16), (fittedWidth - panel.verticalContentInset - stripX - (columnCount - 1) * cellGap) / dayHours)
  readonly property real stripW: dayHours * cellW + (columnCount - 1) * cellGap
  readonly property real rowGap: Style.space(8)

  KeyboardPanel {
    id: panel
    objectName: "plannerCard"
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: root.fittedWidth
    contentHeight: panel.fittedContentHeight(contents.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      objectName: "gridKeys"
      width: parent.width
      height: contents.implicitHeight
      blocked: durationPicker.popupOpen
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) { if (dx !== 0) root.moveHoverCol(dx) }
      onTextKey: function(t) {
        t = t.toLowerCase()
        if (t === "n") { root.selectedUtc = -1; root.hoverCol = -1 }
        else if (t === "h" || t === "l") root.moveHoverCol(t === "l" ? 1 : -1)
        else if (t === "c") root.copyTimes()
        else if (t === "r") root.refresh()
      }

      Column {
        id: contents
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          height: actions.implicitHeight
          Ui.Button {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.selectedUtc >= 0
            text: "Now"
            tooltipText: "Back to the current time (n)"
            focusable: true
            onClicked: { root.selectedUtc = -1; root.hoverCol = -1 }
          }
          Row {
            id: actions
            anchors.right: parent.right
            spacing: Style.space(4)
            Ui.Dropdown {
              id: durationPicker
              objectName: "durationPicker"
              width: Style.space(96)
              showLabel: false
              anchors.verticalCenter: parent.verticalCenter
              options: root.durationOptions
              value: String(root.meetingMinutes)
              onChanged: function(value) {
                if (!root.persistSetting("meetingMinutes", Number(value))) durationPicker.value = String(root.meetingMinutes)
              }
            }
            Ui.Button {
              objectName: "copyButton"
              text: "Copy"
              tooltipText: "Copy meeting times (c)"
              focusable: true
              enabled: root.ready
              onClicked: root.copyTimes()
            }
          }
        }

        Text {
          objectName: "message"
          width: parent.width
          visible: text !== ""
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
          text: root.errorMessage || (!root.gridShown ? "Reading timezones…"
            : root.plan.source === "none" ? "Add Elsewhen to the bar to plan across its cities." : "")
          color: root.errorMessage ? Commons.Color.accent : root.dim
          font.family: root.fontFam
          font.pixelSize: Style.font.bodySmall
        }

        Item {
          width: parent.width
          height: root.gridShown ? Math.min(grid.implicitHeight, Style.space(390)) : 0
          Flickable {
            id: gridFlick
            objectName: "gridFlick"
            anchors.fill: parent
            contentWidth: Math.max(width, root.stripX + root.stripW)
            contentHeight: grid.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            // A band across every city marks the hours they all work.
            Repeater {
              model: root.gridShown ? root.columns : []
              Rectangle {
                required property int index
                required property var modelData
                visible: modelData.working
                x: root.stripX + index * (root.cellW + root.cellGap)
                width: root.cellW * modelData.minutes / 60 + root.cellGap
                height: grid.implicitHeight
                color: Qt.alpha(Commons.Color.accent, 0.08)
              }
            }
            Column {
              id: grid
              width: parent.width
              spacing: root.rowGap
              Repeater {
                model: root.gridShown ? root.zones : []
                Item {
                  id: zoneItem
                  required property var modelData
                  required property int index
                  objectName: "plannerRow-" + index
                  readonly property var zoneRow: modelData
                  readonly property double offset: Model.offsetAt(zoneRow, root.selectedMoment)
                  readonly property string relativeDay: root.homeRow ? Model.relativeDayLabel(root.selectedMoment, offset, Model.offsetAt(root.homeRow, root.selectedMoment)) : ""
                  width: grid.width
                  height: root.cellH
                  Column {
                    x: Style.space(6)
                    width: root.headerW - Style.space(6)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.space(1)
                    Row {
                      width: parent.width
                      spacing: Style.space(6)
                      Text {
                        objectName: "cityTitle"
                        width: Math.min(implicitWidth, parent.width - (homeBadge.visible ? homeBadge.width + parent.spacing : 0)
                          - (relativeBadge.visible ? relativeBadge.width + parent.spacing : 0))
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: zoneItem.zoneRow.label
                        color: zoneItem.zoneRow.home === true ? root.fg : root.dim
                        font.family: root.fontFam
                        font.pixelSize: Style.font.bodySmall
                      }
                      Text {
                        id: homeBadge
                        objectName: "homeBadge"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: zoneItem.zoneRow.home === true
                        text: "home"
                        textFormat: Text.PlainText
                        color: Commons.Color.accent
                        font.family: root.fontFam
                        font.pixelSize: Style.font.caption
                      }
                      Text {
                        id: relativeBadge
                        objectName: "relativeDayBadge"
                        anchors.verticalCenter: parent.verticalCenter
                        visible: zoneItem.relativeDay !== ""
                        text: zoneItem.relativeDay
                        textFormat: Text.PlainText
                        color: Commons.Color.accent
                        font.family: root.fontFam
                        font.pixelSize: Style.font.caption
                      }
                    }
                    Row {
                      width: parent.width
                      spacing: Style.space(6)
                      Text {
                        id: cityTime
                        objectName: "cityTime"
                        text: Model.timeLabel(root.selectedMoment, zoneItem.offset, root.hour24)
                        textFormat: Text.PlainText
                        color: root.hasSelection ? Commons.Color.accent : root.fg
                        font.family: root.fontFam
                        font.pixelSize: Style.font.display
                        font.bold: true
                      }
                      Text {
                        objectName: "cityDetail"
                        anchors.baseline: cityTime.baseline
                        width: Math.max(0, Math.min(implicitWidth, parent.width - cityTime.width - parent.spacing))
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: Model.abbrAt(zoneItem.zoneRow, root.selectedMoment) + " · " + Model.dateLabel(root.selectedMoment, zoneItem.offset)
                        color: root.dim
                        font.family: root.fontFam
                        font.pixelSize: Style.font.caption
                      }
                    }
                  }
                  Row {
                    x: root.stripX
                    spacing: root.cellGap
                    Repeater {
                      model: root.columns.length
                      Rectangle {
                        required property int index
                        readonly property var c: Model.cell(index, root.dayStart, zoneItem.zoneRow)
                        width: root.cellW * root.columns[index].minutes / 60
                        height: root.cellH
                        radius: Style.space(2)
                        color: c.tint === "work" ? Qt.alpha(Commons.Color.accent, 0.22) : Qt.alpha(root.fg, c.tint === "day" ? 0.06 : 0.0)
                        Text {
                          objectName: "cellLabel"
                          anchors.centerIn: parent
                          width: parent.width
                          horizontalAlignment: Text.AlignHCenter
                          fontSizeMode: Text.HorizontalFit
                          minimumPixelSize: 6
                          textFormat: Text.PlainText
                          text: Model.cellLabel(c, root.hour24)
                          color: c.isMidnight ? Commons.Color.accent : Qt.alpha(root.fg, c.tint === "night" ? 0.35 : c.tint === "day" ? 0.7 : 1)
                          font.family: root.fontFam
                          font.pixelSize: c.isMidnight || c.minute ? Style.font.caption - 2 : Style.font.caption
                        }
                      }
                    }
                  }
                }
              }
            }
            Rectangle {
              objectName: "selectedTimeBand"
              visible: root.gridShown && root.selectedColumn >= 0
              x: root.stripX + Math.max(0, root.selectedColumn) * (root.cellW + root.cellGap)
              width: root.selectedColumn >= 0 ? root.cellW * root.columns[root.selectedColumn].minutes / 60 : 0
              height: grid.implicitHeight
              radius: Style.space(2)
              color: Qt.alpha(Commons.Color.accent, 0.12)
              border.color: Commons.Color.accent
              border.width: 1
            }
            Rectangle {
              objectName: "nowMarker"
              visible: root.gridShown && root.nowUtc >= root.dayStart && root.nowUtc < root.snapshot.dayEnd
              x: root.stripX + (root.nowUtc - root.dayStart) / 3600000 * (root.cellW + root.cellGap) - 1
              width: 1; height: grid.implicitHeight
              color: root.fg
              Rectangle { width: Style.space(5); height: width; radius: width / 2; anchors.horizontalCenter: parent.horizontalCenter; color: root.fg }
            }
            MouseArea {
              x: root.stripX
              width: root.stripW
              height: grid.implicitHeight
              hoverEnabled: true
              function columnAt(x) { return Math.max(0, Math.min(root.columns.length - 1, Math.floor(x / (root.cellW + root.cellGap)))) }
              onPositionChanged: function(mouse) { root.hoverCol = columnAt(mouse.x) }
              onClicked: function(mouse) {
                var column = root.columns[columnAt(mouse.x)]
                if (column) root.selectedUtc = column.start
                keyCatcher.forceActiveFocus()
              }
              onExited: root.hoverCol = -1
            }
          }
        }

        // Today's remaining windows that suit every city, in home time; the
        // hint on the right doubles as the status line.
        Item {
          width: parent.width
          height: Math.max(overlap.implicitHeight, hint.implicitHeight)
          Row {
            id: overlap
            objectName: "overlap"
            visible: root.ready
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)
            Text {
              anchors.verticalCenter: parent.verticalCenter
              rightPadding: Style.space(4)
              text: root.overlapWindows.length ? "Overlap" : "No shared working time left today"
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFam
              font.pixelSize: Style.font.caption
            }
            Repeater {
              model: root.overlapWindows.slice(0, 4)
              Ui.Button {
                required property var modelData
                text: root.homeTime(modelData.start) + "–" + root.homeTime(modelData.end)
                tooltipText: "Select the first " + root.meetingMinutes + "-minute slot"
                fontSize: Style.font.bodySmall
                selected: root.selectedUtc >= modelData.start && root.selectedUtc <= modelData.lastStart
                focusable: true
                onClicked: { root.selectedUtc = modelData.start; root.hoverCol = -1 }
              }
            }
          }
          Text {
            id: hint
            objectName: "footerHint"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - (overlap.visible ? overlap.width + Style.space(16) : 0))
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            textFormat: Text.PlainText
            text: root.statusMessage || "click to pin · h/l move · n now · c copy"
            color: root.statusMessage ? Commons.Color.accent : Qt.alpha(root.fg, 0.4)
            font.family: root.fontFam
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
