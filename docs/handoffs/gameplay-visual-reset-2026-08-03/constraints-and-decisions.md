---
type: evidence
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
scope: fixed constraints, non-goals, and decisions required from external review
related:
  - README.md
  - current-state.md
  - source-map.md
---

# Constraints and Decisions

## Purpose

Define what is already settled and force the external review to choose concrete
defaults for the remaining design questions before another implementation pass.

## Sources

- The user's latest corrections.
- Root `AGENTS.md`.
- `docs/source-brief.md`, except for explicitly superseded paint depletion.
- Current code ownership and the two package screenshots.

## Findings

### Fixed product constraints

- The game is a focused single-player 3D physics puzzle, not a terrain sandbox.
- The cannon is stationary. The player manually sets yaw, elevation, and power
  before firing and cannot steer a projectile in flight.
- The mountain is a distant, dominant, thick 3D target with readable gameplay
  routes. It is not a flat backdrop or an arbitrary natural-noise landscape.
- The ball continuously paints every eligible target surface area traversed by
  its rolling/sliding contact footprint. There is no consumable paint payload.
- Coverage and visible persistent paint come from the same authoritative runtime
  mask. A second coverage representation is prohibited.
- A trajectory preview ends at the predicted first collision. It does not reveal
  the post-impact solution.
- Difficulty increases through route topology: more meaningful rises, descents,
  branches, narrower choices, and mechanism interactions, not visual noise.
- Gameplay-relevant visible geometry must have aligned collision. Decorative
  objects need an explicit solid/non-solid policy.
- The default language is Korean. English remains selectable in settings.
- The target reference controls composition and hierarchy, not exact pixel-for-
  pixel geometry.

### Fixed technical constraints

- Godot 4.x, typed GDScript where practical, Compatibility renderer, fixed 60 Hz
  physics, and Windows desktop first.
- `StageController` remains the sole owner of stage state, shot progression, and
  clear/failure decisions.
- `PaintSystem` remains the sole owner of the mutable paint mask and coverage.
- Projectile, stage, mechanism, and result tuning remains in typed Resources.
- Human input, replay, tests, and the agent interface use the same game-rule
  actions and observations.
- Cross-system communication uses typed signals or narrow interfaces. Global
  stage-specific node-path coupling is prohibited.
- No new engine, production dependency, plugin, network service, Docker setup, or
  asset pack should be introduced for this review.
- Future implementation must remain launchable after each milestone and run
  `scripts/verify.ps1` after relevant changes.
- Do not open visible Godot or game windows during the external read-only review.

### Architecture worth preserving unless evidence disproves it

- One accepted deterministic stage layout feeds render geometry, collision,
  surface queries, mechanism placement, paint mapping, replay metadata, and agent
  observations.
- One geometry factory derives the visible top/shell and collision shapes from
  that layout.
- One paint mask drives both terrain appearance and coverage.
- HUD components stay responsibility-shaped rather than returning to one code-
  built catch-all.
- Physical contact data, not fabricated visual coordinates, drives paint and
  mechanisms.

### Non-goals

- Photorealistic mountains, erosion simulation, caves, and overhangs.
- Full fluid paint simulation.
- In-flight steering, direct target locking, or revealing the full result path.
- Hiding defects by lowering target coverage, inflating paint marks arbitrarily,
  or shrinking the mountain until collision appears easier.
- A wholesale rewrite when existing narrow owners can be corrected.
- Treating test-search success as a substitute for a readable running game.

### Decisions Claude must make

Claude should choose a recommended default for each item and justify it against
Godot 4.x, the reference image, and the current architecture. Do not return a menu
of equally weighted possibilities.

1. **Mountain representation:** Decide whether a route-first heightfield plus
   closed shell is sufficient, and specify the exact topology construction and
   shading needed to create stepped depth. If not, define the smallest compatible
   mesh representation that replaces it.
2. **Route graph:** Define nodes, edges, widths, elevations, shelves, branch
   joins, rises/descents, stage-complexity budgets, seeded variation, and
   rejection metrics.
3. **Continuous paint command:** Choose the runtime command shape for a swept
   contact footprint, including previous/current contact, radius, surface normal,
   collider identity, discontinuity rules, and deterministic ordering.
4. **Surface rasterization:** Define how a 3D sweep maps into the authoritative
   world X/Z mask on steep slopes without visible gaps or painting through
   disconnected surfaces.
5. **Contact lifecycle:** Define impact, sustained rolling/sliding, brief contact
   loss, re-contact, high-speed motion, rest, bounds exit, mechanisms, and
   Splitter children.
6. **Paint look:** Define persistent thickness cues, gloss/roughness, edge shape,
   splashes, temporary particles, and how visual paint remains tied to the scored
   mask.
7. **Collision contract:** Define how rendered target and mechanism geometry are
   paired with collision and how mismatch/tunneling is detected.
8. **Camera and scale:** Give measurable composition ranges for mountain screen
   occupancy, cannon occupancy, route/mechanism projected size, perspective, and
   safe camera motion.
9. **HUD system:** Define the Korean-first information hierarchy, typography,
   spacing, component placement, power input, mouse aiming behavior, focus
   states, and language switch without obscuring the mountain.
10. **Migration:** Identify current files/contracts to preserve, replace, split,
    or delete, including payload fields in replay, agent observations, debug UI,
    resources, and tests.
11. **Proof sequence:** Define the smallest vertical prototype and the objective
    code, headless, and screenshot evidence required before progressing to all
    three stages.

## Recommendations

The review should use **must**, **should**, and **avoid** consistently. Every
major recommendation should include a measurable acceptance signal and a likely
owner path. Any assumption that cannot be decided from the evidence should be
listed explicitly with one recommended default.

## Limitations

This document fixes review constraints but does not authorize implementation. An
approved replacement plan will be required after the external review is locally
validated.
