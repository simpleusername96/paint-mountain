---
type: record
status: active
created: 2026-08-02
last_reviewed: 2026-08-03
scope: implemented project state and durable bootstrap decisions
related:
  - Plan.md
  - execplans/2026-08-03-core-interaction-redesign.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
---

# Project Record

## Current Static-Audit Correction (2026-08-03)

The active implementation authority is
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
claim. Next is Task 02's version-3 generated topology.

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
- `ReplayRecorder` stores ordered aim inputs and gameplay events with play/pause/restart and 1×/2× controls. `GameplayAgentApi` exposes the same validated aim/fire/restart/camera actions and structured observations without HUD or mouse coupling.
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

- The bootstrap and projectile sandbox remain isolated validation scenes; the StageData-selected gameplay scene is the project entry.
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

- Godot is not currently on PATH; local verification needs `-GodotPath` or a `GODOT_BIN` environment variable.
- The version-3 generator, physical contact/deposit path, manual aim predictor,
  mechanism bodies, replay format 3, and scene-based UI are not implemented
  until their active ExecPlan tasks pass.
- Generation remains bounded to 32 derived attempt seeds plus one pinned
  fallback and must fail closed; new accepted checksums and solutions cannot be
  copied from the superseded build.
- Targets and shot counts remain fixed at 4%/4, 27%/5, and 70%/6. Prior
  direct-target solution values are historical and cannot validate manual aim.
- Replay must be revalidated in fresh processes after format-3 action-origin
  locking is implemented.
- The generated Windows executable is unsigned and `builds/` is ignored; distribution signing and packaging are outside this vertical-slice scope.
- The imported low-poly models, UI icons, particles, and procedural audio meet the scoped vertical-slice presentation contract but are not a substitute for a later bespoke production-art/audio pass.

## Verification

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
