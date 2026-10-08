import QtQuick
import qs.Ui
import qs.Commons

// Bar icon with an unread count, turning urgent when an agent is stuck waiting for you.
// The popup hosts the same View a hub card would.
BarWidget {
  id: root
  moduleName: "prometheus.acm"

  Backend { id: data }
  HubConfig { id: hub; pluginId: "prometheus.acm" }

  property bool popupOpen: false
  function close() { popupOpen = false }

  readonly property bool alert: data.stuck > 0
  readonly property color tint: root.bar ? root.bar.barForeground : "white"

  // Step aside only when the hub wraps this plugin and hides bar icons.
  visible: !hub.hiddenByHub
  implicitWidth: hub.hiddenByHub ? 0 : row.implicitWidth + Style.space(14)
  implicitHeight: barSize

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Style.space(4)

    Text {
      textFormat: Text.PlainText
      text: "󰍩"
      color: root.alert ? Color.urgent : (data.connected ? root.tint : Qt.darker(root.tint, 1.8))
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: Style.font.body
    }
    Text {
      visible: data.unread > 0 || root.alert
      textFormat: Text.PlainText
      text: root.alert ? "⚠" : data.unread
      color: root.alert ? Color.urgent : Color.accent
      font.family: root.bar ? root.bar.fontFamily : "monospace"
      font.pixelSize: Style.font.body
    }
  }

  readonly property bool tooltipHovered: visible && mouse.containsMouse
  readonly property string tip: {
    if (!data.connected) return "acm: daemon not reachable"
    var parts = []
    if (data.stuck > 0) parts.push(data.stuck + (data.stuck === 1 ? " room has an agent waiting for you" : " rooms have agents waiting for you"))
    if (data.unread > 0) parts.push(data.unread + " unread")
    if (data.turns > 0) parts.push(data.turns + (data.turns === 1 ? " room: your turn" : " rooms: your turn"))
    return parts.length ? "acm: " + parts.join(", ") : "acm: nothing new"
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    onClicked: root.popupOpen = !root.popupOpen
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tip)
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  KeyboardPanel {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(popupView.implicitHeight)

    View {
      id: popupView
      anchors.fill: parent
      backend: data
      fg: root.bar ? root.bar.foreground : Color.popups.text
      bg: root.bar ? root.bar.background : Color.popups.background
      ff: root.bar ? root.bar.fontFamily : Style.font.family
    }
  }
}
