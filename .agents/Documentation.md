---
type: record
status: active
created: 2026-08-02
scope: implemented project state and durable bootstrap decisions
related:
  - Plan.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
---

# Project Record

## Context

The repository was created from a complete vertical-slice brief. The current milestone includes the verified projectile, authoritative paint, gameplay loop, cameras, HUD, exactly three mechanisms, three tuned stages, progression/save foundations, replay, and the UI-independent agent interface.

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
- Presentation uses dependency-free low-poly dressing, a subtle unshaded terrain treatment, an eight-emitter paint-particle pool, bounded camera shake, and runtime-generated PCM music/SFX routed through Master/Music/SFX buses.
- Product behavior, technical ownership, planned work, and implemented status are stored separately to avoid treating plans as working features.

## Rationale

- A small real scene gives the next implementation phase a verified engine baseline without pretending the vertical slice already exists.
- The provided brief already locks the engine, core architecture, mechanisms, scope exclusions, performance target, and acceptance artifacts.
- Compatibility rendering and dependency-free procedural primitives keep the initial project portable on modest Windows hardware.

## Consequences

- The bootstrap and projectile sandbox remain isolated validation scenes; the StageData-selected gameplay scene is the project entry.
- Main menu, stage select, briefing, aiming/observation, result, pause, full settings, all three mechanisms, progression, persistence foundations, replay, agent actions, generated audio, pooled particles, and restrained camera feedback run and have focused checks. Release debug tooling, export, performance evidence, and the required final screenshots remain.
- Future feature completion claims must cite running-game checks and update this record.

## Current Status

- Repository and agent environment: complete.
- Godot project configuration and bootstrap scene: complete.
- Phase 2 cannon and projectile sandbox: complete.
- Phase 3 authoritative paint system: complete.
- Phase 4 stage loop, cameras, and gameplay HUD: complete.
- Phase 5 Burst, Splitter, and Bumper: complete.
- Phase 6 three-stage content, progression/save, replay, and agent API: complete.
- Phase 7 application UI and presentation: complete.
- Phase 8: not started.

## Known Risks

- Godot is not currently on PATH; local verification needs `-GodotPath` or a `GODOT_BIN` environment variable.
- Final targets and recorded solutions are physically validated at 4%, 27%, and 70%; wider playtesting may still reveal alternative balance preferences.
- The Phase 2 deterministic check measured 0.12567 m between repeated first-contact positions at an accelerated 2× test rate. A full replay coverage-tolerance run remains a Phase 8 delivery check.
- The current low-poly material has strong facet contrast and still needs Phase 7 art cleanup; functional Phase 4 captures passed layout and composition but are not final delivery screenshots.
- Mechanism audio/particles are intentionally deferred to the Phase 7 presentation batch; Phase 5 provides distinct silhouettes and spent transparency only.

## Verification

- Run: `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath <path-to-Godot-console.exe>`
- Phase 2 pure check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_test.gd`
- Phase 2 rigid-body check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_physics_test.gd`
- Observed 2026-08-02: import/runtime smoke passed; 31 deterministic ballistic samples matched exactly; two repeated rigid-body shots physically impacted, settled, and differed by 0.12567 m at first contact.
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
- Observed 2026-08-02: the catalog loaded exactly three stages; atomic save fallback, unlock updates, two-shot replay serialization/control, and UI-independent agent actions passed. End-to-end replay coverage tolerance remains a Phase 8 check. Recorded physical clears reached 4.149% for First Descent, 27.310% for Burst Basin with Burst activation, and 77.921% for Split Ridge after both Bumper and Splitter activation.
- Phase 7 UI check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase7_ui_test.gd`
- Observed 2026-08-02: menu, stage select, settings return paths, gameplay briefing, pause, clear result, and gameplay cleanup passed through the real app shell. Rendered captures at 1280×720, 1600×900, and fullscreen 1920×1080 showed no panel clipping; the bright faceted mountain, foreground cannon, trajectory, markers, buttons, and hierarchy remained legible.
- Observed 2026-08-02: the post-presentation regression batch passed Phase 2–7 checks and all three physical solutions without recurring headless errors; Phase 4 restart measured 1.080 ms under the concurrent batch.
- Documentation-only fallback: `git diff --check`
