import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  property bool open: false
  property string mode: "apps"   // "apps" or "procs"
  property var procList: []

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      root.open = !root.open;
    }

    // Pressing the same keybind again closes it; pressing the other one switches mode
    function apps(): void {
      if (root.open && root.mode === "apps") {
        root.open = false;
      } else {
        root.mode = "apps";
        root.open = true;
      }
    }

    function procs(): void {
      if (root.open && root.mode === "procs") {
        root.open = false;
      } else {
        root.mode = "procs";
        root.open = true;
      }
    }
  }

  // Process list, refreshed while the panel is open in process mode
  Process {
    id: psProc
    command: ["ps", "-eo", "pid=,pcpu=,pmem=,comm=", "--sort=-pcpu"]

    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.trim().split("\n");
        var out = [];

        for (var i = 0; i < lines.length && out.length < 300; i++) {
          var f = lines[i].trim().split(/\s+/);
          if (f.length < 4)
            continue;

          out.push({
            pid: f[0],
            cpu: f[1],
            mem: f[2],
            name: f.slice(3).join(" ")
          });
        }

        root.procList = out;
      }
    }
  }

  Timer {
    interval: 2000
    running: root.open && root.mode === "procs"
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!psProc.running)
        psProc.running = true;
    }
  }

  PanelWindow {
    id: win

    anchors {
      top: true
      bottom: true
      right: true
    }
    margins {
      top: 7
      bottom: 7
      right: 7
    }

    implicitWidth: 320
    exclusionMode: ExclusionMode.Auto
    visible: root.open
    color: "transparent"

    WlrLayershell.namespace: "launcher"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
      if (visible) {
        search.text = "";
        list.currentIndex = 0;
        search.forceActiveFocus();
      }
    }

    property string query: search.text.toLowerCase()

    property var filteredApps: {
      var list = DesktopEntries.applications.values;
      var out = [];

      for (var i = 0; i < list.length; i++) {
        var e = list[i];
        if (e.noDisplay)
          continue;

        var hay = (e.name + " " + (e.genericName || "") + " " + (e.comment || "")).toLowerCase();
        if (query === "" || hay.indexOf(query) !== -1)
          out.push(e);
      }

      out.sort(function(a, b) {
        return a.name.localeCompare(b.name);
      });
      return out;
    }

    property var filteredProcs: {
      var out = [];

      for (var i = 0; i < root.procList.length; i++) {
        var p = root.procList[i];
        if (query === "" || p.name.toLowerCase().indexOf(query) !== -1 || p.pid.indexOf(query) !== -1)
          out.push(p);
      }
      return out;
    }

    property var items: root.mode === "apps" ? filteredApps : filteredProcs

    function launch(entry) {
      if (entry.runInTerminal) {
        var cmd = ["kitty"];
        for (var i = 0; i < entry.command.length; i++)
          cmd.push(entry.command[i]);
        Quickshell.execDetached(cmd);
      } else {
        entry.execute();
      }
    }

    function activate(item) {
      if (!item)
        return;

      if (root.mode === "apps") {
        launch(item);
        root.open = false;
      } else {
        Quickshell.execDetached(["kill", String(item.pid)]);
      }
    }

    Rectangle {
      id: frame
      anchors.fill: parent
      radius: 0
      color: "#333c43"

      property int borderWidth: 2

      HoverHandler {
        id: frameHover
      }

      border.width: borderWidth
      border.color: frameHover.hovered ? "#83c092" : "transparent"

      Behavior on border.color {
        ColorAnimation { duration: 120 }
      }

      // Everything lives in here, inset by the border width
      Item {
        id: inner
        anchors.fill: parent
        anchors.margins: frame.borderWidth

        // ---------- Search box ----------
        Rectangle {
          id: searchBox
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 12
          height: 34
          radius: 0
          color: "#333c43"
          border.width: 1
          border.color: "#475258"

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            visible: search.text === ""
            text: root.mode === "apps" ? "Search apps..." : "Search processes..."
            color: "#859289"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
          }

          TextInput {
            id: search
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            color: "#d3c6aa"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            clip: true

            onTextChanged: list.currentIndex = 0

            Keys.onPressed: (event) => {
              if (event.key === Qt.Key_Tab) {
                root.mode = root.mode === "apps" ? "procs" : "apps";
                list.currentIndex = 0;
                event.accepted = true;
              } else if (event.key === Qt.Key_Down) {
                list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                list.currentIndex = Math.max(0, list.currentIndex - 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                win.activate(win.items[list.currentIndex]);
                event.accepted = true;
              }
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: list.count === 0
          text: "No results"
          color: "#859289"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }

        // ---------- Results ----------
        ListView {
          id: list
          anchors.top: searchBox.bottom
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 12
          anchors.topMargin: 8

          spacing: 6
          clip: true
          model: win.items
          keyNavigationEnabled: false

          onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

          delegate: Rectangle {
            id: entry

            required property int index
            required property var modelData

            property bool selected: ListView.isCurrentItem

            width: ListView.view.width
            implicitHeight: 32
            radius: 0
            color: "#333c43"
            border.width: 1
            border.color: selected ? "#83c092" : "#475258"

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 10
              anchors.right: parent.right
              anchors.rightMargin: 10
              anchors.verticalCenter: parent.verticalCenter
              text: entry.modelData.name
              color: "#d3c6aa"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 13
              font.bold: true
              elide: Text.ElideRight
            }

            // Apps launch on click; processes only select (kill with Enter)
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                list.currentIndex = entry.index;
                if (root.mode === "apps")
                  win.activate(entry.modelData);
                search.forceActiveFocus();
              }
            }
          }
        }
      }
    }
  }
}
