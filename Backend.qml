import QtQuick
import Quickshell
import Quickshell.Io

// Non-visual half: follows the acm daemon through `acm watch` and keeps a small list of rooms.
// One instance lives in the bar widget and (later) one in the hub card, so it only reads.
// Posting, closing and adding agents are human-only in acm and need a terminal: use openClient().
Item {
  id: root

  // Absolute path, because the shell does not always inherit the user's PATH.
  property string acmPath: Quickshell.env("HOME") + "/.local/bin/acm"
  // The human's member name in acm rooms (decides what counts as unread).
  property string me: Quickshell.env("USER") || ""
  property int maxRooms: 12

  property var rooms: []          // from `acm ls --json`
  property var waiting: ({})      // room -> agents blocked on the human, from `attention` events
  property var yourTurn: ({})     // room -> true after a `quiet` event, cleared by the next message
  property string notice: ""      // last daemon warning, as "room: text"
  property bool connected: false

  // Open rooms by latest activity, annotated with the live state above.
  readonly property var recent: {
    var out = []
    for (var i = 0; i < rooms.length; i++) {
      var r = rooms[i]
      if (r.status !== "open") continue
      out.push({
        name: r.name, topic: r.topic || "", unread: r.unread || 0, lastTs: r.last_ts || r.created_at || 0,
        member: r.member === true, waiting: waiting[r.name] || [], yourTurn: yourTurn[r.name] === true
      })
    }
    out.sort(function (a, b) { return b.lastTs - a.lastTs })
    return out.slice(0, maxRooms)
  }
  // Total unread messages in rooms you are a member of: what the hub badge should show.
  readonly property int unread: {
    var n = 0
    for (var i = 0; i < recent.length; i++) if (recent[i].member) n += recent[i].unread
    return n
  }
  // Rooms with an agent stuck on an approval or question in its own window.
  readonly property int stuck: {
    var n = 0
    for (var i = 0; i < recent.length; i++) if (recent[i].waiting.length > 0) n++
    return n
  }
  // Rooms where agents went quiet and it is the human's turn.
  readonly property int turns: {
    var n = 0
    for (var i = 0; i < recent.length; i++) if (recent[i].yourTurn) n++
    return n
  }

  function openClient() {
    Quickshell.execDetached(["xdg-terminal-exec", root.acmPath, "ui"])
  }

  function ago(ts) {
    var s = Math.max(0, Date.now() / 1000 - ts)
    if (s < 90) return "now"
    if (s < 3600) return Math.round(s / 60) + "m"
    if (s < 86400) return Math.round(s / 3600) + "h"
    return Math.round(s / 86400) + "d"
  }

  function refresh() { debounce.restart() }

  function _set(map, room, value) {
    var next = Object.assign({}, map)
    if (value === null || value === false || (Array.isArray(value) && value.length === 0)) delete next[room]
    else next[room] = value
    return next
  }

  function handle(ev) {
    var room = ev.room_name
    if (ev.event === "attention") {
      var cur = (root.waiting[room] || []).filter(function (a) { return a !== ev.agent })
      if (ev.waiting) cur.push(ev.agent)
      root.waiting = _set(root.waiting, room, cur)
    } else if (ev.event === "quiet") {
      root.yourTurn = _set(root.yourTurn, room, true)
    } else if (ev.event === "message") {
      root.yourTurn = _set(root.yourTurn, room, null)
    } else if (ev.event === "read") {
      if (ev.member !== root.me) return   // someone else catching up changes nothing here
    } else if (ev.event === "warning") {
      root.notice = room + ": " + (ev.text || "")
      noticeClear.restart()
    } else if (ev.event === "deleted") {
      root.waiting = _set(root.waiting, room, null)
      root.yourTurn = _set(root.yourTurn, room, null)
    }
    refresh()
  }

  Timer { id: noticeClear; interval: 120000; onTriggered: root.notice = "" }
  Timer { id: debounce; interval: 250; onTriggered: if (!ls.running) ls.running = true; else debounce.restart() }
  // A safety net in case an event is missed while the watcher is restarting.
  Timer { interval: 60000; running: true; repeat: true; onTriggered: root.refresh() }

  Process {
    id: ls
    command: [root.acmPath, "--as", root.me, "ls", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { try { root.rooms = JSON.parse(text) } catch (e) {} }
    }
  }

  // `acm watch` ends when the daemon restarts or is stopped, so restart it, backing off while it keeps failing.
  property int restartMs: 3000
  property double startedAt: 0
  Timer { id: restart; interval: root.restartMs; onTriggered: watcher.running = true }
  Process {
    id: watcher
    running: true
    command: [root.acmPath, "--as", root.me, "watch"]
    onRunningChanged: if (running) { root.startedAt = Date.now(); root.connected = true; root.refresh() }
    stdout: SplitParser {
      onRead: function (line) { try { root.handle(JSON.parse(line)) } catch (e) {} }
    }
    onExited: function (code) {
      root.connected = false
      root.restartMs = (Date.now() - root.startedAt > 10000) ? 3000 : Math.min(60000, root.restartMs * 2)
      restart.restart()
    }
  }
}
