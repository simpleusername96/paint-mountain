---
type: evidence
status: active
created: 2026-08-10
scope: architecture, failure-path, maintainability, and runtime-efficiency review of current Godot code
source: ../execplans/2026-08-10-codebase-efficiency-review.md
related:
  - ../Documentation.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
---

# Codebase Efficiency Review Evidence

## Purpose

Identify reachable correctness risks, competing responsibility, duplicated
work, and production overhead using callers, contracts, tests, and current
history rather than file size alone.

## Sources

- Commit `fc02848dc2abad7ee7c8518c4faa6374f57bd452`.
- Current architecture, implementation record, production scripts/scenes/
  resources, focused tests, symbol references, and targeted Git history.
- Godot 4.7.1 smoke verification and focused scheduler, range, rapid-fire,
  paint queue, repository, projectile, camera, aiming, and observation tests.

## Findings

### High: partial source catalogs do not fail closed

`scripts/build_stage_catalog.gd::_build_catalog()` accepts any resource with
`ordered_stages()`. If it contains 27 to 29 stages, the builder appends up to
three legacy sources and then rewrites those inputs as later canonical stages.
`StageCatalogData.ordered_stages()` does not validate completeness, and the
final validation checks the rewritten output instead of the source identity.

Smallest safe fix: make the 30-stage count part of `StageCatalogData.is_valid`,
require a valid current catalog before materialization, remove the ineffective
legacy append path, and add 27/28/29-stage regression checks.

### Medium-high: direct reachability duplicates ballistic recurrence

`DirectReachabilityValidator._build_solver_cache()` and
`_damped_position_at_horizontal_range_cached()` duplicate recurrence and
interpolation already owned by `CannonBallistics`. The current path is reached
by the offline catalog builder and `DefaultAimSolver`; a later physics change
could make target solving disagree with range admission or prediction.

Smallest safe fix: build the recurrence through
`CannonBallistics.build_damped_motion_cache()` and call
`CannonBallistics.damped_position_at_horizontal_range()`, retaining only the
validator's speed and trigonometric lookup tables.

### Low: retired and unconsumed diagnostic surfaces remain

- `DirectReachabilityValidator.validate_predictor()`, `build_certificate()`,
  and `certificate_matches()` have no repository caller. The first is the
  retired exhaustive target-wide proof. Its private reuse helpers are also
  dead. The optional `DirectReachabilityCertificate` data compatibility remains
  live and must stay.
- `PaintSystem` exposes three unconsumed drain/cache metrics. Maintaining them
  adds two clock reads per non-empty drain plus otherwise unused counters.
- `CameraDirector.follow_wide_is_latched()` is a no-op; its safety-solve counter
  and getter have no consumer.
- `GameplayScene.prediction_compute_count()` only forwards the still-tested
  scheduler diagnostic and has no repository consumer.

Smallest safe fix: remove only these dead methods, backing counters, and helpers;
preserve the certificate schema, scheduler counter, camera modes, paint caches,
and used texture-upload diagnostics.

### Blocked: queue budgets lack a policy owner and value

The architecture calls for bounded projectile, split, effect, and paint-command
queues, but the public request paths do not enforce an explicit budget or a
complete rejection signal. Normal production cadence is bounded by active
projectile limits, so this is a contract gap rather than a measured leak.
Implementation is blocked until a typed owner, budget values, and rejection
semantics are selected. No value should be invented during cleanup.

### Clean candidates

`StageController`, `PaintSystem`, `ProjectileManager`, `PaintProjectile`,
`CameraDirector`, `DeliveryCaptureRunner`, `GameplayScene`,
`SeededStageGenerator`, `StageLayoutRepository`, the prediction job/scheduler,
and `MechanismLoadoutPlanner` remain cohesive in their documented roles. Large
line counts and churn did not establish further defects or optimization work.

## Validation Baseline

- `scripts/verify.ps1`: passed.
- Active catalog read-only verification: passed with 30 stages and manifest
  `701b3b63...`.
- Focused scheduler, range, rapid-fire, paint queue, repository, projectile
  capacity/contact, camera safety, aiming composition, and shot-observation
  checks: passed.
- No broad suite, profiler run, generated-catalog write, or visible game run was
  needed to establish these findings.

## Recommendations

Implement the catalog guard, shared ballistic owner, and dead-surface cleanup
as one bounded maintenance contract. Keep the queue-budget finding deferred as
an explicit architecture decision.
