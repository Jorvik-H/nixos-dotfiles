import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
  id: root

  property bool open: false
  property var player: pickPlayer()

  // Null-safe copies of the player's state, so the UI never reads from a missing player
  property real position: player ? player.position : 0
  property real length: player ? player.length : 0
  property real fraction: length > 0 ? Math.min(1, position / length) : 0
  property bool playing: player ? player.isPlaying : false
  property bool canPrev: player ? player.canGoPrevious : false
  property bool canNext: player ? player.canGoNext : false
  property bool canToggle: player ? player.canTogglePlaying : false
  property bool canSeek: player ? player.canSeek : false
  property bool hasVolume: player ? player.volumeSupported : false
  property real volume: hasVolume ? player.volume : 0

  // "Title | Artist | Album", skipping any part that's empty
  property string infoLine: buildInfo()

  function buildInfo() {
    if (!player)
      return "";

    var parts = [];
    parts.push(player.trackTitle !== "" ? player.trackTitle : "Unknown title");

    if (player.trackArtist !== "")
      parts.push(player.trackArtist);
    if (player.trackAlbum !== "")
      parts.push(player.trackAlbum);

    return parts.join("  |  ");
  }

  // Prefer a player that's currently playing, otherwise the first one
  function pickPlayer() {
    var list = Mpris.players.values;

    for (var i = 0; i < list.length; i++) {
      if (list[i].isPlaying)
        return list[i];
    }
    return list.length > 0 ? list[0] : null;
  }

  function fmt(seconds) {
    var t = Math.max(0, Math.floor(seconds));
    var m = Math.floor(t / 60);
    var s = t % 60;
    return m + ":" + (s < 10 ? "0" : "") + s;
  }

  // Uses the player's own volume when it supports one, otherwise the system volume
  function changeVolume(delta) {
    if (hasVolume) {
      player.volume = Math.max(0, Math.min(1, player.volume + delta));
    } else {
      var step = Math.round(Math.abs(delta) * 100) + "%" + (delta > 0 ? "+" : "-");
      Quickshell.execDetached(["wpctl", "set-volume", "-l", "1", "@DEFAULT_AUDIO_SINK@", step]);
    }
  }

  // Position isn't pushed by MPRIS, so poll it while the bar is open and playing
  Timer {
    interval: 500
    running: root.open && root.playing
    repeat: true
    onTriggered: root.player.positionChanged()
  }

  // Lets you control it from Hyprland keybinds
  IpcHandler {
    target: "media"

    function toggle(): void {
      root.open = !root.open;
    }

    function playPause(): void {
      if (root.canToggle)
        root.player.togglePlaying();
    }

    function next(): void {
      if (root.canNext)
        root.player.next();
    }

    function previous(): void {
      if (root.canPrev)
        root.player.previous();
    }

    function forward(): void {
      if (root.canSeek)
        root.player.seek(10);
    }

    function back(): void {
      if (root.canSeek)
        root.player.seek(-10);
    }

    function volumeUp(): void {
      root.changeVolume(0.05);
    }

    function volumeDown(): void {
      root.changeVolume(-0.05);
    }
  }

  PanelWindow {
    id: win

    anchors {
      left: true
      right: true
      bottom: true
    }
    margins {
      left: 7
      right: 7
      bottom: 7
    }

    implicitHeight: 76
    exclusionMode: ExclusionMode.Auto
    visible: root.open
    color: "transparent"

    WlrLayershell.namespace: "media"
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
      if (visible)
        keys.forceActiveFocus();
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

        // ---------- Keyboard shortcuts (active while the bar is open) ----------
        Item {
          id: keys
          anchors.fill: parent
          focus: true

          Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
              root.open = false;
              event.accepted = true;
            } else if (event.key === Qt.Key_Space) {
              if (root.canToggle)
                root.player.togglePlaying();
              event.accepted = true;
            } else if (event.key === Qt.Key_L) {
              if (root.canSeek)
                root.player.seek(10);
              event.accepted = true;
            } else if (event.key === Qt.Key_J) {
              if (root.canSeek)
                root.player.seek(-10);
              event.accepted = true;
            } else if (event.key === Qt.Key_O) {
              if (root.canNext)
                root.player.next();
              event.accepted = true;
            } else if (event.key === Qt.Key_U) {
              if (root.canPrev)
                root.player.previous();
              event.accepted = true;
            } else if (event.key === Qt.Key_I) {
              root.changeVolume(0.05);
              event.accepted = true;
            } else if (event.key === Qt.Key_K) {
              root.changeVolume(-0.05);
              event.accepted = true;
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: root.player === null
          text: "Nothing playing"
          color: "#859289"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }

        Item {
          id: content
          anchors.fill: parent
          anchors.margins: 12
          visible: root.player !== null

          // ---------- Volume bar: full height, right edge ----------
          Rectangle {
            id: volBar
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            visible: root.hasVolume
            width: 6
            radius: 0
            color: "#475258"

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: parent.height * root.volume
              color: "#d699b6"
            }
          }

          // ---------- Info line: Title | Artist | Album, centered ----------
          Item {
            id: topRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 20

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.verticalCenter: parent.verticalCenter

              // Same clearance on both sides, so the line stays centered in the whole bar
              width: parent.width - (volBar.visible ? 2 * (volBar.width + 12) : 0)

              horizontalAlignment: Text.AlignHCenter
              text: root.infoLine
              color: "#d3c6aa"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 13
              elide: Text.ElideRight
            }
          }

          // ---------- Progress bar ----------
          Item {
            id: progress
            anchors.left: parent.left
            anchors.right: volBar.visible ? volBar.left : parent.right
            anchors.rightMargin: volBar.visible ? 12 : 0
            anchors.bottom: parent.bottom
            height: 16

            Text {
              id: posText
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: 44
              text: root.fmt(root.position)
              color: "#9da9a0"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
            }

            Text {
              id: lenText
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              width: 44
              horizontalAlignment: Text.AlignRight
              text: root.fmt(root.length)
              color: "#9da9a0"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 11
            }

            Rectangle {
              id: track
              anchors.left: posText.right
              anchors.leftMargin: 8
              anchors.right: lenText.left
              anchors.rightMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              height: 10
              radius: 0
              color: "#475258"

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: track.width * root.fraction
                radius: 0
                color: "#83c092"
              }

              // Click anywhere on the bar to seek there
              MouseArea {
                anchors.fill: parent
                anchors.topMargin: -4
                anchors.bottomMargin: -4
                enabled: root.canSeek && root.length > 0
                cursorShape: Qt.PointingHandCursor

                onClicked: (mouse) => {
                  root.player.position = (mouse.x / width) * root.length;
                }
              }
            }
          }
        }
      }
    }
  }
}
