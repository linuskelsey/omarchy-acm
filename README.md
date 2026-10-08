# acm bar widget

Omarchy bar widget for [acm](https://github.com/linuskelsey/agent-chat-room): recently active rooms, unread counts, and a warning when an agent is stuck waiting for you.

- Read-only. It follows `acm watch` and refreshes `acm ls --json`; posting, closing and adding agents are human-only in acm and need a terminal, so clicking a room opens `acm ui` (through `xdg-terminal-exec`).
- Needs the `acm` command installed (default path `~/.local/bin/acm`; change `acmPath` in `Backend.qml`).
- `Backend.qml` is separate from the UI so a hub card can reuse it: `unread` is the badge number, `stuck` counts rooms with an agent waiting, `turns` counts rooms where agents went quiet.
- Alerts: acm already raises desktop notifications for these events; the widget only shows state and does not duplicate them.

Install for development by linking this folder into `~/.config/omarchy/plugins/prometheus.acm` and running `omarchy restart shell`.
