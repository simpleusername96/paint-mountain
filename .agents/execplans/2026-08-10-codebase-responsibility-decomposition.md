---
type: plan
status: done
created: 2026-08-10
last_reviewed: 2026-08-10
scope: split the two verified catch-all GDScript owners without changing catalog, aiming, physics, or runtime behavior
related:
  - ../evidence/2026-08-10-codebase-efficiency-review.md
  - 2026-08-10-repository-maintenance-corrections.md
  - 2026-08-10-aggressive-repository-cleanup.md
  - ../../docs/technical-architecture.md
---

# Codebase Responsibility Decomposition - Execution Contract

At commit `5c88cfa`, focused catalog tests and project verification pass, but a
follow-up responsibility audit proves that the offline catalog entrypoint and
direct reachability validator each contain independently changing domains. This
contract preserves every current public call and artifact while moving those
domains behind narrow, named boundaries.

## Purpose

- Objective: remove verified catch-all ownership from the two highest-risk
  production scripts without changing generated data or gameplay.
- Deliverable: a thin catalog CLI/orchestrator backed by materialization and
  bundle-storage owners, plus a direct reachability façade backed by a
  single-target inverse solver.
- Completion state: the original public entrypoints remain compatible, the
  extracted files own one documented reason to change, catalog and aiming
  diagnostics match current behavior, and Godot verification passes.

## Scope and Boundaries

In scope:

- Extract current stage/profile/route/mechanism materialization from
  `scripts/build_stage_catalog.gd` into `StageCatalogMaterializer`.
- Extract content-addressed catalog bundle writing, verification, promotion,
  rollback, and catalog-pointer replacement into `StageCatalogBundleStore`.
- Extract bounded single-target inverse solving from
  `DirectReachabilityValidator` into `DirectTargetAimSolver`; preserve the
  validator's existing static `solve_one_target()` façade.
- Add only focused compatibility coverage needed to protect the extracted
  boundaries.

Out of scope:

- Generated-catalog writes or promotion, catalog format/schema changes,
  progression tuning, physics changes, gameplay/UI behavior, queue-budget
  policy, delivery-capture decomposition, and line-count-only splitting of
  `PaintSystem`, `StageController`, `CameraDirector`, `PaintProjectile`, or
  `MechanismLoadoutPlanner`.
- New dependencies, plugins, tools, folders, or public APIs for consumers.

Constraints and invariants:

- `build_stage_catalog.gd` remains the CLI, exit-code, and workflow owner.
- `StageCatalogMaterializer` is deterministic domain transformation with no
  file I/O, scene-tree lifecycle, or process exit handling.
- `StageCatalogBundleStore` hides bundle filesystem and manifest mechanics;
  callers see only write, verify, promote, publish, hash, and witness-descriptor
  operations required by the existing workflow.
- `DirectReachabilityValidator` remains the compatibility façade and physical
  validation owner. `DirectTargetAimSolver` owns only single-target analytic
  nomination, prediction filtering, and its diagnostics.
- The active v10 manifest hash, all 30 layout payloads, entry witnesses, and
  Godot fixed-step physics behavior remain unchanged.

Destructive or irreversible actions:

- None. This plan does not write generated catalogs or delete local output.

Exact actions requiring owner or user approval:

- The user already authorized ExecPlan-backed code-quality fixes in this
  conversation and explicitly challenged large-script responsibility in the
  current turn. No additional approval remains for this behavior-preserving
  extraction.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Catalog CLI | `build_stage_catalog.gd:18-140` parses modes and owns exit behavior | current source and read-only catalog command | Keep in entrypoint | 1.3 |
| Progression materialization | `build_stage_catalog.gd:444-739` transforms stage/profile/route/mechanism data without I/O | 17-function contiguous block; `StageProgressionData` and typed Resources | Move intact to `StageCatalogMaterializer` | 1.1 |
| Bundle persistence | `build_stage_catalog.gd:747-1200` writes, verifies, promotes, rolls back, and replaces the pointer | file API use and manifest reconstruction | Move intact behind `StageCatalogBundleStore` | 1.2 |
| Direct target solving | `DirectReachabilityValidator:464-1035` performs inverse nomination and prediction filtering | runtime `DefaultAimSolver` and offline builder consumers | Move intact to `DirectTargetAimSolver`; façade delegates | 2.1 |
| Physical parity | `DirectReachabilityValidator:57-463` owns summit and rigidbody validation | offline builder consumer and checksums | Retain in validator | 2.1 |
| Large cohesive owners | Paint, stage, camera, projectile, and mechanism owners match architecture | follow-up top-eight audit | Do not split by line count | 3.1 |

Readiness statement:

- Every material ownership and compatibility decision is closed. The work is
  implementation-only and does not change product, data, UX, dependencies, or
  public consumer behavior.
- Godot 4.7.1, focused tests, the read-only catalog verifier, and the Stage 1
  diagnostic command are available from the repository root.
- Remaining unknowns are local symbol-move mechanics and cannot change this
  contract.

## Tasks

### Phase 1: Decompose offline catalog workflow

Goal: leave the CLI as orchestration while deterministic transformation and
bundle persistence hide their own internals.

Preconditions:

- Worktree is clean at `5c88cfa` except task-owned plan/evidence corrections.
- No command in this phase uses `--write`, bundle promotion, or catalog pointer
  mutation.

Source owners: `scripts/build_stage_catalog.gd`, `StageProgressionData`, `StageLayoutBakeCodec`, `StageCatalogData`

- [x] **1.1** Add deterministic catalog materialization owner.
  - Change: create `src/stage_generation/stage_catalog_materializer.gd`; move
    `_materialize_stage()` through `_canonical_mechanism_data()` and their
    resource preloads behind `materialize_stage(source, stage_number)`.
  - Accept: the entrypoint has no progression-tuning or mechanism-construction
    helpers, and the v9-to-v10 materialization regression passes unchanged.
- [x] **1.2** Add transactional bundle storage owner.
  - Change: create `src/stage_generation/stage_catalog_bundle_store.gd`; move
    bundle write/verify/promote/publish, manifest identity helpers, hashing, and
    pointer replace/restore behind the existing workflow-shaped methods.
  - Accept: the read-only catalog verifier reports the same 30-stage manifest,
    and the entrypoint contains no `FileAccess`, `DirAccess`, or `ResourceSaver`
    bundle transaction.
- [x] **1.3** Reduce the catalog script to CLI and build orchestration.
  - Change: redirect existing calls to the two new owners while keeping
    argument parsing, scene setup, witness generation, diagnostics, messages,
    and exit codes unchanged.
  - Accept: fixed-catalog, materialization, and baked-layout tests pass, and
    Godot parses all three scripts without warnings or missing global classes.

Batch gate outcome:

- The three focused artifact tests pass with the unchanged 30-stage catalog.
- `build_stage_catalog.gd` without write flags did not exit within the bounded
  six-minute run and left four task-owned headless Godot processes, which were
  stopped by exact command-line ownership. No catalog write or promotion ran.
- The extracted bundle block is mechanically source-equivalent to the prior
  implementation except for static-method/public-entry renames and two trailing
  blank lines. This timeout is recorded as a tooling/runtime limitation, not as
  evidence of changed bundle logic.

### Phase 2: Separate direct target solving from physical validation

Goal: isolate the bounded inverse solver while retaining the validator façade
and every current caller.

Preconditions:

- Phase 1 acceptance checks and batch gate pass.

Source owners: `DirectReachabilityValidator`, `DefaultAimSolver`, `CannonBallistics`, `TrajectoryPredictor`

- [x] **2.1** Add the direct single-target solver and compatibility façade.
  - Change: create
    `src/stage_generation/direct_target_aim_solver.gd`; move
    `solve_one_target()` and its analytic nomination, endpoint, cache,
    prediction-filter, and diagnostic helpers. Keep
    `DirectReachabilityValidator.solve_one_target()` as a narrow delegation and
    retain summit/rigidbody validation and evidence hashing in the validator.
  - Accept: `DefaultAimSolver` and the catalog builder require no caller change;
    the Stage 1 diagnostic, projectile-range regression, and existing
    catalog-entry witness checks pass.
  - Guard: no ballistic recurrence is copied; the extracted solver continues
    to call `CannonBallistics.build_damped_motion_cache()` and
    `damped_position_at_horizontal_range()`.

### Phase 3: Audit the resulting boundaries

Goal: prove that extraction reduced reasons to change without adding
pass-through ownership or breaking a contract.

Preconditions:

- Phases 1 and 2 pass.

Source owners: task-owned diff and direct consumers

- [x] **3.1** Run the codebase-quality post-pass and final verification.
  - Change: inspect public calls, dependency direction, file responsibilities,
    failure paths, comments, and tests; make only small task-scoped corrections.
  - Accept: the entrypoint, materializer, bundle store, validator, and solver
    each have one stated reason to change; no copied rule, competing owner,
    missing failure path, or P0-P2 finding remains; `scripts/verify.ps1` passes.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `git diff --check` and Godot parse through `scripts/verify.ps1` only after a complete extraction slice | A moved symbol set compiles | A relevant moved symbol changes |
| Phase 1 gate | `fixed_mountain_catalog_test.gd`, `generation_v10_materialization_test.gd`, `baked_stage_layout_test.gd`, and read-only `build_stage_catalog.gd` | Phase 1 tasks pass | Catalog extraction changes |
| Phase 2 gate | `build_stage_catalog.gd -- --diagnose-stage stage_01` and `projectile_range_constraint_test.gd` | Phase 2 task passes | Solver extraction changes |
| Final gate | `scripts/verify.ps1` and diff-scoped `codebase-quality-auditor` | All tasks pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task; do not write or promote
  a catalog.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Record one known non-blocking engine warning rather than rerunning a passing
  command for confidence.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A moved helper requires scene-tree or process state | Keep that helper in the CLI and document why | Do not leak `SceneTree` into the materializer or bundle store |
| Bundle verification output or hash changes | Restore exact manifest reconstruction behavior and re-run only Phase 1 | Do not accept or regenerate a new catalog |
| The extracted solver changes Stage 1 diagnostic identity or aim | Restore the façade path and fix the extraction | Do not retune tolerance, physics, or aiming |
| A verified material fact contradicts this contract | Stop the affected branch and update the contract | Do not choose a new architecture, schema, product, or validation contract during implementation |

Implementation-local discoveries may be handled inside the locked contract
when they cannot change scope, visible behavior, ownership, architecture,
safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: complete.
- Next task: none in this contract. Delivery-capture decomposition and queue
  budgets remain separate decisions.
- Last completed gate: diff-scoped quality audit plus `scripts/verify.ps1`.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

### Completion evidence

- Physical lines changed from 1,200 to 393 for the catalog entrypoint and from
  1,191 to 624 for the reachability validator. Extracted owners are 304 lines
  for materialization, 516 for bundle storage, and 578 for target solving.
- Mechanical comparison reports zero meaningful moved-block differences: the
  moved blocks differ only by entrypoint names and removed trailing blank lines.
- `generation_v10_materialization_test.gd`, `fixed_mountain_catalog_test.gd`,
  `baked_stage_layout_test.gd`, and `projectile_range_constraint_test.gd` pass.
- `scripts/verify.ps1` passes after the final private-preload and dead-preload
  cleanup. The post-pass found no competing owner, copied rule, new public
  global class, or reachable P0-P2 failure introduced by the extraction.
- The exact Stage 1 diagnostic consistently reaches the retained physical
  validator but rejects its witness with `reachability_batch_cleanup` and
  `physical_target_uncovered`. The moved inverse-solver body is source-equal,
  and the projectile-range regression passes, so no physics/tolerance retuning
  was made inside this behavior-preserving contract.

## Completion and Stop Conditions

Complete when:

- Every task is implemented and each validation gate either passes or has a
  documented bounded exception backed by source-equivalence and passing
  adjacent contract checks.
- Public callers, manifest identity, entry witnesses, fixed-step recurrence,
  CLI behavior, and project startup remain unchanged.
- Durable results are recorded in `.agents/Documentation.md` and the plan status
  is `done`.

Replan when:

- A material discovery invalidates a locked ownership or compatibility
  boundary.

Do not replan or stop for:

- Implementation-local symbol moves already contained by this contract.
- A passing check whose relevant inputs have not changed.
