import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth




PanelWindow {
  id: root

  anchors.top: true
  anchors.left: true
  anchors.right: true
  implicitHeight: 30
  color: "#333c43"

//CLOCK

  Text {
    anchors.centerIn: parent

    id: clock
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

//WORKSPACES

  Row {
    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    spacing: 12
  
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
//        text: isFocused ? (isOccupied ? "■" : "□"): (isOccupied ? "▪" : "▫")

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
//        text: modelData.focused ? "■" : "▪" 
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
  
//Spacer
  Item { Layout.fillWidth: true }

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

//Battery

  Text {
      id: bat

      property int level: 0
      property string status: ""
      property bool present: false

      property var icons: ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
      property string icon: icons[Math.min(10, Math.floor(level / 10))]
      property bool charging: status === "Charging"

      visible: present

      text: (charging ? "" : icon)  + " " + level + "%"
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
        interval: 100
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
      onClicked: Quickshell.execDetached(["nm-connection-editor"])
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

//Notifications
  
  Notifications {}






}
