---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-03
canonical_for: Paint Mountain vertical-slice acceptance and delivery evidence
scope: automated, manual, performance, persistence, and screenshot validation
source: source-brief.md
related:
  - source-brief.md
  - design-spec.md
  - technical-architecture.md
  - ../.agents/Plan.md
  - ../.agents/execplans/2026-08-03-core-interaction-redesign.md
---

# Test Checklist

## Purpose

Define the observable checks required before the game may be reported complete.
An unchecked item is not an implemented claim. All checked items above the
active redesign gate and all dated observations below it are historical
evidence for superseded builds; they do not satisfy the new unchecked gate.

## Scope

Run narrow checks throughout development, then complete this full checklist against a production-style Windows build or the strongest explicitly documented substitute.

## Requirements and Acceptance Criteria

### Bootstrap baseline

- [x] Repository is a Git worktree with scoped agent guidance and an active implementation plan.
- [x] Godot imports the project headlessly without script or resource errors.
- [x] The configured main scene starts and exits cleanly in a headless smoke run.
- [x] The bootstrap scene visibly distinguishes itself from completed gameplay.

### Gameplay loop

- [x] Main menu and stage select start all three stages.
- [x] Briefing camera supports constrained terrain inspection and mechanism selection.
- [x] Cannon yaw, elevation, and power input work; firing consumes exactly one shot.
- [x] Initial trajectory and first-hit preview closely match actual unchanged launch physics.
- [x] High-speed projectile collision uses CCD and does not tunnel through the terrain.
- [x] Ball bounces, rolls, slides, deposits paint, and terminates by every configured condition.
- [x] Firing remains disabled until all parent/child projectiles and paint flow settle.
- [x] Shot coverage gain appears before returning to aim, clear, or failure.
- [x] Coverage at/above target clears; exhausted shots below target fail.
- [x] Retry, next stage, stage select, and replay execute from the correct result states.
- [x] Confirmed restart reaches a clean playable state in under one second.

### Paint and coverage

- [x] Terrain visuals and coverage use the same runtime paint mask.
- [x] Eligible mask excludes platform, background, underside, mechanisms, decorations, and bounds.
- [x] Overlapping stamps never double-count coverage.
- [x] Impact splash, motion trail, payload width reduction, downhill rivulet, and final puddle are finite and readable.
- [x] Empty-payload projectiles stop contributing paint and deactivate correctly.
- [x] Coverage updates several times per second without full-mask per-frame readback.
- [x] Debug views accurately show eligible, painted, excluded, recent stamps, and numeric coverage.

### Mechanisms

- [x] Burst activates once by physical hit, paints the authoritative mask, and shows a spent state.
- [x] Splitter consumes the parent, emits three controlled-payload fan children, and cannot recurse beyond one generation.
- [x] Bumper applies its visible directional impulse without consuming the ball and respects cooldown.
- [x] One collision cannot duplicate an activation.
- [x] Restart resets charges, cooldowns, visuals, timers, and children.
- [x] Active paintballs never exceed eight.
- [x] No fourth mechanism appears in the MVP.

### Stages and composition

- [x] First Descent teaches forgiving impact/roll/coverage and has a recorded reliable clear.
- [x] Burst Basin rewards the upper Burst route and has a recorded reliable clear.
- [x] Split Ridge offers safe/inefficient and difficult/high-value routes, uses Splitter plus Bumper, targets about 70%, and has a recorded reliable clear.
- [x] Stage values are loaded from StageData resources, not stage-specific global code.
- [x] Aiming camera keeps the cannon in the lower foreground at about 15–20% or less of the frame.
- [x] Mountain dominates the middle/upper frame and reads as a distant large landform.
- [x] Major routes and mechanisms are legible without absurd scale; cameras do not clip through terrain.

### UI, settings, feedback, and accessibility architecture

- [x] Main menu, stage select, briefing, aiming/observation, clear, failure, pause, and settings are separate usable screens.
- [x] Target, current coverage, and shots remaining maintain the top information hierarchy.
- [x] Gameplay controls reduce during observation and result panels leave the mountain readable.
- [x] Anchored/container layouts do not clip or overflow at 1280×720, 1600×900, or 1920×1080.
- [x] Settings persist master/music/SFX volume, shake, follow camera, trajectory, fullscreen, resolution, quality, and language key.
- [x] Required sound cues, restrained shake, and pooled particles trigger without recurring console errors.
- [x] No shop, currency, monetization, story, inventory, multiplayer, or live-service UI exists.

### Save, replay, agent API, and debug

- [x] Unlocks, best coverage, best stars, and settings survive a normal process restart.
- [x] Invalid save data falls back safely without blocking play.
- [x] Replay stores stage/version/seed and ordered aim inputs and reproduces the attempt within defined tolerance.
- [x] Replay supports play, pause, restart, 1×, and 2×.
- [x] In-process observation/action/event API operates without mouse input or screen reading.
- [x] Debug overlay contains every specified metric and action and is disabled by default in release.
- [x] Shot-result log export contains stage, seed, aim, gains, activations, and settlement outcome.

### Reliability and performance

- [x] Repeated identical shots on an unchanged stage stay within the documented trajectory and coverage tolerance.
- [x] Repeated restart/out-of-bounds/split-limit tests leave no orphan projectiles or timers.
- [x] Large paint and Burst events cause no major frame-rate collapse or unbounded allocation.
- [x] Stage loads preferably under three seconds and gameplay sustains 60 FPS at 1920×1080 on the test machine; measured results are recorded.
- [x] Normal play produces no recurring console errors.
- [x] Windows export builds and starts through its documented production entry path.

### Deliverables

- [x] README reports the final engine version, launch, controls, structure, and known limitations.
- [x] Design specification, technical architecture, test results, performance observations, remaining issues, next step, and changed-file summary are current.
- [x] `01_main_menu.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] `02_stage_select.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] `03_stage_briefing.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] `04_aiming.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] `05_projectile_and_paint_flow.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] `06_stage_clear.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] `07_stage_failed.png` is a separate 1920×1080 running-game image without debug overlay.
- [x] Screenshots are not a collage, contact sheet, poster, or infographic.

### Core interaction redesign release gate (active 2026-08-03)

Generated terrain and placement:

- [ ] Every stage uses a version-3 path-first generator with the fixed draw order, 32 derived attempt seeds, one pinned fallback, and repeatable accepted layout/checksums.
- [ ] One immutable `GeneratedStageLayout` supplies the height grid, routes, eligibility inputs, decoration/mechanism placement, replay metadata, and agent observations.
- [ ] First Descent, Burst Basin, and Split Ridge prove route reversal progression `0`, `2/2`, and `2/4/4`, plus all fixed height, slope, spacing, shelf, edge, and eligibility metrics.
- [ ] Mechanisms use exact role-owned centerline shelf transforms; an invalid fixed transform rejects the candidate and no scoring/authored X/Z fallback exists.
- [x] The mountain renders as a closed lit shell with exactly 6,912 top, 480 skirt, and 2 bottom triangles while a separate heightmap top collider and skirt/bottom collider match within 0.01 m.
- [ ] Top, ramp, graze, and skirt fixture casts classify the correct collider body; every intended solution records zero penetration-guard events.

Physical contact, paint, and mechanisms:

- [x] `PaintProjectile` reports real direct-body contact point, normal, collider, shapes, impulse, incoming velocity, and deterministic first-contact ordering; it never fabricates world-up impact data.
- [x] All four high-speed terrain fixtures pass 20 real-projectile repetitions with the fixed point/normal/radius/collider tolerances and no tunneling.
- [x] Persistent paint is accepted only through `PaintDepositRequest` on connected eligible top terrain reconstructed in 3D; visible mask pixels and scored pixels are identical.
- [x] The fixed flat paint fixture stamps exactly 3,228 threshold pixels for one radius-4/amount-22 trail request and gains zero coverage on an identical second request.
- [x] Burst, Splitter, and Bumper use matching compound `StaticBody3D` primitives with no gameplay activation `Area3D`; preview and real ball strike the same body/shape.
- [x] Burst uses the authoritative deposit path, Splitter emits exactly three generation-1 children with 90% total remaining payload, and Bumper applies its queued corrective impulse along the displayed tangent.
- [x] Contact debounce prevents duplicate activation while permitting a separated later strike; reset restores all mechanism/projectile state and active balls never exceed eight.

Manual aiming and prediction:

- [x] Terrain clicks never alter aim; empty-viewport drag, A/D, W/S, wheel, power buttons, Space, and Tab follow the fixed independent mappings, clamps, repeat timings, and UI-consumption boundary.
- [x] `ImpactTargetSolver` and every production/test reference to it are removed.
- [x] Every stage's ten frozen aim tuples plus mechanism/bounds fixtures produce a complete collision or bounds-exit prediction with at most 96 dots and no post-impact behavior.
- [x] Predicted and measured first contact differ by at most 2.0 m; collision markers use the measured normal, bounds exits use a red cross, and predictor timeout cannot fire.

Shot causality, camera, and replay:

- [ ] One sealed `ShotObservation` owns commanded aim, ordered contacts/mechanisms, child and payload facts, settlement reasons, coverage delta, and penetration-guard count.
- [ ] A shot settles only after projectiles and paint flow are inactive for two consecutive physics ticks, and HUD/replay/agent consumers do not reconstruct outcomes.
- [ ] Every named camera fixture maintains at least 1.5 m terrain clearance and avoids terrain occlusion except within the final 0.25 m of a terrain focus.
- [ ] Replay format 3 records deterministic actions and expected observations, rejects format 2, and reproduces contact within 0.5 m, coverage within 0.1 percentage point, exact mechanism order, and final state in a fresh process.
- [ ] Replay presentation disables all human/agent/debug gameplay mutation and accepts only replay-origin actions until a clean exit.

Korean UI, visual direction, and approved assets:

- [ ] The logical viewport is 1280×720 with canvas-items stretch; component scenes and one Theme own layout/style while HUD scripts only coordinate behavior.
- [ ] Fresh saves default to Korean; Korean/English switching is complete, immediate, glyph-safe, and persistent, and mechanism/shot copy uses translation keys.
- [ ] Pretendard, fixed color/type/radius tokens, visible focus, 40 px ordinary controls, Korean wrapping, and all reachable UI states pass at 1280×720, 1600×900, and 1920×1080.
- [ ] Every aiming-HUD component matches its frozen edge rectangle within 2 px at 1280×720 and 3 px at the scaled resolutions; no clipping, overflow, offscreen action, center modal, or body text below 16 px exists.
- [ ] Terrain is lit/faceted and physically thick, paint is glossy blue with dry/paint roughness 0.88/0.24 and no emission, the cannon remains small, and mechanisms remain readable without persistent gameplay labels.
- [ ] Only the already approved committed Kenney/Pretendard assets are used; no new dependency, asset pack, or runtime network access exists.

Regression, solutions, and delivery:

- [ ] `scripts/test.ps1` runs the active ordered tests and fresh-process persistence/replay matrices through one explicit Godot path with cleanup on failure.
- [ ] The deterministic beam search clears targets `4/27/70%` within `4/5/6` manual-aim shots, activates required Stage 3 mechanisms, and proves six safe-route-only shots remain below 70%.
- [ ] Obsolete sandbox, target solver, duplicate terrain factory, code-built `UIFactory`, and their references are removed after migration.
- [ ] Complete tests, `scripts/verify.ps1`, import/parse/main-scene smoke, and Windows release export pass without parser errors, invalid calls, orphan nodes, penetration guards, or replay divergence.
- [ ] The 1920×1080 Iris Xe workload loads within 3 s, averages at least 60 FPS, has no frame over 33.3 ms, uses at most 128 MiB static memory, restarts within 50 ms, and never exceeds eight balls.
- [ ] After explicit user coordination, the release executable is inspected at all three resolutions and every named briefing/aiming/impact/mechanism/follow/result/replay bookmark passes.
- [ ] Seven fresh separate 1920×1080 running-release screenshots replace the historical images, and final docs record every measured metric, pass/fail, engine build, limitation, and remaining issue.

## Superseded Remediation Evidence (2026-08-03, Historical)

The observations below were produced by the prior direct-target/open-terrain
build. They are retained for traceability and must not be used to check any
active redesign item above.

- Godot `4.7.1.stable.official.a13da4feb` passed import, parse, main-scene smoke, and Windows release export checks with the Compatibility renderer at a fixed 60 Hz physics tick.
- Deterministic generation accepted First Descent on attempt 1 in 166 ms (`seed 845487911`, checksum `3476095321`), Burst Basin on attempt 2 in 236 ms (`seed 1692123947`, checksum `1568157987`), and Split Ridge on attempt 30 in 1,878 ms (`seed 671737323`, checksum `3215880357`). Repeated generation matched each checksum.
- Physical solutions reached 5.791%, 33.470%, and 74.359% for the `4/27/70%` targets. Burst activated in Stage 2; both Splitter and Bumper activated in Stage 3. The six-shot Stage 3 left-route-only guard reached 4.353% and failed below target.
- The final 1920×1080 rendered Burst workload loaded in 459.79 ms, averaged 60.00 FPS over 360 frames, recorded a 20.18 ms worst frame, used 50.70 MiB static memory, and kept the measured active-ball count at one; separate mechanism checks retain the eight-ball hard cap. A second verbose run completed without the transient two-instance exit warning seen in the first process.
- The state test measured a 1.073 ms restart. Thirty reliability cycles left no projectiles and measured a 2.056 ms slowest restart.
- Fresh-process persistence preserved the explicit English locale and selection flag along with progression/results/settings. Fresh-process replay reproduced first impact and coverage with deltas of 0.00000 m and 0.00000 percentage points.
- Korean and English captures were inspected at 1280×720 and 1600×900; settings, pause, menu, stage selection, and aiming controls stayed inside the viewport. Seven final Korean-default release-build images were inspected individually at exactly 1920×1080 with no debug overlay.
- The Windows executable is unsigned and `builds/` remains intentionally ignored. Godot is not assumed to be on `PATH`; verification accepts an explicit `-GodotPath`.

## Observed Legacy Baseline Evidence (2026-08-02)

- Godot 4.7.1 import and main-scene smoke passed through `scripts/verify.ps1`.
- Identical rigid-body shots stayed within 0.25 m at first impact; the shape-cast preview stayed within 1.622 m. Fresh-process replay reproduced first impact and coverage with measured deltas of 0.00000 m and 0.00000 percentage points.
- Fresh-process persistence preserved three unlocks, Split Ridge best coverage/stars, master volume, and quality.
- Thirty repeated fire/restart/out-of-bounds cycles left zero projectile nodes; the slowest final-batch restart was 1.589 ms. Split recursion and the eight-ball limit passed separately.
- At fullscreen 1920×1080 on Intel Iris Xe Compatibility rendering, Burst Basin loaded in 355.46 ms and a 360-frame Burst workload averaged 59.84 FPS, with a 50.83 ms worst frame, 62.80 MiB static memory, and no allocation growth beyond the eight-ball cap.
- The Windows Desktop release export built and started. Its running executable generated the seven separate images under `screenshots/`; every image was verified as exactly 1920×1080 and visually inspected without the debug overlay.
