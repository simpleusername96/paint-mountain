---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-11
canonical_for: Paint Mountain player-facing UI, HUD, menu, typography, and interaction presentation
scope: HUD, menus, settings, results, layout, copy, localization fit, icons, focus, and visible interaction states
source: ../../docs/source-brief.md
related:
  - DESIGN.md
  - ART_DIRECTION.md
  - VISUAL_REFERENCES.md
  - ../../docs/design-spec.md
  - ../research/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png
  - ../execplans/2026-08-03-gameplay-visual-reset.md
  - ../execplans/2026-08-06-wind-driven-coverage-loop.md
  - ../execplans/2026-08-06-command-columns-hud.md
  - ../execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../execplans/2026-08-07-cannon-shot-observation.md
  - ../execplans/2026-08-08-casual-shared-ui-refresh.md
  - ../execplans/2026-08-09-hud-legibility-and-wind-stable-aim.md
  - ../execplans/2026-08-09-quiet-context-ui-system.md
  - ../execplans/2026-08-10-essential-ui-fidelity.md
  - ../evidence/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png
  - ../../docs/reports/screen-audit-2026-08-10/index.html
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

- Casual, simple, tactile, edge-aware, and calm.
- Functional rather than dashboard-like: no card mosaic, decorative glass,
  filler metrics, or unsupported actions.
- Tactile primary actions with restrained secondary surfaces, generous internal
  padding, and clear selected, hover, pressed, disabled, and focus states.
- Korean-native rather than an English layout with translated strings forced
  into it.

## Requirements

### Approved Quiet Context system

The user-approved 2026-08-09 reference
`.agents/evidence/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png`
(SHA-256
`715DA06D3825E97B0C89975153289ECC0BF11F41A9C93A5129DC8397E2DDC33A`)
is the current interface direction. It supersedes the heavier card and detached
keycap treatment of the 2026-08-08 casual shared refresh while preserving its
real navigation, tactile primary actions, and Korean-first interaction
contracts.

- Put status and labels directly at the screen edges when containment is not
  required. Use spacing, alignment, typography, and surface fill to group
  content before adding any boundary.
- Reserve a filled blue surface for the current primary action. Routine and
  secondary actions use quiet neutral or text-led treatment; disabled state
  remains explicit.
- Use one sentence-like context legend along the safe lower edge of interactive
  gameplay states. Each input cue stays inline with its short action label; do
  not scatter detached dark keycap tiles around controls.
- Menus and interrupted states may use one containment surface when it clarifies
  focus or input blocking. Do not nest bordered cards inside that surface.
- Aim View exposes angle and power only. The target-derived horizontal yaw is
  not a player control or useful planning instrument, so `↔`, a yaw degree, A,
  and D are absent from the visible HUD.
- Apply the same paper-white, navy, blue-accent, restrained radius, type, focus,
  and state rules to Main Menu, Stage Select, Briefing, Map View, Shot Follow,
  Pause, Settings, and Result. Use a thin rule or outline only for semantic
  focus, selection, containment, editable controls, slider/progress rails, or a
  target marker. Do not use decorative full-width or repeated internal lines.
- The seven user-approved 2026-08-10 refined screens registered in
  `VISUAL_REFERENCES.md` are the fidelity targets for their named screens. They
  refine copy density, boundary use, and composition without replacing the
  Quiet Context color, typography, action, or focus system.

### Aiming HUD hierarchy

The approved Quiet Context system replaces
`command-columns-hud.png` as the current visual authority. Retain its useful
functional hierarchy—edge status, centered Fire, compact typography, and open
world center—but do not preserve its literal columns, coordinates, or panel
details. Gear, direction, power steps, focus, disabled
states, Map View, and the contextual Shot Follow return remain supported.

At the 1280x720 logical baseline, preserve this relative hierarchy:

| Element | Placement | Contract |
| --- | --- | --- |
| Stage card | Upper-left | Primary stage identity |
| Interaction-mode chip and toggle | Below Stage | Shows `조준`/`Aim View` or `지도 보기`/`Map View`; the focusable toggle and Tab switch modes |
| Time, shots, Finish, and Gear | Edge-aligned status area | Shots read remaining / maximum; resident-ball activity stays internal; Gear remains the menu action |
| Coverage gauge | Left edge | Sole coverage display; target-area coverage fills bottom-to-top and shows target |
| Aim and power | Lower edge, outside the cannon silhouette | One coherent control group |
| Fire | Bottom-center | Sole primary action |

- Use the active ExecPlan's baseline rectangles as implementation evidence, not
  permanent design tokens. Recompose a component when its minimum size,
  internal padding, or world obstruction contradicts the hierarchy.
- Use a 24 px logical safe margin and anchors/containers so this hierarchy
  survives supported desktop aspect and resolution changes. Do not freeze every
  child to viewport offsets.
- Keep one Fire control. Do not place Restart in the aiming HUD.
- Do not expose the old Follow/Wide/Cannon preset rail, a gameplay-speed toggle,
  or gameplay Pause strips. Active play already uses the fixed two-times pace;
  Shot Follow uses one contextual return action only.
- Keep the top-center and center of the world view free of duplicate status
  cards, and keep visible mountain routes free of
  persistent panels, explanatory text, or modal overlays.
- Do not show passive per-shot summaries or mechanism briefing/activation
  message cards. Preserve internal observation and activation facts without a
  replacement toast or banner.
- Trajectory and impact feedback belong in world space; the HUD must not pretend
  to predict post-impact paint.

### Aim View, Map View, and Shot Follow

- Gameplay remains in the aiming Board Phase while the player switches between
  `Aim View`, `Map View`, and `Shot Follow`; this is a presentation/input state, not a
  separate stage flow.
- In Aim View, click selects a valid terrain top point and drag retargets to the
  latest valid point, retaining the last valid target across invalid gaps. Angle
  controls and W/S request a target-preserving elevation edit; power controls and
  wheel request a target-preserving power edit. A/D is not a human target-mode
  control and is not advertised there. Later same-target solves preserve the
  last successful explicit elevation or power constraint whenever a legal tuple
  exists. The authored view keeps the cannon large in the foreground and the
  complete mountain distant and visible.
- In Map View, left drag changes yaw/pitch around the immutable center of the
  visible terrain mass, the wheel changes radius, and aim and Fire input are
  blocked. Terrain and mechanism clicks do not pan or refocus the camera.
- Tab and one visible focusable toggle switch modes without changing the stored
  committed aim or preview. Mode changes, target selection, orbit, and zoom must
  acknowledge without a visible stall. The shared lower-edge context
  legend exposes the active inputs and mouse behavior; no detached prompt set or
  timed first-session hint is used.
- Accepted Fire enters Shot Follow for the newly launched root paintball. Hide
  controls that imply in-flight steering and show one compact focusable
  `대포로 돌아가기` / `RETURN TO CANNON` action at a screen edge. Tab performs
  the same contextual return. Returning changes only presentation; simulation,
  stored aim, and prior balls continue. First terrain contact remains framed for
  0.8 seconds before automatic return to Aim View.
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
- Time, camera presentation mode, and Finish availability are displayed from
  their authoritative owners. Resident-ball activity stays internal because it
  does not support a visible player decision. The HUD does not run a second
  timer or camera/input state machine.
- Target Coverage means unique painted physical Target Area surface divided by
  its total physical surface. Valid non-target top paint remains visible but is
  lighter and less saturated and is not scored; the dry Target Area cue and HUD
  copy `목표 영역`/`TARGET AREA` make that boundary clear. Its percentage, rail,
  target marker, and visible paint publication must agree.
- Shots, selected target, angle, power, prediction state, and Fire validity
  update from their authoritative owners without duplicated formulas. The
  selected target is visible immediately. An exact impact marker appears only
  for a matching target/aim revision; stale arc dots may remain subdued,
  but stale impact/exit markers are hidden. Pending, confirmed, and rejected
  target states use shape as well as color.
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
- Components must have one internally consistent minimum size. A parent may not
  assign a smaller rectangle than a child's minimum content geometry. Use at
  least 12 px internal padding for compact controls, 16 px for cards, and 24 px
  for primary menu surfaces unless direct rendered evidence requires more.
- Prefer one visible containment surface per functional group. Avoid nested
  outlines, card-in-card framing, and labels whose proximity makes ownership
  ambiguous.

### Layout and tokens

- `resources/ui/paint_mountain_theme.tres` is the implemented token owner. Reuse
  its shared Theme and components instead of constructing StyleBoxes or palette
  constants in scripts.
- Current UI roles are warm surface `#FFFDFC`, navy text/dark surface `#172538`,
  primary blue `#2584FF`, muted progress rail `#C9CDD2`, and danger `#D94C4C`.
  The approved Kenney UI Pack 2.0 subset may supply nine-slice edge and depth
  treatment for shared button and stage-card roles; the Theme remains the owner.
- Panels use restrained 14-18 px radii according to prominence; primary actions
  may use the imported tactile depth edge. Do not mix decorative surface styles
  within one screen.
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
- Input-token styling is Theme-owned and quiet. The shared lower-edge context
  legend uses inline text and the existing mouse-wheel asset; it groups S/W with
  angle, the wheel with power, Space with Fire, Tab with Aim/Map or Shot Follow
  return, F with Finish, and Esc with menu/Continue without owning input. Fire,
  Finish, and Aim/Map controls show semantic action labels only and do not
  repeat those key names. Terrain-target yaw shows no A/D token. Do not use
  detached or outlined keycap tiles in the normal gameplay legend.
- Aim steppers keep decrement, current value, and increment in one row and
  disable the matching direct-control button at its numeric boundary.
- Keyboard focus uses the shared visible 2 px accent treatment.
- Align rows by a deliberate center, baseline, or edge. Keep label-to-value gaps
  tighter than gaps between component groups.

### Copy, typography, and localization

- Pretendard is the shared project font and must be loaded through the Theme.
- Korean is the default locale; English remains switchable and persistent.
- Store translation keys rather than visible display text in gameplay Resources.
- Use short, direct Korean gameplay terms. Normal screens may show only screen
  or stage identity, authoritative values, real actions, a terminal reason,
  conditional loading/error/disabled reasons, and the single current-context
  guide. Remove marketing eyebrow/tagline copy, duplicated objective or strategy
  prose, duplicate mouse hints, autosave/language helper notes, result
  explanation captions, and shortcuts repeated inside controls.
- Explanatory copy belongs in a future guidebook page, the first tutorial, or a
  dedicated UI guide. Preserve useful stage-objective and mechanism-description
  translation content for those owners, accessibility, and diagnostics; do not
  render it as normal-screen filler.
- Briefing shows compact stage number/name and inspection mode, the complete
  terrain with unlabelled surface glyphs, Back/Start actions, and the lower-edge
  context guide. It does not show an objective paragraph, mechanism name floating
  over the terrain, or a second instruction line.
- Results show the terminal title, coverage value, compact target value, grade,
  best value, elapsed time, shots, and supported actions. They do not label the
  metric as “final target coverage” or explain the calculation in body copy.
- Check every visible Korean label for clipping, overlap, awkward forced wrap,
  and insufficient button width. Do not solve text fit by making essential text
  unreadably small.

## Acceptance Criteria

A UI change conforms when:

- the foreground cannon and complete distant mountain remain the dominant world
  composition and Fire is the unmistakable next action during Aim View;
- Aim View keeps the whole mountain and predicted impact readable, and Map View,
  Tab, or the visible toggle returns without losing the
  current aim or blocking the interface;
- Shot Follow keeps the new root paintball and first terrain impact readable,
  while the visible return action and Tab restore Aim View without implying
  in-flight steering;
- the left vertical coverage gauge, lower-edge controls, edge status, top-right
  gear, bottom-center Fire, and one quiet bottom context legend preserve the
  specified hierarchy;
- aiming contains no Restart or duplicate Fire action;
- gameplay contains no ambiguous camera presets, time-scaling strip, or duplicate
  pause action;
- Korean and English labels fit without clipping at supported desktop sizes;
- all reachable controls expose stable enabled, disabled, hover, pressed, and
  keyboard-focus states;
- no panel overlaps another, escapes its container, hides fixed content, or
  blocks the world-space impact point; and
- no reachable screen contains detached shortcut tiles, decorative full-width
  hairlines, repeated unselected-card outlines, avoidable nested card framing,
  duplicated shortcut labels, or a visible yaw readout; and
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
