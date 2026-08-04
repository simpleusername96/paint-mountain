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
  - ../.agents/execplans/2026-08-03-gameplay-visual-reset.md
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

### Stage 1 core-loop MVP evidence (non-release, 2026-08-03)

- [x] A persisted `StageMvpPermit` binds the exact Stage 1 layout identity,
  canonical default aim, and matching predictor/production-rigid-body target-top
  hit evidence in one validated proof checksum.
- [x] The real gameplay scene completes default aim, Fire, `terrain/top`
  contact, short rebound, sustained roll/slide contact, continuous surface paint,
  authoritative coverage, final paint drain, shot result, and deterministic
  Restart without a duplicate miniature implementation.
- [x] The measured parent contact lasts `5.100 s`, follows `36.688 m` of target
  surface, emits `306` continuous sweeps, and reaches `18.8140%` authoritative
  coverage.
- [x] Rejected authoritative paint commands are recorded in `ShotObservation`
  and force `STAGE_FAILED`; they cannot be silently sealed as a normal result.
- [ ] Stage 1 has the target-wide `DirectReachabilityCertificate` required for
  release. The MVP permit intentionally does not satisfy this item.
- [ ] The user-coordinated running-game visual gate has passed. No headless test
  or concept image may satisfy this item.

### Gameplay and visual reset release gate (active 2026-08-03)

Authority and deterministic target terrain:

- [ ] The effective `source-brief.md`, active design/architecture/checklist,
  project prompt, and implementation record agree on continuous contact paint,
  `target_mask`, targets `4/27/70%`, shots `4/5/6`, and the current HUD/menu.
- [ ] Every stage uses a version-4 deterministic route graph with 32 derived
  attempt seeds plus one pinned fallback; accepted seeds, graph/layout data, and
  all checksums repeat across fresh processes or generation fails closed.
- [ ] Each accepted layout has exactly one playable top height per in-bounds XZ,
  broad connected rollable slopes/terraces/ridges/valleys/pads, and no cave,
  overhang, tunnel, stacked top, detached route piece, or literal stair riser.
- [ ] One emitted indexed top-triangle list and fixed diagonal supply the render
  `ArrayMesh`, top `ConcavePolygonShape3D`, hit classification, height/normal
  queries, target rasterization, and paint reconstruction. Structural identities
  match exactly and deterministic engine-ray points differ by no more than
  `0.01 m`; no `HeightMapShape3D`, bilinear query, independent triangulation,
  visual displacement, or query-only playable geometry remains.
- [ ] The immutable filled `target_mask` is one connected route-graph footprint.
  Only the outer non-target band, apron/shell/bottom, and dilated physical
  mechanism footprints are excluded; slope, decoration, visibility, and expected
  difficulty remove no target texel.
- [ ] First Descent, Burst Basin, and Split Ridge prove the frozen route/reversal,
  slope, lip, spacing, shelf, edge, target-ratio, and mechanism-placement gates.
  Failed candidates are rejected rather than repaired with authored coordinates.

Reachability, aim, and containment:

- [ ] Every target-mask texel has a certificate witness in the canonical manual
  yaw/elevation/power domain whose predictor and real rigid body first contact
  the same `terrain/top` cell/triangle within `0.50 m` surface distance. No
  mechanism-first, shell, apron, wall, bounds, or timeout result is accepted.
- [ ] Three fresh verification processes reproduce the reachability and real-body
  checksums exactly. Witness tuples remain certification evidence and are absent
  from player/agent aim assistance.
- [ ] First entry and every restart apply the certified witness whose target-top
  impact is closest to the target-mask centroid and within `8 m`; no StageData,
  scene, or HUD owner hand-authors a replacement aim.
- [ ] Manual play retains independent yaw/elevation/power, empty-playfield drag,
  A/D/W/S, wheel and power buttons, Space/Fire parity, `R` restart, Tab inspect,
  and a depth-tested arc ending at the real first collision. Bounds exit/timeout
  is non-fireable and no post-impact path or coverage is previewed.
- [ ] The visible bright six-face rear wall and collider-matched faceted apron
  contain the entire legal launch domain. Wall contacts produce exactly one
  `BACKSTOP` contact, no paint/mechanism/bank shot, zero motion that tick, and no
  active projectile on the next tick.

Physical contact, continuous paint, and mechanisms:

- [ ] `PaintProjectile` reports every begun collider/shape contact in stable order
  with real point, normal, shapes, incoming velocity, impulse provenance, and
  triangle identity; simultaneous terrain/mechanism contacts are not collapsed.
- [ ] Production contact fixtures prove CCD, no tunneling/penetration, exact body
  identity, ordinary-terrain bounce/friction `0.08/0.78`, post-impact normal
  speed at most 10%, and sustained contact/roll/settle within `0.75 s` on target
  slopes at or below 30 degrees. Bumper alone may redirect strongly.
- [ ] A valid target-top first contact emits an impact radial mark, consecutive
  real contact ticks emit continuous 3D surface sweeps, and valid final contact
  emits an idempotent settle mark. Verified micro-gaps may bridge; airborne and
  non-target intervals remain blank. No payload, amount, depletion, autonomous
  downhill flow, fabricated pool, shell/apron/wall paint, or fake coverage exists.
- [ ] `PaintSystem` alone owns the runtime paint mask and coverage. Ordered paint
  commands drain once at the locked late-physics boundary, target threshold
  crossings count overlap once, terrain visuals use that same mask, and shot
  sealing waits for the last command tick.
- [ ] Burst, Splitter, and Bumper use collider-matched visible 3D masses, distinct
  amber/violet/coral plus silhouette cues, direct-hit witnesses, and forgiving
  activation neighborhoods. Burst emits one authoritative radial mark, Splitter
  creates exactly three generation-one children with smaller footprints, and
  Bumper follows its displayed tangent/cooldown; no fourth feature exists.
- [ ] Full solutions clear `4/27/70%` within `4/5/6` shots, Stage 2 requires Burst,
  Stage 3 requires both Splitter and Bumper, and safe-route-only Stage 3 remains
  below 70%. No target reduction, hidden target hole, extra shot, or invented
  special surface is used to pass.

Korean HUD, game menu, visual direction, and approved assets:

- [ ] The logical baseline is 1280×720 with safe-area containers. Rendered
  rectangles are stage `(24,24,118,48)`, mode `(24,84,110,40)`, target
  `(490,24,300,48)`, shots `(1016,24,180,48)`, gear `(1208,24,48,48)`, left
  coverage `(24,228,104,324)`, aim/power `(144,592,300,104)`, and sole Fire
  `(552,624,176,72)`, within the active plan's scaled tolerance.
- [ ] The left gauge fills bottom-to-top by `min(coverage/target, 1)` while its
  localized text shows absolute authoritative coverage and the cap shows target.
  Decorative gauge children do not intercept playfield pointer/wheel input.
- [ ] Fire is visible/focusable only in `AIMING`, emits exactly one guarded request
  per click or Space press, and is the only bottom-edge aiming action. No aiming
  Restart or second Fire exists; the `R` shortcut uses the same restart action.
- [ ] The labeled top-right gear and Escape open one paused full-viewport input
  barrier from every allowed gameplay state. Continue, Restart, Settings, Stage
  Select, and Main Menu appear in order; focus is trapped/restored, simulation
  advances zero ticks, and no aim, power, Fire, or playfield input leaks through.
- [ ] Settings opens above the still-paused game menu and Close/Escape returns to
  that menu with focus on Settings. The Settings form contains no Restart; menu
  Restart closes the menu, resets cleanly to `AIMING`, and reapplies default aim.
- [ ] Korean defaults and Korean/English switching, Pretendard, accessible names,
  visible focus, contrast/color-independent mechanism cues, and non-clipping
  layout pass at 1280×720, 1280×800, 1366×768, 1600×900, and 1920×1080.
- [ ] The running world uses the locked warm off-white values, faceted lit target
  mass, visible shell depth/wall join/shadow/parallax, small cannon, semantic
  mechanisms, and glossy blue physical paint. Concept images are comparison
  evidence only; literal stairs, detached terrain, fake paint, or pixel matching
  cannot satisfy this gate.
- [ ] Only already approved committed Kenney/Pretendard assets are used; no new
  dependency, asset pack, or runtime network access exists.

Replay, regression, performance, and delivery:

- [ ] Observation schema 4 and replay format 5 contain no payload/flow fields, store stable
  contact/mechanism/child ordering plus paint-drain/checksum facts, and fresh-
  process replay reproduces identities, final state, target checksum, and paint
  checksum exactly while rejecting replay format 4.
- [ ] `scripts/test.ps1`, every active focused test, persistence/replay matrices,
  `scripts/verify.ps1`, import/parse/main-scene smoke, and Windows release export
  pass through the approved explicit headless Godot path without parser errors,
  invalid calls, orphan nodes, penetration guards, or replay divergence.
- [ ] The locked paint-drain workload passes p95 `<=4 ms` and maximum `<=8 ms`;
  the 1920×1080 Iris Xe workload loads within 3 s, averages at least 60 FPS, has
  no frame over 33.3 ms, uses at most 128 MiB static memory, restarts within
  50 ms, and never exceeds eight balls.
- [ ] During the explicitly coordinated visible gates, the release executable is
  inspected at every named gameplay bookmark and all five supported resolutions.
- [ ] Seven fresh separate 1920×1080 running-release screenshots use the canonical
  names including `05_projectile_and_paint_roll.png`; separate 1280×800 Korean
  and English aiming images plus `10_pause_menu_1280x800_ko.png` prove the final
  responsive HUD/menu. No debug overlay, collage, synthetic image, or concept
  render is accepted as running-game evidence.

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
