---
type: evidence
status: active
created: 2026-08-10
last_reviewed: 2026-08-10
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
- Follow-up physical/nonblank/code line inventory at commit `5c88cfa`, plus a
  direct responsibility review of every production script over 700 lines and
  the eight largest production scripts.

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

### Follow-up correction: large-file responsibility findings

The earlier clean-candidate conclusion was too broad. Passing tests and a
single documented system owner disprove a current functional defect, but they
do not prove that one file has one reason to change. The current tree has six
production scripts above 700 physical lines and three above 1,000.

#### High: offline catalog entrypoint is a catch-all

`scripts/build_stage_catalog.gd` has 1,200 physical lines, 1,061 approximate
code lines, and 50 functions. It combines independently changing concerns:

- command parsing and process exit at lines 18-88;
- generation and witness diagnostics at lines 144-443;
- stage/profile/route/mechanism materialization policy at lines 444-739;
- bundle writing, promotion, rollback, manifest verification, and hashing at
  lines 747-1200.

`StageProgressionData`, `StageLayoutBakeCodec`, `SeededStageGenerator`,
`DirectReachabilityValidator`, and `StageCatalogData` already own several of
the underlying rules. The script remains the unbounded integration owner for
materialization and bundle storage. Artifact tests cover output identity, but
no focused test directly exercises its promotion and rollback branches.

Smallest safe direction: keep CLI parsing, exit handling, and orchestration in
the entrypoint; extract materialization, witness adaptation, and transactional
bundle/manifest I/O behind named offline boundaries.

#### Medium-high: direct reachability mixes solver and physical parity

`src/stage_generation/direct_reachability_validator.gd` has 1,191 physical
lines, 1,079 approximate code lines, and 33 functions. It combines bounded
inverse solving at lines 464-938 with real-rigidbody batch reconciliation at
lines 211-457, then carries diagnostics and contact/checksum identity helpers
through line 1191. Runtime `DefaultAimSolver` consumes the solve/select surface,
while the offline catalog builder consumes summit and rigidbody validation.
Those paths change for different reasons and have different runtime costs.

Smallest safe direction: separate target solving from rigidbody parity while
preserving the current static façade until consumers and parity tests migrate.

#### Medium-low: delivery capture harness is overly broad tooling

`src/delivery/delivery_capture_runner.gd` has 977 physical lines and 34
functions. It combines argument/window/output lifecycle with more than twenty
scenario bodies and paint-fixture searches, and some scenarios reach private
app or camera state. This does not affect ordinary gameplay when capture
arguments are absent, but it is a maintenance and release-evidence risk with no
focused unit test for the runner.

Smallest safe direction: retain common capture lifecycle in the runner, move
scenario bodies behind a registry or named scenario modules, and replace
private-state reads with narrow diagnostic APIs only where needed.

#### Large but currently cohesive owners

- `PaintSystem`: 1,002 physical lines and 68 functions. Queueing,
  rasterization, coverage/checksum, topology caching, and texture publication
  all serve the single authoritative mask required by architecture. Treat size
  as a growth warning; any extraction must remain an internal implementation
  helper and must not create another coverage representation.
- `StageController`: 828 physical lines and 48 functions. Action admission,
  state transitions, clock, result barrier, and observation sealing are part of
  its explicit state/result authority. Clock or observation coordination may
  later delegate to helpers, but authority must remain here.
- `CameraDirector`: 761 physical lines and 51 functions. It is broad across map
  inspection, framing, follow, safety, smoothing, and shake, but pure framing
  already delegates to `TerrainCameraFramer` and tests cover the combined
  owner. Treat it as a monitored boundary rather than a current extraction
  mandate.
- `PaintProjectile` (635 lines) and `MechanismLoadoutPlanner` (615 lines) are
  the remaining top-eight files. Their inspected responsibilities are coupled
  entity behavior and placement constraints respectively; length alone does
  not justify a split.

### Implemented responsibility correction

The high and medium-high catch-all findings were corrected under the separate
responsibility-decomposition ExecPlan:

- `build_stage_catalog.gd`: 1,200 to 393 physical lines. It retains CLI,
  generation orchestration, and witness adaptation while private preloaded
  owners now contain deterministic materialization (304 lines) and bundle
  storage/verification (516 lines).
- `DirectReachabilityValidator`: 1,191 to 624 physical lines. Its compatibility
  façade and physical parity remain; the source-equal analytic target solver is
  a private 578-line implementation owner.
- The extraction adds no global class API and no second catalog, coverage, or
  physics representation. A mechanical comparison found only entrypoint-name
  changes and trailing blank-line removal in moved blocks.

The delivery runner remains a lower-impact tooling decomposition candidate.
`PaintSystem`, `StageController`, and `CameraDirector` remain monitored large
owners; this pass found no evidence that a mechanical split would improve their
authority or runtime safety.

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
an explicit architecture decision. Treat the follow-up responsibility findings
as a separate refactoring contract: start with the offline catalog boundaries,
then split reachability solving from physical parity, and keep the delivery
harness as a lower-impact tooling batch. Do not mechanically split
`PaintSystem`, `StageController`, or `CameraDirector` by line count.
