---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-07
canonical_for: Paint Mountain player-facing UI, HUD, menu, typography, and interaction presentation
scope: HUD, menus, settings, results, layout, copy, localization fit, icons, focus, and visible interaction states
source: ../../docs/source-brief.md
related:
  - DESIGN.md
  - ART_DIRECTION.md
  - VISUAL_REFERENCES.md
  - ../../docs/design-spec.md
  - ../../docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png
  - ../execplans/2026-08-03-gameplay-visual-reset.md
  - ../execplans/2026-08-06-wind-driven-coverage-loop.md
  - ../execplans/2026-08-06-command-columns-hud.md
  - ../execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../../resources/ui/paint_mountain_theme.tres
---

# Paint Mountain UIUX Guidelines

## Purpose

Define a clean Korean-first interface that supports aiming and reading the live
3D puzzle without competing with it. The mountain remains primary; HUD and menus
make state and the next action obvious with minimal visual weight.

## Scope

This spec governs HUD and menu hierarchy, layout, components, typography, copy,
localization fit, icons, focus, interaction states, and player-facing feedback.
It does not own stage rules, coverage calculation, trajectory physics, or paint
state.

## Product Feel

- Sparse, edge-aligned, high-contrast, and calm.
- Functional rather than dashboard-like: no card mosaic, decorative glass,
  filler metrics, or unsupported actions.
- Tactile primary actions with restrained secondary surfaces.
- Korean-native rather than an English layout with translated strings forced
  into it.

## Requirements

### Aiming HUD hierarchy

The user-selected `command-columns-hud.png` is the current aiming-HUD visual
direction. Use its narrow left command column, narrow right status column,
restrained warm surfaces, centered Fire action, and compact typography rhythm.
The generated still does not remove real controls or state: Gear remains beside
the right rail, and direction, power steps, dynamic wind detail, focus, disabled
states, and Map Inspection remain supported.

At the 1280x720 logical baseline, preserve this relative hierarchy:

| Element | Placement | Contract |
| --- | --- | --- |
| Stage card | Upper-left | Primary stage identity |
| Interaction-mode chip and toggle | Below Stage | Shows `Aim Lock` or `Map Inspection`; the focusable toggle and Tab switch modes |
| Time, shots, activity, wind, Finish, and Gear | Edge-aligned status area | Readable run state without covering the mountain; Gear remains the menu action |
| Coverage gauge | Left edge | Sole coverage display; target-area coverage fills bottom-to-top and shows target |
| Aim and power | Lower-left | One coherent control group |
| Fire | Bottom-center | Sole primary action |

- Use the active ExecPlan's current baseline rectangles while implementing the
  approved layout, but do not promote those task coordinates into permanent
  design tokens.
- Use a 24 px logical safe margin and anchors/containers so this hierarchy
  survives supported desktop aspect and resolution changes. Do not freeze every
  child to viewport offsets.
- Keep one Fire control. Do not place Restart in the aiming HUD.
- Do not expose Follow, Wide, Cannon, gameplay speed, or gameplay Pause strips.
- Keep the top-center and center of the world view free of duplicate status
  cards, and keep visible mountain routes free of
  persistent panels, explanatory text, or modal overlays.
- Trajectory and impact feedback belong in world space; the HUD must not pretend
  to predict post-impact paint.

### Aim Lock and map inspection

- Gameplay remains in the aiming Board Phase while the player switches between
  `Aim Lock` and `Map Inspection`; this is a presentation/input state, not a
  separate stage flow.
- In Aim Lock, the authored aiming view is restored when its safe frame already
  contains the exact playable-top points, summit headroom, cannon, and muzzle.
  Otherwise the camera receives one deterministic same-direction, same-FOV
  distance correction while retaining the authored focus; prediction changes
  never move it. Left drag adjusts yaw/elevation, the wheel adjusts power,
  keyboard aiming and Fire are enabled.
- In Map Inspection, terrain click changes the inspection focus, left drag
  orbits the safe camera, the wheel zooms, and aim and Fire input are blocked.
- Tab and one visible focusable toggle switch modes without changing the stored
  aim or preview. The first-session hint and toggle tooltip state the shortcut
  and the active mouse behavior.
- Wind is a concise status cue, not a decorative mystery: show the direction
  projectiles are pushed, strength, time until change, and the approaching
  direction during the transition. Leaves or debris are supporting world
  feedback only.
- Finish is unavailable until the first actual launch. Target coverage and spent
  shots do not force an outcome; time expiry or Finish ends the run.

### Navigation and pause

- Gear and Escape open the same full-viewport paused input barrier.
- The paused game menu contains Continue, Restart, Settings, Stage Select, and
  Main Menu.
- Settings opens as a child of that paused flow and returns to the paused menu.
  Settings never contains Restart.
- Restore the exact pre-pause state on Continue; the menu must not advance the
  simulation or leak input into aiming.
- Clear and failure screens expose only actions supported by the current game
  state and make Retry unambiguous.

### Component contracts

- HUD components display authoritative state and emit typed intent. They do not
  calculate coverage, mutate paint, advance stage state, or own launch physics.
- Time, resident-ball activity, wind, interaction mode, and Finish availability
  are displayed from their authoritative owners. The HUD does not run a second
  timer, wind schedule, or camera/input state machine.
- Target Coverage means unique painted Target Area texels divided by all Target
  Area texels. Valid non-target top paint remains visible but is not scored; the
  dry Target Area cue and HUD copy `목표 영역`/`TARGET AREA` make that boundary
  clear. Its percentage, rail, and target marker must agree.
- Shots, target, angle, power, and Fire validity update from their authoritative
  owners without duplicated formulas.
- Icons supplement meaning. Rare, destructive, or menu actions retain visible
  Korean labels; icon-only controls require an accessible name and clear focus
  treatment.
- Disabled, hover, pressed, focused, selected, paused, clear, and failed states
  remain visually stable. Do not communicate a state by color alone.
- Repeated presentational structures use shared component scenes. A scene that
  composes a component may set its supplied text, value, visibility, and layout;
  it must not copy the component's font, color, radius, border, or interaction
  state styling.
- `HUDController` owns whole-HUD state presentation and signal coordination.
  Child component scripts own only their displayed structure and narrow intent;
  no component reads a gameplay singleton to reconstruct authoritative state.

### Layout and tokens

- `resources/ui/paint_mountain_theme.tres` is the implemented token owner. Reuse
  its shared Theme and components instead of constructing StyleBoxes or palette
  constants in scripts.
- Current UI roles are warm surface `#FFFDFC`, navy text/dark surface `#172538`,
  primary blue `#2584FF`, muted progress rail `#C9CDD2`, and danger `#D94C4C`.
- Panels use the established restrained 12 px radius; primary actions use 16 px.
  Do not add nested bordered/background containers beyond two visible levels
  without a clear containment reason.
- Pretendard Variable weight and size roles are Theme-owned semantic type
  variations: `HudCaption` is 14 px/500, `HudBody` 16 px/500, `HudSection`
  18 px/600, `HudValue` 22 px/600, `HudMetric` 28 px/600,
  `PrimaryButton` 20 px/600, and `ScreenTitle` 32 px/700 at the logical
  baseline. Default body copy remains at least 16 px. Scale hierarchy
  intentionally rather than shrinking text to fit.
- Theme variations own reusable font, weight, size, color, panel, button,
  separator, icon-state, and focus decisions. Scene-level overrides are for
  layout-only margins, gaps, anchors, and exceptional geometry; do not repeat
  palette or type roles in each HUD scene.
- Interactive controls are at least 40 px high; primary, mobile-equivalent, or
  high-importance targets prefer 44-48 px or larger.
- Keyboard focus uses the shared visible 2 px accent treatment.
- Align rows by a deliberate center, baseline, or edge. Keep label-to-value gaps
  tighter than gaps between component groups.

### Copy, typography, and localization

- Pretendard is the shared project font and must be loaded through the Theme.
- Korean is the default locale; English remains switchable and persistent.
- Store translation keys rather than visible display text in gameplay Resources.
- Use short, direct Korean gameplay terms. Avoid design commentary, tutorial
  filler, and obsolete payload-language.
- Check every visible Korean label for clipping, overlap, awkward forced wrap,
  and insufficient button width. Do not solve text fit by making essential text
  unreadably small.

## Acceptance Criteria

A UI change conforms when:

- the mountain remains the dominant visual and Fire is the unmistakable next
  action during Aim Lock;
- Aim Lock and Map Inspection make their active input behavior clear, and Tab
  or the visible toggle returns between them without losing the current aim;
- the left vertical coverage gauge, lower-left controls, edge status, top-right
  gear, and bottom-center Fire preserve the specified hierarchy;
- aiming contains no Restart or duplicate Fire action;
- gameplay contains no ambiguous camera presets, time-scaling strip, or duplicate
  pause action;
- Korean and English labels fit without clipping at supported desktop sizes;
- all reachable controls expose stable enabled, disabled, hover, pressed, and
  keyboard-focus states;
- no panel overlaps another, escapes its container, hides fixed content, or
  blocks the world-space impact point; and
- every visible action is connected to real functionality.

Every substantial UI or visual-composition change requires direct inspection of
the actual running-game render before handoff. Headless contracts and scene
inspection are supporting evidence only. Use the task-owned background capture
path when possible so rendered QA does not obstruct the user's desktop, and
record any capture limitation instead of claiming visual conformance.

## Non-Goals

- Mobile-specific layouts, ornamental dashboards, explanatory card grids,
  multiple competing primary actions, or a pixel-for-pixel copy of the original
  reference HUD.
- UI-owned game rules, paint calculations, trajectory simulation, or stage
  progression.
- One-off fonts, colors, panels, or icons that bypass shared project resources.
- Literal copying of generated world pixels, fake state, omitted real controls,
  or accidental artifacts from `command-columns-hud.png`.

## Related

- `ART_DIRECTION.md` owns world composition and gameplay-object visual language.
- `VISUAL_REFERENCES.md` explains which image details are current and which are
  superseded.
- `../../docs/design-spec.md` contains broader interaction and game-state requirements.
