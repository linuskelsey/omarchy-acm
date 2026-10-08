# acm bar widget

Omarchy bar widget for [acm](https://github.com/linuskelsey/agent-chat-room): recently active rooms, unread counts, and a warning when an agent is stuck waiting for you.

- Read-only. It follows `acm watch` and refreshes `acm ls --json`; posting, closing and adding agents are human-only in acm and need a terminal, so clicking a room opens `acm ui` (through `xdg-terminal-exec`).
- Needs the `acm` command installed (default path `~/.local/bin/acm`; change `acmPath` in `Backend.qml`).
- `Backend.qml` is separate from the UI so a hub card can reuse it: `unread` is the badge number, `stuck` counts rooms with an agent waiting, `turns` counts rooms where agents went quiet.
- Alerts: acm already raises desktop notifications for these events; the widget only shows state and does not duplicate them.

## Install

1. Install `acm` itself first (see its [README](https://github.com/linuskelsey/agent-chat-room#install)). The widget calls `~/.local/bin/acm`.
2. Clone this repository and link it into Omarchy's plugin folder, then restart the shell:

```bash
git clone https://github.com/linuskelsey/omarchy-acm.git ~/projects/omarchy-acm
ln -s ~/projects/omarchy-acm ~/.config/omarchy/plugins/prometheus.acm
omarchy restart shell
```

3. Add the widget to your bar from the Omarchy bar settings. To show it as an Omahub card instead, enable the acm card in the hub settings.

The widget follows the daemon's `read` events, so it needs an acm version that sends them (any release after the focus-aware reading change).
