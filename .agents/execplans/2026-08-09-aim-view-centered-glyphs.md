---
type: plan
status: done
created: 2026-08-09
scope: deterministic terrain-glyph placement centered in the default Aim View mountain silhouette
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../design/ART_DIRECTION.md
  - 2026-08-08-instant-approximate-landing-feedback.md
---

# Aim-View-Centered Terrain Glyphs - Execution Contract

Replace the rejected world-height placement preference with deterministic
screen-space ranking against the default Aim View. Preserve terrain,
mechanism, visibility, footprint, route, separation, and camera behavior; then
promote one regenerated thirty-stage bundle and inspect representative release
captures.

## Purpose

- Objective: place eligible glyphs around the visual middle of the mountain as
  the player sees it while aiming, instead of along the upper ridgeline.
- Deliverable: updated placement ranking, focused contracts, a promoted baked
  catalog, current specifications/records, and reviewed Stage 02/03/08/30
  Windows-release captures.
- Completion state: every representative visible glyph is on a readable middle
  surface band unless its mechanism suitability or separation contract requires
  deterministic fallback, and all named gates pass.

## Scope and Boundaries

In scope:

- `MechanismLoadoutPlanner` candidate ranking and its view-projection helpers;
- focused placement tests and representative baked-stage glyph contracts;
- one complete content-addressed v10 bundle and the canonical catalog pointer;
- current source/design/implementation/checklist records and runtime evidence.

Out of scope:

- terrain shape, route graph, camera composition, glyph art or size, mechanism
  behavior, stage difficulty, aim physics, HUD, paint, and dependencies.

Constraints and invariants:

- “Aim View middle” means the vertical center band of the projected Playable
  Terrain Surface silhouette under the canonical 48-degree, 16:9 composed Aim
  View, not normalized world elevation and not the entire viewport midpoint.
- Screen placement is a ranking preference after existing suitability checks.
  The center-slope admission limit is widened only to the measured middle-band
  median while footprint normal variation, Aim View visibility, route semantics,
  and separation remain mandatory. The rejected muzzle-to-anchor height trace is
  not a user-visibility contract and is replaced by a trace from the canonical
  Aim View camera.
- Generation stays deterministic and `MechanismLoadoutPlanner` remains the sole
  mechanism-assignment owner.

Destructive or irreversible actions:

- None. The content-addressed builder preserves the previous immutable bundle;
  the catalog pointer changes only after full staging validation succeeds.

Exact actions requiring owner or user approval:

- None beyond the user's explicit request. No dependency, deletion, or physics
  change is authorized.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Visual midpoint | `MechanismLoadoutPlanner` ranks normalized local Y `0.55..0.85` first | Stage 30 release capture places glyphs on the top ridge; planner constants and candidate sort confirm the cause | Rank projected vertical fraction around `0.50` in the mountain's Aim View silhouette | 1.1, 1.2 |
| Runtime camera parity | `CameraDirector` uses `AimCameraComposer` at 48-degree FOV and 16:9 evidence size | `_composed_aiming_bookmark()` and `phase8_aiming_composition_test.gd` | Reuse `AimCameraComposer`; do not duplicate or change camera composition | 1.1 |
| Glyph visibility | `_has_cannon_side_visibility()` traces from the muzzle instead of the view used to judge the result | Stage 30 Aim View trace changes the generic candidate counts but does not by itself populate the middle band | Preserve visibility intent but trace from the canonical Aim View camera to the anchor | 1.1, 1.2 |
| Middle-face eligibility | The `42°` center-slope cap rejects `1,246 / 1,348` Stage 30 middle-band anchors before ranking | Measured middle-band slope percentiles are `p25 46.5°`, `p50 56.2°`, `p75 73.4°`; only 4 generic anchors survive all checks at `42°` | Use a bounded `60°` center-slope cap, just above the measured median; retain the stricter `32°` footprint normal-variation guard | 1.2 |
| Final composition | First corrected captures put all Stage 30 glyphs at fraction `0.498..0.501`; score-first rework removed the exact row, but one `ebf89e8e...21cc` Burst read as a crescent because its face-to-camera dot was only `0.343` | Direct native-size review, AGY job `20260809T021622968Z-a22f7ac9-1028-4846-bab7-1d134b94c32c`, runtime mesh-bounds probe, and facing diagnostics | Keep the center band as the rank boundary, prefer mechanism score within it, project the terrain-draped perimeter into the safe frame, and prefer a complete assignment at facing dot `>= 0.50` before deterministic fallback | 1.2, 3.1 |
| Mechanism correctness | Existing generic suitability and kind-specific witnesses run before ranking | `_generic_suitability()`, `_splitter_route_targets()`, `_uphill_witness()` | Preserve every kind-specific, footprint, route, count, and separation guard | 1.1, 1.2 |
| Runtime content | Gameplay loads immutable baked placements from the catalog | `StageLayoutRepository` and the current v10 bundle | Rebuild all 30 stages and promote one verified content-addressed bundle | 2.1 |
| Visual authority | Running-game capture is required for world-composition work | Root `AGENTS.md` and UI/UX Gate Level 3 | Inspect Stage 02/03/08/30 at 1280x720 from the canonical Windows build | 3.1 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership,
  safety, and validation decision is closed.
- Godot 4.7.1, the offline builder, representative capture states, and focused
  tests are present and their PowerShell invocations are verified.
- Remaining unknowns are implementation-local and cannot change this contract.

## Tasks

### Phase 1: Screen-space placement preference

Goal: deterministically prefer eligible surfaces in the visual middle of the
default Aim View mountain silhouette.

Preconditions:

- Preserve the unrelated user modification in `tests/target_mask_test.gd` and
  unrelated untracked evidence/staging files.

Source owners: `src/stage_generation/mechanism_loadout_planner.gd`,
`tests/mechanism_placement_test.gd`, `src/camera/aim_camera_composer.gd`

- [x] **1.1 Project candidates into the canonical Aim View**
  - Change: build the same playable-top interest set and render bounds used by
    the runtime composer, use that camera for the visibility trace, project
    eligible anchors, and calculate vertical fraction inside the projected
    terrain silhouette.
  - Accept: the focused fixture returns finite deterministic fractions with `0`
    at the silhouette top and `1` at the silhouette bottom.
  - Guard: camera position/focus and glyph suitability behavior remain unchanged.
- [x] **1.2 Prefer the visual center band**
  - Change: rank `0.38..0.62` first around center `0.50`, `0.28..0.74` second,
    retain deterministic fallback outside those bands, and admit coherent
    center faces up to the measured bounded `60°` slope cap.
  - Accept: `mechanism_placement_test.gd` selects a suitable Burst in the first
    band, ranking retains mechanism score inside that band, the full glyph
    radius remains inside the Aim View safe frame, and repeated generation
    returns the same transforms.
  - Guard: Splitter routes, Uphill tangent, footprint, count, and separation
    checks still pass.

Batch gate:

- Run `mechanism_placement_test.gd`, then one exact Stage 30 diagnostic. Stop
  before the all-stage build if either fails or produces no center-band choices.

### Phase 2: Promoted deterministic catalog

Goal: make the revised placement visible in normal gameplay without changing
terrain or mechanism behavior.

Preconditions:

- Phase 1 acceptance and batch gate pass.

Source owners: `scripts/build_stage_catalog.gd`,
`resources/generated_stage_catalogs/`, `resources/stages/catalog.tres`

- [x] **2.1 Build and promote one complete v10 bundle**
  - Change: run the deterministic all-30 `--write` build, update the canonical
    pointer, and stage only the validated final content-addressed output.
  - Accept: the builder exits zero, names one manifest, and `--check` validates
    all 30 stage/profile/layout entries without drift.
  - Guard: generation-v10 materialization, baked-layout, Stage 02 Burst, Stage 03
    route, and Stage 08 Uphill contracts pass.

### Phase 3: Rendered acceptance and durable record

Goal: prove the corrected composition in the built game and retire the rejected
world-height wording.

Preconditions:

- Phase 2 acceptance passes.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`,
`.agents/design/ART_DIRECTION.md`, `.agents/Documentation.md`,
`docs/test-checklist.md`, `.agents/evidence/aim-view-centered-glyphs-2026-08-09/`

- [x] **3.1 Inspect representative Windows-release Aim Views**
  - Change: export the canonical executable and capture Stage 02/03/08/30 at
    Korean 1280x720 after the standard 24-frame evidence settle.
  - Accept: glyphs read on middle mountain faces rather than the foot or top
    skyline; no glyph is hidden by HUD, cannon, trajectory, or another glyph.
- [x] **3.2 Correct current contracts and record evidence**
  - Change: replace normalized-world-height claims with Aim View silhouette-band
    language and record the new manifest, tests, and inspected captures.
  - Accept: current specs and implementation records contain no active claim
    that `0.55..0.85` normalized terrain height is the desired visual midpoint.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Godot headless `tests/mechanism_placement_test.gd` | Planner or focused fixture changes | Relevant planner/test input changes |
| Phase 1 gate | `scripts/build_stage_catalog.gd -- --diagnose-stage stage_30` | Focused test passes | Placement or generation input changes |
| Phase 2 gate | all-30 `--write`, `--check`, then the five named catalog/glyph tests | Phase 1 gate passes | Builder/planner/catalog input changes |
| Final gate | `scripts/verify.ps1`, Windows export, four captures, `git diff --check`, diff-scoped quality audit | All implementation/docs are coherent | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not choose a new product, architecture, dependency, data, UX, safety, or validation contract during implementation |
| First-band candidates cannot satisfy a mechanism on a stage | Use the locked second-band then deterministic fallback order | Do not weaken mechanism suitability, visibility, or separation |
| All-stage build fails before promotion | Keep the current catalog pointer, retain the exact failure evidence, and fix only the diagnosed task-owned cause | Do not delete or overwrite the last valid immutable bundle |
| A final capture still reads at the skyline | Adjust only screen-band thresholds/ranking, rerun the affected focused/diagnostic gate, then rebuild once | Do not tune camera, terrain, or glyph art to mask ranking failure |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: complete.
- Next task: none.
- Last completed gate: manifest
  `701b3b63feeee0dc1ce064cc91953fbdab91d90db1f004ef247dc4b8b22d1b4e`;
  active-catalog, placement, materialization, bake, Stage 02/03/08 glyph, and
  representative composition contracts pass. `scripts/verify.ps1`, Windows
  release export, and direct native-size inspection of Stage 02/03/08/30 pass.
- Cleanup note: four rejected task-created bundles remain untracked because the
  current execution policy blocked recursive deletion. They are not referenced
  by the active catalog and must not be staged.
- Update rule: after a checkpoint passes, record its concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- The promoted bundle and four inspected release captures reflect the same
  screen-space placement contract.
- Durable terminology is corrected in its owning specs and record.
- Frontmatter status changes to `done` only after implementation completion.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
