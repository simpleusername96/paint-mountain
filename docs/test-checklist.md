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
---

# Test Checklist

## Purpose

Define the observable checks required before the game may be reported complete. An unchecked item is not an implemented claim. Checks marked complete before the 2026-08-03 remediation remain historical baseline evidence; they do not satisfy the new unchecked remediation release gate.

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

### Remediation release gate (2026-08-03)

Generated terrain and placement:

- [x] Each stage generates from its frozen profile/base seed through the deterministic 32-attempt sequence or separately validated fallback, and repeated runs produce the same accepted seed and height-grid checksum.
- [x] One immutable generated layout supplies mesh, collision, paint height queries, eligible-mask inputs, decorations, mechanisms, replay metadata, and agent height observations; no fixed stage height function or second terrain representation remains.
- [x] First Descent, Burst Basin, and Split Ridge pass their exact route-count, width, meaningful-reversal, slope, edge-height, eligible-area, shelf, height, and 6,144-triangle checks.
- [x] Deterministic mechanism placement passes slope, spacing, bounds, route clearance, camera line-of-sight, projected-size, downstream-value, orientation, and stable tie-break checks without authored production X/Z fallback.
- [x] Stage 1 has no mechanism; Stage 2 has one Burst; Stage 3 has one Splitter and one Bumper, with all three distinct 3D silhouettes readable in both briefing and aiming captures.
- [x] Approved sparse nature dressing uses only the five manifest GLBs, stays outside route/mechanism clearance, does not affect collision, and preserves route readability.

Aiming and controls:

- [x] Cursor hover, left-click lock, held drag retarget, and mechanism-center targeting work through `AimInputController`; `CannonController` contains no device polling.
- [x] The target solver uses the real 60 Hz gravity/damping/radius/collision model, returns the lowest valid elevation, rejects unreachable/occluded first impacts, and actual collision lands within 1.25 m of the selected target.
- [x] Invalid aim has red plus non-color feedback, retains the last valid cannon pose, disables Fire, and cannot consume a shot through mouse, keyboard, replay, debug, or agent paths.
- [x] Power minus/plus click, 300 ms hold delay, 80 ms repeat, wheel 1%, keyboard 2%, Space fire, and accessible A/D/W/S angle fallback match the frozen steps and do not double-fire.
- [x] At most 72 pooled trajectory dots and the distance-scaled impact marker remain legible through the actual first collision at 1280×720, 1600×900, and 1920×1080, with no post-impact route or coverage prediction.

Korean UI, visual direction, and approved assets:

- [x] Fresh saves and migrated V1 saves open in Korean; `ko`/`en` switching is immediate, complete, glyph-safe, and persistent after a fresh process; StageData and mechanisms store translation keys rather than display strings.
- [x] Pretendard 500/700/800 typography, frozen palette, card radii, minimum 40 px controls, focus outline, Korean wrapping, and disabled/invalid states apply coherently across menu, stage select, briefing, aiming, observation, results, pause, and settings.
- [x] The aiming HUD matches the frozen edge regions at all three resolutions: top stage/target/shots, mode chip, bottom-left aim/power, bottom-center coverage, bottom-right restart/fire, with no clipping, overflow, unsupported text-symbol icon, or center modal.
- [x] Terrain reads as a bright thick faceted/terraced mountain; paint reads as thick glossy blue routes; the cannon remains small; mechanisms remain visible; composition is compared directly with the supplied reference capture.
- [x] Only the exact 16 approved runtime files are present, every pinned file hash passes, four license texts are included, and `docs/asset-licenses.md` records official URL/version/hash/destination/use. The release works fully offline.

Regression, solutions, and delivery:

- [x] The deterministic beam-search verification clears targets `4/27/70%` within `4/5/6` shots and the Stage 3 left-route-only path remains below 70%, without weakening projectile/mechanism/paint rules.
- [x] Existing projectile, paint, state, mechanism, content, save, replay, UI, debug, reliability, and performance checks pass after migration; format-2 replay validates profile/seed/checksum and deterministic shot results.
- [x] `scripts/verify.ps1` passes after the final scene/resource/project changes, and the Windows release export starts through the already registered fastrun command `& '.\builds\windows\PaintMountain.exe'`.
- [x] Fresh release-build screenshots replace all seven named files, are individually inspected at 1920×1080 without debug overlay, and include Korean/default UI plus the required gameplay states.
- [x] Final production evidence records generation attempts/time, load/restart time, average FPS, worst frame, memory, active-ball cap, persistence/replay results, console review, known limitations, and the exact tested Godot build.

## Observed Remediation Evidence (2026-08-03)

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
