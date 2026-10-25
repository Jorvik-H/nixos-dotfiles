import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

Scope {
  // Created once, outside the per-monitor bar
  Notifications {}
  Launcher { id: launcher }
  Media {}

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root

      required property var modelData
      screen: modelData

      anchors.top: true
      anchors.left: true
      anchors.right: true
      implicitHeight: 30
      color: "#333c43"

      // True only on the monitor that was focused when the launcher opened
      property bool launching: launcher.open && launcher.monitorName === modelData.name

      // The bar needs keyboard focus to receive typing
      WlrLayershell.keyboardFocus: launching ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      //CLOCK

      Text {
        anchors.centerIn: parent

        id: clock
        visible: !root.launching && !root.osdActive && !root.lowBattery && !root.chargeActive && !root.wifiActive

        SystemClock {
          id: sysClock
          precision: SystemClock.Minutes
        }

        text: Qt.formatDateTime(sysClock.date, "-- ddd, d. MMM  HH:mm --")
        color: "#d3c6aa"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
      }

      //VOLUME / BRIGHTNESS READOUT

      Text {
        anchors.centerIn: parent
        visible: root.osdActive && !root.launching

        text: root.osdText
        color: root.osdColor
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
      }
      //LOW BATTERY WARNING

      Text {
        anchors.centerIn: parent
        visible: root.lowBattery && !root.osdActive && !root.launching

        text: "[ low battery : " + bat.level + "% ]"
        color: "#e67e80"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
      }

      //CHARGING MESSAGE

      Text {
        anchors.centerIn: parent
        visible: root.chargeActive && !root.osdActive && !root.launching

        text: "[  battery: charging  ]"
        color: "#a7c080"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
      }

      //WIFI OVERLAY

      Text {
        anchors.centerIn: parent
        visible: root.wifiActive && !root.osdActive && !root.launching && !root.lowBattery && !root.chargeActive

        text: root.wifiState === "connecting" ? "[  wifi: connecting...  ]"
            : root.wifiState === "connected" ? "[  wifi: connected  ]"
            : "[  wifi: disconnected  ]"
        color: root.wifiState === "connecting" ? "#dbbc7f"
             : root.wifiState === "connected" ? "#a7c080"
             : "#e67e80"
        font.pixelSize: 13
        font.family: "JetBrainsMono Nerd Font"
        font.bold: true
      }


      // ---------- Wifi connection overlay ----------
      property string wifiState: ""   // "connected", "connecting" or "disconnected"
      property bool wifiFlash: false
      property bool wifiActive: osdReady && (wifiState === "connecting" || wifiFlash)

      function setWifiState(s) {
        if (s === "" || s === wifiState)
          return;

        var first = wifiState === "";
        wifiState = s;

        // The first reading after startup isn't announced
        if (first || !osdReady)
          return;

        if (s === "connecting") {
          wifiFlash = false;
          wifiTimer.stop();
        } else {
          wifiFlash = true;
          wifiTimer.restart();
        }
      }

      Timer {
        id: wifiTimer
        interval: 3000
        onTriggered: root.wifiFlash = false
      }


      // Brief "charging" message shown right after plugging in
      property bool chargeActive: false

      function showCharging() {
        if (!osdReady)
          return;

        chargeActive = true;
        chargeTimer.restart();
      }

      Timer {
        id: chargeTimer
        interval: 3000
        onTriggered: root.chargeActive = false
      }

      // True while the battery is at 10% or below and not charging
      property bool lowBattery: bat.present && !bat.charging && bat.level <= 10

      // ---------- Volume / brightness readout (replaces the clock briefly) ----------
      property string osdText: ""
      property color osdColor: "#d3c6aa"
      property bool osdActive: false
      property bool osdReady: false   // ignore the values read at startup

      function showOsd(text, color) {
        if (!osdReady)
          return;

        osdText = text;
        osdColor = color;
        osdActive = true;
        osdTimer.restart();
      }

      Timer {
        interval: 2000
        running: true
        onTriggered: root.osdReady = true
      }

      Timer {
        id: osdTimer
        interval: 1500
        onTriggered: root.osdActive = false
      }

      //WORKSPACES

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        visible: !root.launching

        Repeater {
          model: 9

          Text {
            id: ws
            required property int index
            property int wsId: index + 1

            property var workspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
            property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
            property bool isOccupied: workspace !== null
            property bool isUrgent: workspace?.urgent ?? false

            text: isFocused ? (isOccupied ? "▪" : "□"): (isOccupied ? "▪" : "▫")
            // text: isFocused ? (isOccupied ? "■" : "□"): (isOccupied ? "▪" : "▫")

            color: isUrgent ? "#e67e80"
                                 : isFocused ? "#d699b6"
                                 : isOccupied ? "#d3c6aa"
                                 : "#d3c6aa"
            font.pixelSize: 18

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Hyprland.dispatch("workspace " + ws.wsId)
                console.log("clicked workspace", ws.wsId)
              }
            }
          }
        }

        Repeater {
          model: Hyprland.workspaces

          Text {
            id: extra
            required property var modelData

            visible: modelData.id > 9
            // text: modelData.focused ? "■" : "▪"
            text: modelData.focused ? "▪" : "▪"

            font.pixelSize: 18

            color: modelData.urgent ? "#e67e80"
                                 : modelData.focused ? "#d699b6"
                                 : modelData.occupied ? "#d3c6aa"
                                 : "#d3c6aa"

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("workspace " + extra.modelData.id)
            }
          }
        }
      }

      //CPU USAGE

      Text {
        id: cpu

        property int cpuUsage: 0
        property real lastTotal: 0
        property real lastIdle: 0

        anchors.right: mem.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        text: "  " + cpuUsage + "%"
        color: cpuUsage > 90 ? "#e67e80" : "#7fbbb3"
        font.pixelSize: 13

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["kitty", "htop"])
        }

        Process {
          id: proc
          command: ["head", "-n", "1", "/proc/stat"]

          stdout: StdioCollector {
            onStreamFinished: {
              var f = this.text.trim().split(/\s+/);

              var idle = Number(f[4]) + Number(f[5]);

              var total = 0;
              for (var i = 1; i <= 8; i++)
                total += Number(f[i]);

              var dTotal = total - cpu.lastTotal;
              var dIdle = idle - cpu.lastIdle;

              if (cpu.lastTotal > 0 && dTotal > 0)
                cpu.cpuUsage = Math.round(100 * (dTotal - dIdle) / dTotal);

              cpu.lastTotal = total;
              cpu.lastIdle = idle;
            }
          }
        }

        Timer {
          interval: 2000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: proc.running = true
        }
      }

      //MEMORY USAGE

      Text {
        id: mem

        property int memUsage: 0

        anchors.right: vol.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        text: "  " + memUsage + "%"
        color: memUsage > 90 ? "#e67e80" : "#d699b6"
        font.pixelSize: 13

        Process {
          id: memProc
          command: ["head", "-n", "3", "/proc/meminfo"]

          stdout: StdioCollector {
            onStreamFinished: {
              var total = Number(this.text.match(/MemTotal:\s+(\d+)/)[1]);
              var available = Number(this.text.match(/MemAvailable:\s+(\d+)/)[1]);

              mem.memUsage = Math.round(100 * (total - available) / total);
            }
          }
        }

        Timer {
          interval: 2000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: memProc.running = true
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["kitty", "htop"])
        }
      }

      //BATTERY

      Text {
        id: bat

        property int level: 0
        property string status: ""
        property bool present: false

        property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
        property string icon: icons[Math.min(10, Math.floor(level / 10))]
        property bool charging: status === "Charging"

        visible: present

        onChargingChanged: {
          if (charging)
            root.showCharging();
          else
            root.chargeActive = false;
        }

        text: (charging ? icon : icon)  + " " + level + "%"
        color: charging ? "#a7c080" : level <= 15 ? "#e67e80" : "#dbbc7f"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 12

        Process {
          id: batProc
          command: [
            "sh", "-c",
            "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status"
          ]

          stdout: StdioCollector {
            onStreamFinished: {
              var lines = this.text.trim().split("\n");

              if (lines.length < 2) {
                bat.present = false;
                return;
              }

              bat.present = true;
              bat.level = Number(lines[0]);
              bat.status = lines[1];
              bat.checkLow();
            }
          }
        }

        property bool warned: false

        function checkLow() {
          if (present && !charging && level < 5) {
            if (!warned) {
              warned = true;
              Quickshell.execDetached([
                "notify-send", "-u", "critical",
                "Battery low", "Battery is at " + level + "%"
              ]);
            }
          } else {
            warned = false;
          }
        }

        Timer {
          interval: 5000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: batProc.running = true
        }
      }

      //BRIGHTNESS

      Text {
        id: bright

        anchors.right: bt.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        onLevelChanged: root.showOsd("[ brightness: " + level + "% ]", "#d3c6aa")

        property int level: 0
        property bool present: false

        // 7 steps from dim to bright
        property var icons: ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟", "󰃠"]
        property string icon: icons[Math.min(6, Math.floor(level / 15))]

        visible: present

        text: icon + " " + level + "%"
        color: "#e69875"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13

        Process {
          id: brightRead
          command: ["brightnessctl", "-m"]

          stdout: StdioCollector {
            onStreamFinished: {
              var f = this.text.trim().split(",");

              if (f.length < 5) {
                bright.present = false;
                return;
              }

              bright.present = true;
              bright.level = parseInt(f[3]);
            }
          }
        }

        Process {
          id: brightSet
          onExited: brightRead.running = true
        }

        Timer {
            interval: 200
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: brightRead.running = true
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor

          onWheel: (wheel) => {
            var step = wheel.angleDelta.y > 0 ? "1%+" : "1%-";
            brightSet.command = ["brightnessctl", "--min-value=1", "set", step];
            brightSet.running = true;
          }
        }
      }

      //AUDIO

      Text {
        id: vol

        property var sink: Pipewire.defaultAudioSink
        property bool muted: sink ? sink.audio.muted : false
        property int level: sink ? Math.round(sink.audio.volume * 100) : 0

        // low, medium, high
        property var icons: ["󰕿", "󰖀", "󰕾"]
        property string icon: muted ? "󰝟" : icons[Math.min(2, Math.floor(level / 34))]

        onLevelChanged: root.showOsd("[ volume: " + level + "% ]", "#d3c6aa")
        onMutedChanged: root.showOsd(muted ? "[ volume: muted ]" : "[ volume:"  + " unmuted ]", muted ? "#e67e80" : "#a7c080")

        anchors.right: bright.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        visible: sink !== null

        text: icon + " " + (muted ? "muted" : level + "%")
        color: muted ? "#859289" : "#a7c080"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13

        // Required so the sink's audio properties stay live
        PwObjectTracker {
          objects: [vol.sink]
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
              if (vol.sink)
                vol.sink.audio.muted = !vol.sink.audio.muted;
            } else {
              Quickshell.execDetached(["pavucontrol"]);
            }
          }

          onWheel: (wheel) => {
            if (!vol.sink)
              return;

            var delta = wheel.angleDelta.y > 0 ? 0.01 : -0.01;
            vol.sink.audio.volume = Math.max(0, Math.min(1, vol.sink.audio.volume + delta));
          }
        }
      }

      //WIFI

      Text {
        id: wifi

        property bool connected: false
        property int rate: 0
        property int signal: 0

        property var icons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
        property string icon: connected ? icons[Math.min(4, Math.floor(signal / 20))] : "󰤮"

        anchors.right: bat.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        text: icon
        color: connected ? "#83c092" : "#e67e80"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13

        
        // ---------- Connection state, for the overlay ----------
        function refreshState() {
          if (!stateProc.running)
            stateProc.running = true;
        }

        Process {
          id: stateProc
          command: ["nmcli", "-t", "-f", "TYPE,STATE", "device"]

          stdout: StdioCollector {
            onStreamFinished: {
              var lines = this.text.trim().split("\n");

              for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("wifi:") !== 0)
                  continue;

                var s = lines[i].substring(5);

                if (s.indexOf("connecting") === 0)
                  root.setWifiState("connecting");
                else if (s.indexOf("connected") === 0)
                  root.setWifiState("connected");
                else
                  root.setWifiState("disconnected");

                break;
              }
            }
          }
        }

        // nmcli monitor prints a line on every network event; any line means "check again"
        Process {
          running: true
          command: ["nmcli", "monitor"]

          stdout: SplitParser {
            onRead: data => debounce.restart()
          }
        }

        Timer {
          id: debounce
          interval: 150
          onTriggered: wifi.refreshState()
        }

        // Slow fallback in case an event is missed
        Timer {
          interval: 5000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: wifi.refreshState()
        }


        Process {
          id: wifiProc
          command: ["nmcli", "-t", "-f", "ACTIVE,RATE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]

          stdout: StdioCollector {
            onStreamFinished: {
              var lines = this.text.trim().split("\n");
              var active = null;

              for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("yes:") === 0) {
                  active = lines[i].split(":");
                  break;
                }
              }

              if (active === null) {
                wifi.connected = false;
                return;
              }

              // Format is yes:540 Mbit/s:75
              wifi.connected = true;
              wifi.rate = parseInt(active[1]);
              wifi.signal = parseInt(active[2]);
            }
          }
        }

        Timer {
          interval: 5000
          running: true
          repeat: true
          triggeredOnStart: true
          onTriggered: wifiProc.running = true
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.RightButton

          onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton)
              Quickshell.execDetached(["sh", "-c", "[ \"$(nmcli radio wifi)\" = enabled ] && nmcli radio wifi off || nmcli radio wifi on"]);
            else
              Quickshell.execDetached(["nm-connection-editor"]);
          }
        }

      }

      //BLUETOOTH

      Text {
        id: bt

        property var adapter: Bluetooth.defaultAdapter
        property bool powered: adapter ? adapter.enabled : false
        property string deviceName: firstConnected()

        function firstConnected() {
          if (!adapter)
            return "";

          var list = adapter.devices.values;
          for (var i = 0; i < list.length; i++) {
            if (list[i].connected)
              return list[i].name;
          }
          return "";
        }

        // off, on, connected
        property string icon: !powered ? "󰂲" : deviceName !== "" ? "󰂱" : "󰂯"

        anchors.right: wifi.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter

        visible: adapter !== null

        text: icon + (deviceName !== "" ? " " + deviceName : "")
        color: !powered ? "#859289" : deviceName !== "" ? "#7fbbb3" : "#83c092"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.RightButton | Qt.LeftButton

          onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
              if (bt.adapter)
                bt.adapter.enabled = !bt.adapter.enabled;
            } else {
              Quickshell.execDetached(["blueman-manager"]);
            }
          }
        }
      }

      //LAUNCHER (input box takes the workspace switcher's place)


      Item {
        id: launchInput
        visible: root.launching

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 300
        height: parent.height - 8

        onVisibleChanged: {
          input.text = "";
          if (visible)
            input.forceActiveFocus();
        }

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          visible: input.text === ""
          text: "applications..."
          color: "#d3c6aa"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }

        TextInput {
          id: input
          anchors.fill: parent
          verticalAlignment: TextInput.AlignVCenter
          color: "#d3c6aa"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
          clip: true

          // Hide the built-in cursor; the one drawn below blinks with the brackets instead
          cursorDelegate: Item {
            width: 0
            height: 0
          }

          // Typing or moving the cursor makes it solid, then the blink resumes
          onCursorPositionChanged: {
            launchMatch.cursorOn = true;
            blinkTimer.restart();
          }

          onTextChanged: {
            if (root.launching)
              launcher.query = text;

            launchMatch.cursorOn = true;
            blinkTimer.restart();
          }

          Rectangle {
            x: input.cursorRectangle.x
            y: input.cursorRectangle.y
            width: 2
            height: input.cursorRectangle.height
            color: "#d3c6aa"
            visible: input.activeFocus
            opacity: launchMatch.cursorOn ? 1 : 0
          }

          Keys.onPressed: (event) => {
            var ctrl = event.modifiers & Qt.ControlModifier;

            if (event.key === Qt.Key_Escape) {
              launcher.open = false;
              event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_K)) {
              launcher.cycle(1);
              event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_I)) {
              launcher.cycle(-1);
              event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              launcher.launchSelected();
              event.accepted = true;
            }
          }
        }
     }



      //LAUNCHER (closest match takes the clock's place)

      Item {
        id: launchMatch
        visible: root.launching

        anchors.centerIn: parent
        width: matchRow.width
        height: parent.height - 8

        // Toggled by the timer below to make the brackets blink
        property bool cursorOn: true

        // Start each session with the brackets visible
        onVisibleChanged: cursorOn = true

        Timer {
          id: blinkTimer
          interval: 650
          running: launchMatch.visible
          repeat: true
          onTriggered: launchMatch.cursorOn = !launchMatch.cursorOn
        }

        Row {
          id: matchRow
          anchors.centerIn: parent
          spacing: 8

          Text {
            text: "["
            opacity: launchMatch.cursorOn ? 1 : 0
            color: "#d3c6aa"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
          }

          Text {
            width: Math.min(implicitWidth, 300)
            text: launcher.query === "" ? "Launch Mode" : (launcher.best ? launcher.best.name : "no match")
            color: launcher.best ? "#d3c6aa" : "#d3c6aa"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            text: "]"
            opacity: launchMatch.cursorOn ? 1 : 0
            color: "#d3c6aa"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
          }
        }
      }
    }
  }
}
