---
type: spec
status: active
created: 2026-08-02
canonical_for: Paint Mountain vertical-slice product and UX behavior
scope: gameplay, content, presentation, performance, and deliverables
source: user-provided Paint Mountain implementation brief
related:
  - technical-architecture.md
  - test-checklist.md
  - ../.agents/Plan.md
---

# Paint Mountain Design Specification

## Purpose

Define the compact product contract for a polished three-stage vertical slice of a 3D gravity-driven paintball puzzle game.

## Scope

The player inspects a distant mountain, aims a stationary cannon by yaw/elevation/power, fires a finite-payload rigid-body paintball, and watches gravity, terrain, paint flow, and mechanisms produce coverage. After all projectiles and effects settle, the stage clears at its target or continues/fails according to shots remaining.

The vertical slice includes a main menu, stage select, briefing/inspection, aiming, projectile observation, clear/failure, pause, settings, saving, replay, debug tooling, audio/visual feedback, three stages, one ball type, and exactly three mechanism types.

## Requirements

### Experience pillars

- Large readable terrain; predictable but learnable physics; strong causal feedback; sub-second confirmed restart; restrained presentation.
- The challenge is launch planning. The player cannot steer a fired ball.
- An effective shot should produce a legible downhill route or chain reaction and encourage immediate parameter refinement.

### Spatial and camera composition

- Cannon length is roughly 2–3 m; target distance 70–150 m; mountain width 120–250 m and height 60–140 m.
- In the perspective aiming view, the cannon stays in the lower foreground at no more than about 15–20% of the frame; the mountain dominates the middle and upper frame.
- Briefing uses limited three-quarter orbit/zoom; aiming uses roughly 45–55° FOV; observation supports follow, wide terrain, and cannon views; result uses a restrained three-quarter reveal.
- Transitions use smooth 0.3–0.7 second interpolation, avoid terrain clipping and rapid cuts, and widen when split children cannot be read together.

### Controls and information

- Briefing: left-drag orbit, wheel zoom, mechanism selection, Enter/Start to aim, Escape back.
- Aiming: mouse or A/D yaw, mouse or W/S elevation, wheel or Q/E power, Space fire, R restart, Escape pause, Tab inspect.
- Show target, current coverage, shots, angle, power, a dotted initial ballistic arc, and an approximate first impact. Never preview post-impact solution paths or exact coverage.
- During observation, reduce aiming controls and offer camera mode plus optional 1×/2× after landing.

### Stage state

- Authoritative states: `LOADING`, `BRIEFING`, `AIMING`, `PROJECTILE_IN_FLIGHT`, `PAINT_SETTLING`, `SHOT_RESULT`, `STAGE_CLEAR`, `STAGE_FAILED`, `PAUSED`.
- Firing is disabled while any parent/child projectile is active. Coverage finalizes only after projectiles and paint effects settle.
- Shot result briefly shows gained coverage, then clears, fails, or returns to aiming.
- Restart removes projectiles, paint, particles, temporary mechanism state, timers, and camera transitions.

### Projectile and paint

- Rigid bodies use gravity, CCD, bounce, rolling/sliding friction, angular motion, damping, finite payload, bounds/lifetime/slow-stop termination, and fixed-timestep behavior.
- Projectile data owns radius, mass, payload, bounce, friction, damping, lifetime, stop thresholds, stamp/splash radii, deposit rate, and activation cap.
- Airborne travel uses no paint; impact stamps a strength-scaled splash; surface travel stamps by fixed time/distance; stop may leave a finite puddle.
- One 512×512 world X/Z paint mask is the visual and scoring source. A separate eligible mask excludes platform, background, underside, mechanisms, vegetation, rocks, and bounds.
- Coverage is painted eligible pixels above threshold divided by all eligible pixels. Overlap counts once and the UI updates several times per second.
- Optional downhill flow samples lower heightfield neighbors for a small fixed deterministic budget and never becomes a fluid simulation or the primary route.

### Mechanisms

- All mechanisms share data-driven activation, state, cooldown/charges where applicable, feedback, and reset behavior.
- Burst Node: physical hit, normally one charge, direct circular/terrain-aware mask paint, strong splash, visibly spent state.
- Splitter Node: consumes the incoming ball and emits three fan-distributed children at about 30% payload each with about 10% loss; one split generation maximum.
- Bumper Node: applies a visible directional impulse without consuming the ball and uses a cooldown to prevent repeated instability.
- No fourth mechanism is implemented in the vertical slice.

### Stages

- First Descent: broad forgiving slope, no mechanisms, low target, three or four shots.
- Burst Basin: tall ridge, difficult one-charge Burst ledge, broad basin, moderate target, four or five shots.
- Split Ridge: two or three channels, Splitter plus Bumper, safe inefficient low route, valuable difficult high route, five or six shots, target around 70%.
- Each StageData includes identity/name, terrain, cannon transform, camera bookmarks, target/shots/color, mechanisms and states, eligible mask, bounds, star thresholds, best data, and tutorial prompts.
- Every stage has at least one manually verified reliable solution.

### Results, persistence, and replay

- Clear uses coverage only; failure occurs after the last settled shot below target. Stars use stage data and remain understandable.
- Results show stage, final/target coverage, shots used/remaining, previous best, new best, rank/stars, final mountain, retry, next/select, and replay. Failure emphasizes missing coverage and Retry.
- Save version, unlocks, best coverage/stars, and settings locally.
- Replay stores stage/version/seed and ordered yaw/elevation/power; only add low-frequency transform capture if deterministic resimulation proves insufficient.

### UI, art, audio, and debug

- Separate full-screen menu, stage-select, briefing, gameplay, clear, failure, pause, and settings interfaces; anchors/containers support common 16:9 desktop resolutions.
- Use off-white/translucent panels, charcoal/navy text, one saturated paint accent, rounded restrained controls, and a strict information hierarchy: target, coverage, shots, aim/power, actions.
- Use low-poly faceted neutral terrain, sparse scale cues, bright glossy non-emissive blue paint, a dark stylized small cannon, readable white/gray/blue mechanisms, soft daylight, one main directional light, and lightweight effects.
- Provide the specified compact sound set, impact/muzzle/mechanism/clear particles, and small non-continuous shake.
- Release-disabled debug overlay exposes state, FPS, projectile/payload/velocity, coverage gains and masks, preview/collision, mechanisms, seed, bounds, camera, and restart timing plus the specified debug actions.

### Performance and automation

- Target stable 60 FPS at 1920×1080 on modest Windows hardware, restart under one second, and load preferably under three seconds.
- Use one low-poly principal terrain mesh (preferably under ~50k triangles), batched mask updates, effect pooling, lightweight shadows, at most eight balls, and one split generation.
- Provide a UI-independent in-process observation/action/event interface with stage/aim/terrain/mechanism/previous-shot data and set aim/fire/restart/camera/next-stage actions.

## Non-Goals

- Shops, currencies, monetization, customization, upgrades, gacha, dailies, ads, story/dialogue, inventory, multiple cannon/projectile collections, leaderboards, multiplayer, UGC, backend, online service, Docker, and live-service systems.
- Orthographic tabletop primary gameplay, fixed side-view gameplay, direct projectile steering, full fluid simulation, photorealism, caves, overhangs, or high-end rendering requirements.

## Acceptance Criteria

- The complete observable checklist is `test-checklist.md`.
- No feature is accepted from documentation, mockups, or scene structure alone; it must run in the project.
- The final evidence includes seven separate full-resolution, debug-free screenshots with the exact required names.
