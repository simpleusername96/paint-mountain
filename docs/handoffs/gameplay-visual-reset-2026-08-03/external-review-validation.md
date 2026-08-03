---
type: evidence
status: active
created: 2026-08-03
last_reviewed: 2026-08-03
topic: Claude gameplay and visual reset review validation
scope: local validation of external recommendations against repository evidence
source: raw/claude-review.md
related:
  - README.md
  - external-review-raw.md
  - current-state.md
  - constraints-and-decisions.md
  - ../../../.agents/execplans/2026-08-03-gameplay-visual-reset.md
  - ../../../.agents/execplans/2026-08-03-core-interaction-redesign.md
---

# External Review Validation

## Purpose

Reconcile Claude's correction guide with the current Paint Mountain repository.
This document separates useful external analysis from unsupported numerical
choices, product changes, and implementation claims. It is evidence, not an
execution plan.

## Sources

- Raw Claude response: [`raw/claude-review.md`](raw/claude-review.md), SHA-256
  `A29AE72214F1D512A060ED5F33267291FCF6E932C14AAE053B3E1E6D0D3D5FC4`.
- Handoff contract: [`current-state.md`](current-state.md) and
  [`constraints-and-decisions.md`](constraints-and-decisions.md).
- Code baseline reviewed by Claude:
  `15bac6405e79767df55552d0113dd906fb2a6c94`.
- Current repository after the handoff-only commit:
  `bf8a4680b5c11c19e0337b85cdfed44a1e4c1812`.
- Root `AGENTS.md`, `docs/source-brief.md`, `docs/design-spec.md`,
  `docs/technical-architecture.md`, `.agents/Documentation.md`, the active
  ExecPlan, current source, resources, scenes, and targeted tests.
- Target and current-build images under `visuals/`.

Validation was static and read-only. No Godot editor, game window, solver, or
broad test suite was launched.

## Findings

### Executive verdict

Claude found the central failures accurately:

- the generator still builds a smooth lobe mass and carves routes into it;
- the projectile uses a finite payload and spaced trail requests rather than a
  continuous contact path;
- only one begun contact is emitted per physics tick, so a simultaneous terrain
  contact can suppress a mechanism contact;
- the current paint path allocates and uploads far more data per deposit than a
  60 Hz multi-ball sweep can tolerate;
- the foreground plane, lighting ratio, trajectory depth override, projected-
  size calculation, and HUD structure all contribute to the visible mismatch;
- the useful ownership boundaries should be preserved rather than replaced.

The response is not decision-complete. Several confident numbers are tuning
hypotheses, and four recommendations should not enter an ExecPlan as written:

1. changing stage targets to `35 / 50 / 70%`;
2. defining score eligibility only by proximity to the route graph and a fixed
   `42°` slope cutoff;
3. leaving solid-looking decorations non-colliding and counting their footprints;
4. claiming that `max()` mask writes alone make multi-ball physics and replay
   byte-deterministic.

### Recommendation-by-recommendation validation

| External claim or recommendation | Local evidence checked | Verdict | Codex action |
| --- | --- | --- | --- |
| The supplied current-build image is a pre-fire frame and cannot prove paint appearance. | `visuals/02-current-build.png` shows four shots remaining and zero coverage; its exact source revision is not recorded. | accept | Require controlled mid-roll and settled captures before judging paint visuals. Treat the current image as user-supplied symptom evidence, not baseline-revision proof. |
| Preserve `GeneratedStageLayout`, `TerrainGeometryFactory`, `TerrainSurface`, one closed heightfield shell, and one authoritative paint mask. | `src/terrain/terrain_geometry_factory.gd`, `src/terrain/terrain_surface.gd`, `src/stage_generation/generated_stage_layout.gd`, `src/paint/paint_system.gd`. | accept | Keep these ownership boundaries and replace behavior inside them. A world-XZ mask is an XZ projection with reconstructed 3D samples, not literal true-surface-area storage. |
| The lobe-plus-carve generator explains the wall-like target and should become route-graph-first. | `seeded_stage_generator.gd::_generate_lobes`, `_synthesize_height`; stage profiles still configure lobe fields. | accept | Replace lobe-first mass synthesis. Preserve deterministic attempt/fallback/checksum behavior. |
| Claude's exact massif formula, terrace values, slope limits, widths, and visibility thresholds can be copied directly. | No current tests or controlled renders validate those values. The proposed `max over all edges` field increases with distance and can let a high or distant edge dominate unrelated cells. Godot/Jolt traversal is not predicted by `tan(slope) ≈ friction` alone. | modify | Use the route-graph-first direction, but correct the signed-distance/nearest-edge field and validate the fixed numerical profile before promoting it. Treat all quoted ranges as review hypotheses. |
| Add typed route nodes and edges and all downstream consumers will continue working. | Current layout exposes route spines, widths, roles, shelf positions, and route queries used by generation, placement, observations, and tests. | modify | A graph may become the source model, but the migration must explicitly replace or adapt every current route-query consumer. Do not assume automatic compatibility. |
| Add corridor, terrace, silhouette, visibility, branch, and feasibility metrics to generation acceptance. | Current validation checks reversals, net descent, clearance, slope, shelf, separation, and eligibility, but not the proposed visual/topological metrics. | modify | Adopt the metric categories. Calibrate exact thresholds through deterministic generated fixtures and controlled captures before making them fail-closed gates. |
| Restrict eligibility to route distance plus a `12–18 m` margin, surfaces at most `42°`, and a total ratio of `0.14–0.22`. | `_build_eligible_mask` currently uses height and a `75°` normal limit; the same mask controls visuals and coverage. The newest user correction says traversed target terrain is painted, while route-only scoring can hide difficult target surfaces by removing them from the denominator. | reject | Preserve one mask, but define the target/playable surface explicitly. Do not repair coverage by masking away reachable target terrain. Reduce unreachable area through geometry and target classification, then validate any slope rule against real contact paths. |
| Change stage targets from `4 / 27 / 70%` to `35 / 50 / 70%`. | Current stage resources, design spec, test checklist, and active ExecPlan use `4 / 27 / 70`; the source brief gives qualitative low/moderate/~70 guidance but does not support `35 / 50`. | reject | Keep current targets until the corrected mechanic and topology have measured reliable solutions or the user explicitly changes the product rule. Do not use Claude's rectangle arithmetic as a balance decision. |
| Produce a per-physics-tick surface sweep from real contact data inside `_integrate_forces`. | `_current_top_contact` is derived in `_integrate_forces`, but trail writes currently occur later in `_physics_process` and are gated by time/distance/payload. | accept | Introduce a narrow typed sweep command from authoritative physics contacts. Do not derive persistent paint from `global_position`. |
| Bridge every contact gap up to three ticks when collider and chord limits match. | Current debounce tracks absence by collider/shape but does not prove the ball remained on the surface. At 60 Hz a three-tick gap can be a real airborne hop. | modify | Never bridge only because time and distance are small. Require a deterministic terrain cast/surface-clearance check proving continuous near-surface travel; otherwise emit a fresh contact disc and leave the airborne gap unpainted. |
| Rasterize a 3D swept capsule into the 512² mask and seed one connected-component search at both endpoints. | `PaintSystem` already reconstructs 3D surface points and applies an 8-neighbour component to a point deposit, but it has one seed and coverage remains XZ-pixel coverage. | modify | Use 3D distance for the footprint, define deterministic endpoint-to-pixel snapping, require both endpoints to belong to the same candidate component, and test tangent-plane width separately from projected coverage. |
| `max()` writes and sorting make multi-ball output byte-deterministic. | Requests are currently applied immediately in `gameplay_scene.gd`; there is no queue. `get_instance_id()` is not a stable cross-process ordinal, and physics/contact generation can still differ even when mask writes commute. | reject | Add a manager-owned spawn ordinal and a defined queued-application boundary before sorting. Byte-checksum tests must validate the entire request set and drained mask, not infer determinism from the blend operation. |
| Remove payload, amount economics, shrinking marks, payload UI/debug/observation state, and Splitter payload conservation. | `paint_projectile.gd`, `projectile_data.gd`, `paint_deposit_request.gd`, manager, mechanism resources, StageController, ShotObservation, HUD, debug, and tests all propagate the obsolete concept. | accept | Delete the concept coherently rather than aliasing it. Keep physical projectile tuning and one-shot radial commands for impact, Burst, and puddle. |
| Delete optional downhill flow. | Current flow is amount-driven and paints beyond direct ball traversal; the source brief marks it optional. | accept | Remove it from the corrected core model. Keep Burst as an explicit terrain-aware radial command through the authoritative PaintSystem boundary. |
| Lock a `4.0 m` footprint, `0.50` threshold, and Claude's alpha/material ranges. | The values are inferred from one reference image and approximate coverage arithmetic; no controlled running capture or corrected traversal exists. | needs-local-verification | Use them only as a bounded prototype baseline. They become durable tuning only after no-gap, visual-width, coverage, and performance gates pass without changing target semantics. |
| Precompute surface samples, reuse scratch storage, and batch texture upload once per rendered frame. | `_connected_component` allocates a full candidate buffer per request; `_recent_bytes.fill(0)` and full image uploads also occur per deposit. | modify | Adopt the performance direction, but include `_recent_bytes`, flood-fill queue/component allocations, a deterministic request queue, dirty-region clearing, and measured frame timings. Claude's candidate-count estimate is not an exact budget. |
| Emit every begun collider/shape contact instead of reducing all begun contacts to one. | `paint_projectile.gd` builds one primary per key, then reduces `begun_contacts` to one global primary; `GimmickBase` accepts only its exact mechanism body. | accept | Emit one event per begun key and add a simultaneous terrain-plus-mechanism regression test. Keep duplicate-activation guards. |
| Add impulse provenance and a broad `surface_class` enum. | The code substitutes an estimated impulse when the reported value is zero; `TerrainSurface` already distinguishes top and shell colliders. | modify | Add measured/estimated provenance. Add only the minimum surface identity needed by paint/contact diagnostics; do not duplicate existing collider ownership with a second classification system unless tests require it. |
| Test render/collider parity inside cells, not only at vertices. | Current render triangles use a fixed diagonal while existing parity checks emphasize height samples and limited casts. An actual diagonal mismatch has not been demonstrated. | accept | Add deterministic interior ray-versus-render samples. Change triangulation only if the new test proves a mismatch. |
| Decorations should remain non-solid and stop being excluded from coverage. | `EnvironmentDressing` currently creates non-colliding meshes; the generator excludes their footprints; the working spec excludes vegetation/rocks. The user has already identified visually solid objects being passed through as unacceptable. | reject | Solid-looking objects on reachable routes must have aligned collision or be removed/moved outside traversal. Pure visual cues may be non-solid only when they cannot be mistaken for obstacles. Do not change coverage exclusions before that policy is fixed. |
| Replace the flat plane, expose shell thickness, and lower ambient relative to the key light. | `gameplay.tscn` has a large plane, ambient `0.68`, key `0.88`; the shell base and current transforms can bury its visible thickness. | modify | Accept the art direction and faceted foreground concept. Treat shell height, light energy, luminance ratio, and screen fractions as controlled-render targets, not verified constants. |
| Keep the current camera parameters and only fix Stage 2. | Stage 1 framing parameters are close to the reference analytically; Stage 2 uses an obvious 100 m-high bookmark. The supplied capture has unknown revision/resolution, and terrain geometry is about to change. | modify | Preserve `CameraDirector` and the current Stage 1 envelope as a starting point. Recalibrate per-stage bookmarks after the new geometry, using revision-stamped captures. |
| Correct horizontal-FOV math in mechanism placement. | `_projected_horizontal_pixels` applies the vertical half-FOV directly to horizontal width and ignores aspect ratio. | accept | Correct the projection formula and test it at the supported viewport/aspect combinations. |
| Enlarge mechanisms to `6.0–7.5 m` and require `80–115%` visual/body AABB parity. | Current projected-size gates are too permissive, but one union-AABB ratio can be satisfied while individual decorative or interactive parts remain misleading. Exact size estimates are capture-sensitive. | modify | Require a minimum projected size in controlled captures and pair collision with each gameplay-relevant visible mass. Allow explicitly decorative subparts without collision; do not use one AABB percentage as the sole parity contract. |
| Turn trajectory depth testing on and use screen-consistent dots. | `trajectory_preview.gd` uses fixed world spheres and `no_depth_test = true`; the source brief limits the preview to first collision and permits hidden impact markers. | accept | Enable terrain occlusion and use distance-aware sizing/spacing. Validate the proposed pixel ranges in the running build. |
| Rebuild HUD roots with anchors/containers, `expand`, 24 px margins, and fixed type sizes. | HUD scenes use extensive absolute offsets; Korean is already the saved default. The supplied capture may not match the baseline, and all listed target resolutions are 16:9, where `expand` proves little. | modify | Preserve component ownership and Korean default. Rebuild layout with real containers, but validate non-16:9 behavior, every visible text control, ancestor clipping, and controlled captures before locking exact margins/type sizes. |
| Replay format 4 plus a painted-byte checksum proves the new contract. | Replay is format 3 and does not serialize payload, while expected observations would change and no per-shot mask checksum exists. Cross-process tests currently use tolerances. | needs-local-verification | A format bump is justified if observation/schema changes land. Capture the checksum only after queued paint is fully drained and prove fresh-process repeatability before promising byte identity. |
| Use six vertical slices with a running screenshot at every gate. | The order correctly proves terrain/contact/paint early, but several gates (`≥90 m`, `≥25%`, `10× mechanism gain`, exact composition ratios) lack local feasibility evidence. The proposed reviewer-description gate is subjective and GUI capture can interrupt the user's desktop. | modify | Keep vertical stop/go sequencing. Separate deterministic invariants from an explicit visual-review protocol, record revision/renderer/locale/resolution, store interim evidence outside the canonical delivery filenames, and never launch visible capture runs without an agreed non-disruptive path. |
| Amend stale specs and supersede the active ExecPlan immediately. | Root `AGENTS.md` and product docs still say finite payload; the current ExecPlan is the sole active plan. Protected instructions and active-plan supersession require explicit approval and a validated replacement. | modify | Record the authority conflict now. Do not edit protected `AGENTS.md` or supersede the active ExecPlan in this task. Align product docs and install one replacement plan together only after the user approves the corrected contract. |

### Accepted core

The following direction is sufficiently supported for a future replacement plan:

- keep the heightfield, closed shell, one generated layout, and one paint mask;
- replace lobe-first height synthesis with a route-graph-first target generator;
- remove finite paint quantity and downhill flow;
- create continuous paint sweeps from authoritative physics contacts;
- emit all begun contacts and preserve collider identity;
- add cell-interior render/collider parity evidence;
- fix trajectory occlusion and mechanism projection math;
- preserve existing system owners while rebuilding their faulty internals;
- prove one simple route, real contact, continuous paint, and visual composition
  before rebuilding all stages.

### Not accepted as current product truth

- `35 / 50 / 70%` coverage targets;
- route-proximity-only scoring eligibility;
- non-colliding solid-looking route decorations;
- exact physics/replay determinism inferred from commutative mask blending;
- any screenshot-derived number treated as final without a controlled baseline.

### Plan readiness

The user subsequently requested a plan based on this validated analysis.
`.agents/execplans/2026-08-03-gameplay-visual-reset.md` is now the sole active
ExecPlan and the prior core-interaction plan is preserved with `status:
superseded`. The replacement closes the five readiness decisions as follows:

1. its Phase 0 names the exact protected `AGENTS.md` line edit and treats a
   later instruction to execute the plan as approval for that edit only;
2. `target_mask` is one filled graph-derived target footprint, and every top
   texel inside it is paintable/scored without a slope cutoff;
3. non-solid decoration is outside target/route/pad envelopes and no decorative
   gameplay obstacle is added;
4. stage targets remain `4 / 27 / 70%` with `4 / 5 / 6` shots; and
5. normal work is headless, with only a coordinated Stage 1 proof and final
   release session writing separate interim/final evidence.

The numerical baselines in the plan are locked implementation contracts rather
than facts proven by this evidence document. A failed gate requires defect
correction or plan revision; it does not authorize executor-owned retuning.

## Recommendations

1. Use Claude's accepted core as the design direction, not its entire correction
   guide as an implementation contract.
2. Execute only the replacement plan after its exact Phase 0 approval gate.
3. Keep continuous paint, multi-contact reporting, and one readable Stage 1
   route as the first vertical proof.
4. Keep numerical terrain, paint, camera, mechanism, and UI values tied to named
   controlled evidence rather than treating screenshot arithmetic as product
   authority.
5. Preserve the raw review unchanged and cite this validation whenever an
   external recommendation is adopted or rejected.

## Limitations

- No runtime or render validation was performed in this task.
- The current-build image has no proven commit, renderer, or exact viewport
  provenance.
- Godot/Jolt traversal behavior, per-frame paint cost, exact cross-process mask
  identity, and all proposed visual thresholds remain unmeasured.
- This validation does not change the source brief, protected instructions,
  active specifications, stage balance, or active ExecPlan.
