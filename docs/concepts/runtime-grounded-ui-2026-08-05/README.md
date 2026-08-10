---
type: evidence
status: archived
created: 2026-08-05
last_reviewed: 2026-08-05
topic: Runtime-grounded Paint Mountain screen concepts for user review
scope: Current 1280x720 screen evidence, proposed visual direction, and generation provenance
source: ../../../docs/source-brief.md
related:
  - ../../../.agents/design/DESIGN.md
  - ../../../.agents/design/ART_DIRECTION.md
  - ../../../.agents/design/UIUX_GUIDELINES.md
  - ../../../.agents/design/VISUAL_REFERENCES.md
  - ../../handoffs/gameplay-visual-reset-2026-08-03/visuals/01-target-reference.png
---

# Runtime-Grounded Screen Concepts

This folder is review evidence, not an implementation plan and not proof that
the proposed visuals already run in Godot. On 2026-08-05 the user selected this
screen set as the basis for new execution planning. The resulting plans are
`.agents/execplans/2026-08-05-physical-gameplay-mvp.md`,
`2026-08-05-rapid-fire-thirty-stage-progression.md`, and
`2026-08-05-runtime-grounded-interface.md`; their runtime gates remain required.

Open [`index.html`](index.html) for the complete current-versus-proposed review.

## Grounding Method

1. Capture every reachable current screen from the real Godot Compatibility
   renderer at 1280x720 without taking focus or occupying the user's desktop.
2. Inspect the current captures, the primary user reference, the repository
   design system, and the actual screen/component inventory.
3. For every proposed screen, pass its corresponding current runtime capture as
   the first image-generation reference. Pass the primary user reference as the
   second reference for world mass, depth, faceting, paint contrast, and visual
   ambition. The Aiming proposal is also the continuity reference for the
   Observation proposal.
4. Inspect every proposed image for Korean readability, clipping, hierarchy,
   functional consistency, and 16:9 framing, then normalize final files to
   1280x720.

The Clear capture uses the current result component after the controller's
existing debug clear transition. The Failure capture renders the current
failure component with representative values because the old deterministic
capture sequence no longer reaches the terminal state. These two captures are
valid layout evidence only; they are not gameplay-outcome verification.

## Screen Set

| # | State | Current evidence | Proposed concept | Main visual decision |
| --- | --- | --- | --- | --- |
| 00 | Main Menu | [`current/00-main-menu-current.png`](current/00-main-menu-current.png) | [`proposed/00-main-menu-grounded.png`](proposed/00-main-menu-grounded.png) | Preserve the four real actions; let a substantial mountain preview dominate. |
| 01 | Stage Select | [`current/01-stage-select-current.png`](current/01-stage-select-current.png) | [`proposed/01-stage-select-grounded.png`](proposed/01-stage-select-grounded.png) | Replace three fixed cards with unlocked 10-stage pages covering stages 1-30. |
| 02 | Briefing | [`current/01b-stage-briefing-current.png`](current/01b-stage-briefing-current.png) | [`proposed/02-stage-briefing-grounded.png`](proposed/02-stage-briefing-grounded.png) | Keep the mountain readable; move the objective and mechanisms into one low bar. |
| 03 | Aiming | [`current/02-aiming-current.png`](current/02-aiming-current.png) | [`proposed/03-aiming-grounded.png`](proposed/03-aiming-grounded.png) | Preserve the approved edge HUD, strengthen typography, and restore target depth and route readability. |
| 04 | Observation / rapid fire | [`current/03-observation-current.png`](current/03-observation-current.png) | [`proposed/04-observation-grounded.png`](proposed/04-observation-grounded.png) | Keep aim and Fire available while a prior ball rolls; group camera and speed controls by purpose. |
| 05 | Pause | [`current/05-pause-current.png`](current/05-pause-current.png) | [`proposed/05-pause-grounded.png`](proposed/05-pause-grounded.png) | Use one compact modal hierarchy; keep Restart here rather than in the aiming HUD. |
| 06 | Settings | [`current/06-settings-current.png`](current/06-settings-current.png) | [`proposed/06-settings-grounded.png`](proposed/06-settings-grounded.png) | Use four categories and one active settings column; return to Pause and omit Restart. |
| 07 | Clear | [`current/07-stage-clear-current.png`](current/07-stage-clear-current.png) | [`proposed/07-stage-clear-grounded.png`](proposed/07-stage-clear-grounded.png) | Keep painted terrain visible and make the next stage the primary action. |
| 08 | Failure | [`current/08-stage-failed-current.png`](current/08-stage-failed-current.png) | [`proposed/08-stage-failed-grounded.png`](proposed/08-stage-failed-grounded.png) | Explain the remaining target clearly and make Retry the sole primary action. |

## Shared Prompt Contract

- One production-feasible 1280x720 Korean desktop-game screen, never a collage.
- Actual current capture is the screen-state and functional grounding.
- The primary user image contributes only the desired thick low-poly mountain,
  layered route depth, bright restraint, saturated blue paint, and readable
  mechanisms; it does not dictate literal HUD coordinates or topology.
- Pretendard-like bold typography, warm white `#FFFDFC`, navy `#172538`, blue
  `#2584FF`, restrained shadows, 24px safe margins, and no glassmorphism or
  nested-card clutter.
- All visible Korean actions correspond to a requested or already reachable
  function. No fake metrics, navigation, projectile steering, or post-impact
  paint prediction was added.
- Aiming keeps one bottom-center `발사`, lower-left aim/power, left vertical
  coverage, upper-left stage/mode, and upper-right shots/gear.
- Observation keeps aiming and `발사` available, shows an active rolling ball
  with a proportionate continuous paint trail, uses `추적 / 전체 / 대포` as one
  camera group, and replaces separate `1× / 2×` buttons with one `속도 2×`
  control.

## Review Boundary

Selection of these images approves a visual and interaction direction only. It
does not prove closed geometry, collision, continuous paint authority,
physics tuning, responsiveness, localization behavior, focus behavior, or
stage-generation scalability. Those contracts belong to the three linked plans.
