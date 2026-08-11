---
type: plan
status: done
created: 2026-08-11
scope: reduce the time that the Korean stage-loading action remains unavailable in the canonical Windows and shared Web runtime path
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../docs/test-checklist.md
  - 2026-08-11-web-runtime-responsiveness.md
---

# Fast Stage Readiness - Execution Contract

The canonical fastrun executable is current and completes stage preparation, but a fresh 1280x720 release run still keeps the stage action unavailable for about 0.86 seconds on Stage 1 and 1.15 seconds on Stage 30 after `app_root_ready`. This contract reduces the measured terrain-build and repeated render-warm-up costs without changing gameplay, terrain topology, collision, paint ownership, or loading-state truthfulness.

## Purpose

- Objective: shorten the visible `스테이지 불러오는 중…` interval while preserving responsive incremental preparation and an immediate prepared-stage handoff.
- Deliverable: allocation-efficient terrain geometry preparation, process-scoped first-use render warm-up, regression coverage, fresh timing markers, and a rebuilt canonical fastrun release.
- Completion state: focused and repository gates pass, rendered Stage 1 and Stage 30 release captures are reviewed, and three fresh release samples improve the median `app_root_ready` to `gameplay_prepared` time from 0.86/1.15 seconds to at most 0.70/0.90 seconds without a preparation slice over 16 ms.

## Scope and Boundaries

In scope:

- Runtime construction of the existing immutable terrain render and collision geometry.
- Collection of unique playable terrain points used by camera and presentation owners.
- First-use render warm-up reuse within one process when shader, projectile, and effect families are unchanged.
- Delivery-only preparation timing evidence and canonical Windows export replacement.

Out of scope:

- Terrain shape, stage data, physics, coverage, camera behavior, UI layout/copy, save format, new dependencies, renderer changes, or publishing to itch.io.
- Hiding incomplete preparation by enabling Start early or replacing truthful status with an animation.
- Persisting generated runtime meshes as a second stage-layout authority.

Constraints and invariants:

- `StageController` remains the sole stage-state and result owner; `PaintSystem` remains the sole mutable paint and coverage owner.
- The Compatibility renderer, fixed 60 Hz physics tick, canonical topology, full top/shell collision, and three-entry runtime artifact LRU remain unchanged.
- CPU preparation stays cooperative on Web and must not create a visible long frame to reduce total wall time.
- First-use warm-up may be reused only after one successful process-local render pass; cancellation or failure cannot mark it complete.

Destructive or irreversible actions:

- None. The release executable and generated evidence are reproducible.

Exact actions requiring owner or user approval:

- Publishing or replacing the itch.io upload remains outside this task.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| fastrun freshness | The registry starts `builds/windows/PaintMountain.exe`; the file was rebuilt after commit `71f4295` | fastrun registry note, executable timestamp, current git history | Keep the command unchanged and replace the same release target after validation | 2.2 |
| Visible wait | `AppRoot` enables Play/Start only after layout, artifact, hidden Gameplay binding, and warm-up complete | `src/app/app_root.gd`; fresh delivery markers | Preserve this truthful readiness boundary | 1.1-2.2 |
| Terrain build cost | `TerrainGeometryBuildJob` repeatedly creates three-element packed arrays for every triangle and recomputes normals already owned by `TerrainTopTopology` | source trace; Stage 30 geometry phase about 0.33 s | Pre-size packed arrays, fill by index, and consume canonical cached normals without changing output | 1.1 |
| Playable-point cost | `StageRuntimePreparer` uses a hash dictionary to deduplicate bounded integer source indices | source trace; Stage 30 playable-point phase about 0.08 s | Replace hash membership with an index-sized packed-byte set | 1.1 |
| Repeated warm-up and effect resources | Every hidden Gameplay instance creates 32 particle nodes with duplicate per-family materials/meshes, then renders terrain, projectile, effects, and cleanup across five waits | `PresentationEffects`, `GameplayFirstUseWarmup`; first candidate still spent 0.17-0.18 s in warm-up | Share immutable resources within each effect family, batch warm-up families into two render completions, cache only successful process-local completion, and make later instances complete synchronously | 1.2 |
| Regression proof | Existing tests prove identity, deterministic geometry, yielding, immediate handoff, and warm-up isolation but not cross-instance warm-up reuse | focused tests and delivery capture runner | Extend those owners and compare fresh Stage 1/30 release markers to the measured baseline | 1.1-2.2 |

Readiness statement:

- Product behavior, architecture ownership, dependencies, data, UX, safety, and validation decisions are closed.
- Godot 4.7.1, existing test scripts, delivery telemetry, capture runner, and Windows export preset are available.
- Remaining choices are local packed-array indexing and test mechanics that cannot change this contract.

## Tasks

### Phase 1: Remove avoidable repeated runtime work

Goal: produce byte- and topology-equivalent prepared artifacts with less CPU allocation and reuse the one process-level renderer warm-up.

Preconditions:

- Fresh canonical baseline markers remain 0.86 seconds for Stage 1 and 1.15 seconds for Stage 30 from `app_root_ready` to `gameplay_prepared`.

Source owners: `src/terrain/terrain_top_topology.gd`, `src/terrain/terrain_geometry_build_job.gd`, `src/app/stage_runtime_preparer.gd`, `src/effects/presentation_effects.gd`, `src/gameplay/gameplay_first_use_warmup.gd`

- [x] **1.1** Build identical terrain artifacts without per-triangle temporary packed arrays or hash-based vertex membership.
  - Change: expose a duplicate of canonical triangle normals, pre-size render/collision/source arrays, write triangle data by index, and use a packed-byte seen set for playable vertices.
  - Accept: runtime preparer and terrain geometry tests retain exact identity, counts, deterministic checksums, collision, and multi-frame cooperation.
  - Guard: no synchronous fallback path, topology duplication, or reduced collision surface is introduced.
- [x] **1.2** Reuse successful first-use rendering work across later stages in the same process.
  - Change: share immutable material/mesh resources within each live effect family; submit terrain, projectile, and every effect family together for two renderer completions; publish a process-local completed state only after that pass succeeds; later warm-up instances complete without a viewport.
  - Accept: the warm-up test proves family-resource reuse, first-run coverage, cancellation-safe completion, cross-instance reuse, no gameplay/physics owners, and no live-pool mutation.

### Phase 2: Prove and ship the faster canonical path

Goal: verify the player-visible loading boundary and replace the exact fastrun target.

Preconditions:

- Phase 1 focused tests pass.

Source owners: `src/delivery/runtime_delivery_telemetry.gd`, `src/app/stage_runtime_preparer.gd`, `scripts/verify.ps1`, `export_presets.cfg`, `docs/test-checklist.md`, `.agents/Documentation.md`

- [x] **2.1** Record actionable preparation timing without changing ordinary output.
  - Change: include artifact elapsed and maximum cooperative-slice time in delivery-only markers.
  - Accept: ordinary play stays silent; telemetry provides the data required to distinguish layout, artifact, binding, and warm-up time.
- [x] **2.2** Validate and replace the fastrun release.
  - Change: run focused tests, `scripts/verify.ps1`, the complete suite, export `builds/windows/PaintMountain.exe`, and capture Korean Stage 1/30 briefing states with telemetry.
  - Accept: all gates pass; both captures are visually reviewed; Stage 1/30 readiness is at most 0.70/0.90 seconds; maximum artifact slice is at most 16 ms; the fastrun registry still points to the rebuilt executable.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Godot scripts `stage_runtime_preparer_test.gd`, `prepared_gameplay_entry_test.gd`, and `gameplay_first_use_warmup_test.gd` | Each owner is changed | Relevant source or test changes |
| Phase gate | `scripts/verify.ps1` | Focused checks pass | Script, scene, resource, or project setting changes |
| Final gate | Complete `scripts/test.ps1`, Windows release export, background Stage 1/30 captures and telemetry | Implementation and docs are stable | A final-gate input changes |

Validation rules:

- Use release telemetry rather than stopwatch process launch time for stage readiness; executable and graphics startup are separate costs.
- Review actual running renderer captures even though the visible composition is not redesigned.
- Run the complete suite only once after the focused implementation stabilizes.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| Optimized arrays differ from canonical geometry or collision | Stop and correct indexing against topology-owned vertices, indices, and normals | Never weaken geometry/collision acceptance to meet the timing target |
| A cooperative slice exceeds 16 ms | Split the responsible phase or revert its local optimization | Do not raise the budget or hide a long frame |
| Readiness misses the target after both verified owners improve | Use the new phase markers to optimize the next measured owner | Do not add persisted duplicate stage data or change UX without replanning |
| A material fact contradicts this contract | Stop the affected branch and update the contract before resuming | Do not choose a new architecture, dependency, or player-visible contract implicitly |

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: None.
- Last completed gate: Full ordered suite, Windows release export, and final
  Stage 01/30 release telemetry and visual review.
- Candidate finding: the first allocation pass reduced Stage 30 artifact preparation from about 0.61 to 0.51 seconds, but total readiness remained 1.06/1.09 seconds because cold warm-up stayed at 0.17-0.18 seconds and effect-family binding remained repeated.
- Phase 1 evidence: focused runtime-preparer, prepared-entry, and warm-up tests pass. The second release candidate's three-sample medians are 0.60 seconds for Stage 1 and 0.84 seconds for Stage 30; the slowest samples are 0.72/0.85 seconds and the largest measured artifact slice is 12.93 ms.
- Final evidence: focused preparer/entry/warm-up/UI/localization checks,
  `scripts/verify.ps1`, and the complete ordered suite pass. The rebuilt
  canonical release measures 615.258 ms Stage 01 and 796.946 ms Stage 30
  medians across three samples, with a 13.312 ms largest artifact slice. Both
  Korean 1280x720 briefing captures pass visual review, and fastrun still points
  to `builds/windows/PaintMountain.exe`.
- Update rule: record concise evidence and advance this pointer after each checkpoint.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named gate passes.
- Fresh release evidence meets both readiness and frame-slice budgets.
- Implemented-truth and test-checklist docs record the new measured result.
- Frontmatter changes to `status: done` and no unresolved material decision remains.

Replan when:

- The measured owner is not terrain artifact construction or repeated warm-up, or correctness requires a new persisted asset/schema.

Do not replan or stop for:

- Local indexing, telemetry formatting, or test-fixture details already contained by this contract.
