---
type: plan
status: active
created: 2026-08-07
last_reviewed: 2026-08-07
scope: cannon-side wind flag, physical cannon standoff, Aim View composition, automatic Shot Follow, bounded structural performance work, and obsolete recovery cleanup
source: user feedback on 2026-08-07 and docs/source-brief.md
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
  - ../../docs/handoffs/aim-performance-and-product-direction-2026-08-07/README.md
  - 2026-08-07-target-coverage-and-safe-aim-framing.md
---

# Cannon Standoff and Shot Observation - Execution Contract

Paint Mountain will frame a large, readable cannon in the foreground against a
complete distant mountain, replace unclear wind debris with a cannon-side flag,
and automatically follow each newly fired root paintball until its first terrain
impact. The player can return to the cannon view at any time without changing
the projectile. The same implementation restores constant-work Fire admission
and removes verified redundant prediction, UI, camera, and trajectory-preview
work without a timing or profiling pass. It does not restore exhaustive
reachability or authored solution work.

## Purpose

- Objective: make distance, wind, launch, flight, and impact readable as one
  coherent physical sequence.
- Deliverable: a versioned stage placement update, shared Aim View composition,
  cannon-side wind flag, specific-projectile Shot Follow state, contextual return
  control, bounded miss cleanup, a main-thread demand-driven prediction owner,
  batched trajectory dots, focused contracts, production-build captures, and
  current documentation.
- Completion state: Stages 01 and 30 both show a substantial cannon and complete
  distant mountain; the cannon is at least 70 m from the nearest playable front;
  the flag agrees with the authoritative wind; Fire follows the new root ball;
  first terrain impact remains readable; button or Tab returns early while
  physics continues; Fire performs no trajectory query; inactive presentation
  performs no repeated prediction or marker work; no obsolete debris,
  solution-route runner, inactive catalog, or competing active task document
  remains.

## Scope and Boundaries

In scope:

- Keep the stationary cannon, manual yaw/elevation/power, existing left-drag and
  wheel controls, and no post-fire steering.
- Keep deliberate terrain orbit/zoom in Map View. Rename player-facing `Aim
  Lock` to `조준` / `Aim View` and `Map Inspection` to `지도 보기` / `Map View`;
  internal enum names may remain until a schema-neutral rename is convenient.
- Replace `WindDebrisField` with one non-colliding cannon-side flag or streamer
  driven by the existing `WindController` snapshot.
- Derive each stage's cannon placement so the cannon origin is at least 70 m in
  front of the nearest playable terrain edge, then promote one coherent version-9
  catalog with new bounded default/summit witnesses.
- Use one shared Aim View composition with the cannon at roughly 20–30% of
  viewport height and the complete mountain at distant scale. Preserve the
  48-degree gameplay FOV and reject manual per-stage camera repairs.
- Follow the exact generation-0 root returned by an accepted Fire action. Hold
  its first terrain impact for 0.8 seconds, return automatically, and expose one
  visible return-to-cannon action plus context-sensitive Tab.
- Set the never-contacted miss timeout to 6.0 seconds. Treat a representative
  default flight near three seconds as visual pacing guidance only, not a
  legal-shot gate, solver objective, or exact duration assertion.
- Restore constant-work Fire admission: Fire reads one immutable ready prediction
  context and never invokes `TrajectoryPredictor` from the input/action call
  stack. Coalesce aim and wind invalidation in one main-thread scheduler.
- Separate the 60 Hz authoritative wind snapshot from the lower-frequency
  trajectory-prediction epoch and from HUD text refreshes. Suspend trajectory
  prediction when the preview and Fire are unavailable, then publish one current
  prediction before Fire becomes available again.
- Cache Aim View interest data and the composed pose by immutable stage/layout,
  cannon transform, FOV, and viewport aspect inputs. A mode toggle must not scan
  terrain topology.
- Replace 96 individual trajectory-dot `MeshInstance3D` nodes with one
  `MultiMeshInstance3D`, while retaining the separate impact/exit markers and
  existing sample-count contract.
- Remove the unused `StageData.reliable_solution` field and its serialized values
  as part of the version-9 catalog migration.
- Update focused tests, delivery capture states, implemented-truth records, and
  lifecycle metadata.

Out of scope:

- Performance instrumentation, input-latency measurement, FPS profiling, timing
  probes, or a numerical performance claim. Only the named structural reductions
  above are authorized.
- Worker-thread access to `PhysicsDirectSpaceState3D`, a RenderingServer/PhysicsServer
  rewrite, projectile pooling, broad node-process cleanup, new terrain LOD or
  occlusion systems, and baked stage-select preview schema work.
- A new Aim View orbit/pan gesture, Fire from Map View, click-to-target aim,
  inverse aiming, post-fire steering, cinematic replay editing, camera speed
  controls, or multiple observation presets.
- Exhaustive target-texel first-hit certificates, authored success routes,
  solver clears, all-stage playthroughs, or a new solution database.
- Changes to PaintSystem authority, score meaning, target masks, mechanism rules,
  stage timer/result rules, save progression, online services, dependencies,
  plugins, asset packs, or renderer choice.
- A fixed exactly-three-second flight rule. Legal shots are not rejected because
  their elapsed flight differs from the representative pacing target.

Constraints and invariants:

- `StageController` remains the only Board Phase, shot admission, timer, Finish,
  and result owner. Shot Follow is presentation while Board Phase remains
  `AIMING`.
- `CameraDirector` remains the only camera-transform owner. HUD and input code
  emit intents; they do not calculate a camera pose.
- `ProjectileManager.shot_family_started(shot_id, root_projectile)` is the narrow
  source of the newly launched root identity. Shot Follow never discovers its
  target by averaging `active_projectiles()`.
- `WindController` remains the sole wind schedule. The flag displays
  `WindSnapshot.push_direction()` and `normalized_strength`; it never calculates
  wind or applies force.
- `PaintSystem` remains the sole paint/coverage authority, and returning the
  camera never terminates or mutates a projectile.
- The active v8 catalog remains loadable until the complete v9 bundle passes its
  atomic promotion checks. Only then may v8 be removed as recoverable Git history.
- The pre-existing local edits in `src/cannon/trajectory_predictor.gd` and
  `tests/target_mask_test.gd` are not task-owned and must not be staged, reverted,
  or reformatted by this plan.
- Prediction scheduling may reduce calls into `TrajectoryPredictor`, but it must
  not edit or bypass the preserved endpoint-rest collision-parity logic. Direct
  physics-space queries remain on the main thread under the current project
  settings.

Destructive or irreversible actions:

- Removing inactive generated bundles and obsolete tests/scripts is authorized
  by the user's cleanup request and recoverable from Git history.
- Do not delete the active v8 bundle until `resources/stages/catalog.tres` points
  to a fully validated v9 bundle and the production-style start passes.
- Do not delete optional certificate compatibility classes during this plan.
  Current replay/agent/layout schemas still reference them even though exhaustive
  certificate generation is retired.

## Domain Alignment

| Term | Exact meaning | Owner |
| --- | --- | --- |
| Aim View (`조준`) | The authored perspective composition where cannon yaw/elevation/power are editable | `CameraDirector` presentation plus `AimInputController` mapping |
| Map View (`지도 보기`) | The deliberate terrain inspection mode with orbit, zoom, and refocus; aim and Fire are blocked | `CameraDirector` and `AimInputController` |
| Shot Follow (`탄환 추적`) | Temporary presentation that tracks the one newly accepted generation-0 root through first terrain contact | `CameraDirector` |
| Return to Cannon (`대포로 돌아가기`) | Camera-only intent that exits Shot Follow and restores Aim View; simulation and aim persist | HUD/input intent consumed by `CameraDirector` |
| Cannon Standoff | World-space distance from cannon origin to the nearest playable terrain front; minimum 70 m | stage progression/catalog materialization |
| Wind Flag | Non-colliding physical-looking presentation beside the cannon; free end points in projectile push direction | `CannonWindFlag` consuming `WindController` |
| Prediction Context Key | Canonical aim key + wind schedule identity + bounded launch epoch used to decide whether one immutable prediction is ready | `TrajectoryPredictionScheduler` |
| Constant-work Fire | Fire checks the current prediction context and capacity, then accepts or reports pending; it never computes a trajectory | `StageController` admission using scheduler-published cannon state |
| Wind Display Key | The exact rounded direction/strength/countdown/forecast values visible in the HUD; unchanged keys do not rewrite Control text | `RunStatusCard` presentation |
| Bounded Entry Witness | Existing offline default or summit first-hit proof used to keep a generated stage playable | catalog builder; not player auto-aim and not exhaustive certification |
| Reachability/Solver Work | Retired exhaustive target enumeration or authored success-route search | no current owner; obsolete runners removed |

“Follow the cannon” in the user's wording means follow the fired paintball, not
move a camera with the stationary cannon body.

## Verified Current Evidence

| Concern | Current behavior | Evidence | Consequence |
| --- | --- | --- | --- |
| Later terrain approaches the cannon | Stage 01 terrain front is about 57 m from the fixed cannon; Stage 30 is about 17 m because the builder fixes the rear wall and grows terrain forward | `scripts/build_stage_catalog.gd:440-449`; `resources/stages/catalog.tres:3181-3200` | Derive cannon Z after profile bounds are known; do not use one transform for all stages |
| Cannon becomes tiny | the safe framer includes all playable-top points, cannon, and muzzle, then backs away at unchanged FOV | `src/camera/camera_director.gd:348-374`; `src/camera/terrain_camera_framer.gd` | Replace fit-only composition with a shared foreground-cannon composition and validate Stage 01/30 renders |
| Aim Lock meaning | left drag changes yaw/elevation, wheel changes power; Map Inspection owns orbit/zoom/refocus | `src/input/aim_input_controller.gd:76-148`; `src/camera/camera_director.gd:18-21,466-485` | Preserve gestures; change player terminology and default composition, not the whole input model |
| Follow exists but is inactive | legacy `Mode.FOLLOW` averages every active projectile and normal gameplay never selects it | `src/camera/camera_director.gd:7-16,94-99,488-538`; `src/gameplay/gameplay_scene.gd` | Reuse only safe transition/smoothing pieces; replace target selection with one root reference |
| Root identity already exists | manager emits the exact root when a family starts | `src/projectile/projectile_manager.gd:4-20,75-134` | Wire the existing signal to `CameraDirector.follow_root()`; add no duplicate shot registry |
| Impact facts already exist | manager emits typed projectile/contact and valid-top traversal signals | `src/projectile/projectile_manager.gd:5-10,277-349` | Filter events for the followed root and TerrainSurface; do not infer impact from distance or velocity |
| Wind debris is unclear | 36–60 procedural boxes move over terrain and are wired directly from GameplayScene | `src/wind/wind_debris_field.gd`; `src/gameplay/gameplay_scene.gd:24,197-204`; `tests/wind_debris_field_test.gd` | Delete this presentation and replace its focused contract with the flag |
| Prediction is continuously invalidated | `WindController` publishes every 60 Hz physics tick, each snapshot dirties prediction, and GameplayScene can run the 720-step predictor at 20 Hz even without aim input | `src/wind/wind_controller.gd:72-78`; `src/gameplay/gameplay_scene.gd:147-153,381-398`; `src/cannon/trajectory_predictor.gd:4-5,65-123` | Separate authoritative snapshots, HUD display keys, and bounded prediction epochs; suspend the scheduler when prediction is not consumable |
| Fire performs heavy work | every Fire request calls `refresh_prediction_for_fire()` before reading readiness, which invokes the full predictor in the action call stack and conflicts with the existing constant-work focused test | `src/stage/stage_controller.gd:317-328`; `src/cannon/cannon_controller.gd:73-80`; `tests/phase7_user_qa_contract_test.gd:124-153` | Remove the callback path; stale context is immediately `pending`, and only the scheduler publishes readiness |
| Wind HUD rewrites at physics cadence | every snapshot projects wind and rewrites direction, percentage, countdown, forecast, and tooltips although the visible rounded values often have not changed | `src/gameplay/gameplay_scene.gd:381-398`; `src/ui/hud/run_status_card.gd:81-94,144-167` | Store the latest snapshot but refresh Controls only when the pure Wind Display Key changes |
| Aim mode toggles can rescan topology | `_safe_aiming_bookmark()` duplicates playable-top points, rescans maxima/summits, and recomposes the pose whenever the bookmark is requested | `src/camera/camera_director.gd:310-400`; `src/stage_generation/generated_stage_layout.gd:270-313` | Build immutable interest data and one keyed Aim pose per stage/view input set; toggles read the cached pose |
| Trajectory dots are separate render nodes | `TrajectoryPreview` creates 96 identical `MeshInstance3D` dots with one shared mesh/material | `src/cannon/trajectory_preview.gd:1-13,116-139` | Use one 96-instance MultiMesh and update transforms/visible count only when prediction changes |
| Direct physics queries cross callback boundaries | trajectory prediction runs from idle `_process`; render-camera correction and map click focus can call direct-space rays outside `_physics_process` | `src/gameplay/gameplay_scene.gd:147-153,310-328`; `src/camera/camera_director.gd:104-108,466-485,541-625` | Queue prediction/map-pick intents and resolve all direct-space queries in `_physics_process`; render processing consumes cached results only |
| Misses can linger | basic paintball timeout is 30 seconds before first valid-top contact | `resources/projectiles/basic_paintball.tres:15`; `src/projectile/paint_projectile.gd:158-168` | Reduce the typed resource value to 6 seconds; keep terrain-resident persistence unchanged |
| Old solution metadata remains | `StageData.reliable_solution` has no current code consumer but is serialized in legacy sources and v8 Stage 01 | `src/stage/stage_data.gd:29`; repository `reliable_solution` search | Remove it only with v9 promotion so the active content-addressed v8 bundle is not edited in place |

## External Design References and Applied Lessons

| Reference | Relevant observed pattern | Paint Mountain decision |
| --- | --- | --- |
| [Worms 3D manual](https://oldgamesdownload.com/wp-content/uploads/Worms_3D_Manual_Win_EN.pdf) | Default third-person presentation follows weapon projectiles/explosions and provides a way back to the normal view | Fire enters Shot Follow automatically; return is one action, not a permanent camera rail |
| [Total War: Warhammer III hotkeys](https://news.xbox.com/en-us/2022/02/16/total-war-warhammer-3-hot-keys-revealed/) | Unit Camera follows artillery fire and Escape exits that viewing context | Keep the observation state explicitly escapable; use the existing camera key, Tab, while Escape remains pause |
| [Angry Birds design interview](https://www.theguardian.com/artanddesign/2016/feb/23/how-we-made-angry-birds) | Predictable aiming helps players understand failure; target distance creates anticipation through flight time | Keep the real first-impact preview and use physical standoff for anticipation; do not add in-flight control or an exact timer gate |
| [Mario Golf manual](https://www.nintendo.com/eu/media/downloads/games_8/emanuals/nintendo_8/Manual_Nintendo64_MarioGolf_EN.pdf) | Players inspect terrain/landing context and read wind before committing to a shot | Keep Map View separate and make the cannon-side wind flag readable before Fire |
| [Two Worlds II manual](https://steamcdn-a.akamaihd.net/steam/apps/7520/manuals/TWII_Manual_PC_English_V2c.pdf?t=1576500172) | A red streamer on the mast gives a physical wind-direction cue | Use one nearby streamer/flag whose free end shows projectile push direction; HUD numbers remain secondary |

These references supply interaction patterns, not visual assets, control copies,
or licensing inputs. No external game content enters the repository.

## External Performance References and Decisions

| Official Godot 4.7 guidance | Local application | Decision |
| --- | --- | --- |
| [General optimization tips](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html) distinguishes recurring per-frame work, intermittent stalls, and loading costs, and warns against broad unverified optimization | current source already identifies repeated 720-step prediction, synchronous Fire prediction, topology rescans, and 96 identical render nodes | Accept only structural reductions that remove a verified repeated call, allocation, query, or draw owner; make no FPS or latency claim without measurement |
| [Ray-casting](https://docs.godotengine.org/en/4.7/tutorials/physics/ray-casting.html) states that direct physics-space access is safe in `_physics_process`, not arbitrary input or render callbacks | prediction, map focus, and render-camera safety currently reach direct-space queries from `_process` or input | Move those queries to fixed physics callbacks and cache their immutable result for render/input consumers |
| [Node processing](https://docs.godotengine.org/en/4.7/classes/class_node.html) documents that `_process` runs every drawn frame and can be toggled with `set_process()` | preview marker work and a scheduler callback need not run while hidden or clean | Enable processing only while a named pending/visible responsibility exists; do not perform a repository-wide process-mode sweep |
| [MultiMesh](https://docs.godotengine.org/en/4.7/classes/class_multimesh.html) draws repeated meshes in one call and exposes `visible_instance_count` and `custom_aabb`, at the cost of all-or-none culling | 96 trajectory dots share one mesh/material, remain spatially coherent, and are shown/hidden as one path | Replace only the trajectory-dot set with one MultiMesh; keep markers and unrelated environment nodes unchanged |
| [Thread-safe APIs](https://docs.godotengine.org/en/4.7/tutorials/performance/thread_safe_apis.html) says the active scene tree and physics simulation are not thread-safe by default | this project does not enable separate-thread physics and predictor queries inspect the live world | Keep prediction on the main physics callback; reject a worker-thread predictor and a server rewrite |
| [Visibility ranges](https://docs.godotengine.org/en/4.7/tutorials/3d/visibility_ranges.html) targets large, complex 3D scenes and trades detail/popping against rendering work | current generated dressing is only roughly 10–32 low-poly decorations and the whole mountain must remain readable | Reject new LOD/occlusion scope until counts or later evidence justify it |

Rejected for this contract: predictor query/shape reuse because it overlaps the
preserved uncommitted `trajectory_predictor.gd` work; projectile pooling because
the authoritative resident lifecycle is complex and capped at 21; stage-select
preview baking because it changes the catalog schema without fixing the current
aim/flight flow; and generalized RenderingServer or PhysicsServer conversion
because the affected counts do not justify that ownership cost.

## Locked Decisions

1. Keep the current aim gestures. There is no new right-drag, middle-drag, or
   modifier-based camera gesture in Aim View.
2. Keep Tab as the camera-context key. In Aim/Map it toggles those modes; in Shot
   Follow it returns to Aim View. Escape remains pause and Space remains Fire
   only when aiming is available.
3. Enter Shot Follow only after a root spawn is accepted. Rejected Fire never
   changes camera state.
4. Track the exact root from `shot_family_started`; never average resident balls
   and never switch automatically to Splitter children.
5. First TerrainSurface top or skirt contact starts a 0.8-second impact hold.
   Backstop, escape, timeout, stage result, restart, invalid target deletion, or
   early return exits follow safely without changing gameplay outcomes.
6. During Shot Follow, hide aim controls and show one compact secondary
   return-to-cannon action. After return, the stored tuple and normal two-root
   capacity are immediately available.
7. The wind flag's free end points in `WindSnapshot.push_direction()`. Its
   orientation is always visible; normalized strength controls bend/flap
   amplitude. Reduced motion removes continuous flutter but keeps direction.
8. Use procedural primitives and shared project materials. Add no asset or
   dependency. The flag has no collision, shadow-heavy cloth simulation, paint,
   or gameplay authority.
9. Version 9 fixes cannon placement at a minimum 70 m standoff. Aim View keeps
   FOV 48 and one shared composition; the implementing agent may adjust shared
   camera constants only within the 20–30% cannon-height/full-mountain contract,
   never per stage.
10. Approximately three seconds is a feel reference observed in Shot Follow.
    Do not add a timer benchmark or flight-duration admission rule. Only the
    never-contacted miss timeout is exact at 6.0 seconds.
11. `StageController.request_fire()` is constant-work. It reads capacity and one
    scheduler-published immutable prediction context; it never calls a refresh
    callback, `TrajectoryPredictor`, or direct-space query. A mismatched context
    returns the existing visible `pending` state immediately for human, replay,
    and agent origins alike.
12. Add a main-thread `TrajectoryPredictionScheduler` beside the cannon code.
    Its latest-only key is canonical aim + wind schedule identity + wind launch
    epoch. A wind epoch remains stable only while every wind sample across
    `TrajectoryPredictor.MAXIMUM_STEPS` has exactly the same acceleration;
    otherwise it is `floor(elapsed_ticks / 3)`, matching the current 20 Hz
    coalescing cadence at the fixed 60 Hz physics rate. No approximate bucket is
    accepted without the named transition-boundary parity checks.
13. The scheduler performs direct-space prediction only from `_physics_process`,
    at most once for the newest dirty key per epoch. It is disabled while neither
    trajectory preview nor Fire readiness can consume a result. Return from Shot
    Follow marks the latest key pending and publishes one prediction before Fire
    becomes available; Fire itself never forces that work.
14. The authoritative 60 Hz wind snapshot still drives projectile physics and
    the flag. HUD Controls refresh only when the pure Wind Display Key changes:
    direction octant, depth cue, rounded strength percent, integer countdown,
    transition visibility, and rounded next-wind fields.
15. Aim composition caches exact interest points and the final pose by layout
    checksum, cannon transform, FOV, and viewport aspect. Stage/migration,
    viewport, FOV, or cannon-transform change invalidates it; Aim/Map toggles do
    not.
16. All direct-space camera safety and map-pick queries execute in
    `_physics_process`. Follow may run one exact-root safety query per physics
    tick while moving; render `_process` only interpolates the cached safe pose.
17. Trajectory dots use one `MultiMeshInstance3D` with 96 allocated instances,
    `visible_instance_count` equal to sampled dot count, and a refreshed
    `custom_aabb`. The preview and flag create no mesh/resource per frame and
    disable idle processing whenever no visible interpolation/facing work exists.

## Architecture and Data Ownership

| Change | Owner | Narrow interface | Must not absorb |
| --- | --- | --- | --- |
| Standoff formula | `StageProgressionData` plus `build_stage_catalog.gd` materialization | pure nearest-front/cannon transform calculation after profile bounds exist | camera pose, solver routes, runtime mutation |
| Accepted placement/resources | `StageData` and promoted v9 catalog | serialized cannon transform, camera bookmark, bounded witnesses | live camera state or duplicated terrain bounds |
| Aim composition | new responsibility-shaped `AimCameraComposer` beside `CameraDirector` | immutable exact top/summit points + cannon landmarks + FOV/aspect -> one cached pose | StageController state, trajectory solving, per-stage repair table, mode-toggle topology scans |
| Prediction scheduling | new `src/cannon/trajectory_prediction_scheduler.gd` | latest canonical aim/wind epoch -> one immutable prediction published to CannonController | Fire admission, worker threads, collision algorithm changes, HUD text |
| Wind presentation | `CannonWindFlag` under the cannon scene | `configure(WindController)` and settings signal | wind schedule, forces, HUD copy, per-frame mesh creation |
| Wind display de-duplication | `RunStatusCard` | pure display key derived from the latest snapshot and screen projection | wind schedule or prediction invalidation |
| Trajectory dot batching | `TrajectoryPreview` | one MultiMesh transform buffer, visible count, custom AABB | predictor ownership, impact/exit marker behavior |
| Follow target/state | `CameraDirector` | `follow_root(PaintProjectile)`, `return_to_aim()`, impact/terminal signal handlers, physics-cached safe pose | shot admission, projectile registry, result decisions, render-callback physics queries |
| Root publication | existing `ProjectileManager` | `shot_family_started(shot_id, root_projectile)` | camera transforms |
| Return UI | `HUDController` plus one reusable compact control | typed `return_to_cannon_requested` intent and visible/focus state | direct Camera3D access or projectile mutation |
| Flow wiring | `GameplayScene` | connect manager/HUD signals to CameraDirector once | duplicate camera or Board Phase state machine |
| Miss cleanup | `ProjectileData` resource | `never_contacted_timeout = 6.0` | terrain-resident lifetime changes |

## Tasks

- [x] **0.1 Clean abandoned recovery work**
  - Restored the stopped recovery audit, plan, certificate class, and validator
    edits to their committed baseline while preserving unrelated local predictor
    and target-mask work.
  - Removed five untracked v7 bundles, three inactive tracked v7/v8 bundles,
    orphan Stage 30 UID files, the authored-solution runner/test, both exhaustive
    certificate runners under `scripts/` and `tools/`, and the obsolete
    `scripts/test.ps1` solution-test entry.
  - Removed stale Markdown image claims for session-local recovery PNGs.
  - Remaining limitation: 27 untracked binary recovery/probe PNGs could not be
    removed through the available patch-only deletion path. They are not linked
    as current evidence and must remain untracked until a deletion-capable session
    removes the exact listed files.

- [x] **0.2 Close discovery and current authorities**
  - Updated the source brief, design spec, art/UIUX specs, architecture,
    checklist, implemented-truth record, and consumed handoff with the locked
    direction and no-measurement boundary.
  - Recorded current owners, exact failure mechanism, comparator lessons, terms,
    exclusions, and this one active execution contract.

- [ ] **1.0 Restore demand-driven prediction and constant-work Fire**
  - Add `src/cannon/trajectory_prediction_scheduler.gd` as one configured gameplay
    Node that owns the latest dirty context, the 3-tick/nonchanging-wind epoch,
    fixed-physics cadence, and publication into `CannonController`. Keep only the
    newest requested key; do not build a prediction history or worker.
  - Move live `PhysicsDirectSpaceState3D` prediction out of
    `GameplayScene._process()` and into the scheduler's `_physics_process()`.
    GameplayScene forwards aim changes, wind epoch changes, and whether preview
    or Fire can consume a result; it does not own cadence/key arithmetic.
  - Remove `CannonController.configure_prediction_refresh()`,
    `refresh_prediction_for_fire()`, and the call from
    `StageController.request_fire()`. Extend the published prediction metadata so
    readiness requires the current canonical context key. A stale key remains
    visible as `pending` and Fire returns immediately without a query.
  - Add a pure wind-epoch helper under `WindController`: return one stable
    keyframe epoch only if every sample through the 720-step prediction horizon
    has identical acceleration; otherwise return `elapsed_ticks / 3`. Do not
    allocate 720 WindSnapshots merely to build the key.
  - Add the pure Wind Display Key to `RunStatusCard`; retain the latest snapshot
    but skip label/tooltip reassignment when the displayed tuple is unchanged.
  - Create `tests/prediction_scheduler_test.gd`; extend
    `phase7_user_qa_contract_test.gd` and `wind_result_hud_test.gd`. Cover latest-
    key coalescing, stable-wind reuse, three-tick transition epochs, suspend/
    resume, stale pending, no Fire-side compute, and human/replay/agent parity.
    At transition start/middle/end, compare a bucketed prediction to an exact-tick
    prediction and require the same hit identity plus endpoint distance at most
    0.25 m.
  - Accept when prediction queries occur only in fixed physics processing, one
    unchanged stable context is reused, hidden Shot Follow does not recompute,
    and Fire never changes `prediction_compute_count()`.

- [ ] **1.1 Version the physical standoff contract**
  - Bump `StageGenerationContract.CONTRACT_VERSION` and progression resources to
    version 9. Add one pure progression/materialization helper that places the
    cannon origin at `nearest_playable_front_z + 70.0` using the finalized local
    bounds, preserving identity basis and cannon Y.
  - Update shared camera bookmark derivation relative to the accepted cannon and
    terrain; do not add 30 authored values.
  - Add focused Stage 01/30 and all-catalog structural assertions for minimum
    standoff, finite transforms, containment, distinct identities, and no
    per-stage repair branch.
  - Accept when every materialized stage has at least 70 m standoff before
    witness generation and the current v8 pointer is still unchanged.

- [ ] **1.2 Compose a near-cannon Aim View**
  - Replace the current fit-only fallback with a responsibility-shaped composer
    that uses exact playable-top points and cannon/muzzle landmarks. Keep 48 FOV
    and one shared set of constants; target a 25% cannon silhouette with an
    accepted 20–30% band and require the complete mountain/summit safe frame.
  - Build the interest-point set and final pose once per layout checksum, cannon
    transform, FOV, and viewport aspect. Invalidate only on one of those inputs;
    Aim/Map toggles consume the cached pose without calling
    `playable_top_world_points()` or `summit_region()` again.
  - Preserve CameraDirector safety/occlusion correction and Map View behavior.
    Remove the superseded suggestion for independent Aim View navigation. Queue
    Map View click/refocus screen coordinates and resolve their direct-space ray
    in `_physics_process`, never inside `_unhandled_input`.
  - Extend focused camera tests with Stage 01/30 projection assertions and a
    cache-invalidation contract plus a rendered-evidence state; numeric projection
    supports but does not replace runtime image review.
  - Accept when both endpoint stages meet the foreground/distance contract
    without FOV widening or per-stage data, a mode toggle performs no topology
    scan, and input/render callbacks perform no direct-space query.

- [ ] **1.3 Promote the version-9 catalog atomically**
  - Rebuild all 30 persisted stages using only the existing bounded default and
    summit witness path. Do not invoke exhaustive certificate or success-route
    workers.
  - Verify manifest, baked hydration, target/range admission, bounded witnesses,
    progression uniqueness, containment, and standoff. Point
    `resources/stages/catalog.tres` to the complete content-addressed v9 bundle.
  - Remove `StageData.reliable_solution` and its legacy serialized values. After
    the v9 pointer passes import/start, remove the replaced active v8 bundle and
    any now-empty obsolete catalog directories; Git remains the recovery path.
  - Accept when runtime loads every v9 ID through `StageLayoutRepository`, no
    solution-route field remains, and exactly one active generated bundle is
    referenced.

- [ ] **1.4 Batch and suspend trajectory-preview presentation**
  - Replace `_dots: Array[MeshInstance3D]` with one `MultiMeshInstance3D` backed
    by the existing shared dot mesh/material. Allocate 96 transforms once; on a
    new prediction update only the used transforms, set
    `visible_instance_count`, and refresh one conservative `custom_aabb`.
  - Keep impact/exit marker behavior and `visible_sample_count()` compatible.
    Disable `TrajectoryPreview._process()` while the preview is hidden, has no
    prediction, or has no camera-relative visible marker; enable it only for the
    marker scale/facing work that genuinely follows a moving camera.
  - Create `tests/trajectory_preview_efficiency_test.gd` covering one MultiMesh,
    maximum/partial/zero visible counts, endpoints, custom bounds, marker state,
    hidden processing, and absence of `TrajectoryDot*` child nodes.
  - Accept when the visible path is unchanged in the Stage 01/30 Aim captures,
    all dots use one draw owner, and hidden preview processing is disabled.

- [ ] **2.1 Replace wind debris with the cannon-side flag**
  - Add `CannonWindFlag` as a cannon-owned presentation component using a simple
    pole and triangular streamer/flag with shared project materials. Configure it
    from GameplayScene with the existing WindController.
  - Smoothly orient toward `push_direction`; map normalized strength to restrained
    bend/flutter. Reduced motion preserves static direction and disables repeated
    flutter. Build pole/cloth primitives and shared materials once; snapshot or
    interpolation updates change only transforms/material parameters. Disable
    idle processing while hidden, settled, or in reduced-motion static state.
  - Delete `WindDebrisField`, its gameplay scene node/wiring, and
    `wind_debris_field_test.gd`; add a focused flag contract for direction,
    strength ordering, transition, reduced motion, non-collision, and cleanup.
  - Accept when no debris owner/reference remains and flag/HUD/physics consume the
    same snapshot without duplicating wind calculations.

- [ ] **3.1 Implement specific-root Shot Follow**
  - Refactor legacy `Mode.FOLLOW` so CameraDirector stores one weak/reference-safe
    generation-0 root and never reads the active-projectile average. Add explicit
    substate for airborne follow, impact hold, and returning.
  - GameplayScene forwards `shot_family_started` to `follow_root`. CameraDirector
    filters manager contact/terminal signals for that root and TerrainSurface.
    It holds first top/skirt contact for 0.8 seconds and otherwise exits safely on
    early return, terminal event, restart, result, or target invalidation.
  - Preserve camera collision/occlusion safety and transition smoothing. A
    Splitter child never steals focus; a later accepted root replaces the prior
    follow target only after the player has returned and fired again.
  - Remove Follow reads of `ProjectileManager.active_projectiles()` and its copied
    array. Physics processing computes/caches exact-root focus and one safe pose;
    render processing interpolates that cache and performs no `intersect_ray`,
    `cast_motion`, or other direct-space query.
  - Accept when focused tests prove exact-root selection, impact hold,
    auto-return, terminal return, restart/result cleanup, two-family behavior,
    O(1) target access, and physics-only safety queries.

- [ ] **3.2 Add the contextual return path and copy**
  - Add one focusable edge control to the existing HUD component system with
    Korean `대포로 돌아가기` and English `RETURN TO CANNON`. It is visible only
    during Shot Follow and emits a typed intent.
  - Make Tab context-sensitive: Aim/Map toggle outside follow; return-to-cannon
    inside follow. Escape remains pause. Hide aim/power/Fire presentation during
    follow and make `AimInputController._can_adjust_aim()` reject that
    presentation mode so hidden mouse/keyboard input cannot steer or fire;
    restore exact stored values on return.
  - Update localization, hints/tooltips, replay presentation lock, delivery
    capture states, focus behavior, and 1280x720/1920x1080 layout contracts.
  - Accept when button and Tab take the same camera-only path, focus is visible,
    Korean/English fit, and no old Follow/Wide/Cannon rail returns.

- [ ] **4.1 Bound dead airtime without making flight a stopwatch puzzle**
  - Change `basic_paintball.tres` and the `ProjectileData` default to a 6.0-second
    never-contacted timeout. Do not change persistence after valid playable-top
    contact.
  - Review the generated default shot in the real Shot Follow flow for Stage 01
    and Stage 30. Tune only shared standoff/camera/launch presentation inputs if
    the flight reads as immediately adjacent or needlessly prolonged; do not add
    an exact flight-time assertion or target solver.
  - Add focused timeout regression for never-contacted versus terrain-resident
    balls and preserve replay/settlement reason contracts.
  - Accept when misses end promptly, valid-top balls persist, and the two reviewed
    default flights have a readable anticipation/impact beat near the user's
    approximate three-second reference.

- [ ] **5.1 Integrated quality pass**
  - Run `$codebase-quality-auditor` over the final task diff. Check StageController
    ownership, exact-root identity, CameraDirector size, stage-generation
    responsibility, PredictionScheduler ownership, physics-query callback safety,
    no second wind truth, HUD intent boundaries, MultiMesh bounds, schema removal,
    resource lifecycle, and reachable failure paths.
  - Make only safe task-scoped corrections. Accept when no competing state owner,
    catch-all gameplay file, Fire-side prediction, render/input direct-space query,
    dead debris/solution path, silent null-root follow, or v8/v9 pointer ambiguity
    remains.

- [ ] **5.2 One focused and production-style validation gate**
  - Before starting, tell the user this gate runs targeted functional scripts,
    one repository smoke check, one Windows release export, and seven background
    capture states; it does not run the full suite, a timing/FPS benchmark, an
    exhaustive solver, or a foreground window. Stop after the named artifacts are
    produced and reviewed unless a relevant failure requires one corrected rerun.
  - Run focused prediction scheduling, camera/query safety, trajectory batching,
    stage placement, wind flag/HUD, Shot Follow, timeout, and replay-presentation
    scripts directly with headless Godot. Run
    `scripts/verify.ps1` once and one release export.
  - Capture and inspect at native size: Stage 01 Aim View, Stage 30 Aim View,
    weak/crosswind flag, strong/crosswind flag, mid-flight root follow, terrain
    impact hold, and returned Aim View. Use the built executable and the existing
    background capture path.
  - Accept when commands exit zero with no script/runtime errors and the agent's
    visual review finds no clipping, hidden mountain, tiny cannon, ambiguous wind,
    lost projectile, obstructive return control, or steering implication.

- [ ] **5.3 Truthful closeout**
  - Record exact commands, v9 bundle identity, changed/removed files, capture
    paths, visual findings, and remaining user-owned feel approval in
    `.agents/Documentation.md`, `docs/test-checklist.md`, and a task evidence
    report. Mark this plan `done` only when every named gate passes.

## Acceptance Checks

- Stage 01 and Stage 30 report at least 70 m from cannon origin to the nearest
  playable front in accepted data.
- `StageController.request_fire()` never invokes prediction; a stale current key
  reports pending, while a ready matching key launches with no additional
  prediction compute. The three-tick transition epoch preserves hit identity and
  stays within the existing 0.25 m endpoint parity tolerance.
- An unchanged stable aim/wind context is reused; Shot Follow, pause, result, and
  hidden preview states do not run trajectory prediction. Wind physics/flag still
  receive 60 Hz snapshots while unchanged rounded HUD values are not rewritten.
- Direct physics-space prediction, map-pick, and camera-safety queries occur only
  in fixed physics callbacks. Render processing consumes cached prediction and
  safe-pose data.
- Their 1280x720 Aim View renders show the whole playable silhouette and summit,
  a roughly 20–30% foreground cannon, visible muzzle/trajectory/impact marker,
  and no HUD obstruction.
- Flag direction, HUD arrow, preview wind, and live projectile push agree for at
  least two deterministic wind snapshots; stronger wind produces visibly greater
  flag response without changing direction semantics.
- Accepted Fire follows the exact new root; rejected Fire does not change camera;
  first terrain contact is seen; impact hold returns automatically; early button
  and Tab return do not change projectile transform, velocity, lifetime, or aim.
- Two root families can coexist. A resident/older ball never pulls the camera
  away from the newly fired root, and Splitter children do not steal focus.
- Never-contacted root timeout is 6.0 seconds; valid-top contact still disables
  age-based deletion and preserves later wind wake/paint behavior.
- Aim/Map toggles reuse cached stage interest data and Aim pose. Trajectory dots
  have one MultiMesh draw owner with correct visible count/bounds, and the hidden
  preview/settled flag do not run idle presentation callbacks.
- `reliable_solution`, solution-search code, exhaustive-certificate runner,
  WindDebrisField, inactive generated catalogs, and stale active handoff claims
  are absent from the current implementation/documentation authority.
- No measured performance result, timing metric, exhaustive target certificate,
  solver clear, or all-stage playthrough is claimed as acceptance evidence.
  Acceptance claims only the named structural reductions and preserved behavior.

## Regression Guards

- Fire capacity remains two generation-0 root families; follow state is not a
  capacity or Board Phase.
- Prediction context remains one latest immutable value; no cache grows with
  elapsed wind ticks or aim history, and Fire never gains a second admission path.
- The 3-tick wind epoch is an explicit fixed-60-Hz contract guarded at transition
  boundaries; do not silently widen it or key only by broad HUD snapshots.
- Aim tuple, preview, paint mask, wind schedule, timer, result, replay action, and
  stage outcome authorities do not move into HUD, CameraDirector, or flag code.
- Map View retains safe orbit/zoom/refocus and blocks aim/Fire. Aim View retains
  existing drag/wheel/keyboard meanings.
- The 48-degree FOV, Compatibility renderer, typed GDScript, fixed 60 Hz physics,
  Korean-first copy, Theme ownership, and common desktop layout support remain.
- Catalog promotion is atomic; no partial v9 or runtime generation fallback is
  permitted.
- No production dependency, external asset, network service, plugin, Docker
  path, or hand-authored stage repair is added.

## Validation Commands

Use the configured Godot executable; do not invoke `scripts/test.ps1` because it
includes an unrelated performance test and a much broader suite.

```powershell
$paintMountainGodot = (Resolve-Path -LiteralPath $env:GODOT_BIN).Path

foreach ($testScript in @(
  'prediction_scheduler_test.gd',
  'phase7_user_qa_contract_test.gd',
  'stage_cannon_standoff_test.gd',
  'phase8_aiming_composition_test.gd',
  'trajectory_preview_efficiency_test.gd',
  'cannon_wind_flag_test.gd',
  'wind_result_hud_test.gd',
  'shot_follow_camera_test.gd',
  'phase7_ui_test.gd',
  'projectile_settling_test.gd',
  'replay_presentation_test.gd'
)) {
  & $paintMountainGodot --headless --path . --script "res://tests/$testScript"
  if ($LASTEXITCODE -ne 0) { throw "$testScript failed." }
}

& .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
if ($LASTEXITCODE -ne 0) { throw 'Windows release export failed.' }
```

The new focused scripts use the exact names above. If verified repository
ownership makes a different split necessary, revise this contract before adding
or invoking another command. The production capture command set is added after
`DeliveryCaptureRunner` owns the seven named states; it must use
`builds/windows/PaintMountain.exe -- --capture-background` and write only under
a task-specific `.agents/evidence/` directory.

## Predetermined Contingencies

| Trigger | Required response | Stop boundary |
| --- | --- | --- |
| The three-tick wind epoch changes hit identity or exceeds 0.25 m endpoint parity at a named transition fixture | Reduce only the changing-wind epoch to two ticks and rerun the same fixtures; if it still fails, use an exact one-tick changing-wind epoch while retaining stable constant-wind reuse and constant-work Fire | Do not restore synchronous Fire prediction, loosen collision parity, or approximate the authoritative live wind |
| A scheduler receives several aim/wind changes before its next physics callback | Replace its one pending key with the newest key and compute once; leave intermediate keys unpublished | Do not queue a history, start parallel physics queries, or publish a stale key |
| A new task appears to require editing the preserved dirty `trajectory_predictor.gd` | Stop that subtask and establish provenance of the existing diff before changing it | Do not overwrite, stage, or work around collision-parity code silently |
| MultiMesh trajectory dots cull incorrectly | Recompute one conservative `custom_aabb` from the displayed path plus dot radius and retain all-or-none path culling | Do not return to 96 independent draw nodes or disable culling globally |
| Stage 30 mountain does not fit while cannon remains 20–30% at 48 FOV | Increase the shared minimum standoff in 5 m steps, rebuild v9, and stop at the first shared value up to 90 m that passes Stage 01/30; keep one value for all stages | Do not widen FOV, shrink the cannon asset, or add per-stage camera data |
| A new standoff makes the bounded default or summit witness fail | Let the existing 32-candidate catalog search choose a valid persisted seed and bounded witness | Do not invoke target-wide certificate generation or authored solution search; stop and revise the product contract if no candidate passes |
| Representative default flight still feels prolonged | First adjust the shared generated default aim preference within the existing legal tuple and target-centroid neighborhood, then the shared launch-speed curve only if all bounded witnesses and preview/physics parity are regenerated | Do not add a flight-duration gate or per-stage speed |
| Follow root is freed before a contact event | Treat invalidation as a terminal presentation event and return safely to Aim View | Do not keep a dangling node reference or infer a fake impact |
| First contact is backstop rather than TerrainSurface | Return after the existing terminal feedback; do not apply the terrain-impact hold | Do not reclassify backstop as terrain or paint it |
| Flag cannot remain readable without crossing the muzzle path | Move the single shared pole anchor to the opposite cannon side and re-run both Aim View captures | Do not add a HUD-only replacement or per-stage anchor |
| Reduced motion makes direction unclear | Keep the streamer statically aligned and reduce only periodic flutter amplitude to zero | Do not hide the flag or wind rule |
| v9 promotion fails import/start | Keep v8 as the active pointer, retain the staged v9 bundle for diagnosis, and fix only the failing contract | Do not delete v8 or activate a partial bundle |
| A material fact contradicts an ownership or product decision above | Stop the affected implementation, update this contract and linked specs, and ask only if the correction changes user-visible scope, authority, dependency, or destructive risk | Do not silently choose a different camera, wind, solver, or timing design |

## Progress

- Completed: cleanup of abandoned text/catalog/runner artifacts; current-state
  trace; domain alignment; comparator research; authority-doc updates; consumed
  handoff; Godot 4.7 performance-guidance review; decision-complete plan.
- In progress: none. This turn intentionally stops before player-facing Godot
  implementation.
- Next executable task: **1.0 Restore demand-driven prediction and constant-work
  Fire**.
- Preserved unrelated work: `src/cannon/trajectory_predictor.gd` and
  `tests/target_mask_test.gd` local modifications.
- Known untracked residue: 27 obsolete binary PNGs under the two historical
  evidence directories; not linked as current evidence and not staged.

## Next Steps

1. Resume at Task 1.0 and inspect the two preserved unrelated diffs before
   staging anything.
2. Complete Task 1.0 as a prediction/readiness checkpoint, then Tasks 1.1–1.4 as
   one versioned stage-placement/camera/preview checkpoint.
3. Complete the flag and Shot Follow branches, then integrate them before the
   quality audit.
4. Announce and run the single bounded final gate only after the implementation
   and focused contracts stabilize.
5. Update implemented truth and mark this plan `done` only after every named
   acceptance check passes.

## Stop Conditions

- Stop before any dependency, asset pack, renderer, save-format, scoring, or
  mechanism expansion; it requires separate explicit user approval.
- Stop before adding timing probes, FPS thresholds, profiler capture, worker-thread
  physics access, generalized server APIs, pooling, LOD, or occlusion work; none
  is needed to prove the named structural contracts.
- Stop if v9 cannot preserve bounded default/summit witnesses within the existing
  32 candidates and shared standoff contingency. Do not reopen exhaustive solver
  work automatically.
- Stop if runtime evidence cannot show both the full Stage 30 mountain and a
  20–30% cannon by 90 m shared standoff at FOV 48; report the geometric conflict
  with captures before changing FOV or asset scale.
- Stop final validation after the named focused checks, one verify/export, and
  seven reviewed captures. Do not add a performance benchmark or broaden it for
  reassurance.
- Mark this plan `done` only after implementation, focused contracts,
  production-style visual evidence, documentation truth, and quality audit all
  pass. User-owned gameplay feel remains a separate final review.
