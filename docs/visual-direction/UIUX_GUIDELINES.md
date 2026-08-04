---
type: spec
status: active
created: 2026-08-04
last_reviewed: 2026-08-04
canonical_for: Paint Mountain player-facing UI, HUD, menu, typography, and interaction presentation
scope: HUD, menus, settings, results, layout, copy, localization fit, icons, focus, and visible interaction states
source: ../source-brief.md
related:
  - README.md
  - ART_DIRECTION.md
  - VISUAL_REFERENCES.md
  - ../design-spec.md
  - ../../.agents/execplans/2026-08-03-gameplay-visual-reset.md
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

At the 1280x720 logical baseline, preserve this relative hierarchy:

| Element | Placement | Contract |
| --- | --- | --- |
| Stage card | Upper-left | Primary stage identity |
| Aim-mode chip | Below Stage | Compact secondary state |
| Target card | Top-center | Target coverage |
| Shots and Gear | Upper-right | Remaining shots followed by a separate menu action |
| Coverage gauge | Left edge | Vertical rail; absolute coverage fills bottom-to-top and shows target |
| Aim and power | Lower-left | One coherent control group |
| Fire | Bottom-center | Sole primary action |

- Use the active ExecPlan's current baseline rectangles while implementing the
  approved layout, but do not promote those task coordinates into permanent
  design tokens.
- Use a 24 px logical safe margin and anchors/containers so this hierarchy
  survives supported desktop aspect and resolution changes. Do not freeze every
  child to viewport offsets.
- Keep one Fire control. Do not place Restart in the aiming HUD.
- Keep the center of the world view and the visible mountain routes free of
  persistent panels, explanatory text, or modal overlays.
- Trajectory and impact feedback belong in world space; the HUD must not pretend
  to predict post-impact paint.

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
- Coverage always means absolute painted eligible area. Its percentage, rail,
  and target label must agree.
- Shots, target, angle, power, and Fire validity update from their authoritative
  owners without duplicated formulas.
- Icons supplement meaning. Rare, destructive, or menu actions retain visible
  Korean labels; icon-only controls require an accessible name and clear focus
  treatment.
- Disabled, hover, pressed, focused, selected, paused, clear, and failed states
  remain visually stable. Do not communicate a state by color alone.

### Layout and tokens

- `resources/ui/paint_mountain_theme.tres` is the implemented token owner. Reuse
  its shared Theme and components instead of constructing StyleBoxes or palette
  constants in scripts.
- Current UI roles are warm surface `#FFFDFC`, navy text/dark surface `#172538`,
  primary blue `#2584FF`, muted progress rail `#C9CDD2`, and danger `#D94C4C`.
- Panels use the established restrained 12 px radius; primary actions use 16 px.
  Do not add nested bordered/background containers beyond two visible levels
  without a clear containment reason.
- Base text is 16 px and the primary action is 20 px at the logical baseline.
  Scale hierarchy intentionally rather than shrinking text to fit.
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
  action during aiming;
- the left vertical coverage gauge, lower-left controls, top status, top-right
  gear, and bottom-center Fire preserve the specified hierarchy;
- aiming contains no Restart or duplicate Fire action;
- Korean and English labels fit without clipping at supported desktop sizes;
- all reachable controls expose stable enabled, disabled, hover, pressed, and
  keyboard-focus states;
- no panel overlaps another, escapes its container, hides fixed content, or
  blocks the world-space impact point; and
- every visible action is connected to real functionality.

During the current implementation-first stage, inspect scene/resource structure
without opening a visible Godot window. This spec does not authorize later
rendered QA; follow the active ExecPlan and explicit user instruction for that
gate.

## Non-Goals

- Mobile-specific layouts, ornamental dashboards, explanatory card grids,
  multiple competing primary actions, or a pixel-for-pixel copy of the original
  reference HUD.
- UI-owned game rules, paint calculations, trajectory simulation, or stage
  progression.
- One-off fonts, colors, panels, or icons that bypass shared project resources.

## Related

- `ART_DIRECTION.md` owns world composition and gameplay-object visual language.
- `VISUAL_REFERENCES.md` explains which image details are current and which are
  superseded.
- `../design-spec.md` contains broader interaction and game-state requirements.
