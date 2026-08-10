---
type: plan
status: active
created: 2026-08-10
scope: remove verified unused tracked assets and catalogs, prevent documentation imports, and clear regenerable local outputs
related:
  - ../evidence/2026-08-10-repository-hygiene-disposition.md
  - ../evidence/2026-08-10-codebase-efficiency-review.md
  - 2026-08-10-repository-maintenance-corrections.md
---

# Aggressive Repository Cleanup - Execution Contract

At commit `ffb3fb9`, the repository passes focused tests and Godot verification.
The user has now authorized deletion of every artifact that the completed audits
classify as unused, superseded, duplicate, or regenerable. This contract removes
those exact surfaces while retaining current runtime assets, the active v10
catalog, the v9 migration fixture, unique evidence, and all production code.

## Purpose

- Objective: reduce tracked and local repository waste without changing the
  running game.
- Deliverable: remove verified unused assets, superseded images, inactive v10
  bundles, documentation imports, caches, builds, reports, and ignored logs;
  prevent documentation media from being reimported by the main Godot project.
- Completion state: current catalog and main-scene verification pass, no current
  reference points at a deleted path, and post-change code quality review is
  clean.

## Scope and Boundaries

In scope:

- Delete the eight exact duplicate/superseded images in the disposition report.
- Delete unreferenced `pause.png`, `restart.png`, and Kenney `divider.png` with
  their import metadata and provenance rows.
- Delete the three inactive v10 generated catalog bundles. Retain active
  `v10-701b3...` and the v9 migration-test fixture.
- Add `.gdignore` boundaries for documentation, agent evidence, screenshots,
  and standalone prototypes; delete generated sidecars, ignored logs, `.godot`,
  `builds`, and root `reports`.
- Refresh the owning asset and implementation records.

Out of scope:

- Deleting unique concepts/evidence, current runtime assets, licenses, the
  active v10 bundle, the v9 fixture, source code, scenes, tests, or dependencies.
- Queue-budget policy changes or unrelated refactoring.

Constraints and invariants:

- `resources/stages/catalog.tres` continues to select the exact active v10
  bundle and all 30 stages load.
- The v9-to-v10 materialization regression remains runnable.
- No user-facing state changes; UIUX Gate classification is Level 0.

Destructive or irreversible actions:

- Tracked deletions are recoverable from Git. Ignored local caches, builds,
  reports, sidecars, and logs are not committed; the build and caches can be
  regenerated, while transient logs may not be recoverable.

Exact actions requiring owner or user approval:

- The user explicitly approved all audit-backed cleanup in the current turn;
  no additional approval remains.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Runtime UI assets | Scene/script/resource/test reference graph | Hygiene disposition evidence and current `rg` pass | Delete only the three zero-consumer assets and their imports | 1.1 |
| Visual evidence | Visual reference register and exact hashes | Hygiene disposition evidence | Delete eight exact duplicate/superseded images; retain unique/current evidence | 1.2 |
| Generated catalogs | `resources/stages/catalog.tres` and migration test | Active pointer plus current bundle inventory | Delete three inactive v10 bundles; retain active v10 and v9 | 1.3 |
| Godot import scope | No `res://docs`, `.agents`, screenshots, or prototypes consumer | Current reference pass | Add root `.gdignore` boundaries and remove generated sidecars | 2.1 |
| Local output | Ignored directory and log inventory | Exact resolved workspace paths and byte totals | Remove caches/builds/reports/logs; verification may recreate only required `.godot` state | 2.2 |
| Runtime and code quality | Existing focused tests and quality audit | Maintenance evidence at `ffb3fb9` | Reverify and run a diff-scoped post-pass; do not expand into unrelated refactoring | 3.1, 3.2 |

Readiness statement:

- Every deletion target, retained counterpart, owner, and validation command is
  fixed from current repository evidence.
- Godot 4.7.1 and the focused test scripts are available.
- Remaining unknowns are implementation-local and cannot change scope, visible
  behavior, ownership, safety, or acceptance.

## Tasks

### Phase 1: Remove tracked artifacts

Goal: delete only tracked files with no current runtime or unique evidence role.

Preconditions:

- The active catalog pointer is still `v10-701b3...` and the worktree starts
  clean at `ffb3fb9`.

Source owners: `assets/ui/`, `.agents/evidence/`, `docs/reports/`, `resources/generated_stage_catalogs/`, `docs/asset-licenses.md`

- [x] **1.1** Remove unused UI assets and repair provenance.
  - Change: delete pause, restart, and divider PNG/import pairs; remove their
    ledger/source rows while retaining shared package licenses.
  - Accept: no deleted path remains in current runtime/config/test references;
    the asset ledger resolves every remaining row.
- [x] **1.2** Remove duplicate and superseded visual evidence.
  - Change: delete the exact eight report-listed tracked images.
  - Accept: the retained duplicate counterpart and all refined/current evidence
    remain present; no active index references a deleted image.
- [x] **1.3** Remove inactive v10 bundles.
  - Change: delete `v10-4d9...`, `v10-c45...`, and `v10-d508...` only.
  - Accept: the active v10 bundle and v9 fixture remain complete, and the live
    catalog pointer names an existing manifest/layout set.

### Phase 2: Remove regenerable local output and prevent recurrence

Goal: reclaim ignored output and stop the main Godot project from scanning
documentation media.

Preconditions:

- Phase 1 path checks pass.

Source owners: `.gdignore`, `.gitignore`, `.godot/`, `builds/`, `reports/`, ignored `*.log` and `*.import`

- [x] **2.1** Exclude non-runtime trees from Godot imports.
  - Change: add `.gdignore` at `docs/`, `.agents/`, `screenshots/`, and
    `prototypes/`; remove the now-redundant nested `.gdignore` and generated
    documentation/evidence sidecars.
  - Accept: no production/test resource uses those trees and a fresh import does
    not recreate their `.import` files.
- [ ] **2.2** Clear ignored local output.
  - Change: remove verified workspace-local `.godot`, `builds`, root `reports`,
    and ignored log files.
  - Accept: `builds` and root `reports` are absent; ignored historical logs are
    absent; any `.godot` state present after validation is newly regenerated.
  - Blocker: the host execution policy rejected both exact-path recursive
    deletion and a verified file-by-file removal of `.godot`, `builds`, and
    root `reports`. The cleanup did remove 124 ignored logs and the prior
    `.godot` state; validation then regenerated `.godot`. The remaining local
    directories require a deletion-capable executor and remain outside Git.

### Phase 3: Prove unchanged runtime and review quality

Goal: demonstrate that cleanup did not remove a live dependency or weaken the
codebase.

Preconditions:

- Phases 1 and 2 acceptance checks pass.

Source owners: `scripts/verify.ps1`, `tests/fixed_mountain_catalog_test.gd`, `tests/generation_v10_materialization_test.gd`, task-owned diff

- [x] **3.1** Validate catalog and project startup.
  - Change: run the two focused catalog tests, the read-only catalog verifier,
    and `scripts/verify.ps1` with shared Godot 4.7.1.
  - Accept: all commands exit 0 with no missing-resource or script error.
- [x] **3.2** Run the diff-scoped code quality post-pass.
  - Change: inspect deleted references, ownership records, failure paths, and
    validation evidence with `codebase-quality-auditor`.
  - Accept: no current consumer, broken contract, competing owner, or reachable
    failure path remains; only small task-owned corrections are allowed.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `git diff --check`, exact deleted-path `rg`, and catalog-directory inventory | After deletion and record edits | A cleanup-owned input changes |
| Phase gate | `fixed_mountain_catalog_test.gd` and `generation_v10_materialization_test.gd` | Tracked and local cleanup tasks pass | A catalog/resource input changes |
| Final gate | read-only catalog verifier plus `scripts/verify.ps1` | Focused catalog tests pass | A final-gate input changes |

Validation rules:

- Run the narrowest check at its declared cadence.
- Do not regenerate or promote a catalog bundle.
- Do not rebuild the deleted Windows export; source startup verification is the
  acceptance boundary because no player-facing code or resource changed.
- Rerun a failed check only after a relevant implementation change or new
  hypothesis.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A current consumer of a proposed deletion appears | Retain that target and update the contract before continuing | Do not delete through an unresolved reference |
| Catalog or migration validation requires an inactive v10 bundle | Restore only the required bundle from Git and record the live dependency | Do not weaken the test or point runtime at another bundle |
| Fresh Godot import recreates sidecars outside runtime trees | Add the narrowest safe `.gdignore` boundary after confirming no resource consumer | Do not ignore `assets/`, `resources/`, `scenes/`, `src/`, or `tests/` |
| A verified material fact contradicts this contract | Stop the affected branch and update the contract | Do not select a new product, architecture, dependency, data, UX, safety, or validation contract |

Implementation-local discoveries may be handled inside the locked contract
when they cannot change scope, visible behavior, ownership, architecture,
safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 2 is blocked only on ignored local-output deletion.
- Completed work: removed 290 tracked files (three inactive v10 bundles, six
  unused UI source/import files, and eight duplicate or superseded images),
  added four `.gdignore` boundaries, removed 143 generated documentation
  sidecars and 124 ignored logs, and removed 17 empty catalog directories.
- Next task: 2.2 remove exact workspace-local `.godot`, `builds`, and `reports`
  when an executor permits the deletion. At the final check they contain
  113,112,464, 759,200,615, and 2,126,686 bytes respectively; `.godot` is the
  newly regenerated validation cache.
- Last completed gate: Final Gate. The fixed catalog test, v9-to-v10
  materialization test, read-only catalog verifier, and `scripts/verify.ps1`
  all passed with Godot 4.7.1. The diff-scoped quality post-pass found no
  current consumer, broken contract, competing owner, or reachable failure
  path caused by the tracked cleanup.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named validation gate passes.
- No placeholder or unresolved material decision remains.
- Durable cleanup results are recorded in `.agents/Documentation.md` and the
  plan status is `done`.

Replan when:

- A material discovery invalidates a locked deletion or validation boundary.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
