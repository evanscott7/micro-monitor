# Design Spec: earthtone bento touch UI (from reference video)

Source: 197 frames at 10 fps (frame N ≈ (N-1)/10 s), plus stills t_6.5 / 7.0 / 8.0 / 9.0 / 9.5.
Colors were sampled with ffmpeg area-averaging (box average over 6–30 px) or dilation (peak value of small features).
**[OBS]** marks something measured or seen directly. **[INF]** marks an inference or a recommendation.

Video structure **[OBS]**: the clip is edited and loops. Frames 1–16 continue frames 105–128 (launcher closing). Frames 173–187 are a repeat of 61–75 (same pixels: tile samples are identical). Shots alternate between a warm, lifted medium shot (frames 1–60, 76–172, 188–197) and a darker, more saturated close-up (61–75, 173–187). The two gradings disagree, so they are used to cross-check each other.

Timeline map:
| Frames | Time | What happens |
|---|---|---|
| 1–16 | 0.0–1.5 s | Launcher closes (2nd half): chips leave, home fades in, green floods clock tile |
| 17–22 | 1.6–2.1 s | Launcher opens (CLAUDE card) with "CLACLAUDE" scramble |
| 23–40 | 2.2–3.9 s | Home idle (different camera angle, 00:29) |
| 44–48 | 4.3–4.7 s | Tap CLAUDE dock button → launcher opens |
| 49–55 | 4.8–5.4 s | Launcher at rest (CLAUDE card) |
| 56–60 | 5.5–5.9 s | Accordion swap CLAUDE → DESIGN |
| 61–75 | 6.0–7.4 s | Close-up: DESIGN card drains and shrinks, chips leave, green flood |
| 76–85 | 7.5–8.4 s | Home idle 00:25 |
| 86–91 | 8.5–9.0 s | **Settings menu cascade in** (the "0:08" moment) |
| 91–95 | 9.0–9.4 s | Menu at rest |
| 96–100 | 9.5–9.9 s | Menu cascade out, green re-flood |
| 101–128 | 10.0–12.7 s | Launcher at rest → full close sequence |
| 129–134 | 12.8–13.3 s | Launcher opens again (glitch) |
| 153–161 | 15.2–16.0 s | Tap CLAUDE → launcher opens (cleanest open sample) |

---

## 1. COLOR

### 1a. Camera grading model [INF]
- The black device bezel reads **#1E1510** in medium shots. Real black bezel ≈ #0A0A0A, so the medium-shot grade lifts blacks by about +20 R / +11 G / +6 B, which is warm. That lift is why every dark UI color looks brown or olive in those shots.
- In close-ups the lift is smaller: page background **#1D161E**, and the green tile is much more saturated (#06553D vs #21523D).
- Brights clip toward white and pink. The WiFi dot peaks at #A4D48D, and menu titles on terracotta peak at #D6BBE0.
- Correction rule I used: subtract about #0F0A06 from dark values, keep the hue, and boost chroma about 10–20% for greens. Light values (≥ #A0) are left almost as observed.

### 1b. Palette table

| Role | Observed (where) | Proposed screen value | Notes |
|---|---|---|---|
| Page background (aubergine near-black) | #21171F menu (t_9.5 / g_092); #1D161E close-up; #242021 launcher medium; #21171F under rows | **#17121C** | Grade lifts it. The violet cast (B > G) holds in every shot, so it is real |
| Raised app panel (lighter inset rect behind the tiles) | #251B24 | **#1C1622** | One step above the page |
| Dark tile surface (System, Calendar) | #211E21, #211B1F, #282226 | **#1F1A24** | Very low contrast vs bg (about +4–6 L) |
| Radio tile (green-gray) | #252928 | **#1C2421** | Slightly greener than the plain tiles |
| Weather tile (dim green) | #223933 / #233833 | **#173A2F** | A dim "secondary green" tile |
| Tile hairline border | ~+8–12 L above surface; green tile has a lighter top-edge highlight | **rgba(200,205,255,0.08)**; on green **#2F7056** at 1px | Thin, almost invisible, catches light on top edge |
| Gap / gutter color | #211D1D (dock gap) | = page bg | Gaps show the background |
| Forest-green tile, top-right (light side) | #165643 (medium); #06553D (close-up) | **#0F5E45** | Gradient runs from top-right (lighter) |
| Forest-green tile, top-left / mid | #21523D (medium) | **#0D5340** | |
| Forest-green tile, bottom | #1F4735 (medium) | **#0A3F31** | About 25% darker than top |
| Green tile "flash" peak during flood | #1C553E at frame 15 vs #224833 settled at frame 16 | +10% brightness overshoot | See Motion |
| Terracotta card, top-left | #C77C61 (g_052); #C87764 (g_062 close-up) | **#C9735A** | |
| Terracotta card, bottom-right | #C3705E | **#BE6651** | Subtle diagonal gradient, ~4% darker |
| Ink on terracotta ("CLAUDE", "ACTIVE · 01/06") | #3F181D | **#2A1117** | Oxblood-black, not pure black |
| Menu ramp 01 WIFI | #C7846E (t_9.5 and g_092 agree) | **#C47D63** | Peach-terracotta, hue ≈ 15° |
| Menu ramp 02 BLUETOOTH | #BB6A5B / #BC6A5C | **#B5634F** | hue ≈ 9° |
| Menu ramp 03 TERMINAL | #A7524B / #9F5046 | **#9E4A41** | hue ≈ 4° |
| Menu ramp 04 POWER | #863838 / #833637 | **#7D302F** | hue ≈ 0° (oxblood) |
| Menu ramp 05 VOLUME | #57232A / #452027 | **#4D1C23** | hue ≈ 352° (maroon) |
| Menu ramp 06 SYSTEM | #2B1C23 | **#251621** | hue ≈ 330°, nearly bg |
| Menu ramp 07 SERVICES (partly visible) | ≈ bg | = bg #17121C | The ramp converges on the background |
| Row separator | dark 1-sample gap #4D1E18 / #512D2F / #3C1B1E | page bg, 4–6px gap | The rows are separate rounded cards, not borders |
| Green list ramp (launcher) Design / Sound / Dock / Gallery / Games | medium: #244D36 / #26372D / #232726 / #201E20 / #252124; close-up: #054230 / #042822 / #11191B | **#0D4A36 / #123628 / #172722 / #1A1E21 / #1B1820** | Same idea as the menu ramp, green → bg |
| Periwinkle display text (clock, 16°, THU · W38) | #83A8E5, #7EA2D4 (on green) | **#8DB0F2** | Cool, survives the warm grade, so it is close to true |
| Periwinkle dim (clock in transparent / dark tile state) | #22598F, #26578F | **#2C5FA6** | About 55% of the bright value. Used mid-transition |
| Small label text (TIME · IDLE, WEATHER, SYSTEM, dock labels) | peak #77B0C8 on green (blended); bluish on dark | **#8DB0F2 at 80–85% opacity** | Same hue as display text, just dimmer |
| Text on terracotta rows (WIFI, BLUETOOTH…) | peak #D6BBE0 | **#EEE7FB** (lavender-white) | Titles at 100%, index "01" ≈ 40%, subtitle ≈ 55% |
| Mixed-case list labels on green (Sound, Dock) | cyan-periwinkle | **#8DB0F2 → #7FC0D8** | Reads cyan on green because of blending; use periwinkle |
| Red-orange LED / segment ON | #C97767, #C06B57, #C36B57; peak #CC7C71 | **#E06A4E** | Phone grade desaturates. Push chroma |
| LED OFF, weather row (teal) | #315D5C; peak #386260 | **#2B5A56** | Off dots are teal, not dim red |
| Segment meter OFF dots (dot-matrix field) | peak #2D272B over #282226 | **rgba(224,106,78,0.14)** ≈ #3A2228 | Barely visible red dots |
| Status dot top-right of clock tile | #4A8CA9 peak | **#4FA6C9** (teal-blue) | Small, ~6px |
| Green "online" dot (WiFi icon badge) | peak #A4D48D (clipped) | **#5FD07A** | Bright mint-green |
| Bluetooth "off" badge dot | ring with dark center, #CEC1E5 peak ring | lavender ring + #2A1117 center | |
| CLAUDE dock button dot | #BA705D | **#E06A4E** (LED red) | Marks the active app |
| Launcher row icons (Design ◇, Dock Ш, Sound ⎍) | #A6725A, #9B604E | **#D9734F** | Orange glyph icons on green rows |
| Card decor dot / signal-bars icon | #8B372C, #9F4A36 | **#9A3F31** | Darker red-brown details on terracotta |
| Outline-state card fill (transparent card) | #1E1921, #1F1A20 | bg + periwinkle 1px border at ~45% | With dot grid |

Ramp formula [INF]: the menu ramp is close to linear in lightness from #C47D63 to the background, with hue rotating from 15° to 330° through red. The same path appears in time when a card drains (§4). In CSS, `color-mix(in oklch, #C47D63, #17121C X%)` with X = 0, 12, 28, 45, 70, 92 reproduces it well. In practice oklch interpolation goes through red to violet on its own because the bg is violet.

---

## 2. TYPE

Overall [OBS]: two families. (A) an extended, square-geometric "Eurostile / Microgramma Extended" class, in Black for display and Regular/Bold for titles and labels. (B) a plain neo-grotesk for subtitles.

| Role | Examples | Weight | Width | Tracking | Case | Size (rel.) | Proposed Google Font |
|---|---|---|---|---|---|---|---|
| Huge display numerals | 00:25, 16°, THU · W38, CLAUDE, DESIGN | Black (~900) | Very extended: digit advance ≈ 1.25–1.3 × cap height | ~0 to +0.02em | Caps / figures | Clock cap height ≈ 13% of screen height | **Orbitron 900**. Alt: **Saira** variable at wdth 125 / wght 800 (check that the axis range is served) |
| Tiny tracked labels | TIME · IDLE, WEATHER, SYSTEM, CALENDAR, RADIO, TIMER, ACTIVE · 02/06, TAP TO OPEN, THURSDAY SEP 17, 55° · 7M, 21% | Bold (~700) | Extended | **+0.12–0.16em** | ALL CAPS, " · " middle-dot separator | ≈ 1/9 of clock cap height (≈ 9–11px at 720p) | **Michroma** (only weight, reads bold when small). Alt: Orbitron 600–700 |
| Menu titles | WIFI, BLUETOOTH, TERMINAL, POWER, VOLUME, SYSTEM, SERVICES | Regular / Light (~400) | Extended | +0.04–0.06em | ALL CAPS | ≈ 1/3 clock cap height | **Michroma** (exact genre: Microgramma Extended clone) |
| Menu index | 01 … 07 | Heavy (~800) | Extended | 0 | Figures | ~75% of title | **Orbitron 800** at ~40% opacity |
| Mixed-case list labels | Sound, Dock, Design, Gallery, Games, "Claude" chip | Regular (~400) | Extended | +0.02–0.04em | Sentence case | ≈ title size | **Michroma** (has lowercase). Lighter alt: **Jura 500** |
| Small subtitles | Shell access, Reboot / Shutdown, Master volume, Off, 49 | Regular (400) | Normal | 0 | Sentence case | ~70% of title | **Inter 400** (alt: Manrope 400) at ~55% opacity |

Glyph evidence [OBS → INF]:
- **"0"** in the clock: outer shape is a rounded rectangle (superellipse) with straight vertical sides. The counter is a narrow vertical slot about 30–35% of glyph width with squared ends. Strokes are nearly monoline and very heavy. That matches Eurostile Extended Black and Orbitron Black. It rules out Syncopate, Unbounded, Krona One and Audiowide, whose zeros are oval or round-ended.
- **"2"**: flat horizontal top bar into a rounded-square shoulder (no circular arc), then a short diagonal spine onto a flat full-width base. Orbitron and Microgramma "2" have the same square shoulder.
- **"5"**: flat top bar, vertical left stem, squared bowl with rounded outer corners. No curved entry stroke.
- **"W" in W38**: wide, sharp pointed vertices, outer strokes slightly angled, middle apex lower than cap height. **"3"** has a flat top (Microgramma style), **"8"** is two stacked rounded rectangles.
- Colon: two square dots, tightly spaced.
- Corners are **rounded, not chamfered**. That rules out Chakra Petch, Oxanium and Tektur, which are chamfered.
- "O" in BLUETOOTH / POWER is a wide rounded rectangle. "M" in TIME / TERMINAL has vertical outer stems. Both match Michroma.
- Subtitles show a normal-width grotesk with upright terminals ("Reboot / Shutdown"). Nothing quirky, so Inter fits better than Space Grotesk.
- Doto / Major Mono Display: no matching text was seen. The dot-matrix motif is drawn as graphics (LEDs, meter), not set as type.

---

## 3. SHAPE & TEXTURE

Proportions are measured on the angled screen, so they are approximate (±20%). Original screen ≈ square. For 1280×720, the px values below assume the 720 dimension maps to the original screen side.

- **Corner radii** [OBS]: big tiles and cards ≈ 3–3.5% of tile width (clock tile ~22 px on ~640 px displayed). Small tiles use about the same absolute radius, so radius is a constant, not proportional. Menu rows ≈ 2.5% of row width. Dock buttons are about half the tile radius.
  → [INF] `--r-tile: 16px; --r-row: 14px; --r-btn: 10px; --r-chip: 10px;`
- **Gaps** [OBS]: uniform gutters about 2% of screen width between tiles; menu and launcher rows sit 4–6 px apart (dark bg shows through).
  → [INF] `--gap: 10px` (tiles), `--row-gap: 5px`.
- **Outer frame**: tiles sit on a slightly lighter rounded panel (#1C1622) inset about 3% from the screen edge.
- **Hairlines**: 1 px, very low contrast (rgba(200,205,255,.08)). The green tile has a brighter 1 px top/left edge, like a lit bevel. Outline-state cards and chips use a 1 px periwinkle border at about 45%.
- **Dot-grid texture** [OBS]: on outline-state cards, the "Claude" chip, the shrunken list chips, and the dark clock tile. Square grid, pitch ≈ 1/40 of card width (≈ 8–10 px), dot ≈ 1–1.5 px, periwinkle at ~15–20% opacity. The dark clock tile has sparse scattered single dots instead of a full grid. They read like stars or registration specks, about 15 visible.
  → [INF] `background-image: radial-gradient(rgba(141,176,242,.18) 1px, transparent 1.5px); background-size: 9px 9px;`
- **Corner-bracket marks** [OBS]: L-shaped 1 px brackets (~10–14 px arms) at the corners of the clock tile. Clearly visible when the tile is in its transparent/dark state (t_7.0 top-left at "TIME · IDLE", bottom-left near the date, top-right near the status dot). They are hidden or very faint when the tile is green.
- **LED dot matrix (weather)** [OBS]: 2 rows × 6 round dots, offset half a pitch (hex-like stagger). Dot diameter ≈ 1/60 of screen width, pitch ≈ 1.6× diameter. The top row and the first dot of the bottom row are lit red-orange. The other 5 bottom dots are teal "off" dots. Reads as a 12-step bar with 7 lit. Lit dots have a soft glow (bloom ≈ 1 dot radius).
- **Segmented meter (system)** [OBS]: 5 lit rectangular segments (aspect about 1:1.3 w:h, 2 px dark gaps, small 1–2 px radius) in LED red. They continue into a dot-matrix "off" field of about 4 rows × 40 columns of tiny dim red dots that fades out to the right. The value "21%" sits at the bottom right and "55° · 7M" at the top right of that field.
- **Glitch pixel clusters** [OBS]: on terracotta cards, small clumps of dark pixel blocks (2–4 px squares) sit right of the title, with thin dashed crosshair lines and a tiny dot. Their shape changes between frames (61→64). [INF] Flickering decorative noise sprites.
- **Scanline / grain** [OBS]: a fine diagonal moiré over everything in the close-ups. [INF] This is almost certainly the LCD subpixel grid caught by the camera, not designed texture. Optional homage: 1 px horizontal scanlines at 3% opacity, or none.
- **Icons**: thin 1.5 px line glyphs (concentric WiFi target, bluetooth rune, `>_`, power, speaker) in lavender-white on the menu. Chunky pixel-ish orange glyphs (◇, Ш, ⎍, dotted square, pixel cluster) on launcher rows. Small status badge dots sit on the icons' top-right.
- **Radio tile**: a thin ring (~1/6 tile width) with a filled center dot (turntable / dial) and a "--" placeholder bottom-left.
- **Sheet handle**: a short periwinkle bar (~5% width, 3 px) at top center while the settings menu is open.

---

## 4. MOTION
Frame step = 100 ms, so every duration is ±50 ms. Curves are [INF] fits to the frame samples.

### 4.1 Settings menu cascade IN (frames 86→91), the "0:08" moment
Observed:
- **f86**: tap. Home is unchanged (green tile #0C6149 at the sample point).
- **f87**: row 01 WIFI appears **in place** at ~35% opacity (sample #605F4B = blend of green and #C7846E). Home starts dimming.
- **f88**: row 01 at 100%. Row 02 at ~55–60%, with its text **doubled** (a second copy offset about 1 character left/up). The green tile behind has darkened and desaturated. The clock digits still show through.
- **f89**: rows 01–03 solid, 04 at ~50% (POWER doubled, "00:26" visible through it), 05 faint.
- **f90**: rows 01–05 solid, 06 SYSTEM visible. Home gone.
- **f91**: settled. 07 SERVICES fades into bg at the bottom (partly offscreen).
- No visible translation of the rows beyond the text ghosting. Row edges sit at their final position from the first frame. Any slide is under ~1% of screen height.

Spec:
- Per row: `opacity 0→1`, **180 ms**, `cubic-bezier(0.22, 1, 0.36, 1)`. Optional `translateY(-6px)→0` (not visible, harmless).
- Stagger **55 ms** top→bottom, first row delayed about 60 ms after tap.
- Total ≈ 60 + 5×55 + 180 ≈ **515 ms** (observed full-stack-visible at ≈ 400 ms, settled by 500 ms).
- Text inside each row: a 2-frame ghost. Clone the label at 40% opacity offset `-0.6em` X, fade it out over 120 ms while the real label fades in. Or use a 150 ms scramble (see 4.6).
- Background: home layer `filter: saturate(0.3) brightness(0.6)` and `opacity → 0` over 200 ms, ease-out.

### 4.2 Settings menu cascade OUT (frames 95→100)
Observed: f96 rows 05–06 fading (VOLUME ghosted). f97 only row 01 solid, 02 ghost, home visible at ~70% with green returning. f98 row 01 at ~45%. f99 gone; tile green at ~85%. f100 fully green.
Spec: reverse order (bottom→top), stagger **45 ms**, each row 140 ms `cubic-bezier(0.5, 0, 0.75, 0)` (ease-in). Home fades back in parallel starting about 100 ms in, and the green flood (4.5) finishes at about 400 ms. Total ≈ **400 ms**.

### 4.3 Launcher OPEN (frames 44→48, 156→161; cleanest at 156–161)
Observed:
- **f157**: green tile drains (to ~40% in one frame), clock digits become dim. A small terracotta card (~45% of final width) appears in the **right column where the weather tile was**, title "CLA…" clipped at the tile edge.
- **f158**: home is a ghost: clock digits are outlines only (stroke, no fill), labels dim. The card is larger (~60%) at the right, "CLAUDE" crisp. The first green row "Design" appears under it as a small chip.
- **f159**: the card has jumped to the full-width top slot, still semi-transparent, with **double-exposed text** (CLAUDE + ghost offset). Green rows cascade in from the lower right, each offset further right and lower (Design, Sound, Dock), each with scrambled text and box glyphs ("□Dock").
- **f160**: card solid, rows 1–2 solid, rows 3–5 at 40–70%.
- **f161**: settled.

Spec:
- Home drain: `opacity` / `saturate` to 0 over **150 ms**, `cubic-bezier(0.4, 0, 1, 1)`.
- Card: FLIP from the launcher-tile rect to the top slot. `transform: translate+scale(0.45→1)` over **300 ms**, spring **stiffness 260, damping 28, mass 1** (ζ ≈ 0.87, almost no overshoot) or `cubic-bezier(0.16, 1, 0.3, 1)`. Opacity 0→1 in the first 120 ms.
- Rows: enter from `translate(+8%, +12%) scale(0.92)` to identity, opacity 0→1, **250 ms** `cubic-bezier(0.16, 1, 0.3, 1)`, stagger **70 ms**, starting about 100 ms after the card.
- Total ≈ **550–600 ms**.

### 4.4 Accordion swap (frames 56→58)
Observed: f57 is a crossfade. "CLAUDE" is doubled vertically (ghost one row above), the "Design" row is ghosted inside the card area, and the whole card moves down by one row height. f58 is settled: list order becomes Claude (row) / **DESIGN (card)** / Sound / Dock / Gallery / Games. The active item expands in place to about 2.3× row height. The old card collapses into a green row.
Spec: height and position via FLIP, **200 ms** `cubic-bezier(0.4, 0, 0.2, 1)`. Fill color crossfades from terracotta to green (and back) over the same 200 ms. The title crossfades with a ±8 px vertical offset. "ACTIVE · 01/06" → "02/06" updates instantly.

### 4.5 Green flood / drain (clock tile)
Observed tile-center samples:
- Close-up f71→75: #1D1B1E → #1E1E20 → #1E2A26 (≈15%) → #1D3E2D (≈45%) → **#06553D (100%)**. The curve **accelerates**.
- Medium f12→16: #252527 → #233128 (~25%) → #264132 (~55%) → **#1C553E (peak)** → #224833 (settled, slightly darker). That is an **overshoot flash of about 10%**, then settle.
- Drain (f44→46): #22513B → #253A2E (~40%) → bg. Fast, ease-out.

Spec:
- Flood: `background-color`/`opacity` of the green layer, **300 ms**, `cubic-bezier(0.55, 0, 0.85, 0.35)` (ease-in), then `filter: brightness(1.12)→1` over **150 ms** ease-out. Read it as "power-on".
- Stagger the other tiles about 50 ms behind: the weather tile's dim green, the segment bar lighting up (f14), the LED dots.
- Drain: **150–200 ms** `cubic-bezier(0.2, 0, 0, 1)`.

### 4.6 Text scramble / ghosting [OBS]
Seen during every state change:
- "CLACLAUDE" (f17, f129): the new string overprinted while the old partial string is still visible.
- "Claudede" (t_6.5, f63–65): trailing leftover glyphs.
- "DESIGNN" / "DESIGN▒" (f66–68): an extra smeared final glyph.
- "□Dock" and "▯Sound" (f7, f13, t_7.0): tofu or box placeholder glyphs before the real ones.
- Doubled labels offset by about 1 character during fades (menu rows).

Spec: a left→right reveal. Each character position cycles through 1–3 random glyphs from {▯ □ ▮ ▚ █} plus random caps, at 33 ms per tick, and resolves with a 25 ms per-character stagger. Total about 200–300 ms. A trailing ghost copy of the old string at 35% opacity, offset `+0.5–1em` X, fades over 150 ms. Keep it under 300 ms so it reads as texture, not loading.

### 4.7 Card drain and shrink (launcher close), frames 61→75 and 105→128 / 1→16
Card fill over time (close-up, sample tracks the card):
f62 #C87764 → f66 #AF584D → f67 #94545A → f68 #762D33 → f69 #481F25 → f70 #2A1721 (≈ bg). The hue walks **terracotta → crimson → wine → aubergine**, the same path as the menu ramp (01→06).

Sequence:
1. **0–500 ms** (f105–110 / f62–67):
   - The card desaturates along that path.
   - Its ink text **inverts** to periwinkle-white with a glitch smear.
   - The card **shrinks** (scale about 1 → 0.55) and slides toward the right/top-right "launcher slot".
   - Green rows shrink into bordered dot-grid **chips** and move up and right in single file, like a conveyor queue along a diagonal.
   - The "Claude" chip at the top right gets ghosted text.
2. **500–1000 ms** (f68–70 / f110–116):
   - The card becomes outline-only: transparent with a periwinkle hairline, a dot grid, and light text.
   - Home clock digits appear as dim blue (#2C5FA6), first as outlines and then filled.
   - Tile labels and the corner brackets fade in.
3. **1000–1300 ms**: the chips slide out one by one, about 100 ms apart, to the right and offscreen. Weather LEDs and labels fade in.
4. **Last 300–450 ms**: the green flood (4.5), and the segment bar lights.

Spec: total about **1.4 s** in the close-up. The edited medium shot stretches to about 2.4 s, because frames 105–128 then 1–16 are one continuous take with a long chip queue.
- Color: `background-color` keyframes through the ramp values, 500 ms, `cubic-bezier(0.45, 0, 0.55, 1)`.
- Shrink/move: 600 ms spring, **stiffness 170, damping 26** (ζ ≈ 1, no bounce).
- Chips: 350 ms each, `cubic-bezier(0.65, 0, 0.35, 1)`, stagger 90–110 ms.
- Home fade-in: starts at 400 ms, 400 ms `cubic-bezier(0.22, 1, 0.36, 1)`.

### 4.8 Global motion character [INF]
- No bounce anywhere. Springs are near critically damped. Overshoot appears only as a **brightness** flash, never in position.
- Exits are slower and more cinematic than entries (≈1.4–2.4 s vs ≈0.5 s). That suits an ambient display.
- Opacity-led motion, with small positional travel (≤ 10% of screen) except FLIP morphs between slots.
- Suggested tokens:
  - `--ease-out: cubic-bezier(0.22,1,0.36,1)`
  - `--ease-in: cubic-bezier(0.5,0,0.75,0)`
  - `--ease-io: cubic-bezier(0.45,0,0.55,1)`
  - `--ease-expo: cubic-bezier(0.16,1,0.3,1)`
  - `--ease-flood: cubic-bezier(0.55,0,0.85,0.35)`
  - `--stagger: 55ms`
  - `--dur-fast: 150ms; --dur-base: 250ms; --dur-slow: 500ms`

---

## 5. LAYOUT & COMPONENT INVENTORY

### Home bento (square original; estimated grid) [OBS]
Proportions are approximate fractions of the screen side:
```
┌──────────────────────────┬──────────┐
│ CLOCK TILE (green)       │ WEATHER  │  top band ≈ 55% height
│ ~66% w                   │ (dim grn)│
│                          ├──────────┤
│ 00:25                    │ RADIO    │
├──────────────────────────┤          │
│ SYSTEM (dark)            ├──────────┤
│ ▮▮▮▮▮·········  21%      │ CALENDAR │
├─────┬─────┬─────┬────────┤ THU·W38  │
│TIMER│RADIO│PAINT│ CLAUDE │   SET    │  dock ≈ 15% height
└─────┴─────┴─────┴────────┴──────────┘
```
[INF] For 1280×720, keep the left "hero" column at about 62% width (clock + system + dock) and a right column of 3 stacked tiles. Or widen into a 4-column bento: clock 2×2, weather, radio, system 2×1, calendar, dock full width.

### Components
1. **Clock hero tile**:
   - Green gradient fill and 1 px top highlight.
   - Label "TIME · IDLE" at top left (tracked caps).
   - Status dot top right (teal-blue).
   - Huge periwinkle HH:MM bottom left, overflowing close to the tile edge.
   - Date "THURSDAY SEP 17" under the digits (tracked caps).
   - Corner brackets and scattered dots appear in the dark/transparent state.
   - States: green (idle), dark outline (transition / background).
2. **Weather tile**: dim green. Label "WEATHER". 2×6 staggered LED dot row (lit red / off teal). Temperature "16°" in display font, periwinkle.
3. **Radio tile**: green-gray. Label "RADIO". Ring dial icon at center. "--" station text.
4. **System tile**: dark. Label "SYSTEM". 5-segment red bar, then a dim dot-matrix field. Meta line "55° · 7M" and a percentage "21%".
5. **Calendar tile**: dark. Label "CALENDAR". "THU · W38" in heavy display periwinkle.
6. **Dock button** ×5:
   - Rounded rect, dark fill, hairline border.
   - Centered icon: ring (timer), filled periwinkle dot (radio), two linked rings (paint), **red LED dot** (CLAUDE, the active app with a slightly greener fill), ☰ (SET).
   - Tracked-caps label **below** the button, outside it.
7. **Launcher card (active app)**:
   - Terracotta gradient.
   - "ACTIVE · 01/06" top left in ink.
   - Huge app title (CLAUDE / DESIGN) in Black extended ink.
   - "TAP TO OPEN" under the title.
   - Glitch pixel clusters with a dashed crosshair at center right, a dot at top right, signal-bars icon at bottom right.
   - About 2.3× row height. Outline variant: transparent, periwinkle border, dot grid, light text.
8. **Launcher list row**: green ramp fill (darker per index), orange pixel glyph icon at left, mixed-case extended label. The rows form a stack under the card (Claude / Design / Sound / Dock / Gallery / Games).
9. **List chip** (transitional): small rounded rect, 1 px periwinkle border, dot grid, icon and label. This is what rows shrink into.
10. **"Claude" pill chip** (t_6.5): outline chip with dot grid, a circular logo glyph, and a mixed-case label. Sits at the top right as a docked or minimized app.
11. **Settings sheet**:
    - Pull-down from the top, with a periwinkle handle bar at top center.
    - Stacked full-width rows on the terracotta→maroon ramp.
    - Each row: line icon with status badge dot, index "0N" (heavy, 40%), CAPS title (extended light, lavender-white), subtitle (grotesk, 55%), chevron "›" at the right end.
    - Rows: 01 WIFI "49", 02 BLUETOOTH "Off", 03 TERMINAL "Shell access", 04 POWER "Reboot / Shutdown", 05 VOLUME "Master volume", 06 SYSTEM, 07 SERVICES.
12. **Indicators**: LED dot (red), status dot (teal-blue), online badge (mint-green), off badge (lavender ring), segment bar, dot-matrix field, signal bars.

### Observed vs inferred summary
- Observed: every hex in the "Observed" column, frame-by-frame states, row order and labels, which elements double or ghost, the accelerating flood with overshoot, and that rows fade in place.
- Inferred: corrected screen colors, font matches (no font was identified with certainty), exact px radii and gaps (from foreshortened measurements), easing curves and spring constants (fit to 100 ms samples), and that the moiré comes from the LCD and not the design.
