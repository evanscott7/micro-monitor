# Micro-monitor research brief (Wokyis M5, 1280x720 @ ~294 PPI)

## Recommendations at a glance
- **Display:** It runs **1:1 (LoDPI), "looks like 1280x720"** on this Mac. Design in **`vh`/`vmin` units**, so physical sizes stay the same if you later switch to 640x360 HiDPI (1vh = 0.62 mm in either mode).
- **Targets:** **at least 9 mm (≈104 CSS px at 1:1, 52 px at HiDPI, 14.5vh)**, and **12 mm (≈140 / 70 px, 19vh)** for primary actions. Leave **at least 2 mm** between targets.
- **Text at 60–80 cm:** body **about 5 mm em (56 px / 28 px / 8vh)**, floor **3.7 mm (42 px / 21 px / 6vh)**.
- **Kiosk:** a **tiny Swift WKWebView app** (`swiftc` is already installed via Command Line Tools). It gives a borderless window pinned to the screen named "Wokyis", a native bridge for files and Reminders, and a global hotkey. No Node or Python server is needed.
- **Hooks:** one async `command` hook on all status events runs `jq -c` and appends to an NDJSON file. `/usr/bin/jq` ships with macOS.
- **Day arc:** **SunCalc 1.9.0** (3.3 KB gz, offline). Open-Meteo is a cross-check.
- **Capture:** append to a **local `inbox.md`** via the app bridge, with optional forwarding to Reminders via `osascript`. Hotkey ⌃⌥Space through Carbon `RegisterEventHotKey`.
- **Motion:** **pure CSS** (`linear()` spring easing plus transitions and View Transitions), with **no JS library**. If you need one, use Motion's `mini` build (WAAPI, runs on the compositor).

## 1. Display
Local `system_profiler SPDisplaysDataType` (macOS 26.7.1, M4):
```
Studio Display: 5120 x 2880 Retina (main)
Wokyis:
  Resolution: 1280 x 720
  UI Looks like: 1280 x 720 @ 60.00Hz
  Mirror: Off   Online: Yes   Rotation: Supported
```
`ioreg` shows the Wokyis panel's native format as 1280x720, 29x17 cm EDID image size (bogus), and range 56–62 Hz. The WindowServer prefs show it at `Scale = 1`. The panel's EDID reports a 29x17 cm image size instead of 11x6 cm, so macOS treats it as a low-PPI monitor and does **not** offer HiDPI by default. Apple Silicon generally refuses HiDPI modes on sub-4K panels ([BetterDisplay wiki](https://github.com/waydabber/BetterDisplay/wiki/MacOS-scaling,-HiDPI,-LoDPI-explanation), [scaled-res guide](https://github.com/bbhardin/A-Guide-to-MacOS-Scaled-Resolutions)). Option-clicking "Scaled" in Displays settings shows any hidden modes ([Plugable](https://plugable.com/blogs/news/how-to-change-display-resolutions-on-your-mac-and-access-the-hidden-options)). **BetterDisplay** can add a 640x360 HiDPI mode. That mode is pixel-exact (a 2x render into the native 1280x720 framebuffer) and so is the sharpest option, but it is optional.

Reviews confirm the 5" 720p panel and describe it as a secondary display for glanceable things like a clock or reminders. None discuss scaling ([AppleInsider](https://appleinsider.com/articles/25/08/04/wokyis-m5-dock-review-mac-plus-looks-m4-mac-mini-performance), [HotHardware](https://hothardware.com/news/macintosh-style-retro-dock-turns-m4-mac-mini-all-in-one)).

| Mode | CSS viewport (borderless fullscreen) | devicePixelRatio | 1 CSS px |
|---|---|---|---|
| 1:1 default | 1280x720 (about 1280x696 if the per-display menu bar is visible and not covered) | 1 | 0.086 mm |
| HiDPI (BetterDisplay) | 640x360 | 2 | 0.173 mm |

Chrome `--app` also loses about 28 px to a title bar.

## 2. Hit targets and type
- Apple HIG: 44x44 pt for touch, with a smaller minimum on macOS for pointers ([HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)). WCAG **2.5.8 (AA): 24x24 CSS px**, and **2.5.5 (AAA): 44x44 CSS px** ([2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum), [2.5.5](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced)). Both assume the reference pixel (about 0.26 mm at 71 cm), so 44 px is about 11 mm in real life. At 1:1 here, 44 px is only 3.8 mm, which is too small.
- **Fitts's law** (MT = a + b·log2(D/W+1)): the mouse moves through *pixels*, not millimetres. Motor difficulty therefore depends on px size, so 104 px on the Wokyis is as easy to hit as 104 pt on the Studio Display. *Seeing* the target depends on mm and visual angle, and the cursor itself is physically tiny here. Pick the larger of the two constraints. The result is 9–12 mm targets, at most 4–5 per row (the screen is only 62 mm tall). This also suits the ADHD goal of minimal choices. Make the whole tile clickable, not just its label.
- **Text:** critical print size for fluent reading is an x-height of about **0.2°** ([Legge & Bigelow 2011](https://legge.dl8.umn.edu/sites/legge.psych.umn.edu/files/2020-08/Legge%20Bigelow%202011%20Does%20size%20matter%20for%20reading%3F%20A%20review%20of%20findings%20from%20vision%20science%20and%20typography.pdf), [Legge & Cheung 2004](https://legge.dl8.umn.edu/sites/legge.psych.umn.edu/files/2020-08/Legge%20Cheung%202004%20Psychophysics%20of%20reading-%20Implications%20for%20displaying%20text.pdf)). At 70 cm that is about a 2.4 mm x-height, or about a 4.9 mm font-size for a typical sans.
- **Type scale (ratio 1.333, use 3–4 steps only):**

| Role | mm | 1:1 px | HiDPI px | vh |
|---|---|---|---|---|
| caption (floor) | 3.7 | 42 | 21 | 6 |
| body/label | 4.9 | 56 | 28 | 8 |
| status word | 6.5 | 75 | 38 | 10.5 |
| heading | 8.7 | 100 | 50 | 14 |
| hero (time/arc label) | 11.5 | 133 | 67 | 18.5 |

## 3. Kiosk plumbing
| Option | Pinned to display | Borderless | Notes |
|---|---|---|---|
| Chrome `--app=URL --window-position=X,Y --user-data-dir=…` | yes, by coordinates | no (title bar) | Coordinates break if displays are rearranged |
| Chrome `--kiosk` | unreliable on macOS | yes | Uses a fullscreen Space and may land on the main display; the flag is ignored if Chrome is already running ([chromium-discuss](https://groups.google.com/a/chromium.org/g/chromium-discuss/c/iF9_3pY18_E)) |
| **Swift WKWebView app (about 80 lines)** | **yes, by `NSScreen.localizedName == "Wokyis"`** | **yes** | Re-pins on `didChangeScreenParametersNotification`. `.accessory` activation policy (no Dock icon), `canJoinAllSpaces`/`stationary`. JS↔native bridge. LaunchAgent for login |
| Plash | yes, one display | yes, wallpaper level | Clicks need "browsing mode". Can't do hotkey or native capture ([Plash](https://sindresorhus.com/plash)) |
| Übersicht | widget on a display | yes | Desktop level. Clicks are limited. Brings its own ecosystem |
| Hammerspoon `hs.webview` / window rules | yes | yes | Good, but adds a Lua runtime |

**Recommendation: the Swift app.** It is the only option that is borderless, identifies the display by name, stays at 0 overhead when idle, and has file, Reminders and hotkey access without a local server. Node and Python are not installed. Build with `swiftc main.swift -o Lighthouse`.

## 4. Claude Code hooks ([docs](https://code.claude.com/docs/en/hooks))
**Common stdin fields:** `session_id`, `transcript_path`, `cwd`, `permission_mode`, `hook_event_name` (plus `prompt_id`, `effort`, and `agent_id`/`agent_type` inside subagents).

| Event | Extra fields | Status |
|---|---|---|
| `SessionStart` (matchers `startup\|resume\|clear\|compact\|fork`) | `source`, optional `model`, `session_title` | idle/new |
| `UserPromptSubmit` | `prompt`, `session_title` | **working** |
| `PreToolUse` | `tool_name`, `tool_input`, `tool_use_id` | working (heartbeat) |
| `Notification` | `message`, `title`, `notification_type` | `permission_prompt`, `elicitation_dialog`, `agent_needs_input` = **needs input**. `idle_prompt` = waiting. `agent_completed` |
| `Stop` | `stop_hook_active`, `last_assistant_message`, `background_tasks`, `session_crons` | **finished**. Does not fire on user interrupt. API errors fire `StopFailure` instead |
| `SubagentStop` | `agent_id`, `agent_type`, `agent_transcript_path`, `last_assistant_message` | subagent done |
| `SessionEnd` (matcher = reason `clear\|resume\|logout\|prompt_input_exit\|other`) | `reason` | gone. 1.5 s budget |

Also useful: `PermissionRequest`, `StopFailure`, `PostToolUse`.

**Hook command** (identical for every event):
```sh
mkdir -p ~/.lighthouse && jq -c '{t:now, src:"claude", ev:.hook_event_name, sid:.session_id, cwd:.cwd, n:(.notification_type//null), msg:(.message//null)}' >> ~/.lighthouse/events.ndjson
```
**`~/.claude/settings.json` snippet:**
```json
{ "hooks": {
  "SessionStart":     [{"hooks":[{"type":"command","command":"<CMD>","async":true}]}],
  "UserPromptSubmit": [{"hooks":[{"type":"command","command":"<CMD>","async":true}]}],
  "PreToolUse":       [{"matcher":"*","hooks":[{"type":"command","command":"<CMD>","async":true}]}],
  "Notification":     [{"matcher":"permission_prompt|idle_prompt|elicitation_dialog|agent_needs_input","hooks":[{"type":"command","command":"<CMD>","async":true}]}],
  "Stop":             [{"hooks":[{"type":"command","command":"<CMD>","async":true}]}],
  "SubagentStop":     [{"hooks":[{"type":"command","command":"<CMD>","async":true}]}],
  "SessionEnd":       [{"hooks":[{"type":"command","command":"<CMD>"}]}]
}}
```
As an alternative, `{"type":"http","url":"http://127.0.0.1:7777/hook"}` POSTs the same JSON. It fails non-blocking if the server is down. The Grok Bot should append the same NDJSON shape with `src:"grok"`.

**Desktop app vs CLI:** the Desktop app and VS Code run Claude Code through the Agent SDK and read the same settings files. Differences: `permission_prompt` fires about 6 s after the request (it can be disabled with `CLAUDE_CODE_DISABLE_PERMISSION_PROMPT_NOTIFY_HOOKS=1`). Async hook output appears only on the next turn.

**Local state:** `~/.claude/settings.json` **does not exist** (there is also no `settings.local.json`), so no hooks are configured yet.

## 5. Day arc
**SunCalc** `https://cdn.jsdelivr.net/npm/suncalc@1.9.0/suncalc.js` (3.3 KB gz, global `SunCalc`; [repo](https://github.com/mourner/suncalc)). Call `SunCalc.getTimes(date, 47.61, -122.33)` to get sunrise, sunset, dusk and goldenHour. It works offline and needs no key. Vendoring it inline is better than a CDN request. [Open-Meteo](https://open-meteo.com/en/docs) (`daily=sunrise,sunset&timezone=America/Los_Angeles`) is keyless too. A live check returned 07:47 / 17:57 for 2026-10-28, but it adds a network dependency for no gain.

## 6. Capture
| Option | Friction | Notes |
|---|---|---|
| **Local `~/Inbox/inbox.md` via the WKWebView bridge** | lowest | Instant, offline, greppable |
| Apple Reminders: `osascript -e 'tell application "Reminders" to make new reminder at end of list "Inbox" with properties {name:"…"}'` | low | One-time Automation prompt. Syncs to iPhone |
| Shortcuts: `shortcuts run "Capture" <<< "text"` | low | Flexible, but slower to start |
| Things `things:///add?title=…` / Todoist `todoist://addtask?content=…` | medium | Needs the app installed. Neither is installed here |

**Hotkey:** the Swift app registers ⌃⌥Space with Carbon `RegisterEventHotKey`, which needs no Accessibility permission. The hotkey activates the app, shows a single input on the Wokyis, saves on Enter, then hides and restores focus. Esc cancels. Hammerspoon `hs.hotkey`, Raycast or a Shortcuts keyboard shortcut also work. **Default:** write to the local file, with a setting to also send to Reminders.

## 7. Motion
| Option | Size (gz, measured) | Engine | Idle |
|---|---|---|---|
| **CSS `linear()` spring + transitions / View Transitions** | 0 | compositor | 0% when nothing animates |
| Motion `mini` (`https://cdn.jsdelivr.net/npm/motion@13.4.6/mini/+esm`) | about 2–3 KB (per [motion.dev](https://motion.dev/docs/quick-start)) | WAAPI (compositor) | 0% |
| Motion full `https://cdn.jsdelivr.net/npm/motion@13.4.6/dist/motion.js` (2026-09-29) | 49 KB | WAAPI + JS springs | 0% |
| GSAP `https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js` (2026-04-13), plus `…/SplitText.min.js` (7.7 KB raw) and `…/ScrambleTextPlugin.min.js` | 28 KB | rAF ticker (main thread) | ticker auto-sleeps |
| anime.js `https://cdn.jsdelivr.net/npm/animejs@4.5.0/dist/bundles/anime.umd.min.js` (2026-06-22) | 41 KB | rAF | sleeps when idle |

**Recommendation: CSS.** Generate a spring with a `linear()` generator and keep it in a custom property, for example `--spring: linear(0, 0.6 18%, 1.05 38%, 0.99 60%, 1)`. Animate only `transform` and `opacity`, and use View Transitions for state swaps. To idle at 0% CPU:
- Use no `infinite` animations and no `setInterval`.
- Update the day arc with one `setTimeout` aligned to the minute, and watch the NDJSON file natively.
- Avoid `backdrop-filter` and large blurs.
- Honour `prefers-reduced-motion`.

A WKWebView on an always-visible screen is never "hidden", so the page must enforce this itself.
