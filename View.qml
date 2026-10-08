import QtQuick
import qs.Ui
import qs.Commons

// The popup: recently active rooms with unread counts and alerts. Pure UI over `backend`.
Item {
  id: view

  required property var backend
  property color fg: Color.popups.text
  property color bg: Color.popups.background
  property string ff: Style.font.family
  property bool compact: false

  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: parent.width
    spacing: Style.space(8)

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: view.backend.connected ? "acm" : "acm: daemon not reachable"
      color: view.backend.connected ? Qt.darker(view.fg, 1.3) : Color.urgent
      font.family: view.ff
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: view.backend.notice !== ""
      textFormat: Text.PlainText
      text: view.backend.notice
      color: Color.urgent
      font.family: view.ff
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.Wrap
      maximumLineCount: 2
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: view.backend.recent.length === 0
      textFormat: Text.PlainText
      text: "No open rooms"
      color: view.fg
      font.family: view.ff
      font.pixelSize: Style.font.body
    }

    Repeater {
      model: view.backend.recent

      delegate: Rectangle {
        required property var modelData
        readonly property bool hasWaiting: modelData.waiting.length > 0
        width: column.width
        height: rowContent.implicitHeight + Style.space(10)
        radius: Style.space(6)
        color: rowMouse.containsMouse ? Qt.rgba(view.fg.r, view.fg.g, view.fg.b, 0.08) : "transparent"

        Row {
          id: rowContent
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          anchors.margins: Style.space(6)
          spacing: Style.space(8)

          Text {
            width: Style.space(14)
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: hasWaiting ? "⚠" : (modelData.yourTurn ? "●" : "")
            color: hasWaiting ? Color.urgent : Color.accent
            font.family: view.ff
            font.pixelSize: Style.font.body
          }

          Column {
            width: parent.width - Style.space(14) - badge.width - age.width - 3 * parent.spacing
            anchors.verticalCenter: parent.verticalCenter

            Text {
              width: parent.width
              textFormat: Text.PlainText
              text: modelData.name
              color: view.fg
              font.family: view.ff
              font.pixelSize: Style.font.body
              font.bold: modelData.unread > 0
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              visible: text !== ""
              textFormat: Text.PlainText
              text: hasWaiting ? (modelData.waiting.join(", ") + " waiting for you") : modelData.topic
              color: hasWaiting ? Color.urgent : Qt.darker(view.fg, 1.4)
              font.family: view.ff
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
            }
          }

          Rectangle {
            id: badge
            visible: modelData.unread > 0 && modelData.member
            width: visible ? Math.max(height, badgeText.implicitWidth + Style.space(10)) : 0
            height: Style.space(18)
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Color.accent
            Text {
              id: badgeText
              anchors.centerIn: parent
              textFormat: Text.PlainText
              text: modelData.unread
              color: Color.background
              font.family: view.ff
              font.pixelSize: Style.font.bodySmall
            }
          }

          Text {
            id: age
            width: implicitWidth
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: view.backend.ago(modelData.lastTs)
            color: Qt.darker(view.fg, 1.5)
            font.family: view.ff
            font.pixelSize: Style.font.bodySmall
          }
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: view.backend.openClient()
        }
      }
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      text: "Open acm in a terminal"
      color: Color.accent
      font.family: view.ff
      font.pixelSize: Style.font.bodySmall
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: view.backend.openClient()
      }
    }
  }
}
