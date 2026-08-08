---
type: plan
status: active
created: 2026-08-08
scope: direct aim input, pure approximate landing feedback, and retirement of human exact target solving
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../Documentation.md
  - 2026-08-08-terrain-targeted-aiming.md
---

# Instant Approximate Landing Feedback - Execution Contract

Replace the slow Human-only exact terrain-target inversion with immediate direct
yaw, elevation, and power control plus a cheap top-view landing envelope. Keep
the real projectile, collision, paint, replay, and advisory exact trajectory as
the authorities for what actually happens after Fire.

## Purpose

- Objective: every Human aim edit changes the cannon immediately and publishes
  a stable coarse answer to “roughly where will this land?” without raycasts,
  collision queries, candidate searches, or waiting for a physics job.
- Deliverable: a pure landing estimator and immutable result contract, direct
  aim input, one simplified advisory prediction scheduler, migrated tests and
  capture helpers, and measured runtime evidence.
- Completion state: no Human action depends on exact inverse solving; Fire is
  admitted from the current legal aim and normal stage rules; the future map or
  HUD can project normalized landing data onto any top-view grid.

## Product Decision

The planning puzzle remains “choose yaw, elevation, and power, then fire with no
in-flight steering.” The change removes false precision and solver waiting. The
coarse indicator is an estimate, not a target lock and not a promise of contact.

Human controls after this change:

- left drag: horizontal motion changes yaw and vertical motion changes elevation;
- A/D: yaw in 0.5-degree steps, W/S: elevation in 0.5-degree steps;
- wheel and existing power buttons: power;
- existing elevation buttons: elevation;
- Space or Fire: immediately asks `StageController` to fire the current legal tuple.

No new gameplay action, steering mode, target selection, or serialized state is
introduced.

## Scope and Boundaries

In scope:

- `AimInputController` direct drag and keyboard intent.
- `CannonController` canonical aim mutation and removal of pending Human revisions.
- A pure `ApproximateLandingEstimator`, immutable height-band input, and immutable
  `ApproximateLandingEnvelope` output.
- A small runtime coordinator that recomputes the envelope on aim or relevant
  wind-context changes and emits one narrow signal for future presentation.
- Removal of the exact Human terrain-target controller, ray picker, solver,
  target state preview, and target-solution branch in the scheduler.
- Migration of tests, delivery captures, specs, and current implementation record.

Out of scope:

- Rendering a top-view grid, minimap, landing ellipse, or new HUD component.
- Changing projectile rigid-body physics, collision, paint, target coverage,
  stage generation, mechanisms, progression, catalog identity, or stage values.
- Changing replay/save/attempt formats or the direct agent/debug `AimTuple` API.
- Replacing the existing exact world trajectory and first-impact preview. It stays
  advisory and computes only after the latest input settles.

Architecture invariants:

- `StageController` remains the sole Fire-admission, shot-progression, clear, and
  failure owner.
- `CannonController` remains the single canonical current-aim owner.
- `PaintSystem` remains the single mutable paint and coverage owner.
- `GeneratedStageLayout` remains the only terrain-shape authority. The landing
  estimator may receive three immutable scalar height summaries, but cannot own
  a second grid, heightmap, collision mesh, target mask, or coverage representation.
- The estimate never calls `PhysicsDirectSpaceState3D`, never changes Fire
  readiness, and never replaces a live collision result.

Destructive or irreversible actions:

- Obsolete exact-target scripts and their focused tests may be deleted only
  after their replacements pass and `rg` proves no production or delivery
  references remain. Git retains recovery history.

Exact actions requiring owner or user approval:

- None. This document plans only repository-local code and docs. It adds no
  dependency, network service, plugin, asset, or schema migration.

## Verified Current State

| Concern | Current evidence | Decision |
| --- | --- | --- |
| Human aim path | `AimInputController` emits screen positions; `TerrainAimController` holds a committed target and Human revision; `TerrainAimSolver` nominates candidates; `TrajectoryPredictionScheduler` validates each candidate through exact physics | Remove this entire inverse-target chain from the Human runtime |
| Fire readiness | `StageController` rejects Human Fire while `CannonController.human_aim_revision_pending()` is true | Delete this pending gate; keep legal canonical aim, capacity, origin lock, and stage state checks |
| Exact preview | `TrajectoryPredictionScheduler` already owns one bounded advisory `TrajectoryPredictionJob` and publishes a context-matched trajectory | Keep only this preview branch, with latest-only coalescing and no target work |
| Canonical terrain | `TerrainSurface.layout_read_only()` exposes the accepted `GeneratedStageLayout`; its top topology exposes canonical vertices; `StageData.paint_world_bounds()` exposes XZ bounds | Derive three scalar heights once at stage configuration; never sample terrain during an aim edit |
| Wind | `WindController.sample_at_offset()` deterministically exposes the same schedule used by prediction | Sample the schedule in the pure recurrence; do not query live physics |
| Input coverage | Current W/S and wheel/button controls exist; A/D and drag do not directly change the tuple | Restore resolution-stable direct yaw/elevation drag and A/D yaw while preserving current keyboard repeat timing |
| Compatibility | Replay and agent/debug flows call canonical tuple APIs, while delivery and several tests directly reference terrain-target types | Preserve tuple APIs; migrate delivery helpers before deleting exact-target types |

Discovery closure:

- Product, architecture, input, data, compatibility, deletion, and validation
  choices are locked above.
- The exact solver's measured complexity is no longer relevant to Human input;
  the replacement has fixed work and no collision queries.
- Remaining unknowns are implementation-local and cannot change this contract.

## Locked Approximation Algorithm

### Immutable stage summary

At stage configuration, build `LandingHeightBand` from the canonical top
vertices already owned by `GeneratedStageLayout`:

- `low_y`: 20th percentile top-surface height;
- `center_y`: 50th percentile top-surface height;
- `high_y`: 80th percentile top-surface height;
- `world_xz_bounds`: the existing `StageData.paint_world_bounds()`.

The percentile sort happens once per accepted layout. Only these scalars and the
existing bounds survive. This is a summary, not a second terrain representation.

### Pure fixed-step estimate

For each current aim tuple:

1. Start from the cannon's shared launch origin and launch velocity.
2. Advance at the project fixed 60 Hz for at most 13 seconds (780 fixed steps),
   using the same damp-then-gravity-then-position order as
   `TrajectoryPredictionJob` and the deterministic wind sample for each tick.
3. On the descending branch, linearly interpolate the XZ crossings of `high_y`,
   `center_y`, and `low_y`. These become near, center, and far samples.
4. Normalize every sample against `world_xz_bounds`. Preserve unclamped values
   so a consumer can distinguish an off-map shot; provide clamped values only
   for display projection.
5. Classify the result as `IN_BOUNDS`, `EDGE_OR_EXIT`, `NO_DESCENDING_CROSSING`,
   or `INVALID_INPUT`. Report the lateral/longitudinal span between crossings as
   uncertainty, not confidence theatre.

`ApproximateLandingEnvelope` contains only immutable values: classification,
three world XZ samples when available, three normalized samples, center sample,
uncertainty extents, elapsed estimate time, and the aim/wind context key. It
does not contain a collider, terrain triangle, target identity, or “hit” flag.

The future top-view renderer may quantize normalized samples to a grid (for
example 12 by 8), but grid size and drawing remain presentation policy. The
estimator returns continuous normalized coordinates so it does not become a UI
owner.

### Runtime cadence

- Recompute synchronously on canonical `aim_changed` and when the wind context
  key changes enough to invalidate the displayed envelope.
- Publish only when the context key or immutable result changes.
- Keep exact trajectory prediction coalesced during drag and request its latest
  job immediately on drag release, stage entry, camera return, and relevant wind
  boundaries.
- The estimate is always advisory and cannot be read by `StageController`.

## Tasks

### Phase 1: Authority and pure contracts

Goal: record the supersession and land deterministic data boundaries before
changing the Human flow.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`,
`docs/technical-architecture.md`, `src/cannon/`, `src/stage_generation/`

- [ ] **1.1** Record the later user supersession.
  - Change: state that Human terrain clicking and exact inverse target retention
    are replaced by direct tuple control and an approximate top-view-ready
    envelope. Preserve no-steering and exact live physics clauses.
  - Accept: the source brief, design spec, and technical architecture name one
    consistent current Human aim path and label older exact-target docs historical.
- [ ] **1.2** Add the immutable approximation contracts and pure estimator.
  - Change: implement `LandingHeightBand`, `ApproximateLandingEnvelope`, and
    `ApproximateLandingEstimator`; derive the height band once from the accepted
    layout and reuse shared ballistic/wind constants.
  - Accept: focused tests prove deterministic output, finite values, monotonic
    yaw rotation, longer center range for a representative power increase,
    meaningful low/center/high ordering, all classifications, and zero physics
    or scene-tree dependency.
  - Guard: no copied terrain grid, target mask, collider query, node lookup, or
    mutable array enters the estimator result.

### Phase 2: Immediate Human flow and scheduler simplification

Goal: make every Human edit immediate and retire competing exact-target owners.

Source owners: `src/input/aim_input_controller.gd`,
`src/cannon/cannon_controller.gd`, `src/cannon/trajectory_prediction_scheduler.gd`,
`src/gameplay/gameplay_scene.gd`, `src/stage/stage_controller.gd`,
`scenes/gameplay/gameplay.tscn`, `src/delivery/delivery_capture_runner.gd`

- [ ] **2.1** Replace inverse targeting with direct canonical aim changes.
  - Change: emit and apply resolution-stable drag deltas, A/D yaw, W/S
    elevation, and existing power/elevation steps through the canonical tuple
    path; add the runtime envelope coordinator and narrow change signal.
  - Accept: the cannon visibly and numerically changes on the same input frame;
    100 rapid drag samples leave exactly the newest canonical aim and newest
    envelope with no pending revision state.
  - Guard: Map Inspection, focus routing, key repeat timing, action-origin locks,
    direct agent/debug tuple actions, and no in-flight steering remain unchanged.
- [ ] **2.2** Reduce prediction and Fire admission to one owner each.
  - Change: remove target requests, candidate nomination, solver callbacks, and
    target-job state from `TrajectoryPredictionScheduler`; remove pending Human
    revision methods and Fire gate; migrate delivery captures to direct tuples.
  - Accept: scheduler owns at most one replaceable preview job, settled input
    publishes the latest exact advisory preview, and Human Fire succeeds or
    fails only from `StageController`'s canonical legal-aim and stage rules.
- [ ] **2.3** Retire obsolete exact-target files safely.
  - Change: after replacement tests pass, remove `TerrainAimController`,
    `TerrainAimSolver`, `TerrainAimTarget`, `TerrainAimSolution`,
    `TerrainScreenRayPicker`, `TerrainTargetPreview`, their scene nodes, and
    exact-target-only tests.
  - Accept: `rg -n "TerrainAim|TerrainScreenRayPicker|TerrainTargetPreview|human_aim_revision_pending" src scenes tests`
    returns no active reference; delivery capture and project import still pass.
  - Guard: do not remove shared trajectory, ballistic, replay, terrain-topology,
    or direct reachability generation code merely because an exact-target test
    used it.

### Phase 3: Regression, timing, and durable evidence

Goal: prove that the simpler path is immediate, compatible, and truthful.

Source owners: `tests/`, `.agents/evidence/instant-approximate-landing-feedback-2026-08-08/`,
`.agents/Documentation.md`, `docs/test-checklist.md`

- [ ] **3.1** Replace and migrate focused contracts.
  - Change: add `tests/approximate_landing_estimator_test.gd`; rewrite the Human
    sections of `aim_interaction_test.gd`; simplify `prediction_scheduler_test.gd`
    and `stage10_prediction_readiness_test.gd`; migrate
    `phase8_debug_test.gd`, `replay_fractional_contact_test.gd`, delivery capture
    helpers, and any remaining exact-target fixtures.
  - Accept: direct input, estimator, scheduler, Fire, replay, and capture tests
    pass under Godot 4.7.1 with no compatibility shim that preserves the old
    target solver.
- [ ] **3.2** Measure the fixed-cost path and inspect the real game.
  - Change: benchmark 1,000 estimator calls for Stage 1, 10, and 30 contexts;
    record median, p95, maximum, iteration count, and proof of zero space-state
    queries. Export and capture Aim View before input, during rapid adjustment,
    after settled exact preview, and immediately after Fire.
  - Accept: on the delivery machine p95 estimate cost is at most 0.25 ms and
    maximum at most 0.50 ms; no frame waits for an estimate; runtime captures
    show current aim values and Fire responsiveness without a target-lock state.
  - Contingency: if the fixed 780-step loop misses the budget, keep 60 Hz wind
    samples but evaluate every fourth position sample using the closed discrete
    recurrence. Do not reintroduce raycasts, candidate search, or background jobs.
- [ ] **3.3** Finish durable records and gates.
  - Change: update `.agents/Documentation.md`, `docs/test-checklist.md`, and an
    evidence README; mark this plan done only after all checks pass.
  - Accept: current docs describe direct aim plus coarse feedback as implemented,
    while the old exact-target plan is explicitly historical.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Pure estimator | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/approximate_landing_estimator_test.gd` | Phase 1.2 changes | Estimator contract or test changes |
| Human flow | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/aim_interaction_test.gd` | Phase 2.1 changes | Input/controller changes |
| Scheduler | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/prediction_scheduler_test.gd` | Phase 2.2 changes | Scheduler changes |
| Replay contact | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script res://tests/replay_fractional_contact_test.gd` | Compatibility owners change | Replay/cannon/projectile changes |
| Project gate | `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1` | All focused checks pass | Script, scene, resource, or project-setting changes |
| Release export | `& 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'` | Project gate passes | Export-owned input changes |
| Document gate | `git diff --check` | Evidence and records are complete | Touched text changes |

Run the narrowest check that proves the active task. Defer the broad ordered
`scripts/test.ps1` suite unless a focused failure crosses subsystem boundaries;
before running it, explain its cost and stopping condition and obtain the user
alignment required by repository policy.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary |
| --- | --- | --- |
| Approximate crossings are absent for a legal upward shot | Publish `NO_DESCENDING_CROSSING` with the last finite normalized sample | Do not fabricate an impact point |
| The center sample lies outside the map | Publish unclamped and clamped normalized values plus `EDGE_OR_EXIT` | Do not silently snap gameplay physics to the map |
| Exact advisory preview later disagrees with the envelope | Keep both truthful: the envelope stays coarse and the exact preview replaces only its own world marker | Neither result gates Fire |
| A deleted target type still has a delivery/test consumer | Migrate that consumer to direct tuple intent, then rerun `rg` | Do not add a deprecated compatibility wrapper |
| Fixed cost misses the locked budget | Apply the four-step closed-recurrence contingency and remeasure once | No physics query or async solver is permitted |
| A verified material fact contradicts this contract | Stop the affected branch and revise the plan before implementation continues | Do not choose a new product or architecture contract ad hoc |

## Anti-Rework Sequence

Land and test the pure estimator first because it has no scene dependency. Then
switch Human input and Fire readiness while old exact-target files still exist
for comparison. Migrate delivery and regression consumers next. Delete the old
stack only after zero-reference proof. Run import/verify once after deletions,
then one release export and one rendered evidence batch. Do not repeatedly run
the full project suite or export while the ownership graph is still changing.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1.
- Next task: 1.1.
- Last completed gate: Discovery Closure.
- Update rule: check a task and advance this pointer only after its named
  acceptance evidence exists.

## Completion and Stop Conditions

Complete when every task, guard, focused gate, project gate, release export, and
rendered evidence check passes; current docs name one Human aim path; obsolete
target-solver references are absent; and frontmatter status is `done`.

Replan only when verified material evidence invalidates the locked product,
architecture, dependency, compatibility, safety, or validation contract. Do
not replan for ordinary implementation details, a passing check whose inputs did
not change, or a coarse estimate that honestly reports its uncertainty.
