---
type: plan
status: archived
created: 2026-08-06
last_reviewed: 2026-08-06
scope: cannon-anchored Aim View and coverage-opportunity-budgeted late-stage progression
source: user-directed analysis of late-stage Aim Lock framing and target-coverage scaling on 2026-08-06
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
  - 2026-08-06-fast-stage-entry-and-fire-capacity.md
---

# Cannon-Anchored Aim View and Coverage-Opportunity Progression - Execution Contract

> Archived on 2026-08-06 after the user rejected the non-UI coverage-budget and
> exhaustive-validation framing. Do not execute this contract. The user retained
> only the need for a substantially better UI layout; that direction is being
> selected from current-runtime-grounded visual concepts before a new
> implementation contract is written.

Paint Mountain will keep the aiming camera at its authored cannon-side position
while allowing the player to look across and upward through the late-stage
mountain without changing cannon yaw, elevation, power, or projectile motion.
The same implementation will replace the late target curve's raw percentage
growth with a fixed, gentler progression ending at 12.5% and admit generated
layouts only when their authoritative target mask, route corridors, and placed
Burst glyphs provide at least 20% more structural coverage opportunity than the
one-star target. Existing Burst and Splitter glyphs become the coverage and
shot-efficiency amplifiers; ball size, paint footprint, ammunition, and the
three-mechanism set remain unchanged.

## Purpose

- Objective: make upper late-stage terrain aimable from the cannon-side view
  and remove the Stage 20-30 target-area growth that currently outpaces shots
  and readable amplification routes.
- Deliverable: a presentation-only `Aim View`, right-drag view input,
  prediction-aware soft vertical framing, updated Korean/English help, a pure
  offline `CoverageOpportunityEvaluator`, target-aware Burst/Splitter placement,
  a version-9 generated catalog using the revised target curve, focused tests,
  current documentation, and production-style rendered evidence.
- Completion state: Stage 01 preserves the close authored composition; Stage 30
  can frame its summit, upper target surface, and every glyph from the unchanged
  authored camera position through bounded Aim View movement; left drag and the
  wheel retain cannon aim/power behavior; all 30 generated stages pass the
  coverage-opportunity gate; Stage 30 has a 12.5% one-star target and seven
  shots; the production build loads the new format-4 bundle; and no agent-driven
  gameplay, balance, feel, or aesthetic approval is claimed.

## Scope and Boundaries

In scope:

- `CameraDirector`-owned Aim View orientation state while interaction mode is
  `AIM_LOCKED`, with `StageData.aiming_camera_position` as the fixed desired
  camera anchor.
- Right-drag yaw/pitch view intent, stage-derived view bounds, initial
  prediction framing, soft prediction-edge correction, stage/restart reset, and
  preservation across Map Inspection round trips.
- Narrow `GameplayScene` routing of `CannonController.prediction_changed` into
  `CameraDirector`; the camera consumes only presentation data and never owns or
  mutates aim.
- Existing first-session hint and interaction-toggle tooltip copy in Korean and
  English. No new HUD panel or persistent status element is added.
- A pure offline coverage-opportunity evaluator over the immutable target mask,
  generated route graph, exact projectile paint footprint, and placed Burst
  radii.
- Target-mask installation before mechanism placement; target-aware Burst
  marginal-area scoring; Splitter downstream-route/chain scoring; deterministic
  globally useful placement selection; and one reproducible catalog admission
  check.
- A monotonic target curve with exact anchors `4.0%` at Stage 01, `8.5%` at
  Stage 10, `11.0%` at Stage 20, and `12.5%` at Stage 30, snapped to 0.5-point
  steps.
- Generation-contract version 9, one atomic format-4 catalog rebuild and
  promotion, focused contract tests, cross-module quality audit, production
  export/start, four bounded background captures, and current-truth docs.

Out of scope:

- Moving the aiming camera away from its authored cannon-side position, zooming
  in Aim Lock, widening the camera FOV, following projectiles, adding camera
  presets, or redesigning Map Inspection.
- Changing cannon yaw/elevation/power from view input or steering a projectile
  after launch.
- Changing the current `4/5/6/7` shot ladder, the two-root Fire capacity,
  projectile radius `1.20 m`, continuous paint footprint `1.40 m`, impact mark
  `1.75 m`, Burst radius `14.0 m`, or Splitter child-radius multiplier `0.78`.
- A fourth mechanism, new art assets, stage-specific glyph coordinates, a
  stage-ID placement branch, or a new HUD surface.
- A second runtime paint/coverage representation, finite paint payload, a
  runtime coverage estimator, automatic target adjustment per playthrough, or
  exposure of the offline budget to the player.
- An exhaustive trajectory/physics solver, a target-wide first-hit certificate,
  an all-stage live playthrough, fine numeric tolerance matrices, or agent-owned
  gameplay/balance/aesthetic QA. The existing exact target-wide certificate gap
  remains separate.
- Removing or staging unrelated dirty-worktree evidence, probes, generated
  bundles, tests, or user-authored changes.

Constraints and invariants:

- `StageController` remains the sole owner of stage state, shots, Fire
  admission, and results.
- `PaintSystem` remains the sole mutable runtime paint mask and coverage owner.
  The offline opportunity evaluator reads a copy of `GeneratedStageLayout`'s
  immutable target mask and creates only temporary build-time sets.
- `CameraDirector` owns camera transforms and Aim View state;
  `AimInputController` maps human input to narrow intents; neither owns the
  other's state.
- Left drag remains cannon yaw/elevation, wheel remains power, A/D/W/S remain
  cannon aim, Space remains Fire, and Tab remains the Aim Lock/Map Inspection
  toggle. Right drag is the only new Aim Lock gesture.
- The desired Aim View camera position is always
  `StageData.aiming_camera_position`. Existing terrain-clearance correction may
  protect the camera but cannot become zoom, full-terrain framing, or a
  stage-specific offset.
- Glyphs remain flat terrain-conforming circular markings found by the shared
  visible-surface search with full-footprint, slope, visibility, boundary, and
  separation checks.
- Coverage opportunity is structural admission evidence, not a physical clear
  certificate. The user remains the owner of gameplay and balance acceptance.
- The project remains launchable after each completed phase. The version bump
  and new catalog pointer are promoted together, never as an incompatible
  intermediate commit.

Destructive or irreversible actions:

- None. The all-stage build creates a new content-addressed bundle and changes
  the active catalog pointer only after validation. Prior bundles stay intact.
- The final export replaces the ignored local
  `builds/windows/PaintMountain.exe`; it can be rebuilt from source.

Exact actions requiring owner or user approval:

- Starting implementation of this active plan authorizes the one all-30 catalog
  build and one production export named below. Before the catalog build, report
  its expected cost and stopping condition; no additional product choice is
  needed.
- Any dependency, external asset, ammunition, ball/paint scale, mechanism-set,
  FOV, candidate-domain, or target-wide certification change requires an
  explicit plan revision and user approval.

## Domain Alignment

| Term | Exact meaning | Owner |
| --- | --- | --- |
| Cannon Aim | The launch yaw, elevation, and power that determine the preview and real projectile | `StageController` and `CannonController` |
| Aim View | Presentation-only camera yaw/pitch around the fixed authored aiming-camera position while Aim Lock is active | `CameraDirector` |
| Map Inspection | The existing separate presentation/input mode with terrain refocus, left-drag orbit, and wheel zoom | `CameraDirector` with existing input boundary |
| Coverage Result | Runtime unique painted target pixels divided by all immutable target pixels | `PaintSystem` |
| Coverage Opportunity | A temporary offline union of target pixels near designed route corridors and placed Burst footprints | `CoverageOpportunityEvaluator` under stage generation |
| Coverage Opportunity Gate | Candidate admission requiring opportunity pixels to be at least `ceil(required one-star pixels * 1.20)` | `SeededStageGenerator` and `StageCatalogBuilder` recheck |
| Coverage Amplifier | Burst, which directly adds a radial authoritative paint mark, and Splitter, which makes distinct route coverage more shot-efficient | Mechanism resources/runtime owners and `MechanismLoadoutPlanner` for placement |
| Route Extender | Uphill Rebound, which redirects one retained ball but contributes no direct pixels to the opportunity budget | Uphill mechanism owner |

`Coverage Opportunity` must never be called paint capacity, payload, remaining
paint, achievable coverage, or runtime coverage. A paintball remains capable of
painting every new valid-top traversal for the entire stage.

## Locked Product and Algorithm Decisions

### Aim View interaction and framing

- Aim Lock input is `left drag = Cannon Aim`, `right drag = Aim View`,
  `wheel = power`, `A/D/W/S = Cannon Aim`, `Space = Fire`, and `Tab = Map
  Inspection`. Map Inspection keeps its existing click/left-drag/wheel contract.
- Aim View changes orientation only. It does not parent the camera to the cannon,
  move the desired camera position, change FOV, alter the preview, or affect a
  launched projectile.
- On stage start or restart, derive the Aim View envelope from the authored
  aiming direction and the angular directions from the authored camera anchor to
  the cannon muzzle, current predicted first impact, summit-region centroid, and
  every placed glyph center. Add a six-degree composition margin, then clamp the
  manual envelope to at most 25 degrees left/right, 10 degrees below, and 40
  degrees above the authored direction. No stage coordinate is authored.
- The initial orientation is the closest orientation to the authored target that
  places a valid current first-impact point inside the central 60% of the
  viewport vertically. If no fireable prediction exists, retain the authored
  direction until one arrives.
- When the current first impact leaves the central 70% vertical safe band and no
  right drag is active, softly adjust only the automatic base pitch until it
  returns to the nearest safe-band edge. Preserve the player's manual yaw/pitch
  offset; a deliberate manual look may move the impact off-screen.
- Switching to Map Inspection preserves the current Aim View state. Returning
  to Aim Lock restores that state, validates it against the current envelope and
  prediction, and never resets to the obsolete fixed target. Stage restart or a
  different stage resets it to the new stage-derived initial state.
- If the fixed position and 40-degree upward cap cannot individually frame a
  required Stage 01 or Stage 30 interest point, stop and replan; do not back the
  camera away or widen FOV as a hidden fallback.

### Coverage opportunity and progression

- The target curve is fixed and deterministic:
  - Stages 01-10: existing `4.0 + 0.5 * (stage - 1)`.
  - Stages 11-20:
    `snappedf(lerpf(8.5, 11.0, float(stage - 10) / 10.0), 0.5)`.
  - Stages 21-30:
    `snappedf(lerpf(11.0, 12.5, float(stage - 20) / 10.0), 0.5)`.
- The shot ladder stays `4` through Stage 05, `5` through Stage 15, `6` through
  Stage 25, and `7` through Stage 30. Star thresholds stay `target`,
  `target + 2.5`, and `target + 5.0`.
- For a valid generated layout, the evaluator builds one temporary bit set per
  route role. A target pixel belongs to a route set when its exact shared-surface
  3D sample is within the root projectile's `paint_footprint_radius` of that
  route's complete generated centerline. Sample each line segment no more
  coarsely than half the footprint radius.
- Select at most `min(maximum_shots, route_count)` route sets by deterministic
  largest marginal target-pixel gain. Union overlap once.
- Add each placed Burst's target pixels by exact shared-surface 3D distance from
  the glyph center using `MechanismData.burst_radius`. Burst/Burst and
  Burst/route overlap count once.
- Splitter contributes no imaginary paint and adds no raw pixels to the budget.
  Its placement score values three distinct downstream route roles, their
  marginal target corridors, and a usable Splitter-to-Burst link. A link exists
  only when one stored child target lies inside the paired Burst glyph radius
  after subtracting the Splitter child's physical radius. Burst consumes a ball,
  so Burst-to-Splitter is never counted as a chain. Uphill Rebound adds no direct
  budget.
- `required_pixels = ceil(target_pixel_count * target_coverage / 100.0)` and the
  candidate passes only when
  `opportunity_pixels >= ceil(required_pixels * 1.20)`. This is 20% relative
  structural headroom, not 20 percentage points and not a finite shot payload.
- The evaluator is recomputed during candidate generation and the fast catalog
  validation path. Its result is not serialized into the baked runtime layout,
  so the baked schema and bundle format remain unchanged.
- Install the already validated authoritative target mask before glyph
  placement. Burst candidates rank by marginal unique target pixels; Splitter
  candidates rank by distinct downstream coverage roles and useful amplifier
  chaining; Uphill keeps its highest-local-direction ranking. The bounded
  deterministic assignment maximizes the whole placement set, not the first
  individually valid anchors, and retains anchor-ID tie-breaking.
- The mechanism count curve and canonical loadout stay unchanged. In particular,
  Stage 30 retains two Burst, two Splitter, and two Uphill Rebound glyphs.
- A Stage 18-30 candidate must contain at least one readable Splitter-to-Burst
  link under the rule above, and every placed glyph center must be individually
  frameable from the authored position inside the stage's Aim View envelope.
  There is no authored coordinate repair.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Late terrain is clipped in Aim Lock | `CameraDirector.set_mode(AIMING)` restores one fixed StageData bookmark and `_bookmark_for` deliberately bypasses whole-terrain framing | `src/camera/camera_director.gd:149-168,304-323,365-372`; reviewed Stage 30 capture `../evidence/fast-stage-entry-and-fire-capacity/stage_30_aiming-1280x720.png` | Keep the authored position; add bounded orientation-only Aim View and stage-derived envelope | 1.1, 2.1-2.4 |
| Aim and view have no separate gesture | `AimInputController` maps left drag to yaw/elevation and wheel to power; only Map Inspection has orbit/zoom | `src/input/aim_input_controller.gd:93-114`; `src/camera/camera_director.gd:113-147,200-222` | Right drag maps only to Aim View; all existing bindings remain | 2.2-2.3 |
| Prediction cannot currently guide framing | `CannonController` emits `prediction_changed`; only preview/readiness consumers use it | `src/cannon/cannon_controller.gd:6,83-101`; `src/gameplay/gameplay_scene.gd:310-328` | `GameplayScene` forwards only the current prediction endpoint to CameraDirector | 2.1-2.3 |
| Existing camera test cannot prove late-stage access | Composition test uses three legacy resources and a hard-coded 55-degree FOV while gameplay uses 48 degrees | `tests/phase8_aiming_composition_test.gd`; `scenes/gameplay/gameplay.tscn:68` | Test active baked Stages 01, 10, and 30 with the actual scene FOV and coarse viewport bands | 1.2, 2.4 |
| Target burden grows faster than ammunition | Current mask probe found required target area per shot about `55.81 m²` at Stage 01, `155.12 m²` at Stage 10, `267.61 m²` at Stage 20, and `311.66 m²` at Stage 30; total Stage 30 requirement is about 9.8 times Stage 01 while shots grow only 1.75 times | Active format-4 bundle `v8-ac0a370...`; Stage 30 resource has `15.0%`, seven shots, `240x160 m` | Revise the late curve to 11.0% at Stage 20 and 12.5% at Stage 30; keep ammunition and paint scale | 1.1, 3.1, 3.4 |
| Glyph placement ignores actual target contribution | Burst candidates all have score 0; Splitter score is only angular divergence; first valid separated assignment wins | `src/stage_generation/mechanism_loadout_planner.gd:124-171,294-347` | Score marginal target opportunity and the whole set; keep generic surface eligibility | 3.2 |
| Placement cannot currently read the target mask | `_finalize_layout` places mechanisms before building/installing the target mask | `src/stage_generation/seeded_stage_generator.gd:318-377` | Install the same immutable target mask first, then place glyphs, evaluate budget, and place decorations | 3.1-3.3 |
| Budgeting could duplicate runtime coverage | `PaintSystem` is the sole mutable mask/coverage owner; baked layouts already carry the immutable target mask | `docs/technical-architecture.md:108-112,186-203`; `src/stage_generation/generated_stage_layout.gd:32-47` | Use an offline temporary union only and recompute it during catalog validation; persist no second coverage state | 3.1-3.4 |
| Existing product text contains obsolete target guidance | The baseline's old Stage 3 “around 70%” clause was never explicitly named by later 30-stage revisions, although current implementation uses 5%/15% | `docs/source-brief.md:636-648,1508-1557`; `StageProgressionData.target_for` | Add a bounded user supersession that defines the new 30-stage target curve and Aim View before implementation claims | 1.1 |
| Generation semantics change but payload shape does not | Contract version 8 identifies current generation/placement semantics; format 4 already persists target mask and placements | `StageGenerationContract`, `StageLayoutBakeCodec`, active `v8-ac0a370...` bundle | Bump generation contract/profile IDs to 9; retain baked schema, bundle format 4, replay format 8, and old bundle | 3.3-3.4 |
| UI must explain the new gesture without hiding terrain | First-session hint and mode tooltip are existing localized, edge-contained surfaces | `translations/ui.csv:84-89`; `src/ui/hud_controller.gd`; `.agents/design/UIUX_GUIDELINES.md` | Update only those strings to state left-drag aim/right-drag view/wheel power/Tab map | 2.3 |

Readiness statement:

- Every material product, architecture, data, UX, ownership, safety, versioning,
  and validation decision is closed.
- The current Godot executable, offline catalog builder, format-4 codec, export
  preset, background capture runner, and focused test harness are available.
- The coverage gate is intentionally structural and reproducible. It does not
  pretend to close the separately documented physical target-wide certificate
  or replace user gameplay QA.
- Remaining unknowns are implementation-local mechanics inside the locked
  camera envelope, deterministic placement search, and pure raster evaluation.

## Tasks

### Phase 1: Align authority and establish focused contracts

Goal: record the user's latest product decisions and replace stale tests with
focused contracts that fail for the verified current behavior.

Preconditions:

- Preserve all unrelated dirty work and stage only task-owned files.
- Confirm no other ExecPlan has `status: active`.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`,
`docs/technical-architecture.md`, `.agents/design/UIUX_GUIDELINES.md`,
`.agents/design/ART_DIRECTION.md`, camera/input/placement tests

- [ ] **1.1** Record Aim View and budgeted progression as the effective product contract.
  - Change: append a bounded 2026-08-06 source-brief supersession that explicitly
    replaces the old fixed Aim Lock target and obsolete Stage 3 70% target
    guidance; add the Domain Alignment terms, input contract, target anchors,
    ownership, and validation boundary to the working design/architecture docs.
  - Accept: the source brief, design spec, technical architecture, UI/UX guide,
    and art direction agree that Aim View is orientation-only, runtime paint is
    unlimited, Stage 30 targets 12.5%, and the opportunity gate is offline
    structural evidence rather than a physical solution.
- [ ] **1.2** Establish the coarse camera, interaction, progression, and budget contracts.
  - Change: update `aim_interaction_test.gd` for right-drag isolation and Aim
    View persistence; update `phase8_aiming_composition_test.gd` to use active
    baked Stages 01/10/30 and the real gameplay FOV; add
    `stage_coverage_opportunity_test.gd`; update progression/content tests for
    exact anchor targets, monotonic 0.5-point steps, unchanged shots, and star
    thresholds.
  - Accept: tests assert behavior and coarse safe viewport bands, not pixel-perfect
    composition or micro tolerances; the new camera and budget assertions fail
    for the verified current implementation while unrelated existing contracts
    remain green.

Batch gate:

- Product authority, terminology, owners, and focused failing contracts match
  this execution contract before production code changes.

### Phase 2: Implement cannon-anchored Aim View

Goal: make upper late-stage terrain inspectable and aimable without changing
camera position, cannon aim, prediction physics, or interaction mode.

Preconditions:

- Phase 1 acceptance passes.

Source owners: `src/camera/aim_view_framing_policy.gd`,
`src/camera/camera_director.gd`, `src/input/aim_input_controller.gd`,
`src/gameplay/gameplay_scene.gd`, `src/cannon/cannon_controller.gd` signal,
`src/ui/hud_controller.gd`, `src/ui/hud/camera_interaction_control.gd`,
`translations/ui.csv`, `src/delivery/delivery_capture_runner.gd`

- [ ] **2.1** Add one pure, stage-derived Aim View framing policy.
  - Change: derive the authored direction, interest-point angular envelope,
    initial prediction framing, and coarse safe-band correction from the active
    layout, glyph placements, camera FOV/aspect, and current prediction. Keep
    the pure calculation independent of HUD, device input, StageController, and
    physics mutation.
  - Accept: the policy returns deterministic bounds for Stages 01/10/30; Stage
    01 stays closest to its authored direction; Stage 30 summit and every glyph
    center are individually frameable inside the locked caps from the authored
    position.
- [ ] **2.2** Make CameraDirector own persistent orientation-only Aim View state.
  - Change: store automatic base orientation plus manual yaw/pitch offset; expose
    narrow adjust/reset/prediction-update methods; apply soft edge correction;
    preserve state across Map Inspection; reset on stage/restart; keep existing
    safety smoothing and fixed desired position.
  - Accept: Aim View never changes `StageData.aiming_camera_position`, cannon
    values, FOV, interaction mode, or prediction identity; returning from Map
    Inspection restores the current Aim View; a new stage derives a new state.
  - Guard: camera-safety tests still prove terrain clearance and Map Inspection
    bounds.
- [ ] **2.3** Route right-drag and explain it through the existing HUD surfaces.
  - Change: `AimInputController` maps right-drag to CameraDirector while left
    drag/wheel retain their exact owners; `GameplayScene` forwards
    `prediction_changed`; update only `hud.first_hint` and the two interaction
    tooltips in Korean/English. Use concise copy equivalent to “Left-drag aim ·
    Right-drag view · Wheel power · Tab map.”
  - Accept: right-drag changes the rendered view but not yaw/elevation/power;
    left drag and wheel still change only aim/power; Map Inspection blocks aim
    and Fire; both locales fit the existing hint/toggle surfaces at 1280x720.
- [ ] **2.4** Add deterministic render-smoke states for the changed composition.
  - Change: extend `DeliveryCaptureRunner` with a presentation-only Stage 30
    upper-Aim-View state and reuse the existing base/Map-return paths. Do not
    fire, simulate a solution, or play the stage.
  - Accept: focused tests pass and background source-run captures show Stage 01
    base Aim Lock, Stage 30 base Aim Lock, Stage 30 upper Aim View, and Stage 30
    Map-return without missing UI, clipping, overlap, or a camera-position jump.
    These captures are implementation evidence, not aesthetic approval.

Batch gate:

- The player can aim normally, look upward/right/left independently, return from
  Map Inspection, and keep the current first impact readable without camera
  translation or input cross-talk.

### Phase 3: Budget late-stage targets and place useful amplifiers

Goal: make every generated stage carry a target proportional to its designed
unique coverage opportunity while retaining the current physical paint scale,
shot ladder, and mechanism set.

Preconditions:

- Phase 2 acceptance passes so placement readability can use the final Aim View
  envelope.

Source owners: `src/stage_generation/stage_coverage_opportunity_evaluator.gd`,
`src/stage_generation/stage_progression_data.gd`,
`src/stage_generation/seeded_stage_generator.gd`,
`src/stage_generation/mechanism_loadout_planner.gd`,
`src/stage_generation/mechanism_placement_generator.gd`,
`src/stage_generation/stage_generation_contract.gd`,
`scripts/build_stage_catalog.gd`, stage-generation/mechanism resources and tests

- [ ] **3.1** Implement the pure opportunity evaluator and revised target curve.
  - Change: implement the locked target-mask/route/Burst union and 1.20 gate;
    update `target_for`; keep shots and star-offset rules; expose deterministic
    diagnostic counts for target, required, route, Burst, overlap, opportunity,
    and headroom without adding runtime state.
  - Accept: synthetic overlap fixtures count unique pixels once; Splitter and
    Uphill add no fabricated direct pixels; Stage 01/10/20/30 anchors are
    exactly `4.0/8.5/11.0/12.5`; shots remain `4/5/6/7`; evaluator output is
    stable across repeated calls and never mutates the layout or target mask;
    equivalent synthetic sweep and Burst footprints select the same eligible
    target pixels as the authoritative PaintSystem raster fixture.
- [ ] **3.2** Make the generic glyph assignment target-aware and globally useful.
  - Change: build/install the validated target mask before placement; retain all
    common surface eligibility; give Burst its marginal unique-target mask;
    give Splitter distinct downstream route and Splitter-to-Burst link value; keep
    Uphill's local ascent role; select a bounded deterministic whole placement
    set with anchor-ID tie-breaking.
  - Accept: Stage 30 retains six correctly typed flat glyphs; Burst/Burst overlap
    is penalized by marginal union rather than a magic distance; Stages 18-30
    contain a readable Splitter-to-Burst link; all footprint, slope, visibility,
    spacing, direction, checksum, and no-authored-coordinate tests pass.
  - Guard: target-mask checksum and target-pixel count for a fixed pre-change
    layout remain unchanged by the finalization reorder.
- [ ] **3.3** Admit only layouts with 20% relative structural headroom.
  - Change: run the evaluator after placement in candidate finalization; reject
    with a stable `coverage_opportunity` reason when the gate fails; recompute
    the same result during no-argument catalog validation; bump generation
    contract/profile IDs to 9 without changing baked schema, bundle format 4,
    or replay format 8.
  - Accept: diagnostics distinguish target, placement, and opportunity failures;
    a tampered StageData target fails validation; accepted Stages 01-30 all meet
    `opportunity >= ceil(required * 1.20)`; runtime loads no evaluator or second
    mask.
- [ ] **3.4** Build and atomically promote one version-9 thirty-stage bundle.
  - Change: after announcing expected build cost and stop condition, run the
    existing all-stage write once; validate the new content-addressed bundle;
    update the active catalog pointer only after all 30 stages pass; retain the
    prior `v8-ac0a370...` bundle.
  - Accept: active catalog contains exactly Stage 01-30; Stage 30 records target
    12.5, seven shots, thresholds `12.5/15.0/17.5`, and two of each existing
    glyph; every baked layout hydrates; the fast no-write catalog command
    recomputes and passes opportunity admission without generation or physics.

Batch gate:

- The new bundle is deterministic, loadable, structurally budgeted, and active;
  no old bundle, runtime fallback, paint rule, ammo rule, or mechanism effect was
  modified to make it pass.

### Phase 4: Audit, verify, export, and close truthfully

Goal: hand off one coherent implementation with bounded code/build/render
evidence while leaving gameplay and balance judgment to the user.

Preconditions:

- Phases 1-3 and their batch gates pass.

Source owners: all task-owned code/resources/tests/docs,
`scripts/verify.ps1`, export preset, `.agents/Documentation.md`,
`docs/test-checklist.md`, this plan

- [ ] **4.1** Run the cross-module quality audit and make only scoped fixes.
  - Change: invoke `codebase-quality-auditor` over camera/input ownership,
    prediction routing, target-mask ordering, evaluator isolation, placement
    scoring, generation versioning, and stale terms.
  - Accept: no camera transform, aim, paint coverage, target, or placement owner
    is duplicated; no catch-all file absorbs unrelated work; no runtime path
    constructs or reads the opportunity budget.
- [ ] **4.2** Run focused checks and the repository gate once after integration.
  - Change: run the named task tests during implementation, then the fast
    catalog check and `scripts/verify.ps1` once after inputs stabilize.
  - Accept: all pass without weakening range, terrain, target, containment,
    mechanism, or camera-safety contracts and without staging unrelated files.
- [ ] **4.3** Export and inspect the production presentation boundary.
  - Change: export the Windows release, start only the exported executable via
    the background capture path, create the four Phase 2.4 captures at 1280x720,
    and inspect the actual images.
  - Accept: the executable loads the version-9 format-4 bundle; base Aim Lock
    keeps the mountain dominant and controls readable; upper Aim View shows the
    Stage 30 summit/upper glyph band; Map-return preserves the Aim View; HUD
    surfaces do not clip or obscure the tested impact/glyph band. No shot is
    fired for balance QA.
- [ ] **4.4** Align current-truth documentation and close the plan.
  - Change: record the exact bundle identity, target anchors, opportunity counts,
    test results, capture paths, export result, retained first-hit-certificate
    gap, and user-owned QA boundary in `.agents/Documentation.md` and
    `docs/test-checklist.md`; mark this plan `done` only after every gate passes.
  - Accept: docs never call the opportunity budget a solution proof or finite
    paint; implementation status matches code/artifacts; final commits contain
    only task-owned changes.

## Validation and Rework Controls

Resolve the approved Godot console executable before any Godot command:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $paintMountainGodot)) {
    throw 'Approved Godot executable is unavailable.'
}
```

Focused checks:

```powershell
& $paintMountainGodot --headless --path . --script res://tests/aim_interaction_test.gd
& $paintMountainGodot --headless --path . --script res://tests/camera_safety_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase8_aiming_composition_test.gd
& $paintMountainGodot --headless --path . --script res://tests/stage_coverage_opportunity_test.gd
& $paintMountainGodot --headless --path . --script res://tests/mechanism_placement_test.gd
& $paintMountainGodot --headless --path . --script res://tests/stage_progression_candidate_test.gd
& $paintMountainGodot --headless --path . --script res://tests/stage30_progression_test.gd
& $paintMountainGodot --headless --path . --script res://tests/phase6_content_test.gd
& $paintMountainGodot --headless --path . --script res://tests/shot_feedback_test.gd
& $paintMountainGodot --headless --path . --script res://tests/localization_ui_test.gd
& $paintMountainGodot --headless --path . --script res://tests/baked_stage_layout_test.gd
& $paintMountainGodot --headless --path . --script res://tests/stage_layout_repository_test.gd
```

Artifact production and final gates:

```powershell
# Announce scope/cost first. Run once after target, placement, evaluator, and
# generation-version inputs stabilize.
& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd -- --write

# Fast deterministic load/recheck only: no generation and no physics solution search.
& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd

powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'

$paintMountainExport = (Resolve-Path -LiteralPath '.\builds\windows\PaintMountain.exe').Path
$captureEvidence = [System.IO.Path]::GetFullPath(
    (Join-Path (Get-Location) '.agents\evidence\aim-view-and-coverage-opportunity')
).Replace('\', '/')
& $paintMountainExport -- --capture-background --capture-screen=progression_aiming --capture-stage=stage_01 --capture-size=1280x720 "--capture-output=$captureEvidence/stage_01-aim-base.png"
& $paintMountainExport -- --capture-background --capture-screen=progression_aiming --capture-stage=stage_30 --capture-size=1280x720 "--capture-output=$captureEvidence/stage_30-aim-base.png"
& $paintMountainExport -- --capture-background --capture-screen=aim_view_upper --capture-stage=stage_30 --capture-size=1280x720 "--capture-output=$captureEvidence/stage_30-aim-upper.png"
& $paintMountainExport -- --capture-background --capture-screen=aim_return --capture-stage=stage_30 --capture-size=1280x720 "--capture-output=$captureEvidence/stage_30-aim-return.png"

git diff --check
```

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The one or two focused tests owned by the changed camera, input, evaluator, placement, progression, or UI file | After a coherent local behavior exists | A relevant implementation input changes |
| Camera phase gate | Aim interaction, camera safety, composition, yaw direction, feedback, and localization checks | Phase 2 tasks pass | Camera/input/UI inputs change |
| Generation phase gate | Opportunity, placement, progression, content, bake, repository, and fast catalog checks | The one all-stage bundle has been written and promoted | Target/generation/placement/artifact inputs change |
| Final gate | `scripts/verify.ps1`, release export/start, four production captures, image inspection, and `git diff --check` | All phase gates pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- The all-30 `--write` command is artifact production, not an inner-loop test.
  Run it once after its inputs stabilize and rerun only after a relevant input
  changes.
- The no-argument catalog command must remain generation-free and physics-free;
  recomputing the pure opportunity union is allowed.
- Run the build/export/captures once at the end. Before starting the broad build,
  report its purpose, expected cost, and stop condition.
- Inspect actual running-game images for missing output, clipping, overlap,
  camera-position regression, and whether the named terrain/glyph band renders.
  Do not play the game, fire shots for balance, or claim feel/aesthetic approval.
- Do not add exhaustive per-pixel first-hit solving, a trajectory grid, an
  every-stage live capture set, repeated performance sampling, or fine numeric
  tolerance tests.
- Rerun a failure only after a relevant code/data change or a new hypothesis.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let the executor choose a new product, architecture, data, UX, or validation contract |
| Stage 01 or Stage 30 interest points cannot be framed within the locked fixed-position envelope | Report the failing angular extent and stop | Do not move the camera, widen FOV, shrink the terrain, or add a stage-specific bookmark repair |
| Right-drag changes Cannon Aim or left-drag/wheel behavior regresses | Repair intent routing and ownership, then rerun only interaction/camera checks | Do not duplicate aim state in CameraDirector or input state in HUD |
| Target-mask installation reorder changes a fixed layout's target checksum or pixel count | Stop and repair ordering/data flow while preserving the original target raster | Do not edit target pixels or loosen target rules to make placement pass |
| Candidate indices 0-31 exhaust the coverage-opportunity gate | Keep the current active pointer and old bundle, report target/route/Burst/overlap counts and rejection distribution, then replan | Do not add shots, enlarge paint/Burst, reduce the target below this curve, widen the candidate domain, or hand-author glyph coordinates automatically |
| A generated candidate passes only by counting Splitter flight or Uphill as direct paint | Reject the evaluator result and correct the pure union | Airborne or redirected motion cannot be fabricated as painted pixels |
| Fast catalog validation would require persisting opportunity metrics | Recompute from StageData and the hydrated baked layout | A baked-schema or bundle-format change requires a plan revision; do not reinterpret old payloads |
| A task overlaps an unrelated dirty hunk | Preserve and merge around the existing hunk; stop only for a real intent conflict | Never reset, revert, clean, or blanket-stage the worktree |
| Korean or English hint copy clips at 1280x720 | Reflow within the existing hint/toggle containers and keep body text at least 16 px | Do not add a panel, hide a required gesture, or cover the mountain/Fire |
| Production capture renders structurally correct but gameplay still feels too hard or the composition feels wrong to the user | Record the implementation evidence and hand off to user QA | Treat any requested tuning as a separate user-directed pass; do not self-play or silently change balance |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1, authority and focused contracts.
- Next task: Task 1.1, record the bounded source-brief supersession and align the
  working specs.
- Last completed gate: Discovery Closure Gate.
- Current artifact state: active format-4 bundle `v8-ac0a370...`; Stage 30 is
  15.0% with seven shots; fixed-position Aim Lock clips upper terrain and hides
  the upper trajectory/glyph band.
- User-owned boundary: gameplay, balance, feel, and aesthetic QA begins only
  after the implementation handoff. Agent evidence is limited to code,
  artifact, build/start, and bounded background render checks.
- Update rule: after a task passes its acceptance, record concise evidence,
  check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and phase gate passes.
- The active catalog is one validated version-9 format-4 bundle containing all
  30 stages, and its fast recheck proves the locked opportunity margin.
- Stage 30 is 12.5%/seven shots with unchanged projectile/paint scale and
  unchanged mechanism counts/effects.
- The production build demonstrates fixed-position base/upper/return Aim View
  states without input cross-talk or UI obstruction.
- Current-truth docs distinguish structural opportunity from runtime coverage,
  physical certification, and user QA.
- No placeholder or unresolved material decision remains, and frontmatter is
  changed to `done` only after implementation completes.

Replan when:

- A material discovery invalidates the locked camera envelope, target curve,
  opportunity formula, ownership, or versioning contract.
- Candidate indices 0-31 exhaust after the authorized target-aware placement.
- Completion requires new ammo, paint scale, mechanism kinds, FOV, camera
  translation, dependency, asset, persisted budget schema, or exhaustive
  physical solution search.

Do not replan or stop for:

- Implementation-local math, state storage, deterministic search, or test
  fixture mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
