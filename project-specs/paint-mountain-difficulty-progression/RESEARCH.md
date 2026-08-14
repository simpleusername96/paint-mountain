---
type: evidence
status: archived
created: 2026-08-13
last_reviewed: 2026-08-14
topic: limited-preview queues, intrinsic projectile behaviors, and color objectives
scope: local evidence and cross-domain analogies supporting the queued-ball spec
related:
  - PRD.md
  - DECISIONS.md
  - ../../.agents/execplans/2026-08-13-queued-ball-paint-ownership.md
---

# Queued Ball and Color Research

## Purpose

Preserve the evidence and analogies used to choose the queue, ball roster, and
paint rule. This file supports judgment; it does not override the PRD.

## Sources

- `../../docs/source-brief.md`
- `../../.agents/Documentation.md`
- `../../docs/design-spec.md`
- `../../docs/technical-architecture.md`
- `../../src/stage/stage_controller.gd`
- `../../src/projectile/projectile_manager.gd`
- `../../src/projectile/paint_projectile.gd`
- `../../src/paint/paint_system.gd`
- [Official Tetris website](https://tetris.com/)
- [World Curling: guards, draws, and last-stone advantage](https://worldcurling.org/about/curling/)
- [Exploratorium: elasticity and coefficient of restitution](https://annex.exploratorium.edu/baseball/features/how-far-can-you-hit-one.html)
- [NASA/JPL: launch angle and projectile trajectory](https://www.jpl.nasa.gov/edu/resources/lesson-plan/build-and-launch-a-foam-rocket/)

## Findings

- The local game already asks the player to predict a ballistic arc before Fire.
  Apex and rebound behaviors extend that readable variable set without adding
  in-flight input.
- Queue uncertainty is useful only when the visible horizon contains enough
  information for the next decision. A hidden ball cannot be the sole solution
  to the current shot.
- Curling separates placement jobs such as guards and draws and makes order
  important. That supports purpose-specific Anchor and Roller balls rather than
  nine versions of a damage projectile.
- Elastic rebound preserves more collision motion. That makes Hyper Bounce a
  controllable physics risk when its settling condition is explicit and the
  stage supplies readable flat landings.
- Projectile trajectory changes with launch angle, initial velocity, gravity,
  and drag. Apex Split should therefore trigger from authoritative velocity
  state and invalidate prediction whenever the queued ball changes.
- The current resident cap supports at most seven roots expanded into three
  children each if split is generation-one and replaces its root.
- Glyph data is not isolated art. It reaches generation, hydration, checksums,
  gameplay wiring, observations, localization, UI, audio/effects, and tests.
  Safe removal needs a catalog version boundary and complete owner migration.
- Fixed per-stage color thresholds preserve comparable results. Runtime-random
  thresholds and cancellation can make a physically good shot fail for reasons
  that were not visible when aiming.

## Recommendations

- Keep the visible horizon at four and validate that current decisions never
  require tail knowledge.
- Use a mixed roster of placement, traversal, area, and delayed-effect jobs.
- Introduce color only after three single-color teaching stages.
- Treat ball tuning as Resource calibration; preserve each behavior's fixed
  trigger count and strategic job.

## Limitations

- The external sources explain real motion or strategic ordering; they do not
  validate Paint Mountain balance values.
- No queued-ball implementation or playtest exists yet.
- Exact bounce, fan, fuse, trail, and quota values remain subject to the bounded
  evidence-based tuning allowed by the ExecPlan.
