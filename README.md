# Lighthouse

A calm, glanceable screen for the 5″ display in the Wokyis M5 dock under a Mac mini. It shows one thing at a time, in this order:

1. an AI agent that needs you
2. an agent that just finished
3. your next calendar event within the hour
4. a single to-do (coming later)

Every agent is a small shape that keeps its identity: outline = idle, dots = working, solid white = finished, terracotta glow = needs you. A day arc shows how much daylight and evening you have left. Everything else (agents, capture, quiet mode, layouts) sits behind big buttons, because the screen is clicked with a mouse at 1280×720.

Design system and clickable prototype: <https://claude.ai/artifact/JvmtdGbPgVHPdCLgYZAF48> (private until shared).

## Pieces

| Path | What it is |
|---|---|
| `prototype/lighthouse.html` | The whole UI: five home layouts, menu, agents, capture, day views, and the design-system page around them. It runs on demo data in a browser and on live data inside the app. |
| `prototype/build-screen.sh` | Wraps `lighthouse.html` into `screen.html`, a full document. `kiosk` (default) shows only the screen; any other argument shows the design page. |
| `kiosk/Lighthouse.swift` | Tiny macOS app. Borderless window pinned to the display named "Wokyis", menu-bar icon, ⌃⌥Space capture, live agents, calendar, Grok Bot. |
| `kiosk/build.sh` | Builds `kiosk/build/Lighthouse.app` (needs the Xcode Command Line Tools). |
| `kiosk/install-login-item.sh` | Starts Lighthouse at login (`uninstall` to undo). |
| `hooks/lighthouse-hook.sh` | Claude Code hook. Appends one JSON line per event to `~/.lighthouse/events.ndjson`. |
| `docs/` | Research and the design spec extracted from the reference video. |

## Setup

```sh
kiosk/build.sh
open kiosk/build/Lighthouse.app
kiosk/install-login-item.sh   # optional: start at login
```

Then add the hook to `~/.claude/settings.json` on `SessionStart`, `UserPromptSubmit`, `PostToolUse`, `Notification`, `Stop` and `SessionEnd`:

```json
{ "type": "command", "command": "/path/to/micro-monitor/hooks/lighthouse-hook.sh", "async": true, "timeout": 5 }
```

Sessions that were already running pick the hook up only after a restart.

## Data sources

- **Claude Code**: hooks → `~/.lighthouse/events.ndjson`. Prompt or tool use = working, permission prompt = needs you, Stop = finished, SessionEnd = gone. Idle sessions drop off after 3 hours, anything after 12. Clicking a "needs you" card brings Claude to the front; clicking a finished card marks it seen.
- **Grok Bot**: no hooks, so the app watches `~/.grokbot/local-exec-daemon.json` and treats `inflightCount > 0` as working. It only sees tasks Grok runs on this Mac.
- **Any other agent**: append `{"t":<unix secs>,"src":"grok","ev":"working|done|needs|idle|end","sid":"<id>","cwd":"<folder>","why":"<one line>"}` to the events file.
- **Calendar**: macOS Calendar via EventKit (every account added in System Settings → Internet Accounts). Timed, non-declined events starting within the next hour.
- **Capture**: ⌃⌥Space or the Capture button appends `- [ ] …` to `~/Inbox/inbox.md`. The screen never shows the inbox.
- **Daylight**: sunrise and sunset calculated in the page for Seattle; bedtime 10:30 PM. Quiet mode turns on automatically from an hour before bed until sunrise.

## Debugging

`~/.lighthouse/state.json` and `~/.lighthouse/event.json` hold exactly what the app last sent to the screen. Use the menu-bar icon to reload the screen or quit.
