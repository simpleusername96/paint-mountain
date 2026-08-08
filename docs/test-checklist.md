---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-08
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
  - ../.agents/execplans/2026-08-05-physical-gameplay-mvp.md
  - ../.agents/execplans/2026-08-05-rapid-fire-thirty-stage-progression.md
  - ../.agents/execplans/2026-08-05-runtime-grounded-interface.md
  - ../.agents/execplans/2026-08-05-gameplay-contract-recovery.md
  - ../.agents/execplans/2026-08-06-ballistic-terrain-preparation.md
  - ../.agents/execplans/2026-08-06-wind-driven-coverage-loop.md
  - ../.agents/execplans/2026-08-06-command-columns-hud.md
  - ../.agents/execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../.agents/execplans/2026-08-07-cannon-shot-observation.md
  - ../.agents/execplans/2026-08-07-truthful-coverage-and-responsive-aiming.md
  - ../.agents/execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md
  - ../.agents/execplans/2026-08-08-terrain-targeted-aiming.md
  - ../.agents/evidence/terrain-targeted-aiming-2026-08-08/README.md
  - ../.agents/evidence/target-coverage-and-safe-aim-framing-2026-08-07/design-qa.md
  - ../design-qa.md
---

# Test Checklist

## Purpose

Define the observable checks required before the game may be reported complete.
Completed gates and older checked sections are historical evidence for earlier
builds. The completed terrain-targeted aiming gate below owns the current
interaction and predicted-contact-lifetime acceptance; unchecked historical
rows do not override it.

## Completed terrain-targeted aiming and truthful-flight gate (2026-08-08)

- [x] In Aim View, terrain-top click creates a persistent target at the picked
  surface point. Continuous drag keeps only the latest pointer sample, moves the
  target smoothly, and never projects invalid shell/apron/mechanism/sky hits to a
  fake point. Map Inspection still owns drag orbit and wheel zoom.
- [x] W/S and lower-left angle buttons request 0.5-degree changes; wheel power
  and power buttons request their documented steps. The exact solver retains
  the selected surface target while changing the complementary aim values.
  Release evidence shows the same target at low `20.0° / 91.5%` and high
  `57.5° / 54.1%` combinations.
- [x] Pending, confirmed, selected, and rejected target states are shape-first.
  Explicit pending revisions disable Fire and hide stale impact/exit promises;
  rejection restores the last committed target and aim without branch flipping.
- [x] Prediction surface contact, live terrain/top identity, target validation,
  and impact presentation share the same contact point. Projectile-centre
  endpoints remain separate and bounds/timeout predictions fabricate no contact.
- [x] A current matching terrain-top prediction extends only that root through
  predicted duration plus 0.5 seconds, capped at 13 seconds. The long-flight
  fixture predicted `8.384 s`, reached live terrain/top contact at `8.417 s`,
  kept unmatched miss termination at 6 seconds, and kept bounds exit immediate.
- [x] Runtime 0.1% power, Human-only aim revisions, replay/agent/debug bypass,
  replay format 10, attempt schema 2, save format 5, and existing whole-power
  catalog identities pass compatibility checks. No target/solver payload enters
  replay, score, paint, layout, or agent terrain truth.
- [x] The diff-scoped quality audit found one replay action-lock leak in Human
  wind refresh; the corrected path and its focused replay check pass. No
  competing target, aim, prediction, lifetime, paint, or stage-state owner
  remains in the task-owned surface.
- [x] All named phase gates and `scripts/verify.ps1` pass with Godot 4.7.1. The
  final Windows release produces the eight captures below with exit 0 and empty
  stderr; each was inspected directly at native size with no clipped controls,
  false Fire state, stale marker, or premature protected-shot disappearance.

Final running-release evidence:

- `.agents/evidence/terrain-targeted-aiming-2026-08-08/terrain_target_selected-ko-1280x720.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/terrain_target_dragged-ko-1280x720.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/terrain_target_low_arc-ko-1280x720.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/terrain_target_high_arc-en-1920x1080.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/terrain_target_pending-ko-1280x720.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/terrain_target_rejected-ko-1280x720.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/protected_long_flight_impact-ko-1280x720.png`
- `.agents/evidence/terrain-targeted-aiming-2026-08-08/map_inspection-en-1920x1080.png`

## Active two-times projectile, balance, and aim-performance gate (2026-08-08)

- [x] The root physical/visible radius is `2.40 m`; continuous and impact paint
  radii are `2.80 m` and `3.50 m`, with unchanged split-child scaling.
- [x] Every legal launch origin keeps the full sphere above the cannon apron;
  100 exact contact cases and persistent contact/recovery/paint tests pass.
- [x] Active clear targets are `4.0..8.5%` for Stages 01-10 and
  `8.5/9.0/9.5/10.0%` for the four later five-stage tiers. Stars remain
  clear/`+2.5`/`+5.0`.
- [x] The promoted v10 bundle has 30 valid layouts and preserves v9 physical
  terrain, Target Area masks, cannon transforms, and placement identity while
  carrying scale-valid default/summit witnesses.
- [x] Prediction owns one replaceable active job, advances at most 12 steps near
  1 ms per callback, never publishes stale work, and leaves Fire independent.
  Stage 01/10/30 default settled markers completed in 6/6/9 physics ticks; the
  observed slowest callback was `1.089 ms`.
- [x] Pending presentation keeps the last complete arc/first-impact marker
  subdued and contains no normal calculation/update text or spinner.
- [x] `scripts/verify.ps1`, Windows release export/start, and direct inspection
  of task-owned Stage 01/30 Aim/contact captures pass.

Final Godot 4.7.1 Windows-release captures, inspected individually at native
1280x720 size:

- `.agents/evidence/coverage-balance-and-aim-feedback-2026-08-08/stage-01-aiming-ko-1280x720.png`
- `.agents/evidence/coverage-balance-and-aim-feedback-2026-08-08/stage-10-aim-change-ko-1280x720.png`
- `.agents/evidence/coverage-balance-and-aim-feedback-2026-08-08/stage-30-scale-contact-ko-1280x720.png`

## Scope

Run narrow checks throughout development, then complete this full checklist against a production-style Windows build or the strongest explicitly documented substitute.

## Completed truthful coverage and responsive aiming gate (2026-08-07)

- [x] Equal projected target patches at 0 and 60 degrees receive physical-area
  weights in a 1:2 ratio; first paint-threshold crossing adds each weight once,
  repaint adds zero, and painted non-target surface adds zero.
- [x] The v10 baked layout persists coverage metric 2, total target surface area,
  and a verified checksum while retaining every v9 physical terrain, target,
  placement, cannon, and bounded-witness identity.
- [x] One dirty paint presentation batch publishes both the visible mask and its
  weighted percentage; result sealing forces that final batch first.
- [x] Painted target and painted non-target terrain are distinguishable together
  in running Aim View without hiding valid non-target paint.
- [x] Fire admission depends only on legal canonical aim and stage rules. Pending
  or miss prediction never toggles Fire, and Fire performs no physics query.
- [x] Runtime prediction owns at most one active job and one newest pending key,
  advances no more than 24 simulation steps per physics callback, never publishes
  stale work, and keeps the last complete arc visible but subdued while pending.
- [x] Equivalent `screen_relative` mouse motion produces the same canonical aim
  at 1280x720 and 1920x1080; fractional sub-0.1-degree movement accumulates, and
  the persisted 50-150% sensitivity setting affects pointer aim only.
- [x] Aim View, Map View, Shot Follow, Gear, Finish, Fire, and Pause expose the
  locked contextual keycaps and gesture line. Escape resumes Pause, no direct R
  restart remains, and no transient first-session hint remains.
- [x] Focused structural tests, `scripts/verify.ps1`, Windows release export, and
  exported-build start pass without timing/FPS/profiler assertions.
- [x] The implementing agent directly inspects Stage 01 target/non-target paint,
  Stage 10 shortcuts and pending preview, Shot Follow Tab return, Korean 1280x720,
  and English 1920x1080 task-owned background captures.

Final Godot 4.7.1 Windows-release captures, inspected individually at native
size:

- `.agents/evidence/truthful-coverage-and-responsive-aiming-2026-08-07/01-stage01-target-nontarget-ko-1280.png`
- `.agents/evidence/truthful-coverage-and-responsive-aiming-2026-08-07/02-stage10-aim-shortcuts-ko-1280.png`
- `.agents/evidence/truthful-coverage-and-responsive-aiming-2026-08-07/03-stage10-preview-pending-ko-1280.png`
- `.agents/evidence/truthful-coverage-and-responsive-aiming-2026-08-07/04-shot-follow-tab-ko-1280.png`
- `.agents/evidence/truthful-coverage-and-responsive-aiming-2026-08-07/05-stage10-aim-shortcuts-en-1920.png`

## Completed target-coverage and safe Aim Lock validation gate (2026-08-07)

This gate validates the current target-only score presentation and cannon-view
framing. It does not change coverage balance, require whole-terrain scoring,
restore exhaustive first-hit certification, prescribe stage solution routes, or
claim user gameplay/feel approval.

- [x] `PaintSystem` remains the sole mutable paint and coverage owner. The
  focused paint contract proves valid non-target top paint remains visible but
  does not increase unique painted Target Area coverage.
- [x] Saturated shader paint begins at mask threshold `0.5`, matching the CPU
  count boundary, and the former filtered neighbor halo is absent. Dry Target
  Area remains a neutral lower-salience surface cue rather than a second paint
  state.
- [x] Korean and English coverage caption, formatted value, Finish tooltip, and
  result label name `목표 영역` / `TARGET AREA`; localization and HUD truth
  checks pass without adding a second metric or component owner.
- [x] Aim Lock projects deduplicated canonical playable-top points, summit
  samples with 8 m headroom, cannon, and muzzle. It retains authored focus,
  direction, and 48-degree FOV and applies only the distance correction needed
  for a 1.15 safe margin; it does not use the support shell, live prediction,
  stage-ID branches, or manual camera coordinates.
- [x] Active catalog Stages 01, 10, 20, and 30 pass point containment, summit,
  default first-impact, cannon/muzzle, clearance, focus-ray, fixed-mode
  transition, and Map Inspection return contracts using accepted baked layouts.
- [x] The diff-scoped quality audit removed the rejected merged-AABB path and
  its unused API, added missing summit-region headroom, and found no competing
  coverage, geometry, frustum, or camera-transform owner after correction.
- [x] `scripts/verify.ps1`, Windows release export to
  `builds/windows/PaintMountain.exe`, and exactly three exported hidden
  1280x720 captures passed. Native-size evidence and the Level 3 `Result:
  passed` report are under
  `.agents/evidence/target-coverage-and-safe-aim-framing-2026-08-07/`.

## Active shared Command Columns HUD validation gate (2026-08-06)

This gate supersedes earlier HUD geometry and target-normalized coverage rows.
It validates the user-selected aiming layout and shared design system only; it
does not require all-stage solution routes, exhaustive target-wide first-hit
certification, camera redesign, or inferred gameplay/feel approval.

- [x] The selected 1280x720 reference is registered at
  `docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png`; the
  implementation keeps its left-command, bottom-action, and right-status
  hierarchy while retaining supported real controls omitted from the concept.
- [x] `resources/ui/paint_mountain_theme.tres` is the single reusable visual
  owner for Pretendard 500/600/700 typography, semantic label roles, panels,
  buttons, separators, progress/target, focus, disabled, and icon states. The
  affected HUD scenes have no local font/color/icon/StyleBox presentation
  overrides.
- [x] `HudMetric` is a state-free reusable component instantiated for time,
  shots, and resident activity. `RunStatusCard` remains the runtime formatter;
  `HUDController` remains a coordinator rather than a gameplay owner.
- [x] Stage/mode, absolute coverage and target, yaw/elevation/power and step
  controls, sole Fire, Gear, time, shots, activity, wind, forecast, and Finish
  remain visible or state-gated through their established interfaces.
- [x] The coverage bar displays the authoritative absolute 0..100 value; its
  target is a separate marker. Focused shot feedback verifies that 2.0%
  coverage renders as 2.0 rather than as target-normalized progress.
- [x] The declared Phase 7 UI, HUD truth, wind/result, shot-feedback, and
  localization checks passed after integration. A code-quality audit found no
  competing style owner, catch-all gameplay responsibility, or stale component
  consumer.
- [x] The same-state visual comparison in `design-qa.md` passed at 1280x720 with
  no P0/P1/P2 finding. Separate Map Inspection and main-menu regression captures
  are under `.agents/evidence/command-columns-hud-2026-08-06/`.
- [x] `scripts/verify.ps1`, Windows release export to
  `builds/windows/PaintMountain.exe`, exported hidden start, and exported Stage
  30 background capture passed. Final running-release evidence is
  `.agents/evidence/command-columns-hud-2026-08-06/exported-aim-lock-stage30-ko-1280x720.png`.

## Completed cannon, wind, and shot-observation gate (2026-08-07)

These rows describe the implemented user-requested direction. Flight pacing is
a visual gameplay judgment, not wall-clock performance measurement; this gate
includes no timing or profiling pass.

- [x] Stage 01 and Stage 30 Aim View captures show a clearly identifiable cannon
  in the lower foreground and the useful lower/wider mountain mass above it,
  with muzzle, trajectory, and first-impact context readable. The user's
  approximate `3:4` reference is qualitative: modest peripheral crop is allowed,
  and no exact projected ratio or foreground percentage is required. The nearest
  playable front is at least 70 m from the cannon in promoted layout data.
- [x] A non-colliding cannon-side flag or streamer shows the direction
  projectiles are pushed and visibly distinguishes weak from strong wind. It and
  the HUD agree through a transition; generic wind debris is absent.
- [x] Accepted Fire follows the newly launched root paintball through first
  terrain contact, holds impact for 0.8 seconds, and returns to Aim View. The
  visible `대포로 돌아가기` action and Tab return early without steering,
  terminating, or otherwise changing the projectile.
- [x] With two root families allowed, Shot Follow selects the newest accepted
  root rather than averaging resident balls. Returning preserves the stored aim
  and leaves the next shot editable while prior physics continues.
- [x] A representative default shot has a readable arc without an immediate
  adjacent hit or prolonged dead airtime. The approximate three-second reference
  remains a user-owned feel judgment rather than an acceptance stopwatch. No exact
  flight-duration test rejects legal shots; a root that never contacts playable
  top still terminates at the configured 6.0-second miss timeout.
- [x] Focused contracts, `scripts/verify.ps1`, a Windows production-style start,
  and separate running-game captures cover Stage 01/30 Aim View, flag direction,
  mid-flight follow, impact hold, early return, and automatic return. The
  implementing agent visually reviews every capture before handoff.
- [x] No click-to-target solver, prescribed success route, exhaustive target-wide
  certificate run, timing probe, or all-stage manual playthrough is used as an
  acceptance substitute.

## Historical fast-stage-entry and wind/UI validation gate (2026-08-06)

These are historical behavior-level acceptance checks for the completed successor plan. They
intentionally avoid treating small numerical tolerances, individual physics
ticks, exhaustive target-texel first-hit enumeration, or prescribed solution
routes as product requirements. The retained unchecked rows require user
gameplay review; prior exports and captures remain historical unless named below.

- [ ] In `MAP_INSPECTION`, the player can drag and wheel-zoom to inspect the
  whole mountain. In `AIM_LOCKED`, drag and wheel adjust aim and power without
  moving the camera; rightward aim input moves both preview and actual landing
  point right on screen.
- [ ] A ball that reaches playable mountain top remains present for the stage,
  keeps its physical presence while naturally resting, paints again when it
  later moves, and does not disappear from ordinary terrain contact.
- [ ] Ground contact on representative slopes and joins does not produce the
  one-mark-then-disappear failure. A genuine invalid geometry condition is
  diagnosable without being confused with ordinary play.
- [ ] Wind changes on a seeded, readable 30-second rhythm. Prediction, live
  projectile motion, HUD direction/strength/countdown, replay, and decorative
  debris agree; pausing does not advance the run.
- [ ] Strong wind can restart an eligible resting ball. The player can see why
  it moves, and resting balls do not produce repeated stationary paint.
- [ ] A run begins with the first shot and ends only through Finish or time
  expiry. Its result uses final unique painted coverage, not automatic
  clear/failure or hidden time/wind bonuses.
- [ ] Burst, Splitter, and Uphill Rebound are readable terrain-conforming
  glyphs with effects that match their markings: Burst consumes after painting,
  Splitter visibly divides toward its marked routes, and Uphill Rebound sends a
  ball uphill.
- [ ] The active HUD leaves the mountain readable and offers no ambiguous
  Follow/Wide/Cannon rail. Gear and Escape remain one pause/settings entry.
- [ ] Production-style captures at common desktop sizes show the aiming and map
  modes, live ball/paint scale, wind HUD, representative glyphs, and timed-result
  states without obscuring the terrain. Focused runtime contracts separately
  cover persistence, recovery, and wind wake behavior that a still frame cannot
  prove.

Implemented code/structural evidence:

- [x] `resources/stages/catalog.tres` selects the format-5 persisted bundle
  `resources/generated_stage_catalogs/v9-b0eb55b3e366a7a92b1391a6acd0298bbc854d8c831e8ac57f9b5df5ab44c957`,
  containing `stage_01` through `stage_30`, canonical terrain seed
  `1347223552`, and default/summit witnesses.
- [x] `StageLayoutRepository` is the runtime owner. It asynchronously loads the
  selected layout, supports non-blocking prefetch, retains three entries, and
  does not fall back to generation or aim solving.
- [x] Generic glyph placement searches spaced visible playable-top surface; it
  uses no authored stage coordinates.
- [x] Focused code contracts cover repository loading, two-family Fire capacity,
  family observation sealing, localized loading/retry state, and the cannon-side
  wind flag. They do not replace the unchecked production-style rows above.
- [x] `scripts/verify.ps1` and Windows release export/start passed for
  `builds/windows/PaintMountain.exe`. Exported Stage 01/30 entry readiness was
  `1035.5 ms` / `2068.4 ms`. Eight final 1280x720 capture PNGs with stdout/stderr
  logs under `.agents/evidence/fast-stage-entry-and-fire-capacity/` passed with
  exit 0 and empty final stderr: `stage_30_aiming`, `two_family`, `main_menu`,
  `stage_select`, `stage_select_page_2`, `first_hint`, `pause`, and `settings`.
  Render review found no clipping, overlap, or gross terrain obstruction; stage
  select pages 1/2 retain their footer, page 3 is structurally covered, wind
  debris is visible, and Settings is exactly 1280x720.
- [x] Focused wind-debris validation proves shared wind direction, movement, and
  reduced-motion behavior. A temporary timing probe found profile hydration
  `1091.2 ms -> 599.5 ms` after hoisting the summit snapshot from the triangle
  loop, and cached successful immutable readiness reduces repeats from roughly
  `250..320 ms` to `0`; it is not a retained test.
## Completed ballistic-terrain preparation gate (2026-08-06, historical baseline)

- [x] The shared fixed-60-Hz damped recurrence and fixed muzzle transform admit a
  known legal trajectory and reject synthetic yaw, horizon, too-high, and
  too-low samples without creating a scene or physics world.
- [x] Target rasterization evaluates every included projectile-center surface
  sample and rejects the entire candidate on the first analytic-domain failure;
  it never edits target-mask bytes to pass.
- [x] Persisted Stage 01 and Stage 30 seeds rebuild with all target samples and
  at least one Summit Region sample inside the analytic envelope. Their retained
  source layouts remain unchanged when runtime annotations are written to a
  gameplay copy.
- [x] A cold layout request returns without blocking, uses a RefCounted worker
  job rather than a scene-tree object, publishes only matching identities, and
  retains at most three layouts under the LRU test strategy.
- [x] AppRoot has no synchronous `SeededStageGenerator.generate()` navigation
  fallback. Preparing/failure labels are localized, Start remains disabled until
  readiness is true, next-stage prefetch is low priority, and preview artifacts
  retain at most one stage.
- [x] `scripts/verify.ps1` passes the final headless import and main-scene start,
  including real background Stage 01 generation and clean worker joining.
- [x] Per the user's direction for this change, no foreground gameplay or
  rendered-game test is used as acceptance evidence.

## Gameplay-contract recovery gate (2026-08-05, historical and incomplete)

This gate is retained only as historical evidence. Its exhaustive target-wide
certificate and per-stage solution expectations were withdrawn by the later
user supersession and are not current work.

- [ ] Stage 01–30 use committed version-7 per-stage profiles/layout identities;
  all 29 difficulty-score deltas are `0.35..5.00`, adjacent normalized height
  RMS is `1.0..18.0 m`, and Stage 04/05 pass their exact distinctness canary.
- [ ] While ball 1 remains active, human input changes the next aim, a matching
  trajectory remains visible from the cannon view, and ball 2 fires at that new
  tuple before ball 1 settles; capacity disables only Fire.
- [ ] Parent physical radius is `0.90 m`; continuous/settlement/impact paint
  radii are `1.50/1.50/2.10 m`; controlled real-contact mask widths and an
  off-screen running capture prove the relationship.
- [ ] The focused recovery checks, deterministic catalog `--check`,
  `scripts/verify.ps1`, Windows release export, metadata JSON, and named
  background Compatibility captures all pass.
- [ ] `.agents/Documentation.md` and the active ExecPlan checkboxes match the
  observed implementation; no superseded shortcut is called complete.
- [ ] Foreground play review by the user. The agent does not open a desktop-
  blocking Godot window.

The checked `f13927a` evidence formerly listed here proved only partial contact,
catalog enumeration, direct-controller repeat Fire, static UI, and performance.
It is retained in `.agents/evidence/2026-08-05-execution-evidence.md` as historical
evidence and does not satisfy this gate.

### Recovery verification snapshot (2026-08-05)

- Stage 01 and Stage 30 summit-only predictor/rigid-body checks pass with the
  shared visual-muzzle yaw contract; the certificate serialization guard keeps
  the summit aim independent from the target witness table.
- The final focused regression batch passed contact/CCD, projectile-to-paint,
  rapid-fire/readiness, phase-7, phase-8, replay, and default-aim handoff checks.
- `scripts/verify.ps1`, the deterministic catalog `--check`, and the Windows
  release export passed through the approved hidden/headless Godot path.
- The session-local recovery PNGs were not retained as current evidence. The
  tracked metadata and textual record remain historical; a future visual claim
  must use new running-game captures from the active implementation.
- These observations did not check the then-planned exhaustive certificate or
  controlled rendered-width measurement. The certificate item is now retired;
  this historical recovery gate is not active work.

## Historical vertical-slice baseline evidence

The checked rows in this section describe the 2026-08-03 baseline. They remain
traceability evidence, but the completed wind-loop gate above supersedes their
clear/failure, finite-payload, physical-mechanism, eight-ball, observation-strip,
and legacy screenshot statements.

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

### Stage 1 core-loop MVP evidence (historical and incomplete, 2026-08-03)

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
- [ ] The user-coordinated running-game visual gate has passed. No headless test
  or concept image may satisfy this item.

### Gameplay and visual reset release gate (historical 2026-08-03)

Authority and deterministic target terrain:

- [ ] The effective `source-brief.md`, active design/architecture/checklist,
  project prompt, and implementation record agree on continuous contact paint,
  `target_mask`, targets `4/27/70%`, shots `4/5/6`, and the current HUD/menu.
- [ ] Every version-10 stage uses canonical terrain seed `1347223552` plus its
  immutable stage/profile identity and one persisted baked layout. No candidate,
  attempt, or fallback seed remains; graph/layout data and all checksums repeat
  across fresh processes or generation fails closed.
- [ ] Each accepted layout has exactly one Playable Terrain Surface height per in-bounds XZ,
  broad connected rollable slopes/terraces/ridges/valleys/pads, and no cave,
  overhang, tunnel, stacked top, detached route piece, or literal stair riser.
- [ ] One emitted indexed top-triangle list and fixed diagonal supply the render
  `ArrayMesh`, top `ConcavePolygonShape3D`, hit classification, height/normal
  queries, target rasterization, and paint reconstruction. Structural identities
  match exactly and deterministic engine-ray points differ by no more than
  `0.01 m`; no `HeightMapShape3D`, bilinear query, independent triangulation,
  visual displacement, or query-only playable geometry remains.
- [ ] The immutable filled `target_mask` is one connected route-graph footprint
  through the configured target-shoulder boundary. After generation, slope,
  decoration, visibility, expected difficulty, and ballistic failure remove no
  included target texel.
- [ ] First Descent, Burst Basin, and Split Ridge prove the frozen route/reversal,
  slope, lip, spacing, shelf, edge, target-ratio, and mechanism-placement gates.
  Failed candidates are rejected rather than repaired with authored coordinates.

Aim and open play bounds:

- [ ] First entry and every restart apply the generated bounded witness whose
  Target Area impact is near the target-mask centroid; the separate summit
  witness reaches the global highest Playable Terrain Surface region. Neither becomes player
  aim assistance.
- [ ] Manual play retains independent yaw/elevation/power, empty-playfield drag,
  A/D/W/S, wheel and power buttons, Space/Fire parity, Tab inspect,
  and a depth-tested arc ending at the real first collision. Bounds exit/timeout
  is non-fireable and no post-impact path or coverage is previewed.
- [ ] Each stage uses one baked fixed cannon transform at least 70 m from the
  nearest playable terrain edge. Map View camera orbit never changes the launch
  position, and no cannon orbit or launch-station control exists.
- [ ] No visible, collidable, or hidden rear/side containment wall exists. The
  independent mountain closes with its own Support Shell and bottom; the
  restrained apron remains open non-target ground. Live and predicted misses
  share the same explicit exit bounds and never bank from an enclosure.

Physical contact, continuous paint, and mechanisms:

- [ ] `PaintProjectile` reports every begun collider/shape contact in stable order
  with real point, normal, shapes, incoming velocity, impulse provenance, and
  triangle identity; simultaneous terrain/mechanism contacts are not collapsed.
- [ ] Production contact fixtures prove CCD, no tunneling/penetration, exact body
  identity, ordinary-terrain bounce/friction `0.08/0.78`, post-impact normal
  speed at most 10%, and sustained contact/roll/settle within `0.75 s` on target
  slopes at or below 30 degrees. Bumper alone may redirect strongly.
- [ ] A valid Playable Terrain Surface first contact emits an impact radial mark,
  consecutive real contact ticks emit continuous 3D surface sweeps, and valid final contact
  emits an idempotent settle mark. Verified micro-gaps may bridge; airborne and
  non-target intervals remain blank. No payload, amount, depletion, autonomous
  downhill flow, fabricated pool, Support Shell/bottom/apron/mechanism paint, or
  fake coverage exists. Paint outside the Target Area stays visible but unscored.
- [ ] `PaintSystem` alone owns the runtime paint mask and coverage. Ordered paint
  commands drain once at the locked late-physics boundary, target threshold
  crossings count overlap once, terrain visuals use that same mask, and shot
  sealing waits for the last command tick.
- [ ] Burst, Splitter, and Bumper use collider-matched visible 3D masses, distinct
  amber/violet/coral plus silhouette cues, direct-hit witnesses, and forgiving
  activation neighborhoods. Burst emits one authoritative radial mark, Splitter
  creates exactly three generation-one children with smaller footprints, and
  Bumper follows its displayed tangent/cooldown; no fourth feature exists.
Korean HUD, game menu, visual direction, and approved assets:

- [ ] The logical baseline is 1280×720 with safe-area containers. Rendered
  rectangles are stage `(24,24,118,48)`, mode `(24,84,110,40)`, target
  `(490,24,300,48)`, shots `(1016,24,180,48)`, gear `(1208,24,48,48)`, left
  coverage `(24,228,104,324)`, aim/power `(144,592,300,104)`, and sole Fire
  `(552,624,176,72)`, within the then-active plan's scaled tolerance.
- [ ] The left gauge fills bottom-to-top by `min(coverage/target, 1)` while its
  localized text shows absolute authoritative coverage and the cap shows target.
  Decorative gauge children do not intercept playfield pointer/wheel input.
- [ ] Fire is visible/focusable only in `AIMING`, emits exactly one guarded request
  per click or Space press, and is the only bottom-edge aiming action. No aiming
  Restart, second Fire, or direct `R` restart shortcut exists.
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
  mass, visible independent Support Shell depth/shadow/parallax, an open
  background with no enclosing wall, a small cannon, semantic
  mechanisms, and glossy blue physical paint. Concept images are comparison
  evidence only; literal stairs, detached terrain, fake paint, or pixel matching
  cannot satisfy this gate.
- [ ] Only already approved committed Kenney/Pretendard assets are used; no new
  dependency, asset pack, or runtime network access exists.

Replay, regression, structural performance, and delivery:

- [ ] Observation schema 6 and replay format 10 contain no payload/flow or
  `BACKSTOP` fields, store stable contact/mechanism/child ordering plus canonical
  terrain/open-bound/paint-drain/checksum facts, and fresh-process replay
  reproduces identities, final state, target checksum, and paint checksum
  exactly while rejecting replay format 8.
- [ ] `scripts/test.ps1`, every active focused test, persistence/replay matrices,
  `scripts/verify.ps1`, import/parse/main-scene smoke, and Windows release export
  pass through the approved explicit headless Godot path without parser errors,
  invalid calls, orphan nodes, penetration guards, or replay divergence.
- [ ] Structural performance checks prove Fire performs no prediction query,
  unchanged prediction/Aim View inputs reuse cached work, trajectory dots use
  one `MultiMeshInstance3D`, hidden preview and settled flag processing suspend,
  runtime terrain never regenerates, and resident/root/child caps remain bounded.
  This gate adds no timing probe, profiler capture, FPS threshold, or measured
  performance claim.
- [ ] The release executable produces and the implementing agent inspects seven
  separate background captures: Stage 01 Aim View, Stage 30 Aim View, weak and
  strong crosswind flag states, mid-flight Shot Follow, mountain impact hold,
  and returned Aim View. No debug overlay, collage, synthetic image, concept
  render, rear/side enclosure, or hidden-wall behavior is accepted as evidence.

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
