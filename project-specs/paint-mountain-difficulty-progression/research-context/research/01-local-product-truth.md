---
type: evidence
status: active
created: 2026-08-13
topic: local implementation facts relevant to five new candidates
scope: current stage, projectile, mechanism, paint, and HUD ownership
---

# Local Product Truth

## Purpose

Record only current facts that materially constrain the five candidates.

## Sources

- `docs/source-brief.md`
- `.agents/Documentation.md`
- `src/stage/stage_controller.gd`
- `src/stage/stage_progression_data.gd`
- `src/projectile/projectile_manager.gd`
- `src/projectile/paint_projectile.gd`
- `src/cannon/cannon_controller.gd`
- `resources/mechanisms/*.tres`
- `.agents/design/UIUX_GUIDELINES.md`

## Findings

- The player chooses pre-launch target, elevation, and power and never steers a
  projectile in flight.
- `StageController` alone owns stage state, shot progression, and outcomes.
- `PaintSystem` alone owns the mutable paint mask and coverage.
- Power is an existing 0-100 launch input.
- The projectile manager permits two active root launches and up to 21 resident
  bodies; terrain-resting balls can remain active.
- Paint projectiles currently collide with terrain/mechanisms but not with their
  own projectile layer.
- Burst has a limited charge; Splitter and Uphill Rebound use cooldown behavior.
- Current stage progression already varies target, shots, time, terrain, routes,
  relief, and mechanism count.
- The Quiet Context HUD requires the mountain to remain dominant and favors
  compact authoritative status over explanatory panels.

## Limitations

- These facts do not prove candidate fun or balance.
