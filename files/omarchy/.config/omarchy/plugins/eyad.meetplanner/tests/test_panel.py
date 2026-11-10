#!/usr/bin/env python3
"""The real popup and bar widget in headless Quickshell, only the panel
window stubbed. Needs the installed Omarchy shell and `qs`.

Run: python3 tests/test_panel.py (from the plugin folder)."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PLUGIN = Path(__file__).resolve().parents[1]
SHELL = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "shell"

WINDOW = """import QtQuick
Item {
  property var anchorItem
  property var owner
  property var bar
  property bool open: false
  property bool centerOnBar: false
  property var focusTarget
  property real contentWidth: 0
  property real contentHeight: 0
  property real verticalContentInset: 0
  property var screen: null
  width: contentWidth
  height: contentHeight
  function fittedContentWidth(value) { return value }
  function fittedContentHeight(value) { return value }
}
"""

HARNESS = r"""import QtQuick
import Quickshell
import "Plugin" as Plugin
import qs.Commons
import qs.Commons as Commons
ShellRoot {
  id: suite
  property int stage: 0
  property var results: []
  function check(name, passed) { results.push({name: name, passed: !!passed}) }
  function find(item, name) {
    if (item.objectName === name) return item
    for (var child of (item.children || [])) { var found = find(child, name); if (found) return found }
    return null
  }
  function layoutWith(cities) {
    return {center: [{id: "omarchy.elsewhen", hour24: true, cities: cities}],
            centerBegin: [{id: "eyad.meetplanner"}]}
  }
  QtObject {
    id: shellApi
    property var saved: null
    function updateEntryInline(id, entry) { saved = {id: id, entry: JSON.parse(JSON.stringify(entry))}; return true }
  }
  QtObject {
    id: fakeBar
    property color foreground: Commons.Color.foreground
    property color barForeground: Commons.Color.foreground
    property string fontFamily: Style.font.family
    property color urgent: Commons.Color.urgent
    property bool vertical: false
    property int barSize: Style.bar.sizeHorizontal
    property bool foregroundAnimationEnabled: false
    property QtObject shell: shellApi
    property var layoutConfig: suite.layoutWith([{name: "Riyadh", zone: "Asia/Riyadh"},
      {name: "London", zone: "Europe/London"}, {name: "UTC", zone: "Etc/UTC"}])
    function run(command) { console.log("BAR_RUN " + command) }
  }
  Plugin.Panel {
    id: tested
    bar: fakeBar
    clockEnabled: false
    nowUtc: Date.parse("2026-10-05T05:00:00Z")
    settings: ({meetingMinutes: 60})
  }
  Plugin.BarWidget { id: widget; bar: fakeBar; settings: ({}) }
  Timer {
    interval: 600; running: true; repeat: true
    onTriggered: {
      if (suite.stage === 0) {
        suite.check("nothing runs before the popup opens", !tested.gridShown)
        tested.open()
      } else if (suite.stage === 1) {
        var labels = tested.zones.map(function(z) { return z.label + (z.home ? "*" : "") })
        suite.check("rows are Elsewhen's cities with home on the system zone", JSON.stringify(labels) === '["Riyadh*","London","UTC"]')
        suite.check("home row shows local time", suite.find(tested, "cityTime").text === "08:00")
        // London 08-16Z and Riyadh 06-14Z share 08-14Z; UTC does not count.
        suite.check("overlap uses only working cities", tested.ready && tested.overlapWindows.length === 1
          && tested.overlapWindows[0].start === Date.parse("2026-10-05T08:00:00Z")
          && tested.overlapWindows[0].end === Date.parse("2026-10-05T14:00:00Z"))
        suite.check("overlap button reads home time", tested.homeTime(tested.overlapWindows[0].start) === "11:00")
        tested.selectedUtc = Date.parse("2026-10-05T09:00:00Z")
        tested.copyTimes()
      } else if (suite.stage === 2) {
        suite.check("copy writes every city", tested.statusMessage === "Meeting times copied")
        suite.find(tested, "durationPicker").changed("30")
        suite.check("duration is saved to the planner entry", shellApi.saved && shellApi.saved.id === "eyad.meetplanner"
          && shellApi.saved.entry.meetingMinutes === 30 && tested.meetingMinutes === 30)
        fakeBar.layoutConfig = suite.layoutWith([{name: "Tokyo", zone: "Asia/Tokyo"}])
      } else if (suite.stage === 3) {
        var rows = tested.zones.map(function(z) { return z.label + (z.home ? "*" : "") })
        suite.check("an Elsewhen change reloads the open grid", tested.ready && JSON.stringify(rows) === '["Riyadh*","Tokyo"]')
        suite.check("snapshot follows the duration", tested.snapshot.meetingMinutes === 30)
        tested.close()
        fakeBar.layoutConfig = ({})
      } else if (suite.stage === 4) {
        tested.open()
      } else if (suite.stage === 5) {
        suite.check("without Elsewhen the planner shows home and says why", tested.zones.length === 1
          && /Add Elsewhen/.test(suite.find(tested, "message").text))
        suite.check("bar widget has the planner icon", widget.icon !== "")
        var button = suite.find(widget, "plannerButton")
        button.pressed(Qt.RightButton)
        suite.check("right click opens nothing", !widget.opened)
        button.pressed(Qt.LeftButton)
        suite.check("left click opens the planner", widget.opened)
        console.log("PLANNER_RESULTS " + JSON.stringify(suite.results))
        Qt.quit()
      }
      suite.stage++
    }
  }
}
"""


def main():
    with tempfile.TemporaryDirectory(prefix="meetplanner-") as temporary:
        work = Path(temporary)
        for directory in ("runtime", "Plugin", "bin"):
            (work / directory).mkdir()
        (work / "Commons").symlink_to(SHELL / "Commons", target_is_directory=True)
        shutil.copytree(SHELL / "Ui", work / "Ui")
        (work / "Ui" / "KeyboardPanel.qml").write_text(WINDOW)
        for name in ("Panel.qml", "BarWidget.qml", "Model.js", "backend.py"):
            shutil.copy2(PLUGIN / name, work / "Plugin" / name)
        (work / "shell.qml").write_text(HARNESS)
        stubs = {"wl-copy": 'cat > "$PLANNER_CLIPBOARD"\n', "omarchy-launch-browser": 'echo "BROWSER $*"\n'}
        for name, body in stubs.items():
            (work / "bin" / name).write_text("#!/bin/sh\n" + body)
            (work / "bin" / name).chmod(0o700)
        environment = {key: value for key, value in os.environ.items()
                       if key not in ("WAYLAND_DISPLAY", "DISPLAY", "QS_CONFIG_PATH", "QS_CONFIG_NAME")}
        environment.update(QT_QPA_PLATFORM="offscreen", QT_QPA_PLATFORMTHEME="", QT_QUICK_CONTROLS_STYLE="Basic",
                           QT_QUICK_BACKEND="software", TZ="Asia/Riyadh",
                           HOME=str(work), XDG_RUNTIME_DIR=str(work / "runtime"), PLANNER_CLIPBOARD=str(work / "clip.txt"),
                           PATH=str(work / "bin") + os.pathsep + environment["PATH"])
        try:
            output = subprocess.run([shutil.which("qs") or "qs", "-p", str(work), "--no-color"], env=environment,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=20).stdout
            print(output) if os.environ.get("PLANNER_DEBUG") else None
        except subprocess.TimeoutExpired as error:
            output = error.stdout.decode() if isinstance(error.stdout, bytes) else error.stdout or ""
        clipboard = (work / "clip.txt").read_text() if (work / "clip.txt").exists() else ""

    marker = "PLANNER_RESULTS "
    lines = [line.split(marker, 1)[1] for line in output.splitlines() if marker in line]
    problems = [line for line in output.splitlines()
                if any(word in line for word in ("TypeError", "ReferenceError", "Binding loop", "Unable to assign", "BROWSER"))]
    if not lines:
        print(output)
        sys.exit("The popup did not finish its scenarios")
    results = json.loads(lines[-1])
    results.append({"name": "copied text has every city",
                    "passed": all(name in clipboard for name in ("Riyadh: 2026-10-05 12:00", "London:", "UTC:"))})
    results.append({"name": "no QML errors and no browser launched", "passed": not problems})
    for result in results:
        print(("PASS" if result["passed"] else "FAIL") + ": " + result["name"])
    if problems:
        print("\n".join(problems))
    sys.exit(0 if all(result["passed"] for result in results) else 1)


if __name__ == "__main__":
    main()
