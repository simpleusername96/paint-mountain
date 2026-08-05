---
type: plan
status: done
created: 2026-08-06
last_reviewed: 2026-08-06
scope: generation-time projectile-range admission and responsive stage-layout preparation
source: source brief plus the user's 2026-08-06 direction
supersedes:
  - 2026-08-05-gameplay-contract-recovery.md
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
---

# Ballistic Terrain Preparation - Execution Contract

## Purpose

- Objective: reject generated terrain whose scoreable surface falls outside the
  cannon's legal ballistic domain, and remove cold terrain generation from the
  main-thread navigation path.
- Deliverable: one pure generation-time range constraint, one AppRoot-owned
  asynchronous layout preparer with a bounded cache, truthful preparation UI,
  and deterministic non-rendered acceptance checks.
- Completion state: a cold stage request never calls the generator synchronously
  from AppRoot; every generated scoreable target sample passes the analytic
  domain gate; selected/current/next layouts are prepared without retaining
  runtime world state; and focused headless checks pass.

## Verified Evidence

- At task start, `SeededStageGenerator._finalize_layout()` created the target mask
  after structural validation but does not know the cannon or projectile range.
- `TargetMaskRasterizer.build()` already visits every scoreable target sample and
  has its exact top-surface point and normal, so it is the cheapest place to
  reject a whole candidate without a second mask scan.
- At task start, `AppRoot._layout_for_stage()` invoked
  `SeededStageGenerator.generate()` synchronously on a cache miss. Startup also
  reaches that path while constructing the menu preview.
- At task start, the process-lifetime layout cache was unbounded, GameplayScene
  attached runtime annotations to a cached layout, and preview artifacts retained
  heavier mesh, texture, material, and dressing objects.
- `TrajectoryPredictor` advances damped velocity at 60 Hz for at most 720 steps.
  `AimTuple`, `ProjectileData`, and the fixed cannon muzzle geometry own the
  legal input and launch bounds.

## Locked Decisions

1. The generation gate is a pure analytic necessary condition. It checks the
   legal yaw fan, horizontal horizon, and maximum reachable height with the same
   launch speed, damping, gravity, muzzle offsets, physics step, and horizon as
   runtime prediction. It does not claim terrain-occlusion or first-hit proof.
2. Every target pixel is checked while the immutable mask is rasterized. One
   failing pixel rejects the candidate; the gate never crops or edits the target
   footprint to force acceptance.
3. At least one canonical summit-region sample must also lie inside the analytic
   domain. This preserves the separate summit intent without claiming a first
   physical contact witness.
4. Shared launch-origin and damped-motion math belongs to `CannonBallistics`.
   Runtime and generation code must not maintain competing muzzle or recurrence
   formulas.
5. `StageLayoutPreparer`, owned by `AppRoot`, runs only pure layout generation on
   one worker thread. Scene tree, renderer, physics-world, mesh, textures,
   dressing, mechanisms as Nodes, and paint state stay on the main thread.
6. AppRoot never falls back to synchronous generation on Start. A cold request
   leaves the current screen visible and responsive, disables the relevant
   primary action with a short preparing label, then starts when the exact
   requested layout arrives.
7. The immutable layout cache holds at most three entries, sufficient for the
   selected/current/next policy. The heavy preview-artifact cache holds at most
   one entry.
8. After Stage N starts, AppRoot queues only Stage N+1 at low priority. Selection
   intent is urgent and supersedes queued, obsolete selection work; an already
   running pure generation may finish and be harmlessly discarded or cached.
9. This change is validated without foreground or rendered gameplay. Focused
   algorithm/thread tests and the repository's mandatory headless import/start
   smoke check are the stopping evidence.

## Scope

- Shared ballistic math and fixed muzzle geometry.
- A pure `ProjectileRangeConstraint` integrated with target-mask finalization.
- Summit analytic-domain admission and diagnostic generation metrics.
- AppRoot-owned asynchronous layout generation, bounded retention, selection
  prefetch, next-stage prefetch, and truthful readiness states.
- Focused deterministic tests and current documentation.

## Non-scope

- Replacing the stronger predictor/Rigidbody first-hit certification contract.
- Changing the authoritative terrain, collider, paint mask, or runtime gameplay
  construction path.
- Parallel generation with multiple worker threads.
- Persisting generated layouts across processes or adding dependencies.
- Visual redesign, rendered capture, foreground play testing, or export rebuild.
- Cleaning temporary evidence and candidate-catalog artifacts from the stopped
  session unless the user separately requests it.

## Architecture Ownership

- `CannonBallistics`: launch direction, launch origin, and fixed-step damped
  motion recurrence shared by runtime and pure generation checks.
- `ProjectileRangeConstraint`: one immutable stage/projectile analytic domain and
  its per-surface/summit evaluations.
- `TargetMaskRasterizer`: scoreable-footprint construction and whole-candidate
  range admission while visiting each included sample.
- `SeededStageGenerator`: candidate lifecycle, metrics, and final acceptance.
- `StageLayoutPreparer`: one worker, request ordering, result publication, and
  bounded immutable-layout retention.
- `AppRoot`: navigation intent, screen readiness, gameplay handoff, preview
  materialization, and adjacent-stage scheduling.
- Screen scripts: display readiness only; they do not generate terrain.

## Ordered Tasks

- [x] Add shared launch-origin and damped-recurrence helpers, then make the
  runtime cannon use the shared origin contract.
- [x] Add the pure ballistic-domain constraint and reject target/summit samples
  from `SeededStageGenerator._finalize_layout()`.
- [x] Add one focused algorithm test covering legal, yaw-outside, height-outside,
  horizon-outside, and generated-stage integration cases.
- [x] Add the single-worker bounded layout preparer and remove synchronous
  generation from AppRoot startup/navigation.
- [x] Add truthful preparing/failure UI state and selected/next prefetch.
- [x] Add a focused non-rendered preparer test, then run the required headless
  repository verification once the implementation is stable.
- [x] Update implemented-status/spec/checklist records, run the scoped quality
  audit, and commit only the coherent task-owned change.

## Acceptance Checks

- A synthetic surface beyond the yaw fan, horizontal damped horizon, or maximum
  reachable height is rejected with a stable diagnostic reason.
- A legal in-domain surface is accepted by the pure constraint.
- Production `SeededStageGenerator.generate()` cannot install a target mask if
  any included target sample is outside the domain.
- Generated layout metrics record checked target count and minimum analytic
  margins, and at least one summit sample passes.
- AppRoot contains no synchronous call to `SeededStageGenerator.generate()`.
- Two process frames can advance while a cold layout is pending; the current
  screen stays visible and its primary action reports preparation truthfully.
- Ready layouts match stage/profile/version/seed identity. Cache retention never
  exceeds three layouts, and preview retention never exceeds one artifact.
- Starting Stage N schedules only the catalog's Stage N+1 when one exists.

## Regression Guards

- Do not mutate `StageData`, generation profiles, or completed layouts on the
  worker thread after publication.
- Do not instantiate Nodes, meshes, textures, materials, or physics queries on
  the worker thread.
- Do not remove target pixels to make a seed pass.
- Do not report the analytic-domain gate as first-hit reachability proof.
- Keep the 60 Hz step and 720-step horizon aligned with `TrajectoryPredictor`.
- Join the worker thread before its owner exits the tree.

## Validation Commands

Use the locally approved Godot 4.7 console binary when present:

```powershell
& 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script tests/projectile_range_constraint_test.gd
& 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe' --headless --path . --script tests/stage_layout_preparer_test.gd
& 'scripts\verify.ps1' -GodotPath 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
```

Do not run the exhaustive physical target certificate, foreground gameplay, or
rendered capture for this contract.

## Contingencies

- If the current persisted seed fails the new analytic gate, report the exact
  failing sample and generate a new accepted seed offline; do not crop the mask.
- If a generator dependency proves unsafe on the worker, isolate or precompute
  that pure data on the main thread. Do not move scene/render/physics work onto
  the worker and do not restore synchronous navigation generation.
- If preparation fails, keep the initiating screen visible, show a stable
  unavailable state, and permit a later explicit retry.

## Progress

- [x] Read-only trace of generation admission, navigation costs, caches, current
  dirty worktree, active design guidance, and thread-safety constraints.
- [x] Architecture and validation decisions locked.
- [x] Implementation complete.
- [x] Focused checks and mandatory headless verification pass.
- [x] Documentation, audit, and scoped commit complete.

## Outcome

The shared ballistic range gate, immutable runtime-copy boundary, single-worker
layout preparer, bounded caches, and truthful readiness UI are implemented.
Focused non-rendered tests and the repository headless smoke check pass. The
separate terrain-occlusion and first-hit certificate remains outside this
completed plan.

## Stop Conditions

Stop and report rather than broadening scope if the change requires a production
dependency, scene/render/physics work on the worker thread, deleting stopped-
session artifacts, changing the authoritative paint/collision surface, or
weakening the separate first-hit certification requirement.
