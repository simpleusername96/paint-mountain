---
type: evidence
status: archived
created: 2026-08-06
last_reviewed: 2026-08-06
topic: baseline UI quality in the current running build
scope: Korean 1280x720 main menu, stage selection, briefing, Aim Lock, Map Inspection, pause, and settings
source: production-style Windows export from commit 66ae8b6 plus the preserved current dirty worktree
related:
  - ../execplans/2026-08-06-fast-stage-entry-and-fire-capacity.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../../docs/source-brief.md
  - ../../docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png
---

# Running-Build UI Quality Audit

## Purpose

Evaluate the current player-facing interface from fresh running-build images,
separate visible defects from transient loading or broader camera-composition
work, and define the small repairs that belong in the active ExecPlan. This
report is evidence for that plan update; it is not an implementation claim.

## Sources

- Fresh 1280x720 Korean captures created on 2026-08-06 from the exported
  `builds/windows/PaintMountain.exe` through the Windows Compatibility renderer.
- The current UI scenes, scripts, translations, shared Theme, application
  navigation, HUD state presentation, and camera bookmarks.
- `.agents/design/DESIGN.md` and `.agents/design/UIUX_GUIDELINES.md`, especially
  the mountain-first hierarchy, 24 px safe edge, Korean fit, visible focus,
  minimum target size, and no-overlap rules.
- `docs/source-brief.md`, including the later all-open thirty-stage requirement.
- The visual reset image at
  `docs/handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png`
  as a hierarchy and mountain-dominance comparator, not as a literal component
  specification.

The export included unrelated preserved worktree changes. No implementation file
was changed for this audit. The first three capture states settle for only 42
render frames, while current cold Stage 01 preparation takes several seconds;
they therefore document the real loading surface, not the settled menu mountain.
Briefing and gameplay captures wait for an active prepared stage. This audit did
not exercise English, open dropdowns, hover/pressed states, fullscreen-on,
failure/retry, or every resolution.

## Step-by-Step Evidence

| Step | Fresh evidence | Health | Observed result |
| --- | --- | --- | --- |
| 1. Main menu | [01-main-menu.png](ui-quality-audit-2026-08-06/01-main-menu.png) | Needs polish | Focus and action hierarchy are clear, but the Korean subtitle leaves an orphaned `세요.` line and the production surface still shows `VERTICAL SLICE · GODOT 4`. The absent mountain is a captured loading state, not proof of the settled preview. |
| 2. Stage Select, page 1 | [02-stage-select-page-1.png](ui-quality-audit-2026-08-06/02-stage-select-page-1.png) | Blocked | Only Stages 01-10 are visible. No Previous, Next, page count, or range appears despite a large empty footer area. |
| 3. Stage Select, forced page 2 | [03-stage-select-page-2.png](ui-quality-audit-2026-08-06/03-stage-select-page-2.png) | Blocked | Stages 11-20 exist and render when the capture API sets the page directly, but the player-facing pager remains absent. This confirms a navigation defect rather than a ten-stage catalog. |
| 4. Briefing | [04-stage-briefing.png](ui-quality-audit-2026-08-06/04-stage-briefing.png) | Needs follow-up | The primary `조준 시작` action and focus are clear, with no panel collision. Stage 01 occupies only about one third of the viewport width, so the mountain is not visually dominant. This is a camera/framing concern, not a safe generic UI quick fix. |
| 5. Aim Lock | [05-aiming.png](ui-quality-audit-2026-08-06/05-aiming.png) | Needs repair | Fire is the sole primary and the edge HUD is coherent. Both 40 px power-step buttons render as blank white squares, and the four-second first-session hint lies over the cannon/muzzle and lower trajectory while touching Fire. |
| 6. Map Inspection | [06-map-inspection.png](ui-quality-audit-2026-08-06/06-map-inspection.png) | Needs follow-up | The mode switch is clear and Aim/Fire controls correctly disappear. Stage 01 again occupies only about one third of the width; that framing needs a separate camera-owner pass. |
| 7. Pause | [07-pause.png](ui-quality-audit-2026-08-06/07-pause.png) | Pass with polish | Continue is the sole primary, all targets are 48-56 px high, focus is visible, and Restart is correctly confined to Pause. The fixed 520 px panel leaves about 150 px of unused space below the last action. |
| 8. Settings from Pause | [08-settings.png](ui-quality-audit-2026-08-06/08-settings.png) | Needs repair | The Pause title and controls visibly bleed through the translucent Settings panel and two scrims stack. Korean mode still displays `MEDIUM`; the resolution display is mechanically uppercased. |

## Findings

### P1. Twenty of thirty stages are not discoverable through visible UI

`StageSelectScreen` intentionally pages ten cards at a time and calculates three
pages (`src/ui/screens/stage_select_screen.gd:8,121-148`). Its pager is created at
runtime, given center-bottom anchors, and then moved to absolute position
`(310, 664)` (`:55-76`). At 1280x720 the anchor base and position combine to put
the controls outside the viewport. The forced page-2 capture calls
`set_page_for_capture(1)` directly, which is why later stages can appear in
evidence although a player cannot see how to reach them.

Correction: retain ten-card pages, but make a scene-owned footer inside
`CardsPanel`. It must show localized Previous/Next actions and an explicit range
such as `1-10 / 30`, `11-20 / 30`, or `21-30 / 30`. The first/last action has a
clear disabled state, and mouse and keyboard users can reach every page.

### P1. Power-step controls have no visible glyph

The fresh Aim Lock image shows no discernible minus or plus inside either power
button. The source PNGs are white-only RGBA assets; unlike the gear button,
`scenes/ui/hud/aim_controls.tscn:64-97` does not tint them against the light
button surface. The controls are wired and meet the 40 px target requirement,
but their function is visually hidden.

Correction: reuse the gear control's navy icon tint for normal, hover, pressed,
and focus states, add a muted disabled tint, and provide localized
`파워 낮추기` / `파워 높이기` tooltips. Do not replace the approved assets or
change the input behavior.

### P1. The first-session help hides the launch origin

`FirstSessionHint` is a fixed 600x48 center-bottom panel at y=574-622 while Fire
starts at y=620 (`scenes/ui/hud/hud.tscn:50-56,150-168`). It visibly covers the
cannon/muzzle and lower trajectory for four seconds. The help is useful and its
timer is correct; its placement is not.

Correction: keep the help and timer, but place a compact wrapped hint in the
left rail below the interaction-mode toggle and above coverage. It must not
intersect the cannon, trajectory, Fire, coverage, or status card at 1280x720.

### P1. Settings does not suspend the parent Pause presentation

The gameplay branch of `AppRoot._show_settings()` says the paused parent should
be hidden, but executes `pass` (`src/app/app_root.gd:221-233`). Pause and Settings
therefore render both scrims, and the shared 96%-opaque panel lets Pause text
show through. Closing Settings also performs no gameplay focus restoration
(`:236-245`).

Correction: suspend only the Pause overlay presentation while Settings is open;
keep `StageController` paused. Closing or pressing Escape restores Pause and
returns focus to its Settings action. Do not globally change every panel's
opacity to hide the lifecycle error.

### P2. Settings exposes raw display values and an inert fullscreen combination

`SettingsScreen._add_options()` uppercases every stored option
(`src/ui/screens/settings_screen.gd:37-48`), so Korean shows `MEDIUM` and
`1920X1080`. The quality values have no localized display mapping. The resolution
setting is stored but not applied in fullscreen, and disabling fullscreen does
not apply the stored windowed resolution (`:89-100`).

Correction: keep `low`/`medium`/`high` metadata, display localized
`낮음`/`보통`/`높음`, and format resolutions with `×`. Disable Resolution while
fullscreen is active; on return to windowed mode, apply the stored resolution.

### P2. Menu and Pause contain avoidable layout residue

The main subtitle has enough content width to wrap only its last two Korean
syllables, and the bottom-right developer milestone label is not player-facing
product information (`scenes/ui/screens/main_menu.tscn:27-63,90-104`). The Pause
panel uses fixed `-260/+260` vertical offsets even though its children need much
less height (`scenes/ui/screens/pause_overlay.tscn:24-83`).

Correction: give the menu subtitle at least 420 px of content width without
changing its copy, remove the developer milestone label, and make the centered
Pause panel content-height-driven while retaining its 380 px width.

### Existing plan coverage: loading is real but already owned

Images 01-03 show disabled `지형 준비 중…` actions and no settled preview because
they capture the cold request before preparation completes. This is a real
multi-second loading experience, but the active plan already replaces runtime
generation with baked loading, requires under-three-second representative cold
entry, changes the copy to `스테이지 불러오는 중…`, and adds an explicit retry
state. The UI cleanup must not create a second loading owner or mislabel the
blank preview as permanent.

### Deferred: Stage 01 briefing and inspection framing

The mountain is visibly under-scaled in images 04 and 06. `CameraDirector`
reframes the full render bounds through `TerrainCameraFramer`, so blindly editing
one bookmark is not a safe generic UI adjustment. Keep this as a separate
camera-composition follow-up that checks the bounds/margin owner and more than one
stage; do not hide it by enlarging HUD panels or cropping the terrain.

## Positive Evidence

- Fire is the only aiming primary action, and Restart appears only in Pause.
- Aim and Fire hide in Map Inspection while the mode toggle remains visible.
- Primary and mode controls show the shared two-pixel focus ring.
- Gameplay controls use the 24 px edge and meet the 40 px minimum target size.
- Coverage, lower-left aim controls, right status, gear, and Fire preserve the
  intended edge hierarchy without covering the Stage 01 mountain in Aim Lock.
- Korean labels in the gameplay cards do not clip at 1280x720.

## Plan Boundary

The active ExecPlan now owns the seven bounded repairs above: visible stage
pagination, power-icon contrast/tooltips, first-session-hint placement, Pause to
Settings presentation/focus, localized Settings values/fullscreen resolution
state, main-menu residue, and content-fit Pause height. It does not authorize a
new theme, new assets, a screen redesign, camera-framing changes, a broad visual
matrix, or fine pixel-tolerance tests.
