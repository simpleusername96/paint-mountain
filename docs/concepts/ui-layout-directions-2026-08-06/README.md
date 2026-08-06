---
type: evidence
status: active
created: 2026-08-06
last_reviewed: 2026-08-06
topic: Current-runtime-grounded Aim Lock HUD layout directions
scope: Three 1280x720 layout concepts for user selection before implementation
source:
  - ../../../.agents/evidence/fast-stage-entry-and-fire-capacity/stage_30_aiming-1280x720.png
  - ../runtime-grounded-ui-2026-08-05/proposed/03-aiming-grounded.png
related:
  - ../../../.agents/design/UIUX_GUIDELINES.md
  - ../../../.agents/design/ART_DIRECTION.md
---

# Aim Lock HUD Layout Directions

## Purpose

Compare three production-oriented HUD layouts against the current Stage 30
Aim Lock state before any Godot UI implementation begins.

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

## Limitations

- These are image-generated layout concepts, not running-game captures.
- Korean copy accuracy, focus behavior, responsive anchors, dynamic values,
  and interaction states require implementation and rendered Godot QA after the
  user selects a direction.
- World pixels may differ slightly from the source capture; only the selected
  HUD structure and visual treatment become implementation input.
