---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-21
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
  - ../execplans/2026-08-18-three-ball-target-band-prototype.md
  - ../execplans/2026-08-20-cross-stage-ui-theme.md
  - ../execplans/2026-08-21-uiux-image-parity.md
  - ../evidence/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png
  - ../../docs/reports/screen-audit-2026-08-10/index.html
  - ../../docs/reports/ui-refinement-2026-08-20/index.html
  - ../evidence/cross-stage-ui-theme-2026-08-20/README.md
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

### Quiet Context foundation

The user-approved 2026-08-09 reference
`.agents/evidence/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png`
(SHA-256
`715DA06D3825E97B0C89975153289ECC0BF11F41A9C93A5129DC8397E2DDC33A`)
is the foundation of the current interface direction. It supersedes the heavier
card and detached keycap treatment of the 2026-08-08 casual shared refresh while
preserving its real navigation, tactile primary actions, and Korean-first
interaction contracts. The compact shared-component correction below and its
Cannon Focus composition supersede Quiet Context where their presentation rules
differ.

- Put status and labels directly at the screen edges. Use spacing, alignment,
  typography, and a shared contrast scrim before adding any boundary.
- Reserve a filled blue surface for the current primary action. Routine and
  secondary actions use quiet neutral or text-led treatment; disabled state
  remains explicit.
- Show at most three current-context hints along the safe lower edge. Each hint
  is one shared icon plus a short action label; do not use a full-width legend,
  detached keycap tile, or explanatory sentence.
- Menus and interrupted states may use one containment surface when it clarifies
  focus or input blocking. Do not nest bordered cards inside that surface.
- Aim View exposes angle and power only. The target-derived horizontal yaw is
  not a player control or useful planning instrument, so `↔`, a yaw degree, A,
  and D are absent from the visible HUD.
- Apply the same paper-white, navy, blue-accent, restrained radius, type, focus,
  and state rules to Main Menu, Stage Select with pre-play briefing, Map View, Shot Follow,
  Pause, Settings, and Result. Use a thin rule or outline only for semantic
  focus, selection, containment, editable controls, slider/progress rails, or a
  target marker. Do not use decorative full-width or repeated internal lines.
- The seven user-approved 2026-08-10 refined screens registered in
  `VISUAL_REFERENCES.md` are the fidelity targets for their named screens. They
  refine copy density, boundary use, and composition without replacing the
  Quiet Context color, typography, action, or focus system.

### Icon-first TO-BE parity correction

The user's 2026-08-21 correction and
`../../docs/reports/uiux-correction-spec-2026-08-21/index.html` replace the
earlier vertical-live-scale and standalone-Briefing presentation. The selected
TO-BE files registered in `VISUAL_REFERENCES.md` are the literal hierarchy and
composition targets for their named states. Runtime terrain, values,
localization, focus, and responsive geometry remain authoritative.

- Every visible UI element is either a shared component or a structural Godot
  `Container`. Screens supply data, order, anchors, and visibility only. They do
  not copy fonts, colors, icons, borders, radii, StyleBoxes, or interaction
  states.
- All actions are icon-only and use the repository-owned monochrome action
  family through `ActionControl`. Main Menu is the sole exception that reveals
  one sibling localized label on hover or focus. Accessible name and tooltip
  remain present even when visible button text is empty.
- Routine actions have a transparent normal state. Filled blue belongs only to
  the current primary action. A white surface is allowed only for Settings,
  genuine blocking/information content, or the one open ball-detail card.
- Gameplay, Stage Select, and Result use direct overlays. `ContrastScrim` or a
  right-edge gradient may improve contrast without becoming a card. Pause uses
  a navy input barrier with no white sheet; Settings uses one warm-white form.
- `AimScoreStatus` owns live score presentation. In Aim its visual domain is the
  authoritative minimum-to-maximum success range, divided into higher-star
  segments. It shows the unclamped signed current score, an endpoint overflow
  arrow when needed, numeric total painted target percentage, and real
  shape-plus-sign Red/Green role cues. It contains no 0–100 axis, terrain mask,
  prose explanation, or background card.
- Map, Shot Follow, and an open ball-detail state use
  `AimScoreStatus.COMPACT_VALUE`; they do not repeat the success bar. The
  result-only `ScoreScale` retains the horizontal 0–100 summary axis and must
  not be reused as the live Aim component.
- `BallQueue` owns token shape, order, focus, and one warm-white
  `BallDetailCard`. Pointer hover, keyboard focus, and press/touch expose the
  same localized behavior description; press pins it and Escape dismisses it.
- The shared visual inventory is `AimScoreStatus`, result-only `ScoreScale`,
  `BallQueue`, `ValueStepper`, `ActionControl`, `StageRail`,
  `StageRuleSummary`, `ContextLegend`, `ResultSummary`, and the shared scrims.
  Reuse or enhance the existing owner before adding a competing component.
- Red and green belong to paint semantics. Every paint, completion, lock,
  disabled, selected, and focus state also has a shape, icon, stroke, signed
  value, or accessible label so color is never the sole signal.

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
| Stage identity | Upper-left | Shared mountain icon plus compact stage number/name, without a card surface |
| Interaction-mode chip and toggle | Below Stage | Shows `조준`/`Aim View` or `지도 보기`/`Map View`; the focusable toggle and Tab switch modes |
| Time, shots, Finish, and Gear | Edge-aligned status area | Shots read remaining / maximum; resident-ball activity stays internal; Gear remains the menu action |
| Score display | Upper-left safe edge | `AimScoreStatus` shows the complete success range, star segments, current score, numeric paint total, and signed shape-coded R/G roles in Aim; Map/Follow use compact values only |
| Ball queue | Upper-right safe edge | All stages show the current plus next tokens as compact shape-coded controls. Hover, focus, and press/touch open the same one-card description |
| Aim and power | Lower edge, outside the cannon silhouette | One coherent control group |
| Fire | Bottom-center | Sole primary action |

The canonical Aim composition is **Cannon Focus**. `AimScoreStatus` stays at
the safe upper-left, `BallQueue` is horizontal at the upper-right, and the lower
interaction sequence reads angle -> Fire -> power around the cannon. At compact
sizes, angle -> Fire -> power remains one centered row below the cannon. Canvas
stretch density scales the shared components so their physical text and targets
do not collapse; redundant captions may drop, but angle, power, Fire, queue
truth, the signed score, and the success-range endpoints remain visible and
operable.

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
- Finish is unavailable until the first actual launch. Legacy stages keep their
  manual/timeout flow. Prototype Finish also requires a quiet board and an
  in-band score; timeout or a quiet exhausted queue resolves Clear/Failed.

### Navigation and pause

- Gear and Escape open the same full-viewport paused input barrier.
- The paused game menu shows a centered white title and one horizontal icon
  rail: Continue is the only filled-blue primary, followed by Restart,
  Settings, Stage Select, and Main Menu as transparent world actions. It has no
  white sheet and no visible button text.
- Settings opens as a child of that paused flow and returns to the paused menu.
  Settings never contains Restart. Defaults sits beside the title and Close is
  fixed at the top-right; only form content scrolls in compact mode.
- Restore the exact pre-pause state on Continue; the menu must not advance the
  simulation or leak input into aiming.
- Clear and failure screens expose only actions supported by the current game
  state and make Retry unambiguous.
- Stage Select is also the visible Briefing. It places concise stage identity,
  authoritative rule/deal truth, and a full-width ten-node `StageRail` over the
  actual selected `StageRuntimeArtifact` terrain, sky, and ground. Terrain-side
  arrows, rail click, drag, and keyboard navigation use one selection owner.
  Start is the single bottom-right Aim icon and enters Aim directly; there is
  no visible standalone Briefing or pager label.

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
- `ActionControl` owns icon assignment, icon-only rendering, localized
  accessible name/tooltip, target size, readiness, and Routine, Primary,
  Selected, Destructive, and World roles. Screens do not place text inside an
  action. Main Menu's animated label is a separate `MenuActionItem` child.
- `AimScoreStatus` owns live success-range and compact-value presentation.
  Callers supply the authoritative band, score snapshot, and weights; they do
  not draw an axis, star scale, endpoint arrow, paint percentage, or R/G cue.
  Clamping applies only to the marker position, never to signed numeric truth.
- `ScoreScale` is result-only and owns the complete horizontal 0–100 summary
  axis and clamping geometry. It cannot be selected as a live vertical preset.
- `BallQueue` owns token hit targets, hover/focus/pressed state, tooltip
  placement, accessible names/descriptions, and pointer-safe dismissal. Callers
  supply authoritative ordered ball data only and do not recreate tooltip copy
  or token styling.
- Semantic icons must not depend on platform emoji or miscellaneous Unicode
  font coverage. `BallGlyphPainter` owns the vector Standard/Burst/Split shapes
  reused by Ball Queue and `StageRuleSummary`; the latter owns the compact
  target-band, R/G, shot-count, and required-kind row used by Stage Select.
  Callers supply data and never substitute literal symbol characters.
- Disabled, hover, pressed, focused, selected, paused, clear, and failed states
  remain visually stable. Do not communicate a state by color alone.
- All visible presentational structures use shared component scenes. A scene
  that composes a component may set supplied text, value, visibility, order,
  and layout; it must not copy the component's font, color, icon, radius,
  border, StyleBox, or interaction state styling.
- `HUDController` owns whole-HUD state presentation and signal coordination.
  Child component scripts own only their displayed structure and narrow intent;
  no component reads a gameplay singleton to reconstruct authoritative state.
- Components must have one internally consistent minimum size. A parent may not
  assign a smaller rectangle than a child's minimum content geometry. Use at
  least 12 px internal padding for compact controls and 24 px for the rare
  shared interruption surface unless direct rendered evidence requires more.
- When the project keeps a larger logical canvas in a smaller OS window, shared
  compact components receive one bounded display-density value. The component
  scales its own font, icon, hit target, spacing, and minimum geometry together;
  a screen must not compensate with one-off font or child-control overrides.
- Prefer direct overlays and whitespace. Do not add a visible containment
  surface to group metrics, queues, steppers, stage nodes, or result values.

### Layout and tokens

- `resources/ui/paint_mountain_theme.tres` is the implemented token owner. Reuse
  its shared Theme and components instead of constructing StyleBoxes or palette
  constants in scripts.
- Current UI roles are warm surface `#FFFDFC`, navy text/dark surface `#172538`,
  primary blue `#2584FF`, muted progress rail `#C9CDD2`, and danger `#D94C4C`.
  The approved Kenney UI Pack 2.0 subset may supply nine-slice edge and depth
  treatment for shared button and selected stage-node roles; the Theme remains
  the owner.
- The shared interruption surface uses one restrained 14-18 px radius. Primary
  actions may use the imported tactile depth edge. Gameplay and navigation
  components do not create decorative surface levels or nested backgrounds.
- Pretendard Variable weight and size roles are Theme-owned semantic type
  variations: `HudCaption` is 14 px/500, `HudBody` 16 px/500, `HudSection`
  18 px/600, `HudValue` 22 px/600, `HudMetric` 28 px/600,
  `PrimaryButton` 20 px/600, and `ScreenTitle` 32 px/700 at the logical
  baseline. Default body copy remains at least 16 px. Scale hierarchy
  intentionally rather than shrinking text to fit.
- Theme variations own reusable font, weight, size, color, interruption surface, button,
  separator, icon-state, and focus decisions. Scene-level overrides are for
  layout-only margins, gaps, anchors, and exceptional geometry; do not repeat
  palette or type roles in each HUD scene.
- Standard routine actions are at least 44x44 and primary actions 56x56;
  compact uses 40x40 and 48x48. A component scales icon, focus, and target
  together rather than shrinking only its bitmap.
- Context-hint styling is Theme-owned and quiet. The shared component shows no
  more than three icon/short-label pairs for the current state and may use the
  existing mouse-wheel asset. Fire, Finish, and Aim/Map controls show semantic
  action labels only and do not repeat key names. Terrain-target yaw shows no
  A/D token. Do not use a full-width legend or detached/outlined keycap tiles.
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
- Stage Select contains the visible pre-play briefing: compact identity,
  authoritative rule/deal summary, complete terrain, side navigation, full
  stage line, Back, and one Aim primary. It adds no objective paragraph,
  strategy prose, floating mechanism name, page label, or separate Briefing
  action lane.
- Results use one right-side navy gradient and alignment spine. Clear/Failed,
  stage number, Paint Score plus target band, R/G breakdown, the result-only
  horizontal 0–100 scale, grade/time/shots, and supported icon actions remain
  direct overlays. Failure adds one concise range-gap line below the score. The
  mountain stays the result hero; no result card or explanation paragraph is
  used.
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
- `AimScoreStatus`, the all-stage queue, lower-edge controls, edge status,
  top-right gear, and bottom-center Fire preserve the specified hierarchy;
- Aim shows exactly one minimum-to-maximum success bar with internal star tiers,
  numeric total paint, and shape-plus-sign R/G roles; Map and Follow show only
  the compact score value, and every ball token exposes the same one-card
  description on hover, focus, and press;
- subtractive rules keep their actual signed Paint Score in live and Result
  copy while only marker geometry stays bounded and signals endpoint overflow
  by direction;
- Stage Select shows the selected stage's real prepared terrain behind the
  shared `StageRail`, presents its rule through the shared vector
  `StageRuleSummary`, and updates it without committing `GameState` before Start;
- aiming contains no Restart or duplicate Fire action;
- gameplay contains no ambiguous camera presets, time-scaling strip, or duplicate
  pause action;
- Korean and English labels fit without clipping at supported desktop sizes;
- all reachable controls expose stable enabled, disabled, hover, pressed, and
  keyboard-focus states;
- no decorative panel/card/sheet is present in gameplay, Stage Select, Pause,
  or Result; Settings and one open Ball Detail are the only routine white
  surfaces, and the shared contrast scrim never blocks input; and
- no reachable screen contains detached shortcut tiles, decorative full-width
  hairlines, repeated unselected-card outlines, avoidable nested card framing,
  duplicated shortcut labels, or a visible yaw readout; and
- every visible action is connected to real functionality; and
- every visible UI element resolves a shared component/Theme role, the
  result-only score axis keeps `0` and `100` fully visible, the live Aim status
  keeps both success endpoints visible, and no screen-local StyleBox, icon,
  font, or palette copy competes with the shared system.

Every substantial UI or visual-composition change requires direct inspection of
the actual running-game render before handoff. Headless contracts and scene
inspection are supporting evidence only. Use the task-owned background capture
path when possible so rendered QA does not obstruct the user's desktop, and
record any capture limitation instead of claiming visual conformance.

## Non-Goals

- Mobile-specific layouts, ornamental dashboards, explanatory card grids, or
  multiple competing primary actions.
- UI-owned game rules, paint calculations, trajectory simulation, or stage
  progression.
- One-off fonts, colors, panels, or icons that bypass shared project resources.
- Literal copying of generated world pixels, fake state, omitted real controls,
  or accidental artifacts from `command-columns-hud.png`.

## Related

- `../execplans/2026-08-20-cross-stage-ui-theme.md` records the completed
  Cannon Focus implementation contract.
- `../evidence/cross-stage-ui-theme-2026-08-20/README.md` records the final
  production-render, responsive, Web-journey, and release-gate evidence.
- `ART_DIRECTION.md` owns world composition and gameplay-object visual language.
- `VISUAL_REFERENCES.md` explains which image details are current and which are
  superseded.
- `../../docs/design-spec.md` contains broader interaction and game-state requirements.
