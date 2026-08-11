---
type: plan
status: done
created: 2026-08-11
scope: ground the open mountain composition, integrate minimal approved environment assets, and publish Korean rendered evidence
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../../docs/source-brief.md
  - ../../docs/asset-licenses.md
  - ../../docs/test-checklist.md
  - 2026-08-11-web-runtime-responsiveness.md
---

# Grounded Open Environment Asset Integration - Execution Contract

Paint Mountain will retain its independently closed playable mountain and open
miss rules while replacing the visually detached unshaded apron and blank
procedural horizon with a lit, shadow-receiving ground treatment and a small
CC0 panoramic sky. The final Korean HTML report will compare the prior running
capture with production-rendered briefing, Map Inspection, and Aim View states.

## Purpose

- Objective: make the pre-stage mountain read as fixed to a continuous world
  instead of a floating rectangular diorama, then document suitable external
  environment packs and the actual applied subset.
- Deliverable: two minimally vendored CC0 texture assets, a grounded open-world
  material/sky integration, focused regressions, Windows/Web release captures,
  an updated asset ledger, and `docs/reports/environment-grounding-2026-08-11/index.html` in Korean.
- Completion state: every task and named gate passes, the release captures show
  a stable horizon and contact shadow without an enclosing wall or route
  obstruction, and the report distinguishes researched candidates, applied
  assets, rejected alternatives, performance cost, and limitations.

## Scope and Boundaries

In scope:

- The gameplay `WorldEnvironment`, open-ground/apron presentation, existing
  environment dressing, external asset provenance, production captures, and a
  Korean HTML report.
- Kenney Skyboxes `skybox-day.png`, ambientCG Ground 003 1K JPG color map, and
  the already approved Kenney Nature Kit subset.
- A lit Compatibility-renderer ground shader that mutes the realistic source
  texture and receives the mountain's existing directional-light shadow.

Out of scope:

- Terrain transforms, generated height/topology, Support Shell depth, cannon
  position, camera interaction, physics bounds, apron collision, paint, score,
  stage data, mobile layouts, itch.io deployment, plugins, and package installs.
- Full external archives, 2K+ textures, HDR/EXR skies, normal/displacement maps,
  photoreal lighting, dynamic weather, new gameplay collision, or decorative
  objects that hide routes or mechanisms.

Constraints and invariants:

- `StageController`, `PaintSystem`, and `CameraDirector` ownership does not move.
- `OpenPlayEnvironment` retains exactly one apron collider and no rear or side
  walls; the terrain/apron join remains world Y `-2.0` with no geometry gap.
- Saturated blue remains reserved for paint, trajectory, and primary UI. Ground
  and sky remain low contrast and decoration remains non-gameplay.
- The Compatibility renderer, fixed 60 Hz physics, Web export size budget, and
  existing Korean-first UI hierarchy remain intact.
- Only publisher-hosted CC0 files with recorded archive and bundled-file hashes
  may enter `assets/`; no external install scripts or package manager commands run.

Destructive or irreversible actions:

- None. Release files and imported caches are reproducible from tracked source.

Exact actions requiring owner or user approval:

- None beyond the user's explicit request in this conversation to research and
  apply external resource packs. Any non-CC0 asset, paid tier, attribution
  exception, package/plugin install, or itch.io upload requires a new approval.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Floating-ground impression | `open_play_environment.tscn` renders a pale unshaded apron that cannot receive the mountain shadow; terrain and apron already meet at world Y `-2.0` | `OpenPlayEnvironment.configure`, `PlayBoundsSpec`, `TerrainGeometryFactory`, prior Stage 02 Map Inspection capture | Preserve all transforms and collision; correct material, shadow, and horizon only | 2.1, 2.2 |
| Open-world rule | `OpenPlayEnvironment` owns one apron body; source brief forbids rear/side walls and hidden blockers | `tests/open_play_environment_test.gd`, open-mountain supersession in `docs/source-brief.md` | Add no wall and no collision; retain one apron body and open bounds | 2.1, 3.1 |
| Sky asset | Gameplay currently uses a procedural gradient | `scenes/gameplay/gameplay.tscn`; Kenney official page lists five CC0 sky textures and a Godot PanoramaSkyMaterial workflow | Vendor only `skybox-day.png`, disable mipmaps, and use it as the gameplay panorama while retaining the existing sun key | 1.1, 2.2 |
| Ground asset | Apron currently has no texture and uses unshaded flat color | ambientCG Ground 003 official page and CC0 license; 1K JPG archive inspected locally | Vendor only the 1K color JPG; omit normal, displacement, roughness, Blender, USD, and MaterialX files; mute it in a world-space ground shader | 1.1, 2.1 |
| Nature dressing | Five Kenney Nature Kit GLBs already render as muted non-gameplay scale cues | `EnvironmentDressing.MODEL_PATHS`, `docs/asset-licenses.md` | Reuse the existing approved subset; do not change baked decoration identity or add a new synchronous preload path | 2.3 |
| External candidate comparison | Kenney, ambientCG, KayKit, Quaternius, and Poly Haven have viable official sources with different style/payload tradeoffs | Primary publisher pages reviewed 2026-08-11 | Report all viable candidates; recommend the applied small CC0 combination and explain why larger/photoreal alternatives were not bundled | 4.1 |
| Runtime proof | Existing capture runner supports briefing, Map Inspection, and Aim View from exported builds | `DeliveryCaptureRunner`, `docs/test-checklist.md` | Capture Stage 02 at 1280x720 and Map Inspection at 1920x1080 from the final Windows release; compare with the existing pre-change capture | 3.2, 4.1 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership,
  safety, and validation decision is closed.
- Godot 4.7.1, the existing capture runner, official direct asset URLs, PowerShell,
  and the repository validation scripts are available. No new executable
  dependency is required.
- Remaining unknowns are shader/color tuning local to the chosen contract and
  cannot change scope, ownership, licensing, or validation.

## Tasks

### Phase 1: Minimal CC0 asset intake

Goal: commit only the selected publisher files with reproducible provenance.

Preconditions:

- Official source pages, license terms, archive contents, byte sizes, and SHA-256 hashes have been inspected.

Source owners: `assets/environment/`, `assets/licenses/`, `docs/asset-licenses.md`

- [x] **1.1** Vendor the selected sky and ground files.
  - Change: add Kenney `skybox-day.png`, ambientCG `Ground003_1K-JPG_Color.jpg`, and the relevant CC0 notices; generate their Godot imports with sky mipmaps disabled and ground mipmaps enabled.
  - Accept: each tracked file hash equals the inspected source member, every asset loads in Godot 4.7.1, and no unselected archive member or install script appears in the repository.
- [x] **1.2** Extend the third-party asset ledger.
  - Change: record publisher page, official archive URL, archive hash, bundled-file hash, license, and runtime use.
  - Accept: `docs/asset-licenses.md` names exactly the bundled subset and contains no unsupported attribution or license claim.

### Phase 2: Grounded open-environment render

Goal: create a stable ground/horizon read without changing gameplay geometry or rules.

Preconditions:

- Phase 1 acceptance passes.

Source owners: `scenes/gameplay/gameplay.tscn`, `scenes/gameplay/open_play_environment.tscn`, `src/terrain/open_ground.gdshader`, `src/terrain/environment_dressing.gd`, `src/app/app_root.gd`

- [x] **2.1** Replace the apron card material with a lit ground shader.
  - Change: sample the approved Ground 003 color map in world space, reduce saturation/contrast, retain high roughness, receive existing daylight shadows, and extend the existing apron render mesh beyond the camera far plane while preserving the smaller fixed collision faces.
  - Accept: the mountain/apron join has a visible contact shadow, the apron no longer reads as an unshaded rectangle, and `OpenPlayEnvironment` still has exactly one collider with the same stable contact IDs.
  - Guard: `tests/open_play_environment_test.gd` continues to prove no rear/side wall, no hidden blocker, and a zero terrain-join gap.
- [x] **2.2** Apply the approved panoramic day sky.
  - Change: replace the gameplay procedural sky material with a `PanoramaSkyMaterial` using the Kenney day texture; deactivate the menu-preview `WorldEnvironment` whenever its preview world is hidden so it cannot mask the gameplay environment; keep the existing directional sun and restrained ambient contract.
  - Accept: briefing and Map Inspection show a stable cloud horizon at every orbit angle, the sky does not overpower blue paint/UI, and no panorama seam is visible in the inspected captures.
- [x] **2.3** Preserve sparse scale cues.
  - Change: keep the existing five approved Kenney Nature Kit decoration models and their muted runtime material path unchanged.
  - Accept: existing trees/rocks remain visible but subordinate, and no additional decoration load or baked-layout identity change occurs.

Batch gate:

- Run the focused open-environment, decoration-placement, camera-safety, and Map Inspection direction tests once after all Phase 2 inputs settle.

### Phase 3: Production render and performance evidence

Goal: prove the actual shipped renderer, framing, interaction, and Web budget.

Preconditions:

- Phase 2 acceptance and batch gate pass.

Source owners: `export_presets.cfg`, `src/delivery/delivery_capture_runner.gd`, `docs/reports/environment-grounding-2026-08-11/assets/`

- [x] **3.1** Run project and release gates.
  - Change: none beyond fixes required by named failures.
  - Accept: `scripts/verify.ps1`, the full Godot suite, Windows export, Web export, and `scripts/verify-web-release.ps1` pass; the compressed Web payload stays below 20 MiB and its delta is recorded.
- [x] **3.2** Capture final running-game states.
  - Change: export `Windows Desktop` and use its background capture path for Stage 02 briefing, Map Inspection, and Aim View at 1280x720 plus Map Inspection at 1920x1080.
  - Accept: every PNG has the requested dimensions, correct Korean state, grounded join/horizon, readable mountain/routes/glyphs, no UI clipping, no focus artifact, and no debug overlay.

### Phase 4: Korean HTML assessment

Goal: give the user a durable, evidence-backed asset and visual decision report.

Preconditions:

- Phase 3 production captures and payload results pass.

Source owners: `docs/reports/environment-grounding-2026-08-11/index.html`, `docs/reports/environment-grounding-2026-08-11/assets/`

- [x] **4.1** Publish the Korean HTML report.
  - Change: include the current-state diagnosis, before/after runtime images, applied subset, candidate comparison, primary source links, license/attribution facts, Web cost, visual findings, recommendation, and limitations in a responsive standalone HTML page.
  - Accept: the report has `Purpose`, `Sources`, and `Findings` content, opens locally without a server, has no broken local images or links, fits desktop and narrow widths without horizontal clipping, and labels runtime evidence versus publisher information truthfully.
- [x] **4.2** Record implemented truth and QA evidence.
  - Change: update `.agents/Documentation.md` and `docs/test-checklist.md` with only observed passing facts, then mark this contract `done`.
  - Accept: documentation does not claim itch.io deployment or user approval, and the plan contains no unchecked task or unresolved material decision.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `$env:GODOT_BIN --headless --path . --editor --quit-after 2`; focused `open_play_environment_test.gd` and one 1280x720 briefing capture | Asset import or ground/sky scene input changes | A relevant asset, shader, scene, or contract test changes |
| Phase gate | Focused open-environment, decoration-placement, camera-safety, Map Inspection direction tests | Phase 2 tasks pass | A Phase 2 input changes |
| Final gate | `scripts/verify.ps1`; full `scripts/test.ps1`; Windows and Web release exports; `scripts/verify-web-release.ps1`; final four capture runs; HTML link/layout inspection | All implementation and report tasks pass | A production, capture, or report input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Run the production-style final gate once because repository policy requires
  built-render evidence for visual gameplay changes and the new textures affect
  the Web payload.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let the executor choose a new product, architecture, dependency, data, UX, safety, or validation contract |
| The panorama has a visible seam or exceeds the Web budget | Keep the same Kenney source and downselect to another included 1K panorama only after recording its source hash; do not introduce HDR/EXR or a new publisher during implementation | Revise the locked asset row before changing source |
| The ground texture reads photoreal or competes with gameplay | Reduce shader saturation, contrast, and blend strength; if still nonconformant, keep the lit/shadow ground and remove the texture from runtime while retaining it as rejected report evidence | Do not alter terrain geometry or paint material to compensate |
| Contact shadow disappears in Compatibility | Tune only ground shader lighting/shadow participation and the existing directional shadow range | Do not add screen-space effects, a second light rig, or hidden geometry |
| A capture crops the base only after delivery orbit offsets | Preserve runtime camera behavior and add a second initial-briefing capture to distinguish material from framing | Camera interaction changes require a revised contract |

Implementation discovery recorded 2026-08-11: the first release capture proved
that hiding the menu preview's `Node3D` does not deactivate its child
`WorldEnvironment`; the preview background therefore continued to mask the
gameplay panorama. Task 2.2 and its source-owner list now include the narrow
environment handoff fix. This does not change the selected assets, visual
direction, gameplay rules, architecture owner, dependency scope, or gates.
The corrected environment then exposed two presentation facts that had been
masked by the preview background: sky-derived ambient light overexposed the
mountain, and the fixed collision apron edge remained visible. A separate
horizon-plane experiment was rejected because its lighting did not match the
generated apron. Task 2.1 instead extends the existing apron render faces
beyond the camera far plane while retaining the original collision faces;
task 2.2 uses the authored restrained ambient color instead of sky-derived
ambient. Both are render-only corrections inside the locked open-ground and
lighting contract.
The first Web export remained below the 20 MiB absolute ceiling but measured
20,066,411 gzip bytes, which exceeded the repository's stricter 10% allowance
over the 17,269,724-byte baseline. The source assets and their recorded hashes
remain byte-exact; Godot import size limits are set to 1024 pixels for the
stylized panorama and 512 pixels for the deliberately subdued ground detail.
This is the predetermined same-source Web-budget response and introduces no
new asset, package, license, or runtime load path.

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: none; user review or separately authorized itch.io deployment.
- Last completed gate: Final release, rendered evidence, and report gate.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.
- Resume rule: read this contract and inspect the worktree only enough to
  confirm checkpoint inputs, then continue from the first unchecked task whose
  prerequisites pass. Checked work is complete unless a relevant input changed
  or its evidence is missing. Do not repeat passing checks for confidence.

## Completion Evidence

- Godot 4.7.1 `scripts/verify.ps1` and the full ordered test suite pass.
- Fresh Windows and Web release exports pass. Web static verification reports
  12 files, 49,708,547 raw bytes, and 17,296,016 gzip bytes, which is 26,292
  bytes (0.15%) above the 17,269,724-byte baseline and inside both budgets.
- The final Windows release produced four inspected Korean Stage 02 captures:
  Briefing, Map Inspection, and Aim View at 1280x720, plus Map Inspection at
  1920x1080. The report also retains the prior 1920x1080 Map Inspection image.
- The Korean report contains eight semantic sections, six valid local image
  references, 19 HTTPS source links, two responsive breakpoints, and an
  explicit horizontal-overflow guard for wide tables. Chrome policy rejected
  local `file://` navigation; this contract records static report verification
  and does not claim a browser-rendered layout pass.
- `docs/asset-licenses.md`, `.agents/Documentation.md`, and
  `docs/test-checklist.md` record the selected files, implemented truth,
  validation results, and the unchanged itch.io deployment state.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- Durable asset provenance and implemented truth are recorded in their owning
  record/checklist.
- Frontmatter status is changed to `done` only after implementation is complete.

Replan when:

- A material discovery invalidates the locked asset, ownership, open-world,
  collision, performance, or evidence contract.

Do not replan or stop for:

- Shader tuning within the fixed muted-ground direction.
- A passing check whose relevant inputs have not changed.
