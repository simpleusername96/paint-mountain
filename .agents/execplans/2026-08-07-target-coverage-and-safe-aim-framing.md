---
type: plan
status: active
created: 2026-08-07
scope: truthful target-only coverage presentation and stage-aware Aim Lock framing
source: user-requested root-cause analysis, alternative comparison, planning, and implementation on 2026-08-07
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - 2026-08-06-command-columns-hud.md
  - 2026-08-06-aim-view-and-coverage-opportunity.md
---

# Target Coverage Clarity and Safe Aim Framing - Execution Contract

Paint Mountain will make the existing target-mask score understandable in the
world and HUD, and Aim Lock will retain an authored composition only when it
safely contains the playable mountain top. Later stages that exceed that safe
frustum will receive one deterministic distance correction that preserves the
authored direction and 48-degree FOV. The work changes no paint, score, save,
replay, trajectory, stage-generation, or catalog semantics.

## Purpose

- Objective: remove the false impression that visible paint is being dropped
  from coverage and keep Stage 30's summit and valid landing surface visible
  from the cannon view.
- Deliverable: clearer target/non-target terrain classification, target-specific
  HUD copy, threshold-aligned paint presentation, a playable-top-only aiming
  framer, focused contracts, one final production capture set, and current
  documentation.
- Completion state: a player can identify which dry terrain contributes to the
  percentage before firing; valid non-target traversal still paints but is not
  scored; Stage 01 retains its authored view when it already fits; Stage 30
  shows its playable top, summit region, cannon, muzzle, and a valid surface
  impact inside the 1280x720 Aim Lock safe frame; the release build passes the
  named focused and final gates.

## Scope and Boundaries

In scope:

- Preserve target coverage as unique painted target-mask pixels divided by all
  immutable target-mask pixels.
- Make the target footprint visibly distinguishable on dry playable terrain
  without adding an asset, second paint texture, or second score.
- Align shader paint-fill activation with the authoritative `0.5` paint
  threshold so a saturated visual halo does not imply additional scored area.
- Change the compact HUD/result copy from generic painted area to target-area
  coverage while preserving the selected Command Columns layout and Theme.
- Add a cached world AABB for canonical playable-top triangles only.
- Keep the authored Aim Lock pose when all interest bounds already fit a
  15-percent safe margin; otherwise fit the same bounds by moving only along
  the authored view direction at the unchanged gameplay FOV.
- Frame the playable top, its summit with `8.0 m` vertical headroom, cannon
  base, and current muzzle. The complete playable-top bounds already contain
  every valid terrain impact, so prediction changes do not drive the camera.
- Update focused camera, paint, localization, design, architecture, checklist,
  evidence, and implemented-truth records.

Out of scope:

- Changing coverage to all playable-top paint, showing a second whole-terrain
  percentage, changing clear/star targets, migrating best results, or changing
  save/replay/observation/agent schemas.
- Changing `TargetMaskRasterizer`, generation profiles, target curves, catalog
  resources, seeds, reachability checks, first-hit certification, prescribed
  success routes, ammunition, projectile/paint radius, mechanisms, wind, or
  trajectory physics.
- Reintroducing the archived right-drag Aim View, adding pan/orbit to Aim Lock,
  changing Map Inspection, following the projectile, widening FOV, or authoring
  30 manual camera repairs.
- Reworking result/replay/menu styling, creating assets, adding dependencies,
  running a catalog rebuild, exhaustive gameplay QA, or repeated spacing tests.

Constraints and invariants:

- `PaintSystem` remains the sole mutable paint and coverage owner. One paint
  mask still drives both the terrain shader and target-threshold crossings.
- `StageController` remains the sole owner of stage results; the HUD displays
  only the authoritative value.
- `CameraDirector` remains the sole owner of camera transforms. `GameplayScene`
  supplies the existing cannon reference but does not calculate a pose.
- The safe framer reads canonical top geometry and presentation landmarks only;
  it does not read or influence cannon aim, trajectory validity, or a launched
  projectile.
- The target dry-surface cue must be neutral and lower salience than saturated
  blue paint, mechanisms, the predicted trajectory, and the HUD.
- Windows desktop at 1280x720 is the delivery baseline. Mobile/narrow-browser
  evidence is not applicable to this Godot desktop game.
- Existing unrelated tracked and untracked gameplay work remains untouched and
  must never be staged, reverted, cleaned, or absorbed.

Destructive or irreversible actions:

- None. The ignored Windows executable and new evidence images are reproducible
  build artifacts. No save data, generated catalog, or prior evidence is
  deleted or rewritten.

Exact actions requiring owner or user approval:

- Any switch to whole-playable-top scoring, new metric, FOV change, catalog
  rebuild, save migration, dependency, asset, or manual per-stage camera data
  requires a revised product contract and explicit approval.

## Domain Alignment

| Term | Exact meaning | Owner |
| --- | --- | --- |
| Visible Paint | Persistent paint on every verified playable-top traversal, including outside the scoreable target | `PaintSystem` mask and terrain shader |
| Target Area | The immutable route-and-pad target mask that classifies scoreable top texels | `GeneratedStageLayout` / `TargetMaskRasterizer` |
| Target Coverage | Unique painted Target Area texels divided by all Target Area texels | `PaintSystem` |
| Playable Top Bounds | World AABB of canonical top triangles only; it excludes skirt, shell, bottom, apron, wall, mechanisms, and decoration | `TerrainSurface` |
| Authored Aim Pose | `StageData`'s baseline camera position, target, direction, and scale | `StageData` consumed by `CameraDirector` |
| Safe Aim Pose | The Authored Aim Pose when it contains all interest bounds, otherwise a deterministic same-direction/same-FOV distance correction | `CameraDirector` using `TerrainCameraFramer` |

The generic Korean label `칠한 면적` is retired for this screen because it
suggests all Visible Paint. The compact caption becomes `목표 영역` (`TARGET
AREA`), while the target marker remains `목표 N%` and result/Finish copy names
target-area coverage explicitly.

## Alternatives and Decision

| Concern | Alternative | Benefits | Decisive cost or failure | Decision |
| --- | --- | --- | --- | --- |
| Coverage | Score all playable-top paint | Direct numerical match with all visible paint | Changes 30-stage balance, stars, best results, replay/observation meaning, and requires a non-lazy whole-surface denominator plus save migration | Reject for this bug fix |
| Coverage | Show target coverage and whole-terrain coverage | Explains both quantities | Adds a second metric/denominator, HUD density, result ambiguity, and schema ownership pressure | Reject |
| Coverage | Hide non-target paint | Makes visible blue equal scored blue | Contradicts the persistent-contact product rule and physical feedback | Reject |
| Coverage | Preserve target-only score and expose its footprint/copy | Keeps one authority and all current balance/save/replay contracts while fixing the actual misunderstanding | Requires restrained world and copy changes | Select |
| Camera | Tune 30 authored bookmarks | Small local code impact | Fragile manual data, generated-layout drift, and repeated future repair | Reject |
| Camera | Frame the complete render AABB | Reuses the existing framer | Includes skirt/shell/bottom, backs away excessively, and makes the mountain a small wall | Reject |
| Camera | Widen FOV or globally move/raise the camera | Simple | Distorts scale or breaks good early-stage composition | Reject |
| Camera | Restore orientation-only Aim View | Lets a player search manually | Leaves the default view clipped and shifts correction work to the player | Reject |
| Camera | Authored-first playable-top safe framing | Preserves good authored views and corrects only bounds that fail | Adds one bounded geometry/frustum contract | Select |

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Visible paint looks larger than coverage | `_write_paint_value` persists every active-top write but increments only a target byte's first threshold crossing; the shader makes target/non-target dry rock differ by only a few percent and renders paint below the CPU threshold | `src/paint/paint_system.gd:482-503,607-610`; `src/paint/terrain_paint.gdshader:42-65`; `tests/paint_queue_determinism_test.gd:172-188` | Preserve the formula; strengthen target classification, align shader fill threshold, and correct copy | 1.1-1.3 |
| Generic copy implies whole terrain | `hud.coverage` is `COVERAGE/칠한 면적`; Finish and result copy repeat the generic meaning | `translations/ui.csv:37-40,68,80,99`; `scenes/ui/hud/coverage_meter.tscn`; `src/ui/hud/coverage_meter.gd` | Use `TARGET AREA/목표 영역` and target-specific Finish/result wording without changing layout ownership | 1.2-1.3 |
| Whole-top scoring would be a migration | Target thresholds are 4-15%, stars compare the same percentage, and saves retain best coverage without a metric version; surface samples are intentionally lazy | `src/stage_generation/stage_progression_data.gd:18-25`; `src/gameplay/gameplay_scene.gd:404-423,545-550`; `src/autoload/game_state.gd:36-55`; `src/paint/paint_system.gd:857-899` | Do not change denominator, target data, save version, or result/replay schemas | all |
| Stage 30 upper terrain is clipped | AIMING returns the authored bookmark before terrain framing; Stage 30 grew to 240x160 with a peak near 126 while its camera stayed near the common late-stage bookmark | `src/camera/camera_director.gd:304-323`; `resources/stages/catalog.tres:3181-3201`; `.agents/evidence/command-columns-hud-2026-08-06/exported-aim-lock-stage30-ko-1280x720.png` | Use canonical playable-top bounds and authored-first safe framing | 2.1-2.3 |
| Existing full-AABB framer is too broad | `render_world_aabb()` includes top plus support shell/bottom; `TerrainCameraFramer` can preserve authored direction but currently consumes all eight render-AABB corners | `src/terrain/terrain_geometry_factory.gd:13-75`; `src/terrain/terrain_surface.gd:83-86`; `src/camera/terrain_camera_framer.gd` | Add cached playable-top bounds and shared frustum-fit helpers; never feed the closed render AABB to Aim Lock | 2.1-2.2 |
| Existing tests protect the defect | The composition test checks three legacy stages at 55 degrees and caps distance at 1.35x; Stage 30 safety checks only clearance/ray behavior | `tests/phase8_aiming_composition_test.gd`; `tests/camera_safety_test.gd` | Use the gameplay 48-degree FOV, remove the distance cap, and assert safe-frustum landmarks for Stage 01/10/20/30 | 2.3 |
| Prior plans cannot own the fix | The Aim View plan is archived and conflicts with the selected camera/coverage direction; the completed HUD plan explicitly excluded camera and paint | `.agents/execplans/2026-08-06-aim-view-and-coverage-opportunity.md:3,24-27`; `.agents/execplans/2026-08-06-command-columns-hud.md:57-63` | Keep both historical; execute this one new active contract | all |
| Validation must remain bounded | The repository requires `scripts/verify.ps1`, a production-style build, and rendered evidence; the user rejected repeated micro-QA | `AGENTS.md`; `scripts/verify.ps1`; existing background capture runner | Run one focused batch after integration and one final verify/export/three-capture gate | 1.3, 2.3, 3.1-3.3 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership,
  safety, and validation decision is closed.
- Godot `4.7.1.stable.official.a13da4feb`, the explicit repository verify
  command, Windows export preset, and background capture arguments are
  available. No dependency or bootstrap is required.
- Remaining unknowns are implementation-local shader constants and framer math
  corrections inside the locked rendered and frustum acceptance criteria.

## Tasks

### Phase 1: Truthful target-area presentation

Goal: make the existing scoreable footprint and percentage mean the same thing
to the player without changing gameplay state or data.

Preconditions:

- This active contract is committed by itself.
- Existing dirty gameplay/generation files remain untouched.

Source owners: `src/paint/terrain_paint.gdshader`, `translations/ui.csv`,
generated translation resources, `tests/localization_ui_test.gd`,
`tests/paint_queue_determinism_test.gd`, `tests/phase8_hud_truth_test.gd`

- [ ] **1.1** Distinguishable target footprint and threshold-aligned paint
  - Change: retain the target texture as classification only, make dry target
    and non-target playable top visibly distinct at aiming distance, and move
    saturated paint-fill activation to the authoritative `0.5` threshold.
    Remove or neutralize any neighbor halo that reads as additional blue fill.
  - Accept: target corridors/pads are identifiable before firing; target and
    non-target traversal still read as one physical paint material; the same
    PaintSystem texture remains the sole mutable visual source.
  - Guard: `paint_queue_determinism_test.gd` continues proving that valid
    non-target top paint persists but does not increase target coverage.
- [ ] **1.2** Target-specific HUD and result language
  - Change: update Korean/English coverage caption, coverage-format, Finish
    tooltip, and final-result copy to name the target area. Preserve existing
    translation keys, meter component, target line, values, signals, and Theme.
  - Accept: `TARGET AREA/목표 영역` fits the existing narrow meter at 1280x720;
    Korean and English state that Finish/results score target-area coverage and
    do not imply whole-terrain paint.
- [ ] **1.3** Coverage contract integration
  - Change: update only focused localization/HUD assertions needed for the new
    words and owner semantics. Do not add pixel-by-pixel visual tests.
  - Accept: the focused paint, localization, and HUD truth scripts pass together
    after Phase 1 and camera integration are complete.

### Phase 2: Authored-first safe Aim Lock framing

Goal: keep good authored views and correct only stages whose playable top and
landing surface leave the Aim Lock safe frame.

Preconditions:

- Phase 1 source changes are integrated; its batch checks are intentionally
  deferred to the combined focused gate after Phase 2.

Source owners: `src/terrain/terrain_surface.gd`,
`src/camera/terrain_camera_framer.gd`, `src/camera/camera_director.gd`,
`src/gameplay/gameplay_scene.gd`, `tests/phase8_aiming_composition_test.gd`,
`tests/camera_safety_test.gd`

- [ ] **2.1** Canonical playable-top bounds and shared frustum math
  - Change: cache a world AABB from canonical playable-top vertices during
    `TerrainSurface.configure`; add `TerrainCameraFramer` helpers that evaluate
    and solve bounds with the same authored basis/FOV/aspect math.
  - Accept: the top AABB contains every canonical top vertex and excludes the
    skirt, shell, bottom, wall, apron, mechanisms, and decorations; the fit
    helper reports the same pass/fail used by the solver and tests.
- [ ] **2.2** Conditional Aim Lock distance correction
  - Change: give `CameraDirector.configure` an optional read-only
    `CannonController`, build interest bounds from playable top, `8.0 m`
    headroom, summit samples, cannon base, and muzzle, and first test the exact
    authored AIMING pose with margin `1.15`. If it fails, use the nearest-target
    sample as a real terrain focus and call `framed_pose_around` while preserving
    authored forward direction and camera FOV. Pass the cannon from
    `GameplayScene`; do not subscribe to prediction changes.
  - Accept: authored-safe stages return the unchanged StageData pose; corrected
    stages change only camera position/focus through CameraDirector and retain
    clearance, a clear focus ray, 48-degree FOV, Map Inspection state, and all
    cannon/trajectory behavior.
  - Guard: AIMING never uses `render_world_aabb`, live prediction, stage-ID
    branches, manual coordinates, or a wider FOV.
- [ ] **2.3** Representative composition contracts
  - Change: replace the stale 55-degree/1.35x-distance assertion with actual
    48-degree safe-frustum assertions. Cover cannon base, muzzle, playable-top
    bounds, summit, default first impact, clearance, and focus ray for early
    authored fixtures and active catalog Stages 01, 10, 20, and 30.
  - Accept: the composition and camera-safety scripts pass; Stage 01 remains
    authored when it fits, and Stage 30 requires and passes the correction.

Combined focused gate, run once after Tasks 1.1-2.3 are integrated:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
@(
  'res://tests/paint_queue_determinism_test.gd',
  'res://tests/localization_ui_test.gd',
  'res://tests/phase8_hud_truth_test.gd',
  'res://tests/phase8_aiming_composition_test.gd',
  'res://tests/camera_safety_test.gd'
) | ForEach-Object {
  & $paintMountainGodot --headless --path . --script $_
  if ($LASTEXITCODE -ne 0) { throw "Focused target/camera check failed: $_" }
}
```

### Phase 3: Integration evidence and current truth

Goal: inspect the final Compatibility render once, prove the production path,
and close the plan without broad balance or gameplay claims.

Preconditions:

- Tasks 1.1-2.3 and the combined focused gate pass.

Source owners: all task-owned code/tests, `.agents/design/ART_DIRECTION.md`,
`.agents/design/UIUX_GUIDELINES.md`, `docs/design-spec.md`,
`docs/technical-architecture.md`, `.agents/Documentation.md`,
`docs/test-checklist.md`, task evidence, this contract

- [ ] **3.1** Cross-module quality audit and durable contracts
  - Change: run `$codebase-quality-auditor` once over paint/target presentation,
    camera/framer responsibility, GameplayScene wiring, tests, and docs. Make
    only safe task-scoped corrections. Update the design/architecture wording
    so target coverage and authored-first camera safety are current truth.
  - Accept: no second coverage owner, duplicated frustum formula, camera-owned
    gameplay decision, catch-all module, stale authored-distance lock, or false
    whole-terrain label remains.
- [ ] **3.2** One repository, export, and rendered UIUX gate
  - Change: announce cost/stopping condition, run `scripts/verify.ps1` once,
    export Windows once, then use the existing hidden background runner for
    exactly three 1280x720 captures: Stage 01 Aim Lock, Stage 30 Aim Lock, and a
    painted-contact state. Inspect each at native size and write the Level 3
    UIUX evidence report under the task evidence directory.
  - Accept: verify/export/captures exit zero without script/runtime errors;
    Stage 01 stays close and readable; Stage 30 shows cannon, summit, full
    playable-top silhouette, and impact surface without HUD overlap; target dry
    area and painted target/non-target contact are understandable; no text,
    focus, control, or container clips.
  - Guard: no foreground window, exhaustive resolution matrix, repeated visual
    polish loop, gameplay/balance approval, or whole-stage playthrough.
- [ ] **3.3** Truthful documentation and plan closeout
  - Change: record exact checks, build, capture paths, selected/rejected
    alternatives, and remaining owner-only visual/feel approval in
    `.agents/Documentation.md`, `docs/test-checklist.md`, the task evidence
    report, and this progress pointer. Mark this plan `done` only after every
    named acceptance and final gate passes.
  - Accept: one active-plan pointer and every completion claim match the actual
    code, logs, and images; archived/done predecessor plans stay historical.

Final gate, run once after quality review and documentation inputs stabilize:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
& .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
if ($LASTEXITCODE -ne 0) { throw 'Windows release export failed.' }
$paintMountainExport = (Resolve-Path -LiteralPath '.\builds\windows\PaintMountain.exe').Path
$captureEvidence = [System.IO.Path]::GetFullPath(
  (Join-Path (Get-Location) '.agents\evidence\target-coverage-and-safe-aim-framing-2026-08-07')
).Replace('\', '/')
& $paintMountainExport -- --capture-background --capture-screen=progression_aiming --capture-stage=stage_01 --capture-size=1280x720 "--capture-output=$captureEvidence/stage-01-aim-lock-1280x720.png"
if ($LASTEXITCODE -ne 0) { throw 'Stage 01 capture failed.' }
& $paintMountainExport -- --capture-background --capture-screen=progression_aiming --capture-stage=stage_30 --capture-size=1280x720 "--capture-output=$captureEvidence/stage-30-aim-lock-1280x720.png"
if ($LASTEXITCODE -ne 0) { throw 'Stage 30 capture failed.' }
& $paintMountainExport -- --capture-background --capture-screen=projectile_and_continuous_paint --capture-stage=stage_04 --capture-size=1280x720 "--capture-output=$captureEvidence/painted-target-contact-1280x720.png"
if ($LASTEXITCODE -ne 0) { throw 'Painted-contact capture failed.' }
```

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Static inner loop | Godot editor import/parse only when a parser/import error blocks integration | All implementation files from both branches are present | A parsed/imported task file changes |
| Focused phase gate | Five scripts in the combined focused command | Tasks 1.1-2.3 are integrated | A tested paint, copy, HUD, camera, or framer input changes |
| Quality gate | `$codebase-quality-auditor` | Focused gate passes and the integrated diff is stable | A reviewed responsibility or public API changes |
| Final gate | `scripts/verify.ps1`, one release export, three hidden captures, native-size inspection | Quality fixes and docs inputs are stable | A final-gate source/export/render input changes |

Validation rules:

- Run the narrowest check that proves the current integrated behavior; do not
  run a test after each constant, caption, or spacing edit.
- Run each named phase/final gate once at its declared checkpoint.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce different evidence.
- Record a known non-blocking warning once instead of rediscovering it.
- On start or resume, read this contract and inspect the worktree only enough to
  confirm checkpoint inputs, then continue from the first unchecked task whose
  prerequisites are satisfied.
- Treat checked tasks and recorded passing evidence as complete unless a
  relevant input changed, the evidence is missing, or the contract schedules a
  broader final gate.
- Mark a task complete only after its acceptance passes; update the checkbox and
  the single progress pointer together.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let an executor choose a new product, architecture, data, UX, or validation contract |
| Strong target tint competes with paint/trajectory/mechanisms | Adjust only neutral dry-surface contrast inside the existing target texture path and recollect the three final captures | Do not add an outline asset, second material state, or new HUD explanation panel |
| Authored Stage 01 fails the safe bounds | Accept the deterministic correction only if it remains close, keeps the cannon below 20% of the frame, and passes the same composition criteria | Do not special-case Stage 01 or weaken Stage 30 bounds |
| Safety correction moves the camera into/behind terrain | Let the existing CameraDirector clearance/occlusion solver correct the position, then verify final frustum fit | Do not bypass safety or change collision/terrain data |
| Symmetric margin still allows HUD occlusion | Increase only the shared aiming margin or apply one documented asymmetric safe-rect offset in `TerrainCameraFramer` | Do not move HUD components or author stage coordinates |
| A required target/camera source overlaps unrelated dirty work | Stop that file branch and report the exact hunk | Do not stage, revert, or rewrite the unrelated change |
| A focused test fails because an old contract protects the verified defect | Replace only the stale distance/whole-paint expectation with the locked target/frustum contract | Do not weaken unrelated physics, replay, paint-order, or state ownership assertions |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1.
- Next task: 1.1 Distinguishable target footprint and threshold-aligned paint.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- The combined focused, quality, and final gates pass at their declared cadence.
- The Level 3 evidence report records the desktop-only exception and says
  `Result: passed` with no unresolved blocker.
- Current documentation records target-only coverage and authored-first safe
  framing without reviving archived coverage-opportunity, first-hit, or success-
  route work.
- Frontmatter status changes to `done` only after implementation completion.

Replan when:

- A material discovery invalidates target-only scoring, one-mask ownership,
  same-FOV authored-direction framing, save/replay compatibility, or the named
  production validation path.

Do not replan or stop for:

- Shader constants, AABB iteration details, or frustum helper implementation
  mechanics that stay inside the locked rendered and behavioral contracts.
- A passing check whose relevant inputs have not changed.
