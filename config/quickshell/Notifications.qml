import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Scope {
  id: root

  property bool centerOpen: false
  property bool dnd: false

  // Plain-data history, separate from the live popups
  ListModel {
    id: history
  }

  NotificationServer {
    id: notifServer
    keepOnReload: true
    bodyMarkupSupported: true
    imageSupported: true

    onNotification: (notification) => {
      notification.tracked = true;

      history.insert(0, {
        summary: notification.summary,
        body: notification.body,
        appName: notification.appName,
        urgency: notification.urgency,
        time: Qt.formatDateTime(new Date(), "HH:mm")
      });

      // Keep the last 50
      if (history.count > 50)
        history.remove(50, history.count - 50);
    }
  }

  IpcHandler {
    target: "notifications"

    function toggle(): void {
      root.centerOpen = !root.centerOpen;
    }

    function toggleDnd(): void {
      root.dnd = !root.dnd;
    }

    function clear(): void {
      history.clear();
    }
  }

  // ---------- Popups ----------
  PanelWindow {
    id: popups

    anchors {
      top: true
      right: true
    }
    margins {
      top: 43
      right: root.centerOpen ? 14 + 360 + 8 : 14
    }

    implicitWidth: 340
    implicitHeight: popupColumn.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    visible: !root.dnd && notifServer.trackedNotifications.values.length > 0
    color: "transparent"

    Column {
      id: popupColumn
      width: parent.width
      spacing: 8

      Repeater {
        model: notifServer.trackedNotifications

        Rectangle {
          id: card
          required property var modelData

          property bool critical: modelData.urgency === NotificationUrgency.Critical

          width: popupColumn.width
          implicitHeight: content.implicitHeight + 24
          radius: 0
          color: "#333c43"
          border.width: 2
          border.color: critical ? "#e67e80" : "#83c092"

          Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 12
            spacing: 4

            Text {
              width: parent.width
              text: card.modelData.summary
              color: "#d3c6aa"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 13
              font.bold: true
              wrapMode: Text.Wrap
            }

            Text {
              width: parent.width
              visible: card.modelData.body !== ""
              text: card.modelData.body
              textFormat: Text.StyledText
              color: "#9da9a0"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12
              wrapMode: Text.Wrap
            }
          }

          // Auto-dismiss, except for critical notifications
          Timer {
            interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : 5000
            running: !card.critical
            onTriggered: card.modelData.expire()
          }

          MouseArea {
            anchors.fill: parent
            onClicked: card.modelData.dismiss()
          }
        }
      }
    }
  }

  // ---------- Notification center ----------
  PanelWindow {
    id: center

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
    visible: root.centerOpen
    color: "transparent"

    Rectangle {
      id: frame
      anchors.fill: parent
      radius: 0
      color: "#333c43"

      property int borderWidth: 2

      HoverHandler {
        id: centerHover
      }

      border.width: borderWidth
      border.color: centerHover.hovered ? "#83c092" : "transparent"

      // Everything lives in here, inset by the border width
      Item {
        id: inner
        anchors.fill: parent
        anchors.margins: frame.borderWidth

        Item {
          id: header
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 12
          height: 28

          Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            color: "#d3c6aa"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            font.bold: true
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Text {
              text: root.dnd ? "󰂛 DND on" : "󰂚 DND off"
              color: root.dnd ? "#e67e80" : "#9da9a0"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dnd = !root.dnd
              }
            }

            Text {
              text: "󰆴 Clear"
              color: "#9da9a0"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 12

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: history.clear()
              }
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: history.count === 0
          text: "No notifications"
          color: "#859289"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 13
        }

        ListView {
          anchors.top: header.bottom
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.margins: 12
          anchors.topMargin: 8

          spacing: 8
          clip: true
          model: history

          delegate: Rectangle {
            id: entry

            required property int index
            required property string summary
            required property string body
            required property string appName
            required property string time
            required property int urgency

            width: ListView.view.width
            implicitHeight: entryContent.implicitHeight + 20
            radius: 0
            color: "#3a464c"
            border.width: 1
            border.color: urgency === NotificationUrgency.Critical ? "#e67e80" : "#475258"

            Column {
              id: entryContent
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: 10
              spacing: 3

              Text {
                width: parent.width
                text: entry.appName + " · " + entry.time
                color: "#859289"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                elide: Text.ElideRight
              }

              Text {
                width: parent.width
                text: entry.summary
                color: "#d3c6aa"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.Wrap
              }

              Text {
                width: parent.width
                visible: entry.body !== ""
                text: entry.body
                textFormat: Text.StyledText
                color: "#9da9a0"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                wrapMode: Text.Wrap
              }
            }

            // Click an entry to remove it from the history
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: history.remove(entry.index)
            }
          }
        }
      }
    }
  }
}
