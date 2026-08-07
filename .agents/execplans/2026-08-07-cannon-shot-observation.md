---
type: plan
status: active
created: 2026-08-07
last_reviewed: 2026-08-07
scope: fixed baked open mountain-range terrain, playable-surface paint scope, fixed cannon standoff, cannon-side wind flag, Aim View composition, automatic Shot Follow, bounded structural performance work, and obsolete recovery cleanup
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

# Fixed Open Mountain Range, Cannon Standoff, and Shot Observation - Execution Contract

Paint Mountain will load one persisted canonical terrain layout per stage,
lower and widen the generated mass into an independently closed mountain-range
silhouette, remove the enclosing rear/side walls, and frame a large fixed cannon
in the foreground against that complete distant target. Valid contact paints the
Playable Terrain Surface while only Target Area overlap scores. It
will also replace unclear wind debris with a cannon-side flag and automatically
follow each newly fired root paintball until its first terrain impact. The same
implementation restores constant-work Fire admission and removes verified
redundant prediction, UI, camera, and trajectory-preview work without a timing
or profiling pass. It does not restore runtime terrain randomness, exhaustive
reachability, or authored solution work.

## Purpose

- Objective: make one stable lower/wider mountain, distance, wind, launch,
  flight, and impact readable as one coherent planning sequence.
- Deliverable: a version-9 fixed-seed baked catalog with a lower/wider terrain
  family, versioned stage placement, shared Aim View composition, cannon-side
  wind flag, specific-projectile Shot Follow state, contextual return control,
  bounded miss cleanup, a main-thread demand-driven prediction owner, batched
  trajectory dots, focused contracts, production-build captures, and current
  documentation.
- Completion state: Stages 01 and 30 both show a substantial cannon and complete
  distant lower/wider independent mountain range from the same persisted data
  on every load; no rear/side containment wall or hidden replacement exists;
  the fixed cannon is at least 70 m from the nearest playable front; the flag
  agrees with the authoritative wind; Fire follows the new root ball; first
  terrain impact remains readable; button or Tab returns early while physics
  continues; Fire performs no trajectory query; inactive presentation performs
  no repeated prediction or marker work; no runtime terrain generation,
  obsolete debris, backstop path, candidate search, solution-route runner,
  inactive catalog, or competing active task document remains.

## Scope and Boundaries

In scope:

- Keep the stationary cannon, manual yaw/elevation/power, existing left-drag and
  wheel controls, and no post-fire steering.
- Keep deliberate terrain orbit/zoom in Map View. Rename player-facing `Aim
  Lock` to `조준` / `Aim View` and `Map Inspection` to `지도 보기` / `Map View`;
  internal enum names may remain until a schema-neutral rename is convenient.
- Replace `WindDebrisField` with one non-colliding cannon-side flag or streamer
  driven by the existing `WindController` snapshot.
- Replace the version-8 candidate-seed contract with one canonical terrain-family
  seed used by all current stage profiles and exactly one persisted baked layout
  identity per stage. Runtime entry, retry, replay, and process restart load that
  layout and never generate or select another terrain.
- Lower the shared peak progression from the current `72..126 m` to `64..92 m`,
  widen lateral terrain bounds from `180..240 m` to `210..280 m`, and require
  the connected footprint to occupy at least 72% of its X bounds at its widest
  row while retaining taper, valleys, terraces, and real support faces.
- Remove the visible/collidable rear backstop and artificial side containment
  walls without hidden replacement planes. Generate one independent closed
  mountain whose perimeter Support Shell and bottom close the mass; retain only
  a restrained collider-matched non-target apron in an open environment.
- Replace wall-based containment identity with versioned open play bounds shared
  by generation, prediction, live projectile escape, replay, and validation.
  Crossing those bounds seals with `ESCAPED`; apron- or Support Shell-only roots
  remain never-contacted and use the 6.0-second timeout if they do not exit.
- Preserve the current XZ paint representation: all valid Playable Terrain
  Surface traversal paints, only immutable Target Area overlap scores, and the
  Support Shell, bottom, apron, decorations, and mechanisms never paint.
- Treat projected playable-silhouette height:width `3:4` as the target center
  with an accepted `0.65..0.85` band in the shared 1280x720 Aim View. This is a
  visual composition contract, not an X:Z grid ratio or a reason to flatten the
  mountain.
- Derive each stage's cannon placement so the cannon origin is at least 70 m in
  front of the nearest playable terrain edge, then promote one coherent version-9
  catalog with new bounded default/summit witnesses.
- Keep that one baked cannon transform stationary for the stage. Map View may
  orbit the inspection camera, but no player action changes the launch position.
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
- Cannon-position orbit, continuous movement around the mountain, discrete
  launch stations, Support Shell paint/score, and a triangle-atlas or other
  all-exterior-face coverage representation.
- Exhaustive target-texel first-hit certificates, authored success routes,
  solver clears, all-stage playthroughs, or a new solution database.
- Changes to PaintSystem authority, score meaning, target masks, mechanism rules,
  stage timer/result rules, save progression, online services, dependencies,
  plugins, asset packs, or renderer choice.
- Runtime terrain generation, seed rolls on retry/run entry, a terrain editor,
  downloadable seeds, daily challenges, multiple current catalog variants, or
  making all thirty stages share one identical topology. Future randomness is a
  separate product revision and may use only prebuilt reviewed variants.
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
- `PaintSystem` keeps one authoritative XZ mask over the Playable Terrain
  Surface. This plan does not introduce a second mask or extend addressing onto
  the Support Shell, bottom, apron, decorations, or mechanisms.
- No visible/collidable/hidden rear or side containment wall remains in v9.
  `PlayBoundsSpec` is data used for exit decisions, not collision geometry.
- The active v8 catalog remains loadable until the complete v9 bundle passes its
  atomic promotion checks. Only then may v8 be removed as recoverable Git history.
- `StageLayoutRepository` remains a persisted-layout loader and fails closed on
  missing, corrupt, or identity-mismatched v9 data. It never calls
  `SeededStageGenerator`, chooses a seed, or repairs a layout.
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
- Removing `BackstopEnvironment`, wall/side-wall scene nodes, `ContainmentSpec`,
  `BACKSTOP` settlement identity, and their superseded tests is authorized after
  their open-environment replacements pass the named v9 checks; Git is the
  recovery path.
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
| Fixed Cannon Position | One baked transform per stage; yaw/elevation/power change, but player input never translates/orbits the launch position | `StageData` plus `CannonController` |
| Canonical Terrain Seed | The one current terrain-family seed supplied to every stage profile; stage ID and immutable profile still make stage layouts distinct | `StageProgressionData` and the v9 catalog builder |
| Baked Layout | The persisted height grid, connected footprint, topology, target, mechanisms, decorations, witnesses, and checksums loaded as runtime terrain truth | `BakedStageLayoutData` through `StageLayoutRepository` |
| Mountain-Range Silhouette | The projected playable mass in Aim View; lower and wider with several lateral rises, targeting height:width 0.75 inside a 0.65–0.85 band | generation contract plus `AimCameraComposer` validation |
| Playable Terrain Surface | The continuous one-height-per-XZ skin, including cannon-facing slopes, terraces, valleys, ridges, summits, and far-side slopes; valid traversal can paint | `TerrainTopTopology`, `TerrainSurface`, and `PaintSystem` |
| Support Shell | The collidable perimeter walls and bottom that close the independent mountain; never paintable or scoreable | `TerrainGeometryFactory` and `TerrainSurface` shell identity |
| Target Area | Immutable score-eligible subset of the Playable Terrain Surface; non-target surface paint remains visible but unscored | baked `target_mask` consumed by `PaintSystem` |
| Open Play Bounds | Versioned non-colliding exit limits shared by prediction, live projectiles, replay, and validation | `PlayBoundsSpec` carried by the baked layout |
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
| Later terrain approaches the cannon | Stage 01 terrain front is about 57 m from the fixed cannon; Stage 30 is about 17 m because the builder fixes the rear wall and grows terrain forward | `scripts/build_stage_catalog.gd:440-449`; `resources/stages/catalog.tres:3181-3200` | Remove the wall anchor, use one shared terrain-center rule, and derive one fixed per-stage cannon Z after the accepted footprint exists |
| Backstop owns unrelated responsibilities | `BackstopEnvironment` creates visible/collidable rear and side walls plus the apron; `ContainmentSpec` mixes wall geometry, apron limits, and exit bounds; projectile settlement has a `BACKSTOP` terminal path | `scenes/gameplay/backstop_environment.tscn`; `src/terrain/backstop_environment.gd`; `src/terrain/containment_spec.gd`; `src/projectile/projectile_settlement_reason.gd` | Split the retained open apron and exit-bound responsibilities, then remove every wall/contact/terminal branch rather than hiding the wall mesh |
| Paint vocabulary hides the real rule | the authoritative 512-square XZ mask addresses the one-height terrain skin; current prose calls this `playable top`, while shell/apron/wall contacts never write paint | `src/paint/paint_system.gd`; `src/terrain/terrain_surface.gd`; `.agents/Documentation.md:303-313` | Preserve the data representation and rename the product meaning to Playable Terrain Surface; Support Shell remains collision-only |
| Runtime terrain is already persisted | the active v8 pointer loads thirty compressed layout Resources; `StageLayoutRepository` hydrates them and never generates or solves | `resources/stages/catalog.tres`; active v8 `manifest.json`; `src/app/stage_layout_repository.gd:1-120`; `src/stage_generation/baked_stage_layout_data.gd:1-51` | Preserve the baked Resource boundary; migrate its identity rather than add a second terrain format |
| Randomness remains in offline admission | the builder searches candidate indices `0..31`; current v8 accepted indices vary and eleven stages do not use candidate zero | `scripts/build_stage_catalog.gd:251-275`; active v8 `manifest.json`; `src/stage_generation/stage_progression_data.gd:7-69` | Version 9 removes the candidate range and fallback seed; one exact terrain-family seed either builds a valid stage or the shared generator/profile contract must be corrected |
| Height progression dominates late shape | nominal peak grows from 72 m to 126 m while lateral bounds grow only from 180 m to 240 m | `src/stage_generation/stage_progression_data.gd:51-69`; `scripts/build_stage_catalog.gd:468-520` | Lower peak growth, widen X bounds, and shift difficulty toward routes, passes, basins, reversals, width, and mechanisms |
| A wide grid does not prove a wide mountain | the footprint synthesizer may keep the real connected mass much narrower than `local_bounds`; no projected silhouette ratio exists | `src/stage_generation/route_graph_mountain_synthesizer.gd:40-103`; `tests/phase8_aiming_composition_test.gd` | Validate footprint span and the projected playable silhouette separately; never scale only the render mesh |
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
| [Angry Birds AR: Isle of Pigs](https://www.rovio.com/articles/rovio-and-resolution-games-give-the-green-light-to-angry-birds-ar-isle-of-pigs-released-today-in-the-app-store/) | Walking around a 3D structure makes viewpoint selection part of the puzzle | Keep Map View inspection orbit, but defer movable launch positions because current Paint Mountain keeps launch planning to yaw/elevation/power |
| [Team17's Worms 3D retrospective](https://www.team17.com/news/team17s-100-games-part-eight-2002-2004-worms-3d-worms-blast-more) | Fully 3D artillery increased level-authoring burden enough that levels became hand-designed | Preserve the deep mountain but avoid an all-face coverage and 360-degree launch-position expansion in this slice |

These references supply interaction patterns, not visual assets, control copies,
or licensing inputs. No external game content enters the repository.

## External Terrain References and Applied Decisions

| Primary source | Relevant lesson | Paint Mountain decision |
| --- | --- | --- |
| [Into the Breach design postmortem](https://media.gdcvault.com/gdc2019/presentations/Into%20the%20Breach%20Postmortem%20Final.pdf) | Subset treats readability and reduced random chance as deliberate planning-game constraints | Keep retries and stage entry deterministic while the launch-planning loop is being established |
| [Into the Breach official page](https://www.subsetgames.com/itb.html) | Run-level variety can coexist with deterministic readable decisions | Defer variety to an explicit future selection among reviewed baked catalogs; never reroll the active puzzle during retry |
| [XCOM 2 procedural level design, GDC](https://www.gdcvault.com/play/1025213/Plot-and-Parcel-Procedural-Level) | Procedural layouts improve content volume but reduce artistic agency and require explicit spacing/visibility checks | Retain the generator as an offline authoring tool, then commit the reviewed output as one content-addressed runtime authority |
| [Invisible Intuition, GDC](https://media.gdcvault.com/gdc2018/presentations/DShaver_Invisible_Intuition_GDC2018.pdf) | Landmarks, leading lines, framing, and composition make level flow readable | Judge the lower/wider range by lateral rises, route-leading lines, landmark visibility, and occlusion as well as numeric relief |
| [Godot 4.7 Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html) and [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html) | Typed Resources can persist generated data for later loading | Keep `BakedStageLayoutData` as the one saved layout payload; do not add JSON, a second mesh asset, or runtime regeneration |

The `3:4` ratio comes from the user's composition preference, not an external
standard. This contract defines it as projected playable-silhouette
height:width and gives it a band so the executor does not reinterpret its
orientation or apply it to the XZ grid.

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
5. First contact with either the Playable Terrain Surface or the Support Shell
   starts a 0.8-second impact hold. Only Playable Terrain Surface traversal may
   write paint. Escape, timeout, stage result, restart, invalid target deletion,
   or early return exits follow safely without changing gameplay outcomes.
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
18. Version 9 uses `CANONICAL_TERRAIN_SEED := 1347223552` for the current terrain
    family. Every stage passes that same seed plus its stage ID and immutable
    profile into keyed generation. Distinct profiles preserve the thirty-stage
    route/mechanism ladder; the seed is not varied to rescue a failed stage.
19. Remove current candidate/fallback identity from production: no
    `CANDIDATE_STRIDE`, `candidate_seed_for()`, `fallback_seed`, 0..31 builder
    loop, manifest candidate index, or repository candidate check remains in
    the v9 path. If the exact seed fails, correct only shared generation/profile
    inputs and rebuild; do not pick another seed or hand-author coordinates.
20. `BakedStageLayoutData` remains the authoritative persisted payload and its
    schema/version advances with the v9 catalog. The runtime repository loads
    and verifies the exact payload/hash and has no generator fallback.
21. Version 9 uses `terrain_size.x = 210..280 m`, keeps depth progression at
    `120..160 m`, and uses nominal peak `64..92 m`. Footprint synthesis must
    reach at least 72% of X bounds in its widest active row, remain row-solid,
    form one independently closed mass, taper by at least four cells, and
    preserve one physical Playable Terrain Surface/Support Shell source.
22. The 1280x720 Aim View projects the playable mountain at height:width
    `0.65..0.85`, targeting `0.75`, while retaining the 20–30% cannon, complete
    silhouette, summit headroom, route layers, trajectory, and impact marker.
    Difficulty growth uses route and mechanism structure rather than a taller
    summit outside the locked peak range.
23. Remove `BackstopEnvironment`, rear/side wall geometry and contact identity,
    `ContainmentSpec`, and `BACKSTOP` settlement. `OpenPlayEnvironment` owns only
    the restrained non-target apron/ground, while `PlayBoundsSpec` owns
    non-colliding exit bounds shared by prediction, live physics, replay, and
    the v9 payload checksum. Do not add hidden collision walls.
24. All valid Playable Terrain Surface traversal writes the one authoritative XZ
    paint mask. Only immutable Target Area overlap scores. Support Shell,
    bottom, apron, decorations, and mechanisms remain unpainted and unscored;
    this plan adds no second texture, face atlas, or coverage representation.
25. Each stage owns one baked fixed cannon transform derived after its footprint
    exists. The player edits yaw/elevation/power only. Map View camera orbit is
    inspection and never translates or rotates the launch transform around the
    mountain.
26. A root that crosses `PlayBoundsSpec` terminates as `ESCAPED`. A root that
    contacts only the apron or Support Shell remains never-contacted and reaches
    the 6.0-second timeout if it does not exit first. Neither contact creates
    paint, coverage, a bank shot, or a resident terrain-ball lifetime.

## Architecture and Data Ownership

| Change | Owner | Narrow interface | Must not absorb |
| --- | --- | --- | --- |
| Fixed terrain identity | `StageProgressionData`, `StageData`, and `build_stage_catalog.gd` | one canonical family seed + stage/profile identity -> one content-addressed baked layout | runtime seed rolls, candidate history, fallback selection, identical thirty-stage topology |
| Lower/wider range synthesis | `StageProgressionData`, `StageGenerationContract`, `RouteGraphMountainSynthesizer`, and `RouteGraphHeightSynthesizer` | stage number/profile -> bounded X/depth/relief and connected footprint | camera-only scaling, visual duplicate, per-stage coordinate repair |
| Independent mountain closure | `RouteGraphMountainSynthesizer`, `TerrainGeometryFactory`, and `TerrainSurface` | footprint perimeter -> one Playable Terrain Surface plus collidable Support Shell/bottom | rear-wall join, all-face paint addressing, duplicate visual shell |
| Open environment | new `OpenPlayEnvironment` plus `PlayBoundsSpec` | restrained apron contact + shared non-colliding exit AABB | rear/side wall geometry, hidden blockers, scoring, bank shots |
| Persisted terrain payload | `BakedStageLayoutData`, `StageLayoutBakeCodec`, and `StageLayoutRepository` | exact versioned payload/hash -> immutable runtime layout copy | generation, solver, scene/physics creation, silent repair |
| Standoff formula | `StageProgressionData` plus `build_stage_catalog.gd` materialization | pure nearest-front/cannon transform calculation after profile bounds exist | camera pose, solver routes, runtime mutation |
| Accepted placement/resources | `StageData` and promoted v9 catalog | serialized fixed cannon transform, camera bookmark, bounded witnesses | live camera state, player launch-position movement, or duplicated terrain bounds |
| Paintable/scored surface scope | `TerrainTopTopology`, `TerrainSurface`, baked `target_mask`, and `PaintSystem` | Playable Terrain Surface contact -> visible paint; Target Area overlap -> coverage | Support Shell/apron paint, face atlas, second mask |
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

- [ ] **1.1 Freeze and reshape the version-9 terrain family**
  - Bump `StageGenerationContract.CONTRACT_VERSION` and progression resources to
    version 9. Add
    `StageProgressionData.CANONICAL_TERRAIN_SEED := 1347223552` as the single
    positive seed supplied to all thirty profiles. Keep stage ID and profile ID
    in `KeyedStageSampler` keys so stages remain distinct without changing the
    seed.
  - Remove `CANDIDATE_STRIDE`, `candidate_seed_for()`, profile `fallback_seed`,
    contract `attempt_count`/`attempt_seed_stride`, layout/bake `accepted_seed`,
    `candidate_index`, and `generation_attempt`, builder candidate diagnostics/
    search, manifest `accepted_seeds`/`accepted_candidate_indices`, and
    repository candidate checks from the v9 path. Keep only `terrain_seed` for
    persisted identity. Rename any remaining authoring API from accepted/
    fallback terminology to exact canonical generation; do not leave a second
    legacy path reachable by catalog production.
  - Set `StageProgressionData.terrain_size_for()` endpoints to
    `Vector2(210, 120)` and `Vector2(280, 160)`, cell-count endpoints to
    `Vector2i(84, 48)` and `Vector2i(96, 64)`, and
    `nominal_peak_for()` endpoints to `64.0` and `92.0`. Update the difficulty
    formula/canaries so monotonic growth comes from routes, reversals, ridges,
    basins, passes, width, undulation, and mechanisms rather than removed height.
  - Update `StageGenerationContract` bounds and
    `RouteGraphMountainSynthesizer` shared contour rules so every row-solid
    footprint forms one independent mass, its widest active row covers at least
    72% of X cells, its front and rear contours both close through the generated
    Support Shell, its row spans still vary by at least four cells, and its
    occupied ratio stays below 0.85 to prevent a rectangular slab. Remove the
    rear-wall join assertion and height blend. Lower relief only in
    `RouteGraphHeightSynthesizer`/profile inputs; never scale the rendered mesh
    after baking.
  - Replace stale `tests/stage_progression_candidate_test.gd` and
    `tests/mountain_range_mvp_test.gd` with
    `tests/fixed_mountain_catalog_test.gd`. Update
    `tests/stage30_progression_test.gd`, `tests/stage_generation_test.gd`, and
    decoration/glyph/bake fixtures for exact-seed v9 identity, lower/wider
    endpoints, distinct stage checksums, footprint span/taper, and absence of
    candidate or fallback production symbols. Rename
    `tests/generation_v8_materialization_test.gd` to
    `tests/generation_v9_materialization_test.gd` and make it assert one shared
    seed plus thirty distinct payload checksums.
  - Accept when one exact seed produces all thirty structurally valid layouts in
    a dry build, repeated builds produce the same per-stage payload hashes, no
    current source/test/resource expects a candidate/fallback seed, and the
    active v8 pointer is still unchanged.

- [ ] **1.2 Remove the enclosure and establish open play bounds**
  - Replace `ContainmentSpec` with `PlayBoundsSpec`. Preserve one versioned
    explicit AABB and bounded apron XZ limits for deterministic generation,
    prediction, live escape, replay, and checksums; remove backstop center/size,
    side-wall geometry, join gap, and wall-contact fields.
  - Replace `BackstopEnvironment` with `OpenPlayEnvironment`, retaining only the
    restrained collider-matched non-target apron/ground. Delete rear and side
    mesh/body/shape nodes and do not add invisible blockers. Keep the existing
    terrain Support Shell and bottom as the mountain's only physical closure.
  - Remove backstop/side-wall owner and shape IDs, `BACKSTOP` settlement,
    wall-specific projectile branches, wall material/copy, and builder fixtures.
    Prediction and live projectiles use the same `PlayBoundsSpec`: leaving it is
    `ESCAPED`; apron- or Support Shell-only roots remain never-contacted and use
    the 6.0-second timeout if they do not exit.
  - Replace `containment_domain_test.gd`, `containment_geometry_test.gd`, and
    `containment_wall_test.gd` with `play_bounds_test.gd` and
    `open_play_environment_test.gd`. Add
    `terrain_surface_paint_scope_test.gd` to prove Playable Terrain Surface
    traversal paints, only Target Area overlap scores, and Support Shell,
    bottom, apron, decoration, and mechanism contacts never write paint.
  - Accept when scene inspection and focused physics checks find no rear/side
    wall or hidden blocker, the independent mountain remains watertight and
    collidable, predicted/live exit reasons match, no `BACKSTOP` symbol remains,
    and the active v8 catalog pointer is still unchanged.

- [ ] **1.3 Place the fixed cannon and compose the lower/wider Aim View**
  - After each exact layout exists, derive one cannon transform with the origin
    at least 70 m in front of the nearest active footprint edge, preserving
    identity basis and cannon Y. Persist that transform as the sole launch
    position for the stage. Update shared bookmark derivation relative to that
    accepted cannon and terrain; do not add 30 authored values, cannon orbit, or
    launch-station input.
  - Replace the current fit-only fallback with a responsibility-shaped composer
    that uses exact Playable Terrain Surface points and cannon/muzzle landmarks.
    Keep 48 FOV and one shared set of constants; target a 25% cannon silhouette with an
    accepted 20–30% band, projected mountain height:width `0.65..0.85` centered
    on `0.75`, and the complete mountain/summit safe frame.
  - Build the interest-point set and final pose once per layout checksum, cannon
    transform, FOV, and viewport aspect. Invalidate only on one of those inputs;
    Aim/Map toggles consume the cached pose without calling
    `playable_top_world_points()` or `summit_region()` again.
  - Preserve CameraDirector safety/occlusion correction and Map View behavior.
    Remove the superseded suggestion for independent Aim View navigation. Queue
    Map View click/refocus screen coordinates and resolve their direct-space ray
    in `_physics_process`, never inside `_unhandled_input`.
  - Extend `tests/phase8_aiming_composition_test.gd` with Stage 01/30 standoff,
    projected silhouette ratio, cannon ratio, projection containment, and cache
    invalidation assertions plus a rendered-evidence state; numeric projection
    supports but does not replace runtime image review.
  - Accept when both endpoint stages meet the foreground/distance contract
    and visibly read as a lateral range without FOV widening or per-stage camera
    data, a mode toggle performs no topology scan, and input/render callbacks
    perform no direct-space query.

- [ ] **1.4 Promote the version-9 catalog atomically**
  - Advance `BakedStageLayoutData.BAKED_LAYOUT_SCHEMA_VERSION` to 2 and
    `build_stage_catalog.gd` bundle format to 5 because candidate/attempt fields
    leave the payload and manifest. Rebuild all 30 persisted stages from the
    one canonical seed using only the bounded default and summit witness path;
    do not invoke exhaustive certificate or success-route workers.
  - Verify manifest and payload hashes, exact-seed identity, baked hydration,
    target/range admission, bounded witnesses, distinct stage profiles/layout
    checksums, footprint span/taper, independent shell closure, open play bounds,
    fixed-cannon standoff, and repeat-build
    equality. Point `resources/stages/catalog.tres` to the complete
    content-addressed v9 bundle only after these checks pass.
  - Extend `tests/baked_stage_layout_test.gd` and
    `tests/stage_layout_repository_test.gd` to prove process reload/retry returns
    the same immutable heights, footprint, placement, and checksums; corrupt or
    missing payloads fail and never call `SeededStageGenerator`.
  - Replace serialized `containment_checksum` with `play_bounds_checksum` in the
    v9 baked payload, replay, agent/debug observations, and catalog manifest.
    Persist no wall geometry or backstop identity.
  - Advance `ReplayRecorder.FORMAT_VERSION` from 8 to 9, replace its redundant
    `accepted_seed` field with the one canonical `terrain_seed`, and rename
    `tests/replay_recorder_v8_test.gd` to `tests/replay_recorder_v9_test.gd`.
    Reject format 8 deterministically rather than silently guessing the new
    identity contract; update replay/debug/agent consumers to use
    `terrain_seed`.
  - Remove `StageData.reliable_solution` and its legacy serialized values. After
    the v9 pointer passes import/start and exported-PCK loading, remove the
    replaced active v8 bundle, `backstop_environment.tscn`, version-8-only
    generation resources, stale candidate/containment tests, and any now-empty
    obsolete catalog directories; Git remains the recovery path.
  - Accept when runtime loads every v9 ID through `StageLayoutRepository`, no
    solution-route/candidate/fallback/backstop/containment field remains, clean
    process load and retry resolve identical hashes, the export contains every layout path, and
    exactly one active generated bundle is referenced.

- [ ] **1.5 Batch and suspend trajectory-preview presentation**
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
    It holds first Playable Terrain Surface or Support Shell contact for 0.8
    seconds and otherwise exits safely on early return, terminal event, restart,
    result, or target invalidation. Support Shell contact never writes paint.
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
    never-contacted timeout. Do not change persistence after Playable Terrain
    Surface contact. Apron or Support Shell contact does not disable the
    never-contacted timeout.
  - Review the generated default shot in the real Shot Follow flow for Stage 01
    and Stage 30. Tune only shared standoff/camera/launch presentation inputs if
    the flight reads as immediately adjacent or needlessly prolonged; do not add
    an exact flight-time assertion or target solver.
  - Add focused timeout regression for never-contacted versus terrain-resident
    balls and preserve replay/settlement reason contracts.
  - Accept when misses end promptly, balls that reach the Playable Terrain
    Surface persist, and the two reviewed default flights have a readable
    anticipation/impact beat near the user's approximate three-second reference.

- [ ] **5.1 Integrated quality pass**
  - Run `$codebase-quality-auditor` over the final task diff. Check StageController
    ownership, exact-root identity, CameraDirector size, stage-generation
    responsibility, PredictionScheduler ownership, physics-query callback safety,
    no second wind truth, HUD intent boundaries, MultiMesh bounds, schema removal,
    resource lifecycle, PlayBounds/open-environment ownership, exact paint-scope
    enforcement, and reachable failure paths.
  - Make only safe task-scoped corrections. Accept when no competing state owner,
    catch-all gameplay file, Fire-side prediction, render/input direct-space query,
    dead debris/solution/backstop path, silent null-root follow, competing paint
    representation, hidden blocker, or v8/v9 pointer ambiguity remains.

- [ ] **5.2 One focused and production-style validation gate**
  - Before starting, tell the user this gate runs targeted functional scripts,
    one repository smoke check, one Windows release export, and seven background
    capture states; it does not run the full suite, a timing/FPS benchmark, an
    exhaustive solver, or a foreground window. Stop after the named artifacts are
    produced and reviewed unless a relevant failure requires one corrected rerun.
  - Run focused prediction scheduling, camera/query safety, trajectory batching,
    stage placement, open play bounds, paint-surface scope, wind flag/HUD, Shot
    Follow, timeout, and replay-presentation scripts directly with headless
    Godot. Run `scripts/verify.ps1` once and one release export.
  - Capture and inspect at native size: Stage 01 Aim View, Stage 30 Aim View,
    weak/crosswind flag, strong/crosswind flag, mid-flight root follow, terrain
    impact hold, and returned Aim View. Use the built executable and the existing
    background capture path.
  - Accept when commands exit zero with no script/runtime errors and the agent's
    visual review finds no clipping, hidden mountain, tiny cannon, ambiguous wind,
    boxed-in backdrop, visible or hidden enclosure, lost projectile, obstructive
    return control, or steering implication.

- [ ] **5.3 Truthful closeout**
  - Record exact commands, v9 bundle identity, changed/removed files, capture
    paths, visual findings, and remaining user-owned feel approval in
    `.agents/Documentation.md`, `docs/test-checklist.md`, and a task evidence
    report. Mark this plan `done` only when every named gate passes.

## Acceptance Checks

- Every v9 `StageData`, generation profile, baked payload, and manifest entry
  records `terrain_seed = 1347223552`; none records an accepted, candidate,
  attempt, or fallback seed.
- All thirty v9 layouts have distinct payload checksums despite sharing that
  seed. Retry and a clean process load return the exact same height, footprint,
  placement, and payload checksums for each stage.
- Runtime stage entry has no reachable generator or candidate-search fallback.
  A missing or corrupt baked payload fails visibly instead of producing a new
  mountain.
- Stage 01/30 use X width `210/280 m`, depth `120/160 m`, nominal peak
  `64/92 m`, and widest footprint span of at least 72% of X cells. Their
  reviewed 1280x720 Aim View projections fall inside mountain height:width
  `0.65..0.85`, targeting `0.75`, without render-only geometry scaling.
- Stage 01 and Stage 30 report at least 70 m from cannon origin to the nearest
  playable front in accepted data.
- The cannon transform is fixed for the whole stage. Map View orbit, zoom, and
  refocus do not move the cannon or create another launch position.
- Scene and focused physics checks find no visible, collidable, or hidden rear or
  side wall. The mountain remains an independent closed mass, the retained apron
  is non-target ground, and no `BACKSTOP` settlement symbol remains.
- The one authoritative paint mask writes only from Playable Terrain Surface
  traversal. Paint is visible outside the Target Area but scores only inside it;
  Support Shell, bottom, apron, decoration, and mechanism contact never writes
  paint.
- Prediction and live flight use the same `PlayBoundsSpec`; crossing it produces
  the same `ESCAPED` result in both paths without collision geometry.
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
- Never-contacted root timeout is 6.0 seconds; Playable Terrain Surface contact
  disables age-based deletion and preserves later wind wake/paint behavior.
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
  existing drag/wheel/keyboard meanings. Camera movement never changes the fixed
  cannon transform.
- The 48-degree FOV, Compatibility renderer, typed GDScript, fixed 60 Hz physics,
  Korean-first copy, Theme ownership, and common desktop layout support remain.
- Catalog promotion is atomic; no partial v9 or runtime generation fallback is
  permitted.
- The canonical terrain seed is one catalog-family constant, not a per-stage
  tuning control. Stage variety comes from stage/profile identity, and all
  runtime visual/collision/paint consumers use the same baked topology.
- `PlayBoundsSpec` is exit-decision data only; it must not create a visible,
  collidable, or hidden containment wall. The one XZ paint mask represents only
  the Playable Terrain Surface, not the Support Shell or arbitrary exterior faces.
- No production dependency, external asset, network service, plugin, Docker
  path, or hand-authored stage repair is added.

## Validation Commands

Use the configured Godot executable; do not invoke `scripts/test.ps1` because it
includes an unrelated performance test and a much broader suite.

```powershell
$paintMountainGodot = (Resolve-Path -LiteralPath 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe').Path

foreach ($testScript in @(
  'prediction_scheduler_test.gd',
  'fixed_mountain_catalog_test.gd',
  'stage_generation_test.gd',
  'stage30_progression_test.gd',
  'generation_v9_materialization_test.gd',
  'baked_stage_layout_test.gd',
  'stage_layout_repository_test.gd',
  'play_bounds_test.gd',
  'open_play_environment_test.gd',
  'terrain_surface_paint_scope_test.gd',
  'phase7_user_qa_contract_test.gd',
  'stage_cannon_standoff_test.gd',
  'phase8_aiming_composition_test.gd',
  'trajectory_preview_efficiency_test.gd',
  'cannon_wind_flag_test.gd',
  'wind_result_hud_test.gd',
  'shot_follow_camera_test.gd',
  'phase7_ui_test.gd',
  'projectile_settling_test.gd',
  'replay_recorder_v9_test.gd',
  'replay_presentation_test.gd'
)) {
  & $paintMountainGodot --headless --path . --script "res://tests/$testScript"
  if ($LASTEXITCODE -ne 0) { throw "$testScript failed." }
}

& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd -- --dry-build
if ($LASTEXITCODE -ne 0) { throw 'Exact-seed v9 catalog dry build failed.' }

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
| The exact canonical seed fails a bounded default/summit witness or another structural contract | Adjust only shared generator/profile inputs within the locked width, depth, peak, and footprint ranges, rebuild all thirty stages from `1347223552`, and keep the first shared rule set that passes | Do not choose a rescue seed, restore candidate search, hand-author coordinates, or invoke exhaustive solution/certificate work |
| Two stages built from the shared seed produce the same payload checksum | Correct the stage/profile identity fed into keyed sampling or the shared profile differentiation, then rebuild all stages | Do not vary the seed per stage merely to force a different checksum |
| Aim View projected mountain ratio exceeds 0.85 | First widen the shared footprint contour while staying below 0.85 occupied ratio; if needed, lower the shared peak progression without going below the locked `64..92 m` endpoints | Do not hide the problem with FOV, camera roll, or render-only mesh scaling |
| Aim View projected mountain ratio falls below 0.65 | Restore relief within the locked `64..92 m` range and verify the shared camera composer before changing contour width | Do not narrow the widest footprint below 72% or add per-stage camera tuning |
| Representative default flight still feels prolonged | First adjust the shared generated default aim preference within the existing legal tuple and target-centroid neighborhood, then the shared launch-speed curve only if all bounded witnesses and preview/physics parity are regenerated | Do not add a flight-duration gate or per-stage speed |
| Follow root is freed before a contact event | Treat invalidation as a terminal presentation event and return safely to Aim View | Do not keep a dangling node reference or infer a fake impact |
| First contact is the Support Shell rather than the Playable Terrain Surface | Show the same 0.8-second impact hold, write no paint, then continue the normal escape or never-contacted timeout rules | Do not reclassify the Support Shell as paintable terrain or add another paint representation |
| A missed root remains inside PlayBounds without reaching the Playable Terrain Surface | Keep the 6.0-second never-contacted timeout and the shared prediction/live exit check | Do not add a hidden wall, enlarge bounds merely to retain the root, or invent a new settlement identity |
| The open background weakens the mountain silhouette | Adjust shared background, ground, lighting, and material contrast, then review both endpoint captures | Do not restore a rear wall or dark enclosure |
| The retained apron dominates the open composition | Reduce its visible extent or contrast within the locked bounded-ground responsibility while preserving collision and bounds parity | Do not make the apron paintable or scoreable |
| Flag cannot remain readable without crossing the muzzle path | Move the single shared pole anchor to the opposite cannon side and re-run both Aim View captures | Do not add a HUD-only replacement or per-stage anchor |
| Reduced motion makes direction unclear | Keep the streamer statically aligned and reduce only periodic flutter amplitude to zero | Do not hide the flag or wind rule |
| v9 promotion fails import/start | Keep v8 as the active pointer, retain the staged v9 bundle for diagnosis, and fix only the failing contract | Do not delete v8 or activate a partial bundle |
| A material fact contradicts an ownership or product decision above | Stop the affected implementation, update this contract and linked specs, and ask only if the correction changes user-visible scope, authority, dependency, or destructive risk | Do not silently choose a different camera, wind, solver, or timing design |

## Progress

- Completed in the current worktree: demand-driven prediction and constant-work
  Fire; exact-seed version-9 generation; the 75 m fixed-cannon catalog; open
  play bounds and apron; version-9 replay/layout identity; batched trajectory
  dots; cannon-side wind flag; exact-root Shot Follow, impact hold, and early
  return; removal of the active v8 bundle and obsolete wall/debris/candidate
  artifacts; removal of the obsolete delivery responsiveness probe and its
  timing-threshold test. The active v9 manifest is
  `b0eb55b3e366a7a92b1391a6acd0298bbc854d8c831e8ac57f9b5df5ab44c957`.
- Paused at Task 1.3's predetermined geometry stop. Development captures at
  `.agents/evidence/cannon-shot-observation/dev_stage01_aim.png` and
  `dev_stage30_aim.png` show the full mountain only by pushing the camera far
  enough that the cannon is clipped or visually negligible. The exact
  projection contract reports Stage 01 mountain/cannon ratios `0.386/0.153`
  and Stage 30 ratios `0.315/0.082`, versus required `0.65..0.85` and
  `0.20..0.30`.
- A bounded Stage 30 camera-space diagnostic with the cannon shifted to the
  maximum allowed 90 m standoff found no shared 48-degree-FOV pose satisfying
  the complete playable surface and both ratios. A close 20 m rear camera still
  projected the interest set to width `2.255` where the full normalized
  viewport width is `2.0`. A real 90 m exact catalog rebuild then failed closed
  at Stage 18 because predictor and rigid-body first contact selected adjacent
  terrain cells; the active 75 m catalog pointer was not changed.
- No final validation gate, release export, or production capture set has run.
  The temporary geometry-search diagnostics were removed after recording these
  facts; timing/FPS instrumentation was not added or invoked. A post-pass found
  no new responsibility owner that should absorb the scheduler, flag, bounds,
  or camera composer, but it did confirm that legacy broad-suite tests still
  reference removed v4/v8 containment/candidate APIs and must be retired or
  migrated before the task can be complete.
- Preserved unrelated work: `src/cannon/trajectory_predictor.gd` and
  `tests/target_mask_test.gd` local modifications.
- Known untracked residue: 27 obsolete binary PNGs under the two historical
  evidence directories; not linked as current evidence and not staged.

## Next Steps

1. Obtain the user's decision on the Task 1.3 geometry conflict before changing
   the 48-degree FOV, cannon asset scale, locked `3:4` projected ratio, or 90 m
   standoff ceiling. The recommended amendment is to preserve the lower/wider
   physical mountain and real cannon scale, treat `3:4` as a visual preference
   rather than an exact playable-top projection gate, and permit the shared
   standoff to move beyond 90 m until a close cannon camera contains Stage 30.
2. After that decision, update this contract first, then regenerate the entire
   v9 catalog and re-review Stage 01/30 Aim View captures. Do not loosen
   predictor/rigid-body hit-identity parity merely to make the farther catalog
   pass.
3. Complete the remaining focused contracts, retire or migrate legacy tests
   that still compile against removed containment/candidate APIs, reconcile the
   metadata-only `ContainmentSpec` bridge after the preserved predictor diff is
   owned, and update documentation truth.
4. Announce and run the single bounded final gate only after implementation and
   focused contracts stabilize; then mark this plan `done` if every accepted
   criterion passes.

## Stop Conditions

- Stop before any dependency, asset pack, renderer, save-format, scoring, or
  mechanism expansion; it requires separate explicit user approval.
- Stop before adding cannon orbit, multiple launch stations, moving the fixed
  cannon, painting the Support Shell, or replacing the one-height XZ paint mask
  with an all-face atlas; each changes the approved game contract.
- Stop before adding timing probes, FPS thresholds, profiler capture, worker-thread
  physics access, generalized server APIs, pooling, LOD, or occlusion work; none
  is needed to prove the named structural contracts.
- Stop if the exact canonical seed cannot preserve bounded default/summit
  witnesses after the predetermined shared generator/profile corrections. Do
  not change seed, restore candidate search, or reopen exhaustive solver work
  automatically.
- Stop if runtime evidence cannot show both the full Stage 30 mountain and a
  20–30% cannon by 90 m shared standoff at FOV 48; report the geometric conflict
  with captures before changing FOV or asset scale.
- Stop final validation after the named focused checks, one verify/export, and
  seven reviewed captures. Do not add a performance benchmark or broaden it for
  reassurance.
- Mark this plan `done` only after implementation, focused contracts,
  production-style visual evidence, documentation truth, and quality audit all
  pass. User-owned gameplay feel remains a separate final review.
