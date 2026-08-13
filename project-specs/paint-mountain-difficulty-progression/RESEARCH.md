---
type: evidence
status: active
created: 2026-08-13
topic: five replacement difficulty systems
scope: local product evidence and comparative analysis
related:
  - research-context/02-synthesis.md
  - research-context/exploration/01-candidate-ledger.md
  - research-context/exploration/02-comparison-and-selection.md
---

# Replacement Difficulty Research

## Purpose

Preserve the evidence used to create and compare five new difficulty systems
after the earlier route-ladder proposal was rejected.

## Sources

- `docs/source-brief.md`
- `.agents/Documentation.md`
- `docs/design-spec.md`
- `docs/technical-architecture.md`
- `src/stage/stage_controller.gd`
- `src/stage/stage_progression_data.gd`
- `src/projectile/projectile_manager.gd`
- `src/projectile/paint_projectile.gd`
- `resources/mechanisms/*.tres`
- `research-context/research/01-local-product-truth.md`

## Findings

- The core puzzle is pre-launch planning; difficulty should not depend on
  post-launch steering.
- Root launches already expose a 0-100 power choice and a stage shot limit.
- `StageController` is the correct owner for a stage-wide consumable rule.
- Splitter creates derived projectiles, so charging every projectile would
  make one mechanism secretly expensive and break player expectations.
- Two active root launches and mechanism cooldowns make relay play technically
  plausible, but it moves pressure toward execution timing.
- Paint projectiles do not currently collide with each other; resident-ball
  bumpers therefore require a material physics change.
- `PaintSystem` can continue to own one target mask if separated target regions
  are ever explored; no second coverage representation is needed.
- The current Quiet Context HUD favors one compact authoritative value and
  conditional reason over a new panel or tutorial.

## Recommendations

- Implement Shared Propellant first.
- Treat 100/90/82/75/68 as calibration starting points, not proven balance.
- Require allocation reachability and two-strategy representative playtests
  before catalog promotion.
- Use Target Archipelago only if Shared Propellant fails playtesting for reasons
  that cannot be fixed through budget tuning.

## Limitations

- No gameplay implementation or balance trial has occurred.
- Exact useful allocations depend on the current stage geometry and trajectory
  solver and must be measured during implementation.
