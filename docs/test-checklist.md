---
type: spec
status: active
created: 2026-08-02
canonical_for: Paint Mountain vertical-slice acceptance and delivery evidence
scope: automated, manual, performance, persistence, and screenshot validation
source: user-provided Paint Mountain acceptance criteria
related:
  - design-spec.md
  - technical-architecture.md
  - ../.agents/Plan.md
---

# Test Checklist

## Purpose

Define the observable checks required before the vertical slice may be reported complete. An unchecked item is not an implemented claim.

## Scope

Run narrow checks throughout development, then complete this full checklist against a production-style Windows build or the strongest explicitly documented substitute.

## Requirements and Acceptance Criteria

### Bootstrap baseline

- [x] Repository is a Git worktree with scoped agent guidance and an active implementation plan.
- [x] Godot imports the project headlessly without script or resource errors.
- [x] The configured main scene starts and exits cleanly in a headless smoke run.
- [x] The bootstrap scene visibly distinguishes itself from completed gameplay.

### Gameplay loop

- [ ] Main menu and stage select start all three stages.
- [ ] Briefing camera supports constrained terrain inspection and mechanism selection.
- [ ] Cannon yaw, elevation, and power input work; firing consumes exactly one shot.
- [ ] Initial trajectory and first-hit preview closely match actual unchanged launch physics.
- [ ] High-speed projectile collision uses CCD and does not tunnel through the terrain.
- [ ] Ball bounces, rolls, slides, deposits paint, and terminates by every configured condition.
- [ ] Firing remains disabled until all parent/child projectiles and paint flow settle.
- [ ] Shot coverage gain appears before returning to aim, clear, or failure.
- [ ] Coverage at/above target clears; exhausted shots below target fail.
- [ ] Retry, next stage, stage select, and replay execute from the correct result states.
- [ ] Confirmed restart reaches a clean playable state in under one second.

### Paint and coverage

- [ ] Terrain visuals and coverage use the same runtime paint mask.
- [ ] Eligible mask excludes platform, background, underside, mechanisms, decorations, and bounds.
- [ ] Overlapping stamps never double-count coverage.
- [ ] Impact splash, motion trail, payload width reduction, downhill rivulet, and final puddle are finite and readable.
- [ ] Empty-payload projectiles stop contributing paint and deactivate correctly.
- [ ] Coverage updates several times per second without full-mask per-frame readback.
- [ ] Debug views accurately show eligible, painted, excluded, recent stamps, and numeric coverage.

### Mechanisms

- [ ] Burst activates once by physical hit, paints the authoritative mask, and shows a spent state.
- [ ] Splitter consumes the parent, emits three controlled-payload fan children, and cannot recurse beyond one generation.
- [ ] Bumper applies its visible directional impulse without consuming the ball and respects cooldown.
- [ ] One collision cannot duplicate an activation.
- [ ] Restart resets charges, cooldowns, visuals, timers, and children.
- [ ] Active paintballs never exceed eight.
- [ ] No fourth mechanism appears in the MVP.

### Stages and composition

- [ ] First Descent teaches forgiving impact/roll/coverage and has a recorded reliable clear.
- [ ] Burst Basin rewards the upper Burst route and has a recorded reliable clear.
- [ ] Split Ridge offers safe/inefficient and difficult/high-value routes, uses Splitter plus Bumper, targets about 70%, and has a recorded reliable clear.
- [ ] Stage values are loaded from StageData resources, not stage-specific global code.
- [ ] Aiming camera keeps the cannon in the lower foreground at about 15–20% or less of the frame.
- [ ] Mountain dominates the middle/upper frame and reads as a distant large landform.
- [ ] Major routes and mechanisms are legible without absurd scale; cameras do not clip through terrain.

### UI, settings, feedback, and accessibility architecture

- [ ] Main menu, stage select, briefing, aiming/observation, clear, failure, pause, and settings are separate usable screens.
- [ ] Target, current coverage, and shots remaining maintain the top information hierarchy.
- [ ] Gameplay controls reduce during observation and result panels leave the mountain readable.
- [ ] Anchored/container layouts do not clip or overflow at 1280×720, 1600×900, or 1920×1080.
- [ ] Settings persist master/music/SFX volume, shake, follow camera, trajectory, fullscreen, resolution, quality, and language key.
- [ ] Required sound cues, restrained shake, and pooled particles trigger without recurring console errors.
- [ ] No shop, currency, monetization, story, inventory, multiplayer, or live-service UI exists.

### Save, replay, agent API, and debug

- [ ] Unlocks, best coverage, best stars, and settings survive a normal process restart.
- [ ] Invalid save data falls back safely without blocking play.
- [ ] Replay stores stage/version/seed and ordered aim inputs and reproduces the attempt within defined tolerance.
- [ ] Replay supports play, pause, restart, 1×, and 2×.
- [ ] In-process observation/action/event API operates without mouse input or screen reading.
- [ ] Debug overlay contains every specified metric and action and is disabled by default in release.
- [ ] Shot-result log export contains stage, seed, aim, gains, activations, and settlement outcome.

### Reliability and performance

- [ ] Repeated identical shots on an unchanged stage stay within the documented trajectory and coverage tolerance.
- [ ] Repeated restart/out-of-bounds/split-limit tests leave no orphan projectiles or timers.
- [ ] Large paint and Burst events cause no major frame-rate collapse or unbounded allocation.
- [ ] Stage loads preferably under three seconds and gameplay sustains 60 FPS at 1920×1080 on the test machine; measured results are recorded.
- [ ] Normal play produces no recurring console errors.
- [ ] Windows export builds and starts through its documented production entry path.

### Deliverables

- [ ] README reports the final engine version, launch, controls, structure, and known limitations.
- [ ] Design specification, technical architecture, test results, performance observations, remaining issues, next step, and changed-file summary are current.
- [ ] `01_main_menu.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] `02_stage_select.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] `03_stage_briefing.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] `04_aiming.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] `05_projectile_and_paint_flow.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] `06_stage_clear.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] `07_stage_failed.png` is a separate 1920×1080 running-game image without debug overlay.
- [ ] Screenshots are not a collage, contact sheet, poster, or infographic.
