import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// A bar icon that opens the meeting planner. Elsewhen shows the clocks; this
// only plans across its cities.
BarWidget {
  id: root
  moduleName: "eyad.meetplanner"

  // md-calendar_clock, in every Nerd Font since 3.0; `icon` overrides it.
  readonly property string icon: Model.plainText(setting("icon", "")) || "󰃰"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    var next = Model.plainObject(root.settings)
    if (JSON.stringify(next) !== JSON.stringify(target.settings)) target.settings = next
    target.anchorItem = button
    target.hostWidget = root
  }

  // Shape the shell's summon/hide/toggle routing needs on the widget root.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item) panelLoader.item.openFromHotkey() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function refresh() { if (panelLoader.item) panelLoader.item.refresh() }
  function copyTimes() { if (panelLoader.item) panelLoader.item.copyTimes() }
  // Forwarded so this widget can stand in for the panel as the bar's popout.
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  // Every monitor has a copy of this widget but only one IpcHandler is
  // registered, so IPC acts on the copy that is open.
  function visibleInstance() {
    var items = root.bar && typeof root.bar.moduleWidgets === "function" ? root.bar.moduleWidgets(root.moduleName) : []
    for (var i = 0; i < items.length; i++) if (items[i] && items[i].opened === true) return items[i]
    return root
  }
  // The shell's routing picks the open copy, else the focused monitor's.
  function hostRoute(method) {
    var shell = root.bar ? root.bar.shell : null
    return !!shell && typeof shell[method] === "function" && shell[method](root.moduleName) === true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    objectName: "plannerPanelLoader"
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: root.injectPanel()
  }

  IpcHandler {
    target: "eyad.meetplanner"
    function open(): void { if (!root.hostRoute("summon")) root.visibleInstance().open() }
    function close(): void { if (!root.hostRoute("hide")) root.visibleInstance().close() }
    function toggle(): void { if (!root.hostRoute("toggle")) root.visibleInstance().togglePanel() }
    function refresh(): void { root.visibleInstance().refresh() }
    function copyTimes(): void { root.visibleInstance().copyTimes() }
  }

  WidgetButton {
    id: button
    objectName: "plannerButton"
    anchors.fill: parent
    bar: root.bar
    text: root.icon
    tooltipText: "Meeting planner"
    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) root.refresh()
      else if (b === Qt.LeftButton) root.togglePanel()
    }
  }
}
