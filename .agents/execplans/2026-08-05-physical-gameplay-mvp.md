---
type: plan
status: active
created: 2026-08-05
last_reviewed: 2026-08-05
scope: visible closed mountain gameplay, first-hit aiming, real projectile contact, continuous authoritative paint, and fire/camera responsiveness
source: source brief plus user corrections through 2026-08-05 and the runtime-grounded screen review
supersedes: 2026-08-04-rapid-fire-progression-redesign.md
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
  - ../../docs/concepts/runtime-grounded-ui-2026-08-05/README.md
  - 2026-08-05-rapid-fire-thirty-stage-progression.md
  - 2026-08-05-runtime-grounded-interface.md
---

# Physical Gameplay Foundation - Execution Contract

The first deliverable is one visibly credible, closed, collidable mountain board
on which the real ball lands, rolls, and paints the exact scoreable surface it
physically traverses without blocking the desktop or stuttering. This plan is
the first of three separately scoped plans requested by the user. The other two
may be read for downstream context, but they must not be executed until this
plan reaches its user review gate.

## Purpose

- Objective: prove the game's physical and visual core before expanding content
  or restyling every screen.
- Deliverable: a production-style Stage 01 gameplay slice with a substantial
  mountain-range target, real first-hit trajectory, low-rebound rigid ball,
  continuous mask-backed paint, truthful coverage, and responsive camera/fire.
- Completion state: focused contracts and off-screen running-build evidence
  prove the slice, and the user accepts that evidence as the foundation for the
  thirty-stage plan.
- Implementation does not begin merely because this document exists. The first
  unchecked task is the only authorized starting point when the user asks to
  execute this plan.

## Authority and Execution Order

1. `docs/source-brief.md`, including its 2026-08-03 and 2026-08-04
   supersessions, is the product authority.
2. The user's later corrections require a closed 3D target mass, physical ball
   contact, paint across every traversed target-top interval, a rear wall that
   contains the current board, immediate repeat fire in the final product, and
   visible gameplay before fine optimization.
3. The approved direction in
   `docs/concepts/runtime-grounded-ui-2026-08-05/proposed/03-aiming-grounded.png`
   and `04-observation-grounded.png` is visual-composition evidence only. It
   cannot override collision, paint, target, or generated-stage truth.
4. Current code is the starting implementation, not proof that the visible MVP
   is acceptable. `.agents/Documentation.md` must remain truthful throughout.
5. After this plan passes its objective gates, stop and present actual captures.
   Do not begin the thirty-stage plan until the user approves that checkpoint.
6. This is a deliberately bounded implementation slice, not a final release
   contract. It does not modify the current serial admission defect while
   isolating terrain/contact/paint work. That defect remains source-noncompliant
   and blocking at every checkpoint, is never accepted or waived, and is owned
   by the immediately following plan. The physical evidence scenarios use one
   root only and make no claim about Fire admission.

## Scope and Boundaries

In scope:

- Stage 01 mountain mass, silhouette, lighting, materials, wall/apron join, and
  cannon-relative framing.
- Shared top topology, closed render/collision shell, target identity, surface
  queries, trajectory collision, and paint addressing.
- Default aim and full scoreable-target reachability under the legal yaw,
  elevation, and power domain.
- Ball/collider/preview scale, bounce, friction, damping, settlement, contact,
  continuous paint, first-impact paint, and coverage publication.
- Fire, camera-follow, and paint-publication work that causes visible stalls.
- Focused headless checks, production export, off-screen Compatibility-renderer
  captures, responsiveness telemetry, and one explicit user review gate.

Out of scope:

- Implementing concurrent root shots, shot-family attribution, Fast Progress,
  schema version changes, thirty-stage generation, all-open progression, and
  multiple mechanism slots. Those belong to the second plan. Their absence
  remains a known blocking defect during this partial milestone; the physical
  checkpoint explicitly excludes and does not approve those behaviors.
- Final menu, stage-select, briefing, HUD, pause, settings, and result styling.
  Those belong to the third plan; this plan may only preserve working UI around
  the physical slice.
- New dependencies, plugins, external assets, renderers, physics engines,
  terrain representations, fluid simulation, caves, tunnels, overhangs, hollow
  terrain, destructible terrain, or steering after launch.
- Broad historical test matrices, performance work unrelated to visible Fire,
  camera, contact, or paint stalls, and foreground Godot/editor automation.

## Discovery Closure

| Concern | Verified starting fact | Locked response | Recheck boundary |
| --- | --- | --- | --- |
| Closed 3D mass | `RouteGraphMountainSynthesizer` emits a row-solid connected footprint and `TerrainGeometryFactory` emits top, skirt, and bottom geometry | Keep this representation; correct its visible profile and joins rather than replacing it | Recheck after terrain owners change |
| One surface authority | `TerrainTopTopology` supplies the indexed top triangles used by render collision, query, target, and paint reconstruction | Every consumer continues to receive the same topology and stable terrain identity | Recheck after topology/collision changes |
| Current visual failure | Running captures show an oversized empty apron, weak depth separation, and a central slab/void reading despite structurally closed geometry | Reframe and rematerial the real mass; no hidden collider or decorative fake mountain may substitute for it | Recheck every Stage 01 actual capture |
| Contact and paint | `PaintProjectile` emits first-impact and same-top contact sweeps; `PaintSystem` is the sole mask/coverage owner | Preserve measured contact, make every valid traversed interval visible, and reject shell/wall/apron paint | Recheck after projectile/paint changes |
| Scale mismatch | The current ball radius is 0.52 m while continuous/impact/settle radii are 4.0/6.0/4.0 m | Apply the exact physical/paint tuning table below | Recheck only if the user rejects actual scale evidence |
| Aiming truth | `DefaultAimSolver` and `DirectReachabilityValidator` can solve a physical first target hit; the preview uses shared ballistics and collision | Certify every scoreable texel offline, restore a centroid-near default, and end the guide at the real first collision | Recheck after aim, terrain, or projectile changes |
| Containment | `BackstopEnvironment` and the generated `ContainmentSpec` own wall/apron collision | Rear wall fills the camera background, joins the mountain, and contains the current legal domain | Recheck after bounds or camera changes |
| Visible stutter | Direct paint drain is within budget; the measured hidden rendered drain/non-drain p95 delta is 4.457 ms, which is 0.457 ms over the existing 4.0 ms gate | Fix only confirmed hot-path work and retain the existing telemetry limits | Recheck after visible hot-path changes |
| Non-disruptive QA | `DeliveryCaptureRunner` already moves a Compatibility window to `(-32000,-32000)` and removes focus | Extend and use only this path; never open a normal visible Godot window | Every rendered verification run |

Readiness statement:

- No product, geometry, collision, paint, camera, tuning, dependency, test, or
  handoff decision is left to the executor.
- A small implementation defect may be resolved within these contracts. A fact
  that would require a new representation or a changed visible behavior invokes
  the replan rule rather than executor discretion.

## Locked Domain Contract

### 1. Terms and ownership

- **Target Top** is the immutable indexed heightfield surface eligible for ball
  traversal and paint. It has exactly one height per in-bounds XZ sample.
- **Shell** is the side and bottom closure beneath the Target Top. It makes the
  target a solid-looking 3D mass but is neither paintable nor scoreable.
- **Backstop** is the bright rear containment wall. **Apron** is the front floor
  between cannon and target. Both collide and neither paints nor scores.
- **Verified Target Contact** is a physics contact whose collider and shape
  resolve to the exact `TerrainSurface` top identity. Proximity, ray-only visual
  overlap, shell contact, or contact with a hidden plane is not target contact.
- **Traversed Paint Interval** is the continuous path between consecutive
  verified target contacts. `PaintSystem` alone rasterizes it and owns both the
  visible mask and coverage.
- `StageController` remains the sole stage/shot/result authority. This plan does
  not change its current admission model; that is a temporary test-slice
  limitation, not approval of serial firing and not a second state machine.

### 2. Mountain geometry and generation

- Preserve the heightfield-plus-closed-shell method. Render, concave collision,
  target mask, surface queries, default-aim queries, paint reconstruction, and
  downhill sampling consume one accepted `TerrainTopTopology` instance and one
  stable terrain identity.
- The Stage 01 footprint is one four-connected, row-solid mass that reaches the
  rear wall. It has no internal empty row span, detached island, tunnel, cave,
  overhang, stacked top, literal staircase riser, open skirt, or missing bottom.
- The range uses broad primary and secondary ridges, shelves, shallow valleys,
  and at least one readable pass. Local noise amplitude is exactly 0.50 m; it may
  facet a broad surface but may not create needle or saw-tooth peaks.
- Target-top absolute slope is at most 38 degrees for Stage 01. A vertex whose
  one-ring neighbors would exceed that limit is smoothed by the generator before
  topology is emitted; it is never repaired by hand-authored coordinates.
- A basin, if present in a later stage, is off-centre, at least 12 m across, and
  3.5-5.5% of nominal peak depth. Stage 01 contains no basin and its central
  range is never excavated into a crater.
- `TerrainGeometryFactory.DEFAULT_BASE_Y` remains `-28.0`. The top contour is
  closed down to that base with outward-facing skirts and a bottom cap. The rear
  top edge terminates inside the Backstop so no bright slit appears at the join.
- The current Stage 01 `72 x 48` cells, `180 x 120 m` bounds, 512 paint mask,
  fixed diagonal, 32-attempt budget, and seed stride 7,919 remain in this plan.
  Variable-size version 6 is deferred to the second plan.

### 3. World presentation and camera composition

- Use the Compatibility renderer, one WorldEnvironment, one shadowed directional
  key light, and the existing low-poly/faceted shader path. Do not add a post-
  processing dependency or a second decorative terrain mesh.
- Material roles are: Target Top `#EEF0F3`, Shell `#D6DBE2`, Backstop
  `#FAF7F1`, Apron `#E7E3DB`, navy hardware `#172538`, and paint `#2584FF`.
  Vertex/face shading may vary luminance by at most 12%, but hue roles do not
  drift. The Target Top, Shell, and Backstop must remain distinguishable.
- In the actual 1280x720 aiming render, the target projects across 68-92% of the
  viewport width and 50-76% of its height. The center-bottom Apron occupies at
  most 24% of viewport height. The cannon occupies at most 20% of viewport
  height and does not hide the central route.
- At least three depth layers are readable from the aiming camera: a front
  landing slope, a middle ridge/pass or shelf, and a rear crest. Their silhouette
  or value separation is at least 16 screen pixels; a single flat vertical slab
  cannot dominate the center.
- The Backstop covers the complete camera background beyond the range. It must
  read as an environmental wall, not an empty sky gap or a second 2D mountain.
- The aiming, briefing, wide, follow, and result cameras use perspective with an
  exact 48-degree FOV. Per-layout framing changes camera position/target, not the
  lens. Camera near/far planes include cannon, trajectory, target, and Backstop.
- FOLLOW interpolates rendered projectile transforms and camera motion. WIDE
  shows the whole containment board. CANNON returns to the exact aiming frame.
  Camera mode changes only transforms/tracked targets and never rebuild geometry,
  masks, materials, dressing, or UI.

### 4. Aim, collision, and containment

- Preserve the existing legal yaw, elevation, and power ranges. For every
  scoreable target texel, the offline validator must find at least one legal
  tuple whose sphere-cast first hit resolves to that exact Target Top. A stage
  with an unreachable scoreable texel is rejected.
- The default tuple hits the certified target texel closest to the target-mask
  centroid. Its impact marker lies in the central 40% of the mountain's screen
  projection unless geometry makes that impossible, in which case generation
  is rejected rather than the camera being distorted.
- Trajectory prediction uses the same 0.60 m sphere radius, launch origin,
  damping, gravity, fixed 60 Hz integration, collision layers, and first-hit
  identity as the real projectile. Dots extend to the first collision and the
  final ring is centered on that collision; post-impact motion is never shown.
- The projectile is a real `RigidBody3D` with CCD. Terrain, mechanisms,
  Backstop, and Apron collide through their visible shapes. No hidden catch
  plane or teleport may make a failed collision look successful.
- Legal domain proof includes every minimum/maximum yaw, elevation, and power
  corner plus the default aim. Current-stage shots terminate against terrain,
  wall, apron, or bounded lifetime and cannot pass beyond the rear visible board.

### 5. Ball, contact, paint, and settlement tuning

| Parameter | Locked value |
| --- | ---: |
| Visible and collision ball radius | 0.60 m |
| Continuous contact paint radius | 2.25 m |
| First-impact paint radius | 3.20 m |
| Settlement paint radius | 2.25 m |
| Physics bounce | 0.03 |
| Physics friction | 0.90 |
| Linear damp | 0.55 |
| Angular damp | 1.10 |
| Minimum movement speed | 1.70 m/s |
| Stop-duration threshold | 0.50 simulation seconds |
| Maximum lifetime | 12.0 simulation seconds |

- Ball mesh, collider, CCD sweep, predictor, contact classifier, and impact
  offset all consume the same 0.60 m radius. Visual scale cannot diverge from
  collision scale.
- On the first Verified Target Contact, submit one impact mark. During rolling
  or sliding contact, submit one surface sweep for every consecutive verified
  contact interval. A missing interval may be bridged only across at most two
  physics ticks and a chord no longer than 10 m; otherwise painting stops until
  contact is verified again.
- Airborne motion, Shell, Backstop, Apron, decorations, and non-target mechanism
  surfaces never write persistent paint. Mechanisms retain their own activation
  rules but cannot create a second coverage representation.
- Continuous/settlement paint diameter is 4.50 m against a 1.20 m ball diameter,
  a 3.75:1 ratio. The executor implements exactly 2.25 m. If the user later
  rejects that actual scale, a documented plan update may choose a replacement
  within 2.00-2.50 m; no tuning change is left to executor discretion. Impact
  radius, ball radius, and changes outside that interval require a replan.
- Coverage changes only when the authoritative mask first paints eligible Target
  Top pixels. Visible terrain paint uses that same mask; no delayed duplicate,
  trail decal, or presentation mesh may disagree with coverage.

### 6. Responsiveness contract

- Fixed physics remains 60 Hz and normal gameplay, responsiveness measurement,
  and every recorded motion/contact/paint evidence interval use
  `Engine.time_scale = 1.0`. Delivery setup code may accelerate or slow only
  non-recorded scene preparation, must restore 1.0 before the requested state,
  and cannot use altered-time frames as physical/performance evidence.
- Stage generation, topology, collision, target rasterization, dressing, and
  material setup finish before AIMING and do not run on Fire or camera motion.
- Paint commands drain deterministically at the existing physics priority.
  Texture publication is capped at 15 Hz, reuses the authoritative mask/image,
  and does not synchronously recreate texture/material resources per contact.
- Existing telemetry gates remain normative: dirty-aim Fire <= 2 ms, ready Fire
  <= 8 ms, paint-drain p95 <= 4 ms, paint-drain maximum <= 8 ms, rendered drain
  versus non-drain p95 delta <= 4 ms, and interpolated camera movement ratio >=
  0.95.
- A numerical gate passing does not substitute for visible continuity. The
  off-screen observation capture must show a continuous arc, contact, rolling
  motion, and paint trail without a frozen multi-frame jump.

## Tasks

### Phase 0: Establish the truthful Stage 01 baseline

Goal: make one repeatable evidence case before changing physical owners.

- [ ] **0.1 Record the implementation baseline**
  - Owners: `.agents/Documentation.md`, `.agents/evidence/physical-gameplay-mvp/`.
  - Change: record the current Stage 01 seed/profile/checksums, current projectile
    tuning, current camera bookmark, and existing responsiveness telemetry. Save
    current off-screen aiming and continuous-paint captures as `before-*`.
  - Accept: evidence comes from the running Compatibility renderer and current
    runtime owners; no mockup is labelled as runtime proof.
- [ ] **0.2 Lock the focused acceptance harness**
  - Owners: `src/delivery/delivery_capture_runner.gd`,
    `src/camera/terrain_camera_framer.gd`, and existing focused tests.
  - Change: add named `wide_mountain`, `aiming`, `first_target_contact`, and
    `continuous_paint` delivery states. Each state drives AppRoot/StageController
    actions and exits automatically from an off-screen, non-focusable window.
    Emit composition JSON from projected target/cannon/apron bounds and generated
    front/middle/rear route landmarks so the locked viewport percentages and
    16-pixel depth separation are repeatable rather than eyeballed.
  - Accept: every state is deterministic at 1280x720 and directly fails when the
    requested physical state, composition metric, or published paint cannot be
    reached. Recorded motion evidence always runs at time scale 1.0.

Phase gate: run `scripts/verify.ps1` once because capture code changed. Do not
run the broad historical test matrix.

### Phase 1: Make the target read as one closed mountain range

Goal: correct the visible world without creating a competing geometry owner.

- [ ] **1.1 Refine the Stage 01 range and solid footprint**
  - Owners: `src/stage_generation/route_graph_mountain_synthesizer.gd`,
    `route_graph_height_synthesizer.gd`, `footprint_height_blend.gd`,
    `resources/stage_generation/first_descent_profile.tres`.
  - Change: produce broad front/middle/rear depth, remove needle candidates,
    retain a row-solid footprint, and meet the Stage 01 slope/range contract.
  - Accept: `mountain_range_mvp_test.gd` area/scans every emitted Stage 01 top
    triangle, proves the 38-degree absolute slope ceiling, one connected top,
    and a closed shell; actual wide/aiming metrics satisfy the projection and
    depth-layer gates.
- [ ] **1.2 Correct the Backstop, Apron, shell join, and materials**
  - Owners: `src/terrain/terrain_geometry_factory.gd`,
    `backstop_environment.gd`, `apron_geometry_factory.gd`,
    `src/paint/terrain_paint.gdshader`, `src/gameplay/gameplay_scene.gd`,
    `scenes/gameplay/backstop_environment.tscn`, and
    `scenes/gameplay/cannon.tscn`.
  - Change: use the locked material roles, hide no gap with a fake plane, bring
    the target naturally into the apron, and make the rear join continuous.
  - Accept: no hole, bright slit, giant central support slab, or ambiguous 2D
    silhouette is visible; collision and render geometry still share owners.
- [ ] **1.3 Reframe aiming, WIDE, FOLLOW, and CANNON**
  - Owners: `src/camera/terrain_camera_framer.gd`,
    `src/camera/camera_director.gd`, `scenes/gameplay/gameplay.tscn`, stage camera
    bookmarks, and delivery composition telemetry.
  - Change: derive transforms from accepted bounds and implement the locked
    composition; preserve interpolation and stable return-to-aim framing.
  - Accept: the four modes never clip the board, hide the ball behind the HUD,
    rebuild world resources, or violate the viewport occupancy gates.

Phase gate: update and run `mountain_range_mvp_test.gd`,
`containment_geometry_test.gd`, and `phase8_aiming_composition_test.gd`, then run
`scripts/verify.ps1` once.

### Phase 2: Prove first-hit aiming and real physical contact

Goal: make the preview, collider, and first hit describe the same event.

- [ ] **2.1 Certify the target and default aim**
  - Owners: `src/stage_generation/direct_reachability_validator.gd`,
    `direct_reachability_certificate.gd`, `default_aim_solver.gd`, Stage 01
    generated layout/resource.
  - Change: certify every eligible target texel under the legal aim domain and
    persist the centroid-near default tuple/checksum.
  - Accept: restart restores the same tuple, predictor first-hit identity equals
    the real first contact, and no unreachable scoreable pixel is admitted.
- [ ] **2.2 Align predictor, projectile, and containment collision**
  - Owners: `src/cannon/trajectory_predictor.gd`, `trajectory_preview.gd`,
    `src/projectile/projectile_data.gd`, `paint_projectile.gd`,
    `resources/projectiles/basic_paintball.tres`, terrain collision owners.
  - Change: apply the 0.60 m shared radius, tuning table, CCD, and exact contact
    identity; keep the preview through the first collision.
  - Accept: `containment_domain_test.gd` explicitly covers all eight
    min/max-yaw/elevation/power corners plus the default tuple; those shots
    collide visibly with the same object/shape predicted, do not penetrate the
    target, and remain contained.

Phase gate: update and run `default_aim_handoff_test.gd`,
`target_reachability_test.gd`, `projectile_contact_test.gd`, and
`containment_domain_test.gd`, then run `scripts/verify.ps1` once.

### Phase 3: Make every traversed target interval paint truthfully

Goal: align ball scale, paint width, visible paint, and coverage.

- [ ] **3.1 Apply contact, paint, and settlement tuning**
  - Owners: `resources/projectiles/basic_paintball.tres`,
    `src/projectile/paint_projectile.gd`, `src/paint/paint_surface_tuning.gd`.
  - Change: apply the locked radii, friction, damping, movement threshold,
    settlement threshold, and lifetime without changing authority.
  - Accept: the ball lands with low rebound, rolls/slides instead of pinballing,
    settles within the bound, and the visible footprint is moderate.
- [ ] **3.2 Preserve continuous verified-contact sweeps**
  - Owners: `src/projectile/paint_projectile.gd`,
    `surface_contact_gap_validator.gd`, `src/paint/radial_paint_mark.gd`,
    `surface_paint_sweep.gd`, `paint_system.gd`.
  - Change: submit and drain the exact impact/sweep/settle commands described in
    the contract; eliminate any lost same-top interval or off-target write.
  - Accept: the ball's complete verified route paints without visual gaps;
    coverage and mask checksum change together; shell/wall/apron contact does not.
- [ ] **3.3 Keep shader publication identical to score authority**
  - Owners: `src/paint/paint_system.gd`, `terrain_paint.gdshader`,
    `src/terrain/terrain_surface.gd`.
  - Change: publish the sole runtime mask at bounded cadence and improve only
    mask-derived thickness/roughness/edge presentation.
  - Accept: no second persistent decal or coverage map exists and a captured
    painted pixel corresponds to the authoritative mask address.

Phase gate: update and run `phase3_projectile_paint_test.gd`,
`projectile_settling_test.gd`, `paint_queue_determinism_test.gd`, and
`target_mask_test.gd`, then run `scripts/verify.ps1` once.

### Phase 4: Remove visible Fire, paint, and follow-camera stalls

Goal: make the proven slice visually continuous before content expansion.

- [ ] **4.1 Measure before changing hot paths**
  - Owners: `src/delivery/delivery_capture_runner.gd` and
    `.agents/evidence/physical-gameplay-mvp/responsiveness-before.json`.
  - Change: run the bounded off-screen responsiveness probe and identify only
    threshold failures with frame/paint/camera attribution.
  - Accept: evidence names the failing owner; no speculative rewrite begins.
- [ ] **4.2 Remove confirmed synchronous or repeated work**
  - Owners: only the owner identified by 4.1, normally `PaintSystem`,
    `CameraDirector`, `GameplayScene`, or `AppRoot`.
  - Change: reuse buffers/resources, batch mask publication, and keep camera work
    transform-only while preserving fixed-tick command ordering.
  - Accept: every numerical responsiveness gate passes and actual contact/paint
    captures show no frozen jump. Physics and paint truth remain unchanged.

Phase gate: run `phase8_performance_test.gd`, the off-screen responsiveness
probe, and `scripts/verify.ps1` once.

### Phase 5: Audit, export, capture, and stop for user review

Goal: hand off proof of the core instead of continuing on assumptions.

- [ ] **5.1 Run the task-scoped quality audit**
  - Change: use `codebase-quality-auditor` read-only on the completed multi-file
    implementation and save its task-scoped findings.
  - Accept: the audit explicitly covers StageController, PaintSystem, topology,
    Resource, camera, terrain, and delivery boundaries.
- [ ] **5.2 Correct blocking audit findings**
  - Change: correct only task-owned competing owners, catch-all growth, stale
    geometry, duplicate paint authority, or broken public contracts identified
    by 5.1; record each disposition.
  - Accept: every blocking finding is fixed or causes a replan; the audit and fix
    evidence remain separate.
- [ ] **5.3 Build and capture the actual slice**
  - Change: run the production export once, then capture `wide_mountain`,
    `aiming`, `first_target_contact`, and `continuous_paint` at 1280x720 through
    the exported off-screen path. Pair them with the current baseline and the
    corresponding direction images in an evidence README.
  - Accept: all locked physical, composition, paint, and responsiveness gates
    are visible or linked to exact telemetry. No concept image is called a build
    screenshot.
- [ ] **5.4 Update status and request the checkpoint decision**
  - Owners: this plan, `.agents/Documentation.md`, `docs/test-checklist.md`.
  - Change: record commands, commits, capture paths, checksums, and any bounded
    remaining issue. Present the evidence to the user and stop.
  - Accept: after objective checks pass, mark this implementation plan `done`,
    present the evidence, and stop. Downstream execution still requires a
    separate explicit user approval. If the user rejects the foundation, reopen
    or supersede this plan before any downstream work.

## Validation and Rework Controls

Set the verified engine path once per shell:

```powershell
$env:PAINT_MOUNTAIN_GODOT = (Resolve-Path 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe').Path
```

Use these exact command forms:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $env:PAINT_MOUNTAIN_GODOT
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/mountain_range_mvp_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
```

| Cadence | Check | Run when | Rerun condition |
| --- | --- | --- | --- |
| Phase smoke | `scripts/verify.ps1` | Once after a phase changes scripts/scenes/resources/settings | A relevant input changes |
| Focused contract | Only tests named in that phase | After the owned functional slice is complete | Its owner or expected contract changes |
| Responsiveness | Delivery responsiveness JSON | Once before and once after confirmed hot-path work | Fire/camera/paint hot path changes |
| Export | Windows Desktop release export | Once after all focused gates pass | A production input changes |
| Rendered proof | Exported executable with `--capture-background` | Once per named state after export | A visible owner or capture scenario changes |

Rules:

- Do not run `scripts/test.ps1` or the historical broad matrix in this plan.
- Do not launch a normal foreground editor or game window. The user performs any
  later foreground play check through the existing fastrun command.
- Run the narrowest failing check, change the relevant owner, and rerun only
  after that input changes. A previously passing check is not repeated for
  reassurance.
- When a checkbox passes, append concise evidence and advance the progress
  pointer in the same edit. On resume, start at the first unchecked task.

## Predetermined Contingencies

| Trigger | Required response | Forbidden shortcut |
| --- | --- | --- |
| The current representation cannot meet a locked geometry gate | Stop, record the exact contradiction, and replan with the user | Add a hidden collider, second decorative mountain, or authored repair mesh |
| Full target reachability fails | Reject the generated layout and adjust route/target generation inside locked slope/size bounds | Mark unreachable pixels non-scoreable after generation or weaken the requirement silently |
| Ball tunnels or predictor disagrees | Correct shared radius/integration/collision identity and rerun the focused contact case | Teleport, catch plane, widened paint, or visual-only marker correction |
| Continuous paint gaps persist | Fix verified contact interval ownership; the first fallback is no more than the locked two-tick/10 m bridge | Paint from airborne proximity or enlarge the brush beyond the allowed range |
| Rendered p95 delta remains over 4 ms | Reuse/batch resources in the confirmed owner; if correctness would change, stop and replan | Lower physics below 60 Hz, disable contact paint, or hide the stall with a cut |
| A visual gate conflicts with physical truth | Physical truth wins; record the concept deviation and show it to the user | Fabricate terrain, paint, trajectory, or result state to match a mockup |

## Progress and Next Steps

- Canonical progress: the checkboxes in this file.
- Current phase: Phase 0.
- Next task: 0.1 Record the implementation baseline.
- Last completed gate: discovery and decision closure on 2026-08-05.
- Downstream gate: do not start
  `2026-08-05-rapid-fire-thirty-stage-progression.md` until task 5.4 passes and
  the user explicitly approves the physical evidence.

## Completion and Stop Conditions

Complete when every task and phase gate passes, actual exported-build evidence
exists, the physical slice matches the locked visible/behavioral contract, and
status records are truthful. Completion does not authorize the next plan; the
separate user checkpoint does.

Replan when a verified fact requires a different representation, ownership,
product behavior, dependency, or acceptance contract. Do not replan for a local
defect already covered by this document, a passing unchanged check, or a small
faceting difference inside the locked geometry and composition ranges.
