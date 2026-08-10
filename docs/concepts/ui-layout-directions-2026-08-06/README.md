---
type: evidence
status: archived
created: 2026-08-06
last_reviewed: 2026-08-06
topic: Current-runtime-grounded Aim Lock HUD layout direction selection
scope: Three 1280x720 concepts and the user-selected Command Columns implementation reference
source:
  - ../../../.agents/evidence/fast-stage-entry-and-fire-capacity/stage_30_aiming-1280x720.png
  - ../runtime-grounded-ui-2026-08-05/proposed/03-aiming-grounded.png
related:
  - ../../../.agents/design/UIUX_GUIDELINES.md
  - ../../../.agents/design/ART_DIRECTION.md
---

# Aim Lock HUD Layout Directions

## Purpose

Record three production-oriented HUD layouts against the current Stage 30 Aim
Lock state and identify the user-selected implementation reference.

## Sources

- The current Stage 30 production capture supplies the required world,
  gameplay state, and current information inventory.
- The user-selected 2026-08-05 Aiming concept supplies restrained typography,
  palette, spacing, and control treatment. Its obsolete pre-wind information
  inventory is not copied.
- `UIUX_GUIDELINES.md` supplies the Korean-first, mountain-dominant, sole-Fire,
  edge-safe, and accessibility constraints.

## Findings

The three displayed options are recorded in their conversation display order:

1. `quiet-edge-hud.png`: independent compact edge clusters.
2. `instrument-rail-hud.png`: one slim top rail and one bottom command dock.
3. `command-columns-hud.png`: narrow left and right information columns.

Each concept preserves time, shots, resident-ball state, wind, Finish,
coverage, aim, power, gear, mode, and Fire while reducing central obstruction.

The user selected option 3, `command-columns-hud.png`, on 2026-08-06. Its narrow
left command column, narrow right status rail, compact lower-left aim group,
centered Fire action, warm surfaces, and typography rhythm are implementation
input. Options 1 and 2 remain unselected alternatives.

## Limitations

- These are image-generated layout concepts, not running-game captures.
- Korean copy accuracy, focus behavior, responsive anchors, dynamic values, and
  interaction states require implementation and rendered Godot QA.
- World pixels may differ from the source capture; only the selected HUD
  structure and visual treatment become implementation input. Required real
  actions and states remain governed by `UIUX_GUIDELINES.md` when the generated
  still omits or simplifies them.
