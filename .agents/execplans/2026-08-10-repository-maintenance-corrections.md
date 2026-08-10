---
type: plan
status: done
created: 2026-08-10
scope: non-destructive documentation lifecycle repairs, asset provenance, catalog input validation, shared ballistic math, and dead diagnostic surfaces
related:
  - 2026-08-10-repository-hygiene-disposition.md
  - 2026-08-10-codebase-efficiency-review.md
  - ../evidence/2026-08-10-repository-hygiene-disposition.md
  - ../evidence/2026-08-10-codebase-efficiency-review.md
---

# Repository Maintenance Corrections - Execution Contract

At commit `fc02848`, the bounded audits found stale active documentation,
missing generated-asset provenance, a documentation import-ignore gap, one
catalog source-integrity defect, duplicated ballistic recurrence, and unused
diagnostic surfaces. This contract repairs those issues without deleting or
moving files and without changing player-facing behavior.

## Purpose

- Objective: restore truthful repository guidance and remove verified code
  hazards and overhead inside existing owners.
- Deliverable: repaired lifecycle/content/provenance records, fail-closed
  catalog input validation with regression coverage, one shared ballistic
  recurrence owner, and removal of no-caller diagnostics.
- Completion state: focused tests and `scripts/verify.ps1` pass, audit reports
  remain truthful, and destructive candidates remain untouched.

## Scope and Boundaries

In scope:

- Archive the 26 exact historical documents identified by the hygiene report
  in place, repair current authority statements, and add required evidence
  structure.
- Ignore documentation-local Godot import sidecars and record the missing
  generated timeout icon provenance.
- Reject incomplete source catalogs, delegate validator recurrence to
  `CannonBallistics`, and remove proven no-caller diagnostic surfaces.

Out of scope:

- Deleting or moving assets, evidence, generated catalog bundles, builds,
  reports, or Godot cache state.
- Choosing queue budget values or changing projectile, paint, stage, UI,
  camera, or prediction behavior.
- Dependencies, generated catalog rewrites, product redesign, and visual work.

Constraints and invariants:

- `StageController`, `PaintSystem`, and typed Resources retain their documented
  ownership.
- Optional reachability-certificate data compatibility remains intact.
- The current 30-stage catalog identity and all player-visible behavior remain
  unchanged.

Destructive or irreversible actions:

- None.

Exact actions requiring owner or user approval:

- Any path deletion, move, generated-bundle removal, or local-output reclaim
  remains outside this contract and requires a separate exact approval.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Document authority and lifecycle | Source brief/spec graph and lifecycle metadata | Hygiene disposition report | Repair current claims; archive historical evidence in place | 1.1, 1.2 |
| Asset provenance and import noise | Generated asset record, license ledger, `.gitignore` | Hygiene disposition report | Add timeout icon record; ignore `docs/**/*.import` | 1.3 |
| Source catalog integrity | `StageCatalogData.is_valid`, offline builder | Code review report | Require exactly 30 valid ordered source stages | 2.1 |
| Ballistic recurrence | `CannonBallistics` is the existing shared math owner | Code review report | Validator delegates recurrence/interpolation to it | 2.2 |
| Dead diagnostics | Repository-wide caller trace | Code review report | Remove only no-caller methods, counters, and private helpers | 2.3 |
| Queue budget | No typed owner/value is defined | Code review report | Defer; do not invent policy | none |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership,
  safety, and validation decision in scope is closed.
- Godot 4.7.1, focused tests, and `scripts/verify.ps1` are available and passed
  at baseline.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Repair repository truth without deleting history

Goal: current guidance, lifecycle metadata, provenance, and ignore rules match
the implemented repository.

Preconditions:

- The exact path dispositions in the hygiene report remain unchanged.

Source owners: `README.md`, `.agents/Prompt.md`, `.agents/design/VISUAL_REFERENCES.md`, `docs/design-spec.md`, evidence frontmatter, `docs/asset-licenses.md`, `assets/ui/icons/GENERATED_ASSETS.md`, `.gitignore`

- [x] **1.1** Archive historical evidence in place.
  - Change: set only the 26 report-listed lifecycle statuses to `archived`.
  - Accept: protected/raw files remain unstamped, paths and inbound links remain
    unchanged, and lifecycle type/status combinations are valid.
- [x] **1.2** Repair current documentation authority and evidence structure.
  - Change: update the current gameplay summary, stale active-plan wording,
    current catalog path/format, and the two active evidence structures.
  - Accept: current documents agree with the effective source brief, live
    catalog, architecture, and implemented-state record; historical text stays
    historical.
- [x] **1.3** Close provenance and import-ignore gaps.
  - Change: record `result_timeout_clock.png` and ignore documentation-local
    `.import` sidecars.
  - Accept: the recorded hash matches the asset and Godot import no longer
    makes documentation evidence appear as untracked source.

### Phase 2: Fix bounded code defects inside current owners

Goal: invalid offline inputs fail closed, ballistic math has one owner, and
unused diagnostics stop adding code and runtime work.

Preconditions:

- Phase 1 acceptance checks pass.

Source owners: `src/stage/stage_catalog_data.gd`, `scripts/build_stage_catalog.gd`, `src/cannon/cannon_ballistics.gd`, `src/stage_generation/direct_reachability_validator.gd`, `src/paint/paint_system.gd`, `src/camera/camera_director.gd`, `src/gameplay/gameplay_scene.gd`

- [x] **2.1** Reject incomplete catalog sources.
  - Change: make exact 30-stage completeness an invariant, require a valid
    existing source catalog, and add 27/28/29-stage regression checks.
  - Accept: the focused catalog test rejects all three partial variants and
    accepts the current catalog; read-only catalog verification still passes.
- [x] **2.2** Use the shared ballistic recurrence.
  - Change: delegate validator cache construction and range interpolation to
    `CannonBallistics`, retaining local solver lookup tables only.
  - Accept: range, stage-generation, and catalog-readiness checks pass without
    a second recurrence implementation in the validator.
- [x] **2.3** Remove verified dead diagnostic surfaces.
  - Change: remove the retired exhaustive validator entry/build/compare path,
    unconsumed paint timing/cache metrics, no-op camera API/counter, and unused
    gameplay forwarding getter.
  - Accept: repository search finds no removed symbols; retained certificate,
    paint, camera, and scheduler behavior passes focused checks.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `git diff --check` and repository symbol searches | After each phase's edits | Relevant files change |
| Phase gate | Focused catalog, range/generation, paint queue, camera safety, and prediction scheduler tests | After Phase 2 tasks pass | A phase-owned input changes |
| Final gate | `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1` | All tasks and focused checks pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Do not write or promote a generated catalog.
- Do not run the broad suite unless a focused failure demonstrates that the
  change crosses its stated boundary.
- Record the Godot-created documentation `.import` state once; the ignore rule
  is the intended fix.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| Current catalog identity changes during implementation | Stop and refresh the audit evidence | Do not rewrite or promote a bundle |
| A removed symbol has a current repository caller | Restore it and narrow the dead-surface batch | Do not redesign the caller |
| Shared ballistics changes solver output | Revert the delegation branch and report the parity conflict | Do not alter gameplay physics to force parity |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval | Do not choose a new product, architecture, dependency, data, UX, safety, or validation contract |

Implementation-local discoveries may be handled inside the locked contract
when they cannot change scope, visible behavior, ownership, architecture,
safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: Request exact approval for any destructive cleanup batch; the
  queue-budget architecture decision remains separately deferred.
- Last completed gate: Focused tests, active catalog verification,
  `scripts/verify.ps1`, lifecycle/provenance checks, and the diff-scoped quality
  audit passed.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every phase and final gate named by this contract passes.
- No placeholder or unresolved material decision remains in scope.
- Frontmatter status changes to `done` only after implementation completes.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
