---
type: record
status: active
created: 2026-08-02
last_reviewed: 2026-08-04
scope: implemented project state and durable bootstrap decisions
related:
  - Plan.md
  - execplans/2026-08-03-gameplay-visual-reset.md
  - execplans/2026-08-03-core-interaction-redesign.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
---

# Project Record

## Current Gameplay and Visual Reset (2026-08-04)

The active execution plan is
[`execplans/2026-08-03-gameplay-visual-reset.md`](execplans/2026-08-03-gameplay-visual-reset.md).
Production implementation tasks 1.1 through 5.4 are complete. The plan remains
active only because visible gameplay QA and the deferred formal checks still
require explicit user authorization.

`RouteGraphMountainSynthesizer` now produces both a sampled height field and a
connected, irregular cell footprint for all three stages. Its seeded noise is
restricted to the exterior contour: each occupied depth row is filled between
its left and right edges, empty interior rows are bridged, and adjacent rows
overlap. Branching route bands therefore cannot carve a visible or physical
hole through the target. `TerrainTopTopology`
emits top triangles only for those cells and supplies the same indexed faces to
rendering, concave collision, surface queries, target rasterization, and paint
addressing. `TerrainGeometryFactory` closes every exposed contour with thick
support walls and a bottom cap. The mountain is therefore a real closed 3D mass,
not a full-bounds top card with a camera-hidden collider.

Runtime admission no longer depends on `StageMvpPermit`, candidate sweeps, or an
exhaustive certificate. Each stage builds its persisted seed once, installs its
target and mechanism data, and derives a bounded default yaw/elevation/power by
sphere-casting the real projectile toward an eligible point near the target
centroid after physics registration. The existing `StageController`, rigid-body
projectile, measured contact, low-rebound tuning, settlement, result, and
restart owners remain connected to that same terrain.

The paint/coverage contract is now correctly separated. A ball in verified
contact with any real mountain-top triangle emits continuous impact, sweep, and
settle commands, so every traversed top area can become visibly painted.
`PaintSystem` remains the only paint-mask writer. Its separate eligible mask is
used only to decide which threshold crossings increase coverage; wall, apron,
support faces, and empty cells are neither scoreable nor treated as top surface.

Stage 1 uses the broadest route mass, Stage 2 adds Burst, and Stage 3 adds
Splitter plus Bumper and the greatest route complexity. Mechanism placement
still comes from generated route pads; their solid collision silhouettes are
now color-separated as amber, violet, and coral. Approved trees and rocks remain
non-gameplay dressing outside route and mechanism clearance.

World presentation now uses a bright warm rear wall, warm off-white faceted
mountain, lower support/apron plane, white-and-navy cannon, restrained blue
trajectory dots, a depth-tested impact ring, and aiming cameras behind the
cannon. The Korean-first Pretendard HUD now has a left vertical goal-relative
coverage rail with an absolute percentage, lower-left aim/power, one centered
Fire button, and top-right shots plus gear. Gear/Escape opens the full paused
menu; Restart exists there and in result/replay flows, not in the aiming HUD.
Closing the application-level Settings overlay returns to the still-paused menu.

No visible Godot process, test suite, certifier, screenshot capture, performance
pass, replay matrix, balance check, or user visual review was run for this
revision. Godot 4.7.1 headlessly passed project import/script parsing,
main-scene startup, and a direct First Descent gameplay-scene startup that
reached `BRIEFING`. The verifier was strengthened to fail on Godot script/runtime
error text even when the engine returns exit code zero; this caught and led to
fixes for invalid constant expressions and an obsolete decoration admission
gate. The Windows release was rebuilt from current source and passed a hidden
headless startup. Its SHA-256 is
`F59E7D7B50C208538226C5AB366B4A695FC8AAED345AD6730B1791C70F3A06BD`, and the
existing fastrun entry points to `builds/windows/PaintMountain.exe`.

These checks establish importability and startup, not visual correctness,
gameplay balance, all-stage outcomes, projectile behavior, or user approval.

## Superseded Core-Interaction Implementation Record (2026-08-03)

The superseded implementation authority was
`execplans/2026-08-03-core-interaction-redesign.md`. A source-level audit after
the prior remediation release found that several reported outcomes were not
supported by the current implementation: the terrain render mesh has no closed
visual shell, projectile contacts fabricate a world-up point, mechanisms use
gameplay trigger areas instead of matching solid bodies, paint stamping is an
X/Z approximation, aiming still solves clicked targets, replay input is not
isolated, and the HUD remains code-built and compositionally inconsistent with
the supplied reference.

The previously recorded run metrics, screenshots, seeds, and solution results
below are retained as historical evidence for the superseded build. They do
not satisfy the active ExecPlan's unchecked acceptance gates. No redesign
feature is considered implemented until its task-specific tests and final
production evidence pass.

Task 00 completed the documentation correction only. Static diff/lifecycle
checks passed; no runtime behavior was changed or claimed. The next executable
milestone is Task 01, which introduces the typed contracts and `TerrainSurface`
owner without changing visible gameplay.

Task 01 added the typed `TerrainGeometry`, `TerrainSurface`,
`ProjectileContact`, `PaintDepositRequest`/tuning, `ShotObservation`, and
`TrajectoryPrediction` contracts plus collision-layer names and narrow owner
interfaces. Godot 4.7.1 registered every class, passed headless import/parse,
and started the existing main scene. The new terrain owner/factory is not wired
into production until Task 03, so this milestone makes no visual-completion
claim.

Task 02 replaced authored route control points with deterministic version-3
route rules, path-first mountain lobes, realized-grid validation, role-owned
mechanism shelves, deterministic decoration placement, and one finalized
eligible mask. Base requests accept First Descent attempt 0
(`845479992`, height checksum `3976121806`, eligible checksum `91346562`),
Burst Basin attempt 1 (`1692116028`, `1331063294`, `2859517061`), and Split
Ridge attempt 6 (`671547267`, `2783769031`, `2129835509`). Repeated base and
fallback-request runs matched seed, attempt, height/mask checksums, route roles,
reversals, mechanism transforms, and decorations. Task 03 is next and will wire
the already-added closed `TerrainGeometry` into production rendering/collision.

Task 03 wired `TerrainSurface` into gameplay and the retained projectile
sandbox. `TerrainGeometryFactory` is now the sole production terrain builder:
it emits `6,912` top, `480` skirt, and `2` bottom triangles, a scaled
`HeightMapShape3D` top collider, and a separate backface-enabled shell collider.
The obsolete `TerrainMeshFactory`, its stage-specific height formulas, and the
legacy PaintSystem eligibility fallback were removed. Headless fixture casts
classified flat, 35-degree ramp, graze, and skirt contacts by distinct body
identity; normalized shell-edge ownership and render/collision parity passed.
The opaque lit shader now uses flat mesh facets, shadows, `0.88 / 0.24`
dry/paint roughness, shell classification, and a restrained paint rim without
emission. Task 04 is next.

Task 04 replaced fabricated world-up impacts and X/Z paint circles with typed
direct-body contacts and one authoritative deposit path. High-speed CCD
manifolds are grouped before collider/shape debounce; the selected contact
retains the measured terrain point, normal, collider identity, shape indices,
incoming velocity, and measured/fallback physical impulse. `PaintSystem`
reconstructs every candidate pixel in 3D, requires connected eligible terrain,
binds its paint and eligibility textures to the terrain shader, applies bounded
steepest-descent flow, and returns the accepted amount before projectile
payload changes. The 80-shot contact matrix, exact 3,228-pixel narrow stamp,
zero-overlap gain, cliff isolation, bounded flow, and live projectile payload
integration passed headlessly. The obsolete Area-based mechanism collision now
fails its historical Phase 5 assertion as expected; Task 05 replaces that path
with matching solid bodies.

Task 05 replaced all gameplay trigger areas with scene-owned compound
`StaticBody3D` mechanisms and a separate selection-only query layer. Burst now
submits one terrain-aware `14 m / 140` deposit through `PaintSystem`; Splitter
removes its parent and emits exactly three route-role children with 90% total
payload, generation-1 radius multipliers, and the frozen contact-normal spawn
formula; Bumper queues the frozen downstream corrective impulse for the next
direct-body integration tick. Real rigid-body fixtures matched preview body,
shape, and impact center, rejected duplicate contacts, accepted a later
separated Bumper strike, restored state on reset, and enforced the eight-ball
cap. The sealed observation recorded four activations and three children.

Task 06 removed `ImpactTargetSolver` and its UID. Empty-viewport drag now maps
directly to yaw/elevation, A/D/W/S apply fixed independent steps with owned
hold timing, wheel and focused `−/+` controls change power only, and Space,
Fire, and Tab enter the same guarded stage actions. `TrajectoryPredictor`
integrates the frozen 60 Hz damping/gravity order, sphere-casts the real ball
radius against terrain/mechanism bodies, stops at the first measured collision
or exact bounds crossing, and leaves timeout non-fireable. The preview
arc-length samples the complete result into at most 96 dots, always preserves
launch/end points, aligns the collision ring to its measured normal, and uses
a camera-facing red cross for bounds exit. Actual UI events, all 30 frozen
stage/aim cases through the Godot physics backend, three isolated mechanism
casts, bounds exit, timeout, and the prior projectile/mechanism/state
regressions passed. Task 07 is next.

Task 07 made `ShotObservation` the single sealed shot summary and corrected
fire-time ordering so spawn/contact signals cannot precede its creation. The
controller now waits for two consecutive inactive physics ticks, conserves
aggregate payload across split and settled balls, and gives replay and the
agent API the same sealed object. Every aim, fire, restart, and debug mutation
now carries or respects an action origin; replay presentation holds an
exclusive `REPLAY` lock until its clean briefing exit. Replay format 3 stores
only ticked actions plus stage/profile/seed/checksum metadata and expected shot
outcomes, rejects format 2, and validates contact, coverage, mechanism order,
settlement reasons, and result state. `CameraDirector` now applies 1.5 m terrain
clearance and line-of-sight correction to all bookmarks, briefing orbit,
mechanism focus, and speed-weighted split framing with a 96 m wide-view latch.
All named camera fixtures passed across the three stages. A fresh-process
record/replay matched first contact and coverage with zero measured delta, and
the independent persistence matrix preserved locale, unlocks, results, and
settings. Task 08 is next.

Task 08 replaced code-built interface panels with scene-owned HUD and screen
components on a 1280x720 logical canvas. One Theme now owns Pretendard,
palette, typography, radii, progress, and keyboard-focus styling;
`HudController` only coordinates typed state. The frozen aiming edge layout,
aggregate payload, direction/elevation, target marker, sealed shot summary,
first-session hint, mechanism callouts, replay controls, result width, and
immediate persistent Korean/English switching passed their headless tests at
all three supported 16:9 sizes. `UIFactory` and its UID were removed, and only
the previously approved committed Kenney/Pretendard files are referenced.
The dummy headless renderer could not provide a viewport texture, so no render
capture was produced or treated as visual approval. Task 09 is next.

Task 09 retired the obsolete projectile sandbox and migrated its projectile-
paint integration check to the production gameplay scene. The new explicit
`scripts/test.ps1` owns the ordered fresh-process suite and unconditional
persistence/replay cleanup; reliability and performance assertions now use the
frozen `50 ms`, `60 FPS`, `33.3 ms`, and `128 MiB` limits. A resumable offline
search tool evaluates production 60 Hz shots and composes their authoritative
paint masks. First Descent now has a normally validated one-shot solution at
`(12, 26, 100)`, reaching `5.335%`.

Task 09 is stopped at its locked balance-contract gate. Precision probes that
physically activated every mechanism measured a best isolated Burst result of
`2.689%`, a best Splitter result of `1.293%`, and `0%` for each of eight exact
Bumper strikes. Sample five/six-shot sequences reached only `4.533% / 3.443%`,
far below the fixed `27% / 70%` targets. Contact, finite-payload paint, mask
authority, and mechanism activation tests pass, so silently lowering targets
or restoring oversized paint would violate the active ExecPlan. Burst Basin
and Split Ridge intentionally retain empty `reliable_solution` arrays, and
`phase6_content_test.gd` remains a truthful failing gate pending an explicit
balance-contract revision or conforming search result.

## Context

The repository was created from a complete vertical-slice brief. The
2026-08-02 baseline established the broad application and gameplay systems.
The first 2026-08-03 remediation produced a generated-stage,
direct-target/Korean-first build, but its completion claims were superseded by
the static-audit correction above.

## Decision

- The project uses Godot 4.x, GDScript, the Compatibility renderer, Windows desktop, and a fixed 60 Hz physics tick.
- The initial runnable entry is an explicitly labeled bootstrap scene that checks project loading, 3D rendering, procedural heightfield geometry, collision generation, and the intended distant-mountain composition.
- Phase 2 replaces the configured main entry with a projectile sandbox while preserving the isolated bootstrap scene. `ProjectileData` owns tuning, `CannonBallistics` is shared by preview and launch, and `ProjectileManager` bounds and cleans up rigid bodies.
- `PaintSystem` owns one 512×512 runtime paint image and its derived texture. The terrain shader samples that texture, while incremental threshold accounting derives coverage from the same pixel writes and an inset eligible mask.
- `StageController` is the sole stage-state authority. Human buttons and cannon input call the same validated fire/restart methods; `CameraDirector` and `HUDController` only react to emitted state.
- `GimmickBase` owns common physical activation, duplicate-projectile rejection, cooldown/charges, state snapshots, and reset. Burst delegates to `PaintSystem`, Splitter delegates bounded child creation to `ProjectileManager`, and Bumper applies one directional rigid-body impulse.
- `StageCatalog` owns the exact three-stage resource list, while `GameState` and `SaveSystem` own selection/unlocks/results/settings and atomic versioned local persistence. Stage scripts contain no stage-specific rule branches.
- `ReplayRecorder` stores format-3 deterministic actions and expected sealed observations. `ReplayPresentationController` exclusively locks gameplay mutations to replay-origin actions until clean exit; `GameplayAgentApi` uses the same validated action and observation boundaries without HUD or mouse coupling.
- Split children are redirected toward the visible downhill face and disperse divided payload over wider lanes. This gives Split Ridge a difficult, high-value route while retaining the one-generation and eight-projectile limits.
- `AppRoot` owns navigation among separate main-menu, stage-select, settings, and active-gameplay interfaces. Gameplay emits narrow navigation signals instead of knowing the application shell.
- Presentation uses approved Kenney low-poly dressing and particle textures, bright faceted terrain, an eight-emitter paint-particle pool, bounded camera shake, and runtime-generated PCM music/SFX routed through Master/Music/SFX buses.
- `DebugOverlay` is debug-build-only and derives four mask views plus metrics/actions from runtime owners; it exports ReplayRecorder-backed JSON rather than maintaining parallel gameplay state.
- `DeliveryCaptureRunner` deterministically reproduces the seven evidence states only when explicit command-line arguments are present. `export_presets.cfg` owns the Windows Desktop release path.
- `PaintSystem` keeps paint, eligible, recent, and derived excluded masks in byte buffers; threshold crossings update coverage incrementally and each dirty batch uploads once. This removed the measured Burst-frame stall without adding a second coverage authority.
- Product behavior, technical ownership, planned work, and implemented status are stored separately to avoid treating plans as working features.

## Rationale

- A small real scene gives the next implementation phase a verified engine baseline without pretending the vertical slice already exists.
- The provided brief already locks the engine, core architecture, mechanisms, scope exclusions, performance target, and acceptance artifacts.
- Compatibility rendering and dependency-free procedural primitives keep the initial project portable on modest Windows hardware.

## Consequences

- The bootstrap remains an isolated validation scene; the obsolete projectile sandbox is retired and the StageData-selected gameplay scene is the only projectile/paint integration entry.
- The complete menu-to-stage-to-result flow, all three stages and mechanisms, persistence/replay, agent actions, debug tooling, presentation, export, performance evidence, and seven release screenshots run and have focused checks.
- Future feature completion claims must cite running-game checks and update this record.

## Superseded Remediation Claims (2026-08-03, Historical)

- `.agents/Plan.md` completed all six earlier phases and is lifecycle `done`.
  Its entries below describe the superseded build and are not current proof.
- `SeededStageGenerator` produces the exact three deterministic layouts from typed profiles. One accepted immutable `GeneratedStageLayout` supplies the 6,144-triangle mesh, collision, paint queries/mask inputs, dressing, mechanism placement, replay checksum, and agent height observations.
- Stage profiles increase route count, reversals, shelves, and vertical complexity. Accepted seeds/checksums are First Descent `845487911/3476095321`, Burst Basin `1692123947/1568157987`, and Split Ridge `671737323/3215880357`.
- Stage 1 has no mechanism, Stage 2 has one Burst, and Stage 3 has one Splitter plus one Bumper. Placement is deterministic and validated; distinct scene-authored 3D silhouettes, compact below-device labels, and validated camera bookmarks keep mechanisms readable.
- `AimInputController` owns pointer/keyboard device input. It raycasts terrain/mechanisms, asks the fixed-tick damped `ImpactTargetSolver` for the lowest valid elevation at current power, exposes explicit invalid aim, and renders at most 72 dots through the real first collision. `CannonController` remains device-independent.
- Power uses visible minus/plus controls, hold repeat, wheel fine tuning, and keyboard fallback; Space or Fire requests the same guarded shot action. A/D/W/S remain the accessible angle fallback.
- The app ships complete `ko`/`en` translations, defaults new/V1-migrated saves to Korean, persists explicit locale choice in save format 2, and applies Pretendard plus shared UI primitives across menu, selection, settings, HUD, pause, and results.
- The approved runtime import is complete: five Kenney Nature Kit GLBs, six Kenney Game Icons PNGs, four Kenney Particle Pack PNGs, Pretendard Variable WOFF2, and four local license files. `docs/asset-licenses.md` records the pinned hashes, provenance, and uses.
- Physical reliable solutions clear `4/27/70%` targets at 5.791%, 33.470%, and 74.359%; Stage 2 activates Burst and Stage 3 activates both Splitter and Bumper. The six-shot Stage 3 left-route-only guard remains below target at 4.353%.
- The final Godot 4.7.1 Windows release and seven Korean-default 1920×1080 screenshots replace the legacy evidence. Separate Korean/English 1280×720 and 1600×900 captures cover responsive settings, pause, menu, stage selection, and aiming.

## Historical Baseline Status (2026-08-02)

- Repository and agent environment: complete.
- Godot project configuration and bootstrap scene: complete.
- Phase 2 cannon and projectile sandbox: complete.
- Phase 3 authoritative paint system: complete.
- Phase 4 stage loop, cameras, and gameplay HUD: complete.
- Phase 5 Burst, Splitter, and Bumper: complete.
- Phase 6 three-stage content, progression/save, replay, and agent API: complete.
- Phase 7 application UI and presentation: complete.
- Phase 8 debugging, delivery, and final QA: complete.

## Current Redesign Risks

- Godot is not currently on PATH. The user approved the discovered Godot 4.7.1
  console executable for Paint Mountain headless verification/export commands
  only; no visible editor or game launch is authorized outside the two
  explicitly coordinated evidence sessions.
- Stage 1 currently has an MVP permit, not the exhaustive all-target
  `DirectReachabilityCertificate` required for release. Do not label the stage
  fully certified or use the permit to satisfy export/final-delivery gates.
- Stage 2 and Stage 3 have version-4 structural inputs but no accepted permit or
  full certificate. Production generation intentionally rejects them until
  Phase 2 supplies their exact target, reachability, balance, and containment
  evidence.
- The core loop is headlessly proven, but the current terrain composition, HUD,
  camera framing, collision readability, and running paint appearance have not
  passed the user-coordinated visual gate. Do not infer visual acceptance from
  headless physics results or concept images.
- The complete legacy `scripts/test.ps1` matrix is not yet a passing release
  gate: its Stage 2/3 prediction/reliability assumptions predate fail-closed
  admission, and the all-target Phase-5 fixture remains pathologically slow.
  The focused Stage 1/contact/paint/state/schema tests and `scripts/verify.ps1`
  pass; performance and broad test migration remain parked behind the MVP.
- Targets and shot counts remain fixed at `4%/4`, `27%/5`, and `70%/6`.
  Superseded direct-target solutions and old checksums are historical only.
- The generated Windows executable is unsigned and `builds/` is ignored; distribution signing and packaging are outside this vertical-slice scope.
- The imported low-poly models, UI icons, particles, and procedural audio are
  approved inputs, but neither they nor the concept board prove the active
  physical terrain, paint, HUD, or presentation contracts.

## Verification

### Current Stage 1 MVP verification (2026-08-03)

- `stage1_mvp_test.gd` passed against the real gameplay scene and owners: first
  `terrain/top` contact, `5.100 s` target contact, `36.688 m` parent surface
  path, `306` continuous sweeps, `18.8140%` coverage, drain-before-result, and
  deterministic Restart.
- `stage_mvp_permit_producer.gd --verify-only` reproduced accepted seed
  `845487911`, default aim stable key `-6:591:67`, and predictor/rigid-body
  local hits within one millimeter of each other near the target centroid. The
  stored proof checksum binds the exact layout, aim, and both hit witnesses; an
  aim-only substitution fails closed.
- Focused contact and paint gates passed: `projectile_contact_test.gd`,
  `projectile_settling_test.gd`, `containment_wall_test.gd`,
  `paint_queue_determinism_test.gd`, `phase3_paint_test.gd`, and
  `phase3_projectile_paint_test.gd`.
- Focused state and consumer gates passed: `phase4_state_test.gd`,
  `shot_observation_test.gd`, `replay_presentation_test.gd`,
  `shot_feedback_test.gd`, `localization_ui_test.gd`, and
  `phase8_debug_test.gd`. A rejected authoritative paint command is preserved in
  the sealed observation and forces `STAGE_FAILED`.
- `scripts/verify.ps1` passed headless project import/script parsing and
  main-scene startup with Godot `4.7.1.stable.official.a13da4feb`. No visible
  Godot window or retained Godot process was used.

### Historical verification for superseded or pre-MVP builds

- Active redesign Task 02: `stage_generation_test.gd` passed base and
  fallback-request determinism for all stages. Fallback requests accepted at
  attempts `0 / 5 / 28`; eligible ratios remained `0.423386 / 0.446671 /
  0.414547`. `mechanism_placement_test.gd` passed exact role/centerline/shelf,
  transform, tangent, physical-clearance, visibility, and fixed-point rejection
  gates. `decoration_placement_test.gd` passed deterministic `10 / 14 / 18`
  placements. All checks used Godot 4.7.1 headlessly.
- Active redesign Task 03: `terrain_geometry_test.gd` proved the exact
  `7,394`-triangle production shell, flat winding, normalized watertight edge
  ownership, `≤0.01 m` heightmap parity, stable gameplay nodes, shader
  constraints, and all four direct fixture casts. The migrated
  `phase2_physics_test.gd`, `phase2_test.gd`, `phase3_paint_test.gd`, and
  `phase5_mechanism_test.gd` passed, followed by `scripts/verify.ps1` and a
  30-frame headless main-project startup.
- Active redesign Task 04: `projectile_contact_test.gd` passed 20 repetitions
  each of flat, 35-degree ramp, high-speed graze, and skirt impacts (80/80),
  exact collider/shape identity, measured point/normal/radius tolerances, and
  separated recontact debounce. `phase3_paint_test.gd` produced exactly 3,228
  visible/scored pixels and 1.231384% coverage, zero second-stamp gain, no
  opposite-cliff or ineligible writes, and bounded synchronous flow.
  `phase3_projectile_paint_test.gd` accepted 112/112 physical requests, consumed
  329.4 of 520 payload only after contact, and reached 4.2039% coverage with no
  ineligible pixels. Phase 2 ballistics/fixture and Phase 4 state regressions
  also passed headlessly.
- Active redesign Task 09 partial gate: the ordered `scripts/test.ps1` passed
  terrain geometry, generation, placement, decoration, ballistics, contact,
  authoritative paint, production projectile-paint, state, and mechanism
  tests before stopping at the intentional Stage 2/3 empty-solution assertions.
  Its `finally` block then completed both persistence and replay cleanup
  processes. The production integration measured 111/111 accepted requests,
  295.4 consumed payload, and 4.1488% coverage. Separate strengthened probes
  measured a 2.686 ms slowest restart and, at 1920x1080 headlessly, 594.76 ms
  load, 145.05 unpaced average FPS, 10.19 ms worst frame, one active ball, and
  43.19 MiB static memory. `phase6_solution_test.gd` validated the recorded
  First Descent shot at 5.335% under the normal 60 Hz path.

- Final tested engine: Godot `4.7.1.stable.official.a13da4feb`, Windows Compatibility renderer, Intel Iris Xe, fixed 60 Hz physics.
- Final 2026-08-03 regression: every Phase 2–8 check plus `stage_generation_test.gd`, `mechanism_placement_test.gd`, `aim_interaction_test.gd`, and `localization_ui_test.gd` passed. `scripts/verify.ps1` passed after final scene/resource/script changes.
- Generation: First Descent attempt 1/166 ms, Burst Basin attempt 2/236 ms, Split Ridge attempt 30/1,878 ms; repeated checksums matched. Physical clears were 5.791%, 33.470%, and 74.359%; the Stage 3 left-route-only guard failed at 4.353%.
- Persistence/replay: format-2 save preserved explicit English selection across a fresh process; replay first-impact and coverage deltas were both zero.
- Reliability/performance: 30 cycles left no projectile nodes; slowest restart was 2.056 ms. The final 1920×1080 Burst workload loaded in 459.79 ms, averaged 60.00 FPS, recorded a 20.18 ms worst frame, used 50.70 MiB static memory, and kept the observed active count within the tested bound. A confirming verbose run exited without the first run's transient two-instance ObjectDB warning.
- Production: the release preset exported `builds/windows/PaintMountain.exe`; the registered fastrun command `& '.\builds\windows\PaintMountain.exe'` starts it. That executable generated the seven final 1920×1080 Korean-default screenshots, all individually inspected without the debug overlay.
- Run: `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath <path-to-Godot-console.exe>`
- Phase 2 pure check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_test.gd`
- Phase 2 rigid-body check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_physics_test.gd`
- Observed 2026-08-02 after final preview validation: 31 deterministic ballistic samples matched exactly; two repeated rigid-body shots physically impacted and settled within 0.01632 m in the final batch (0.25 m tolerance), while the radius-aware preview was within 1.62103 m of the physical first impact.
- Phase 3 mask check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase3_paint_test.gd`
- Phase 3 integration check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase3_projectile_paint_test.gd`
- Observed 2026-08-02 after stage tuning: overlap remained 0.3802%; bounded flow increased a 0.015406% direct stamp to 0.043754%; one physical shot emitted 57 finite requests, accepted 8 terrain-aligned deposits, and produced 1.3274% authoritative coverage.
- Phase 4 state check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase4_state_test.gd`
- Phase 4 render helper: `Godot_v4.7.1-stable_win64_console.exe --path . --resolution 1280x720 --script res://tests/capture_gameplay_frame.gd -- --state=aiming --output=<path>`
- Observed 2026-08-02: the live shot traversed every intermediate state and returned to aim below target; duplicate fire was rejected; restart cleared paint/projectiles/refilled shots in 0.452 ms; pure clear/failure boundary checks passed; 1280×720 briefing and aiming captures showed no HUD clipping after one overlap correction.
- Phase 5 mechanism check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase5_mechanism_test.gd`
- Observed 2026-08-02 after content tuning: physical Burst collision added 24.0171% and spent one charge; Splitter produced three generation-one children totaling 468/520 payload; Bumper redirected one retained projectile; reset, duplicate, recursion, and eight-ball guards passed.
- Phase 6 content check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase6_content_test.gd`
- Phase 6 solution check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase6_solution_test.gd -- --stage=<stage_id>`
- Observed 2026-08-02: the catalog loaded exactly three stages; atomic save fallback, unlock updates, two-shot replay serialization/control, and UI-independent agent actions passed. Final byte-mask physical clears reached 4.128% for First Descent, 27.306% for Burst Basin with Burst activation, and 76.796% for Split Ridge after both Bumper and Splitter activation.
- Phase 7 UI check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase7_ui_test.gd`
- Observed 2026-08-02: menu, stage select, settings return paths, gameplay briefing, pause, clear result, and gameplay cleanup passed through the real app shell. Rendered captures at 1280×720, 1600×900, and fullscreen 1920×1080 showed no panel clipping; the bright faceted mountain, foreground cannon, trajectory, markers, buttons, and hierarchy remained legible.
- Observed 2026-08-02: the post-presentation regression batch passed Phase 2–7 checks and all three physical solutions without recurring headless errors; Phase 4 restart measured 1.080 ms under the concurrent batch.
- Phase 8 debug check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase8_debug_test.gd`
- Observed 2026-08-02: the overlay was hidden by default, exposed every specified live metric, four mask views, and ten actions in debug builds, and exported a complete stage/seed/aim/gain/mechanism/outcome JSON log.
- Phase 8 fresh-process persistence: run `phase8_persistence_test.gd` in `write`, `read`, then `cleanup` modes. Three unlocks, Split Ridge 77.921%/one star, master volume 0.43, and high quality survived the second process.
- Phase 8 fresh-process replay: run `phase8_replay_process_test.gd` in `record`, `replay`, then `cleanup` modes. The replay reproduced first impact with 0.00000 m delta and coverage with 0.00000 percentage-point delta.
- Phase 8 reliability: `phase8_reliability_test.gd` passed 30 fire/restart/out-of-bounds cycles with no projectile nodes, verified empty-payload and lifetime paths, and measured a 1.589 ms slowest restart in the final batch. The Phase 5 test separately retained the one-generation/eight-ball split limits and briefing selection intent.
- Phase 8 performance: fullscreen 1920×1080 Compatibility rendering on Intel Iris Xe loaded Burst Basin in 355.46 ms and averaged 59.84 FPS over 360 frames; the worst frame was 50.83 ms, static memory was 62.80 MiB, and active balls stayed bounded.
- Phase 8 production check: the `Windows Desktop` release preset built `builds/windows/PaintMountain.exe`, the executable started successfully, and it generated seven separately inspected 1920×1080 PNGs under `screenshots/` with no debug overlay.
- Documentation-only fallback: `git diff --check`
