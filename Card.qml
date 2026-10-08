import QtQuick
import qs.Commons

// Omahub face of the acm plugin: the same View as the bar popup, in one column.
// Declared in manifest.json under "hubCard".
Item {
  id: card

  property real hubWidth: 300
  // View draws its own "acm" heading (it doubles as the connection status): the hub hides its header title while expanded.
  property bool hubOwnTitle: true
  // Unread messages in your rooms, plus one per room where an agent is waiting on you.
  // Unread is acm's own read state, so there is nothing for markViewed() to clear.
  readonly property int badge: data.unread + data.stuck
  function markViewed() {}

  implicitHeight: view.implicitHeight

  Backend { id: data }

  View {
    id: view
    width: parent.width
    height: implicitHeight
    backend: data
    compact: true
    fg: Color.popups.text
    bg: Color.popups.background
    ff: Style.font.menuFamily
  }
}
