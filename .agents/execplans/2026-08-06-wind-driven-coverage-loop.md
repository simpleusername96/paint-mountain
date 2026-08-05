---
type: plan
status: done
created: 2026-08-06
last_reviewed: 2026-08-06
scope: screen-correct aiming, persistent paintballs, deterministic wind, timed coverage scoring, surface-glyph mechanisms, and edge HUD
source: ../evidence/2026-08-06-wind-score-loop-audit.md
related:
  - 2026-08-06-ballistic-terrain-preparation.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
---

# Wind-Driven Coverage Loop - Execution Contract

Paint Mountain is now a deterministic timed coverage puzzle: screen-right input moves the predicted and real landing point right, paintballs that reach playable mountain top persist until the stage ends and can move again after collision or strong wind, wind changes on a readable 30-second schedule, the player ends a 90/120/180-second run manually or by timeout, coverage is the sole score, the three existing mechanisms are terrain-conforming circular glyphs, and one clear aim-lock/map-inspection interaction replaces the legacy camera preset strip. The completed ballistic-range and layout-preparation checkpoint at `19f2d45` was the implementation baseline.

## Purpose

- Objective: turn the user's revised rules into one coherent, learnable, replayable gameplay loop instead of layering wind and a timer over the old clear/fail rules.
- Deliverable: revised product contracts, screen-correct aiming, persistent paintball motion states, seeded wind physics and cues, timed coverage results, three surface-glyph mechanisms, edge-aligned HUD, compatible save/replay/agent observations, focused tests, and production-rendered evidence.
- Completion state: all thirty persisted stages structurally materialize under the new loop contract; representative runtime checks cover deterministic retry, valid-top paint, persistence, wind, and both result reasons; and exported 1280×720 and 1920×1080 captures prove the visible camera, HUD, scale, glyph, and result states.

## Scope and Boundaries

In scope:

- Positive-yaw semantics and screen-space aim acceptance.
- Paintball physical/visual scale and paint footprint scale.
- Paintball `MOVING_AIRBORNE`, `MOVING_ON_TERRAIN`, `RESTING_ON_TERRAIN`, and terminal reason lifecycle.
- One data-driven, fixed-tick, seeded wind schedule and its predictor/physics consumers.
- 90/120/180-second stage durations, manual Finish, coverage-only score, and star thresholds.
- Burst, Splitter, and Uphill Rebound as terrain-conforming circular glyphs.
- Aim-lock/map-inspection camera interaction, edge HUD, world wind debris, result presentation, accessibility labels, and reduced decorative motion.
- Save, replay, attempt observation, agent/debug API, localization, generation admission, tests, docs, export, and rendered evidence affected by these rules.

Out of scope:

- Implementing the nine additional mechanism candidates in the audit report.
- Changing terrain family generation except where the new projectile radius, yaw convention, or flat-glyph placement invalidates an admission contract.
- Replacing the completed asynchronous layout preparer or its three-entry cache.
- Unlimited ammunition, steering a projectile in flight, online services, new dependencies, plugins, or external asset packs.
- Mobile layout or a new art direction unrelated to wind and mechanism readability.

Constraints and invariants:

- `StageController` remains the sole owner of the stage state machine, timer, Finish action, and result decision.
- `PaintSystem` remains the only authoritative paint mask and coverage source. No second scoring representation is allowed.
- Game rules use the fixed 60 Hz physics tick. Render delta and wall-clock time do not decide wind, scoring, replay, or terminal state.
- The player still chooses yaw, elevation, and power before firing and never steers a projectile in flight.
- Existing per-stage ammunition remains 4–7 shots. At most two root shot families may be in their initial launch flight; later collision/wind reawakening does not consume or wait for those Fire slots. The proved resident-body cap remains 21.
- Every valid playable mountain-top contact paints visually; only overlap with the scoreable target mask increases coverage.
- Paintballs have no finite paint payload and never terminate because paint is depleted.
- Once a paintball has contacted valid playable top, neither age, low speed, nor Godot sleeping may remove it before the stage result. Natural sleeping is allowed as a reversible physics optimization, not as deletion or permanent freeze.
- The same stage and accepted layout seed produce the same wind schedule on retry and replay.
- Flat mechanism glyphs do not participate in projectile collision. Activation derives from an authoritative mountain-top contact inside the glyph footprint.
- `StageController` remains in gameplay `AIMING` while the player toggles presentation/input between `AIM_LOCKED` and `MAP_INSPECTION`; camera interaction never becomes a competing gameplay state owner.
- Compatibility rendering, Windows desktop, typed GDScript where practical, and no production dependency additions remain mandatory.

Destructive or irreversible actions:

- Generated stage catalogs and reachability evidence may be replaced only after their version changes and their deterministic rebuild command passes. These artifacts are reproducible; no save data is deleted.
- Existing save data is migrated in place. The implementation must not clear user best results.

Exact actions requiring owner or user approval:

- None inside this contract. Any external asset pack, dependency, change to ammunition policy, change to the coverage-only score, or implementation of additional mechanism kinds requires a new user decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Completed predecessor | Commit `19f2d45` implements the analytic range gate and asynchronous three-layout preparation; its plan is `done` | Git history, predecessor plan, implementation record | Use `19f2d45` as the baseline, preserve its ownership and current user-authored worktree changes, and do not reopen its completed scope | 0.1 |
| Horizontal aim | Input makes right drag/D increase yaw, while positive yaw launches toward world `-X`; tests check numbers, not screen direction | `aim_input_controller.gd`, `cannon_ballistics.gd`, `aim_interaction_test.gd` | Positive yaw means screen-right in the fixed aiming camera; keep right drag and D positive and change the shared ballistic/visual convention, then prove it by projection | 1.1 |
| Scale | Current radii are 0.90/1.50/2.10m and current scale capture does not show a live contact comparison | Projectile resource and runtime capture | Use 1.20m ball, 1.40m continuous paint, 1.75m impact paint, and no separate settle blob; visible and collision radius remain identical | 1.2, 2.3 |
| Paint disappearance | There is no payload; slow/sleep/12-second lifetime paths immediately free the body | `paint_projectile.gd`, `projectile_data.gd` | A valid-top ball persists through the stage. Low speed/sleep becomes reversible `RESTING_ON_TERRAIN`; only explicit consumption, real escape, unrecoverable invalid geometry, or a never-contacted 30-second miss terminates it before result | 2.1 |
| Ground embed then disappearance | Impact can paint before the current deep-penetration guard frees the body; settle paint can overlap impact | `paint_projectile.gd` contact and deactivation order | Remove deletion as the normal penetration response; recover sphere clearance from authoritative surface point/normal, preserve tangent motion, and reserve termination for verified invalid geometry | 2.2 |
| Contact paint | Valid top contact emits paint; containment and mechanism bodies do not | Contact validator and paint projectile | Paint every valid playable top traversal, including non-scoreable top; score only through the existing target mask; suppress stationary duplicates and wake blobs/bridges | 2.3 |
| Wind | No current owner, data, physics, UI, or replay contract exists | Repository search and architecture audit | Use one seeded 30-second schedule with a 3-second transition/forecast, a configured strong-wind threshold, and one snapshot shared by predictor, physics, HUD, replay, and agent | 2.4–2.6, 5.2 |
| Stage result | Target coverage auto-clears and zero shots auto-fails; no timer/Finish | `StageController`, `StageData`, result HUD | Timer starts when the first queued root actually spawns; stage tiers are 90/120/180 seconds; no coverage/shot auto-terminal; Finish or timeout snapshots coverage; coverage is the sole score | 3.1–3.3 |
| Resting shots and observations | Shot observations seal when families terminate; resting balls can later wake | Stage controller, replay, agent API | Initial-flight Fire capacity ignores already-resident and reawakened balls; add attempt-level rest/wake/recovery/result events; keep per-shot observations as initial-flight diagnostics | 2.7, 3.4 |
| Mechanism form | All three mechanisms are 8–10m physical 3D bodies and `GimmickBase` requires their physics bodies | Mechanism scenes/base and runtime captures | Replace `GimmickBase` with a glyph presentation/charge base plus `TerrainMechanismResolver`; selection remains query-only | 4.1 |
| Mechanism effects | Burst does not consume, Splitter creates three children, Bumper redirects downstream | Mechanism scripts and phase 5 tests | Burst consumes after ordered paint; Splitter keeps three route-aligned children; Bumper migrates to `UPHILL_REBOUND` using local terrain gradient | 4.2–4.4 |
| Mechanism count | Stage count already grows from 0 to 6 | `StageProgressionData` | Keep the count curve; replace placement checks with glyph overlap, slope projection, and screen-size checks | 4.5 |
| Camera interaction and HUD occlusion | Follow/Wide/Cannon change only camera presets while aim drag/wheel remain active, and their horizontal panel covers the mountain | CameraDirector, AimInputController, observation controls, runtime capture | Replace the preset strip with `AIM_LOCKED` and `MAP_INSPECTION`; Tab and one clear toggle switch them, map drag/wheel inspect the terrain, and Gear/Escape remain the only pause entry | 5.1–5.3 |
| Persistence/replay | Save stores coverage/stars; replay format 7 lacks wind and Finish; agent lacks both | GameState, ReplayRecorder, GameplayAgentApi | Save format 4 preserves prior results and adds metadata for the best-coverage run; replay format 8 records wind and Finish tick; agent/debug expose the same snapshot | 3.4, 5.4 |
| Additional mechanisms | Nine non-overlapping candidates are documented | Audit report | Do not implement them in this slice; collect evidence from the revised core three first | Out of scope |

Readiness statement:

- Every material product, architecture, data, UX, ownership, safety, and validation decision for this slice is closed.
- The approved Godot 4.7.1 console binary and the repository's build, test, export, and background-capture paths are available.
- Remaining unknowns are implementation-local calibration details constrained by the visible and behavioral acceptance below; they cannot change this contract.

## Tasks

### Phase 0: Establish the uncontested authority and baseline

Goal: establish the completed predecessor as the baseline and make the user's latest rules authoritative before gameplay code changes.

Preconditions:

- Commit `19f2d45` and the `done` predecessor plan are present.
- `git status --short` has been reviewed; existing user-authored changes and stopped-session artifacts remain untouched and unstaged.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`, `docs/technical-architecture.md`, `docs/test-checklist.md`, `.agents/Documentation.md`, this plan

- [x] **0.1** Preserve the completed predecessor and establish the successor baseline.
  - Change: record `19f2d45`; inspect its final `CannonBallistics`, `ProjectileRangeConstraint`, `StageLayoutPreparer`, generated-catalog version, and changed docs; identify the remaining uncommitted user-owned files so later task commits do not absorb them.
  - Accept: the predecessor plan is `done`, its implementation record names the same owners, and no existing user-owned change is staged, overwritten, or claimed by this plan.
- [x] **0.2** Record the latest user supersession in product and technical contracts.
  - Change: append the 30-second wind and direction UI, stage-long valid-top paintball persistence, recover-instead-of-delete terrain contact, timed coverage result, flat-glyph mechanism, Burst consumption, uphill rebound, scale, and aim-lock/map-inspection camera contract to `source-brief.md`; update interpretations and checklist rows; mark the old physical-3D mechanism, clear/fail, and camera-preset clauses as superseded only in the named scope.
  - Accept: source brief, design spec, architecture, checklist, implementation status, and this plan use the same terms and do not claim the new behavior is implemented.
- [x] **0.3** Remove stale scale assertions before adding new ones.
  - Change: update or retire legacy projectile-scale assertions that conflict with the revised contact-paint contract.
  - Accept: one canonical projectile resource defines production scale, tests load it, and no test embeds an incompatible legacy scale.

Batch gate:

- Product/spec/status documents agree on the new loop, old scale assertions are removed, and the committed predecessor remains intact before gameplay code changes.

### Phase 1: Make aim direction and scale truthful

Goal: the same positive-yaw contract drives input, text, cannon pose, generation range, preview, and actual impact, and the live ball/paint proportion matches the user's direction.

Preconditions:

- Phase 0 passes.

Source owners: `src/cannon/cannon_ballistics.gd`, `src/cannon/cannon_controller.gd`, `src/input/aim_input_controller.gd`, `src/cannon/trajectory_predictor.gd`, `src/stage_generation/projectile_range_constraint.gd`, `resources/projectiles/basic_paintball.tres`, projectile scenes/materials, aim tests, delivery capture runner

- [x] **1.1** Define positive yaw as aiming-camera screen right.
  - Change: reverse the shared yaw transform in launch direction, launch origin, cannon visual rotation, and analytic range fan while leaving right drag and D as positive input. Update directional copy to derive from the same sign convention.
  - Accept: in the running aiming view, right drag and D move the preview and real first contact to the right, while left drag and A move them left; the cannon, preview, and physical shot agree.
  - Guard: do not special-case the mouse or change only a label; all human, agent, replay, solver, and generator callers share the same yaw meaning.
- [x] **1.2** Apply the revised physical and paint scale.
  - Change: set the production ball radius to `1.20m`, continuous paint radius to `1.40m`, and impact paint radius to `1.75m`; remove the separate settle-paint emission and later retire its resource field after migration; update split-child spacing/radius derivation and collision/visible-mesh parity.
  - Accept: resource, collision shape, visible mesh, contact sampling, predictor clearance, reachability admission, and tests use the new values; no hidden visibility shell changes the apparent collision radius.
- [x] **1.3** Rebuild radius/yaw-dependent structural catalog evidence.
  - Change: increment the generation contract/catalog version and regenerate the deterministic stage catalog affected by the new physical radius, yaw convention, and glyph placement. Do not reopen the separately scoped target-wide ballistic certification effort.
  - Accept: catalog check and all-thirty structural materialization pass, representative live/glyph stages pass, and no target pixel is cropped to make admission pass.
- [x] **1.4** Replace the false scale capture with rendered contact evidence.
  - Change: make `scale_contact` hold a real live projectile against a representative stage-04 top surface with its continuous trail and first-impact mark visible in the same frame.
  - Accept: at both supported desktop resolutions the live ball is easy to identify and its continuous and impact marks read as plausible contact paint rather than an oversized unrelated stain.

Batch gate:

- Screen-space aim, projectile contact, analytic range, generated catalog, and scale-capture checks pass together before wind changes the trajectory recurrence.

### Phase 2: Add deterministic wind and persistent paintballs

Goal: wind affects both predicted and real motion, resting balls remain paint-capable and can wake from normal collision or explicit strong wind, and all valid top traversal paints without duplicate stationary work.

Preconditions:

- Phase 1 passes and generated layouts are valid for the new radius/yaw contract.

Source owners: new `src/wind/wind_profile.gd`, new `src/wind/wind_controller.gd`, new `resources/wind/standard_wind.tres`, `src/stage/stage_data.gd`, `src/projectile/paint_projectile.gd`, `src/projectile/projectile_manager.gd`, `src/projectile/projectile_data.gd`, `src/mechanisms/mechanism_data.gd`, `src/mechanisms/splitter_node.gd`, `src/cannon/cannon_ballistics.gd`, `src/cannon/trajectory_predictor.gd`, paint/contact tests

- [x] **2.1** Replace deletion-on-settle with a persistent, reversible projectile lifecycle.
  - Change: add `MOVING_AIRBORNE`, `MOVING_ON_TERRAIN`, `RESTING_ON_TERRAIN`, and terminal reason data. Keep `can_sleep=true`; interpret Godot sleeping or stable valid-top rest as `RESTING_ON_TERRAIN` without `queue_free()` or permanent `freeze`. Collision and explicit force may set `sleeping=false` and resume movement. Stop using `minimum_movement_speed`, `stop_duration`, and `maximum_lifetime` as terminal rules for any ball that has touched valid top. Use a bounded resource-owned timeout only for balls that never reach valid terrain. Before result, termination is limited to explicit `CONSUMED`, real bounds/side-wall/backstop `ESCAPED`, or Task 2.2's unrecoverable `INVALID_GEOMETRY`. Result/restart cleans all remaining bodies after the score snapshot.
  - Accept: a valid-top ball remains visible, collidable, and queryable through the longest stage regardless of age or low speed; sleeping produces no paint or continuous-force work; collision can wake it; a ball that never reaches valid terrain is eventually cleaned up with a truthful reason.
  - Guard: sleeping is a reversible engine state, not a gameplay terminal; do not solve persistence by forcing every resting body awake.
- [x] **2.2** Recover shallow terrain embedding instead of deleting the ball.
  - Change: replace the current deep-below-surface deletion guard with radius- and surface-normal-aware recovery inside the rigid-body integration path. Restore the ball to valid surface clearance, remove only inward normal velocity, preserve tangent motion and rotation, and emit no extra paint. Only a repeated, verified mismatch between authoritative terrain data and the real collider may terminate as `INVALID_GEOMETRY`, with enough diagnostics to reproduce it.
  - Accept: representative steep, seam, and high-speed terrain contacts recover or continue without the ball vanishing; an intentionally invalid terrain/collider fixture fails with a clear diagnostic reason.
- [x] **2.3** Guarantee paint on every valid playable-top traversal.
  - Change: emit impact on first valid top contact and distance-based sweeps for every subsequent traversed segment, whether or not the segment is scoreable. Remove separate settle-paint emission. Keep the target mask solely inside `PaintSystem` coverage calculation. On entry to rest, close the movement interval after its last accepted contact; on wake, seed a new sweep anchor at the current valid contact without a second impact mark and without bridging a non-contact or long-rest gap. Suppress identical stationary writes.
  - Accept: a ball crossing target and non-target top leaves one continuous visible trail; only target overlap changes coverage; the paint-mask checksum remains unchanged while stationary; wake adds paint only along measured new travel; containment walls, backstop, selection shapes, and glyph query shapes never paint.
- [x] **2.4** Add the seeded 30-second fixed-tick wind owner.
  - Change: add typed `StageData.wind_profile` and point every current stage at `standard_wind.tres`. `WindProfile` owns tuning and `WindController` owns one seeded schedule plus the authoritative current/next vectors, strength, countdown, transition, `strong_episode_id`, and signals. Wind targets change every 30 seconds, ease during the last 3 seconds, and begin their forecast at that transition. A strong episode begins when the profile's configured threshold is crossed upward.
  - Accept: retrying the same stage reproduces the same wind sequence, wind changes on the 30-second rhythm with a readable transition, and pause advances neither wind nor countdown.
- [x] **2.5** Apply the same wind sample to prediction and live physics.
  - Change: add wind acceleration to the shared fixed-step recurrence and rigid-body force path. The predictor samples wind changes that may occur during flight and publishes the aim, schedule identity, and intended launch tick used for its result. Fire launches only from a matching current prediction; stale results are discarded.
  - Accept: a shot never launches from a stale prediction, and in calm, steady, and changing wind the preview and physical first contact remain visibly consistent without making the legal aim space unusable.
  - Guard: do not send continuous wind through `queue_desired_velocity()`, which remains an instantaneous mechanism effect.
- [x] **2.6** Wake terrain-resting balls naturally under readable strong wind.
  - Change: when the configured strong-wind threshold is met, project the current wind onto the tangent plane stored from each valid top contact. Each ball stores `last_wake_strong_episode_id`. When a strong episode begins, or when a not-yet-latched ball enters `RESTING_ON_TERRAIN` during that episode, set `sleeping=false`, apply one bounded wake impulse, latch that episode ID, then apply continuous tangent acceleration while it moves. If it rests again in the same episode, do not issue a second impulse. Collision may wake a resting ball at any wind strength through normal rigid-body behavior. Weaker wind affects airborne/already-moving balls but does not explicitly wake a sleeping one. Reawakened residents do not acquire or wait for initial-flight Fire slots. Rest events and strong-episode transitions drive the bounded eligibility scan; do not poll every sleeping body for impulses every physics tick.
  - Accept: weak wind does not explicitly wake resting balls; a strong episode wakes each eligible ball at most once, collision can wake it independently, and resumed terrain travel paints naturally without a gap, blob, or repeated impulse jitter.
- [x] **2.7** Make persistent projectile capacity and Fire admission truthful.
  - Change: track resident bodies, moving bodies, and initial-flight root families separately. A root family consumes one of two Fire slots only through its initial flight; later reawakening never consumes that slot. Move Splitter's one-generation rule into typed data shared by activation and capacity admission. The current 4–7 shot budget and one three-way split generation establish one hard resident cap of 21; reject any future loadout that exceeds it before stage admission.
  - Accept: valid current Splitter use is never silently rejected, two initial-flight roots still gate a third Fire without spending ammunition, reawakened residents do not block Fire, and resident bodies never exceed 21.

Batch gate:

- Wind scheduling, predictor parity, persistent lifecycle, terrain recovery,
  collision/strong-wind wake, continuous paint, pause, and resident capacity work
  together on one no-mechanism stage and one Splitter stage.

### Phase 3: Replace clear/fail with a timed coverage result

Goal: a run begins when the first queued root actually launches and ends only by Finish or timeout, with coverage as the sole score and deterministic attempt-level evidence.

Preconditions:

- Phase 2 passes.

Source owners: `src/stage/stage_controller.gd`, `src/stage/stage_data.gd`, `src/stage_generation/stage_progression_data.gd`, new `src/stage/attempt_observation.gd`, `src/projectile/projectile_manager.gd`, `src/autoload/game_state.gd`, `src/autoload/save_system.gd`, `src/replay/replay_recorder.gd`, `src/replay/replay_presentation_controller.gd`, `src/agent/gameplay_agent_api.gd`, result/stage tests

- [x] **3.1** Add the stage clock and Finish action to `StageController`.
  - Change: add `StageData.duration_seconds`. Generated stages use 90 seconds for 1–10, 120 for 11–20, and 180 for 21–30. The first actual root spawn starts the timer and wind. Add `finish_stage` for human, replay, and agent origins. Replace clear/fail terminal decisions with `FINISHING` and `RESULT`; once Finish or timeout is accepted, no later wind, wake, shot, or paint changes the result.
  - Accept: preparation and pre-fire aiming consume no run time; pause freezes the run; Finish is available only after the first shot; target coverage and zero shots do not auto-end; each duration tier ends once by Finish or timeout.
- [x] **3.2** Snapshot one authoritative coverage score.
  - Change: Finish or timeout rejects later actions, cancels queued-but-unspawned Fire without spending ammunition, drains already accepted paint, snapshots coverage from `PaintSystem`, and only then cleans resident balls. Coverage percentage is the displayed and persisted score; existing star thresholds remain grades only.
  - Accept: cleanup cannot add late paint or change the saved result; manual and timeout endings with the same paint mask produce the same score; time, shots, wind, and mechanisms add no separate score bonus.
- [x] **3.3** Preserve ammunition planning without forced waiting.
  - Change: retain generated 4–7 shot budgets and two initial-flight root slots. When ammunition is zero, aiming/fire disables but time, wind, resident balls, natural wakes, and Finish remain active. Reawakened balls never block Fire; only two root families whose initial flight has not first settled/terminated produce the capacity message, and rejected Fire never consumes ammunition.
  - Accept: the player can wait for strong wind to move resident balls or finish immediately; zero ammunition is never labeled failure; two initial-flight roots reject a third Fire; any number of already-admitted residents waking on the same tick does not change that Fire result or exceed the 21-body bound.
- [x] **3.4** Add attempt-level replay and observation truth.
  - Change: add `AttemptObservation` schema 1 for shots, wind schedule and
    transitions, rest/wake and terrain recovery, projectile terminal reasons,
    mechanism activations, result reason, authoritative paint identity, and final
    coverage. Keep per-shot observations for initial-flight diagnostics, but do
    not use them as stage terminal authority. Upgrade replay to format 8 with the
    wind identity and ordered aim/Fire/Finish actions; expose the same meaningful
    state through the agent/debug API.
  - Accept: retry and replay reproduce the same gameplay outcome and coverage;
    initial-flight Fire capacity does not depend on whether a resting shot
    observation is sealed; a disappearance always has a truthful reason.
- [x] **3.5** Migrate saved results without loss.
  - Change: move save format to version 4. Preserve existing `coverage` and `stars`; add elapsed seconds, shots used, and terminal reason only as metadata for a strictly better coverage run, not as score tie-breakers. An equal score preserves the previous metadata.
  - Accept: a version-3 fixture loads with identical best coverage/stars; lower or equal coverage cannot replace the best result or its metadata; a clean install receives valid defaults.

Batch gate:

- One representative run covers manual Finish, timeout, no-ammunition waiting, pause/resume, restart, save migration, replay, and agent actions without duplicating the same checks in each task.

### Phase 4: Convert the core mechanisms to flat terrain glyphs

Goal: Burst, Splitter, and Uphill Rebound read as circular terrain markings, activate only from real mountain contact, and produce the promised effects.

Preconditions:

- Phase 3 passes, including attempt-level activation recording and persistent projectile capacity.

Source owners: new `src/mechanisms/terrain_mechanism_resolver.gd`, new `src/mechanisms/terrain_glyph_mechanism.gd`, obsolete `src/mechanisms/gimmick_base.gd`, `src/mechanisms/mechanism_data.gd`, mechanism scripts/scenes/resources, `src/projectile/paint_projectile.gd`, `src/gameplay/gameplay_scene.gd`, new `src/stage_generation/mechanism_loadout_planner.gd`, `src/stage_generation/route_graph_resolver.gd`, `src/stage_generation/mechanism_placement_generator.gd`, phase 5 mechanism tests and capture fixtures

- [x] **4.1** Replace physical mechanism bodies with one surface-glyph contract.
  - Change: replace `GimmickBase` with `TerrainGlyphMechanism`, which owns presentation, selection, charges/cooldown, and a narrow effect interface but no projectile body. Store each glyph's radius in its typed data and use that same value for its rendered circle, activation footprint, and query-only selection footprint. Build terrain-conforming circular ring/icon meshes offset only enough to avoid z-fighting. `PaintProjectile` submits base top paint first, then emits a typed valid-top-contact event; `TerrainMechanismResolver` evaluates the center/radius and invokes the glyph effect. Delete the obsolete physical-body base and scenes after migrated tests pass.
  - Accept: a projectile cannot collide with a glyph in midair; a top contact inside the visible circle activates exactly once per allowed charge/cooldown; an equally close contact outside does not; visible and activation footprints align on representative slopes.
- [x] **4.2** Make Burst a consuming bomb glyph.
  - Change: apply the normal contact paint, accept the Burst radial paint into the authoritative queue, consume the glyph charge, and then terminate the projectile as `CONSUMED`.
  - Accept: one hit produces the normal and Burst paint, removes the incoming ball only after paint acceptance, records `burst_consumed`, and cannot reactivate when spent.
- [x] **4.3** Make Splitter's three directions readable and useful.
  - Change: refactor mechanism loadout into two deterministic passes: build terrain/route topology and generic glyph anchors first, then choose mechanism kinds. Admit Splitter only where three distinct reachable top branches produce visibly different useful routes, store those routes, and draw matching arrow spokes. If an anchor fails, choose another valid kind before placement; keep split recursion disabled.
  - Accept: fixture and running capture show three visually distinct branches; all three arrows match their child launches and three distinct valid-top targets; capacity never silently rejects a valid activation.
- [x] **4.4** Replace Bumper with Uphill Rebound.
  - Change: migrate `BUMPER` data/replay values to `UPHILL_REBOUND`. Use the authoritative local height field to find the steepest meaningful ascent, store that tangent, align the glyph arrow, and apply a tangent-plus-lift impulse. Reject locations too flat to promise an uphill result.
  - Accept: the arrow, stored uphill direction, higher terrain side, and actual redirected motion agree; flat terrain does not receive this glyph.
- [x] **4.5** Keep the count curve and replace placement acceptance.
  - Change: retain 0, 1, 2, then gradual growth to 6 glyphs. Replace the current kind-first physical-pad construction with generic candidate anchors followed by deterministic kind assignment. Validate minimum glyph separation, projected slope distortion, valid top footprint, camera-readable screen diameter, and kind-specific effect witnesses before typed placement/catalog materialization.
  - Accept: small stages contain 0–2 glyphs, large stages may contain up to 6, no glyph overlaps another or leaves valid top terrain, and each placed effect has a reachable/useful route witness.

Batch gate:

- Updated mechanism tests, stage generation admission, prediction/contact ordering, attempt observation, and 1280×720 mechanism captures pass for all three kinds.

### Phase 5: Unify camera interaction and expose the new run state without covering the mountain

Goal: the player can move naturally between locked aiming and free map inspection, read the new run rules, and keep the mountain and trajectory as the dominant visual surface.

Preconditions:

- Phase 4 passes; runtime signals and result fields are stable.

Source owners: `src/camera/camera_director.gd`, `src/input/aim_input_controller.gd`, `src/gameplay/gameplay_scene.gd`, HUD scenes/scripts, replay/agent presentation actions, result panel, pause/settings, translations, new wind cue presentation owner, procedural mesh/particle resources, delivery capture runner, `.agents/design/*`

- [x] **5.1** Replace camera presets with aim lock and map inspection.
  - Change: replace Follow/Wide/Cannon and the gameplay 1×/2×/Pause observation strip with `CameraDirector.InteractionMode { AIM_LOCKED, MAP_INSPECTION }`. Keep `StageController` in `AIMING` during both modes. `AIM_LOCKED` restores the authored aiming pose; left drag adjusts yaw/elevation, wheel adjusts power, keyboard aim remains active, and Fire is available. `MAP_INSPECTION` blocks aim and Fire input; a short terrain click changes the inspection focus, left drag orbits the safe camera around that focus, and the wheel zooms across a range that can frame the whole mountain. Tab and one focusable localized toggle switch modes. Briefing starts in inspection; Start enters aim lock; returning to aim preserves the current aim values and preview. Gear and Escape remain the only pause entry. Replay playback may keep its own speed controls, but normal gameplay does not expose time scaling.
  - Accept: drag and wheel affect only aim/power while locked and only camera orbit/zoom while inspecting; terrain click can refocus inspection; the whole mountain can be inspected without camera penetration; returning to aim restores the same aim and preview; no Follow/Wide/Cannon or duplicate Pause control remains; keyboard focus, Korean/English labels, and Gear/Escape behavior remain usable.
- [x] **5.2** Add one compact run-status card and Finish action.
  - Change: place remaining time, remaining shots, moving/resting resident counts, wind, and Finish in one compact edge-aligned status area. The main arrow means **projectile push direction**, projects the authoritative world vector through the active camera, and refreshes after camera movement. Show a localized strength band plus percentage and a countdown to the next 30-second change. During the final 3 seconds show the next wind direction and strength; use an explicit into-screen/out-of-screen cue when a flat arrow would mislead. The accessible label states direction, strength, and time. Place Finish away from Fire, enable it only after the first root spawns, and bind it to `F`.
  - Accept: every value comes from the same StageController/WindController/ProjectileManager snapshot used by physics, prediction, replay, and the agent API; direction cues agree with visible projectile/debris motion in both camera modes; Finish works by mouse and keyboard; the status area does not obscure the mountain at supported desktop resolutions.
- [x] **5.3** Add restrained world wind cues.
  - Change: use pooled procedural low-poly leaf/debris particles with no collision or paint participation. Drive direction and speed from the current wind vector. Add a brief gust/wake cue without camera shake.
  - Accept: particles visibly agree with the HUD push direction in calm, side wind, depth wind, and strong wind; they do not obscure glyphs or trajectory; disabling reduced decorative motion hides/limits particles without changing physics or UI wind information.
- [x] **5.4** Replace clear/fail result copy with coverage results.
  - Change: show final coverage, prior best, stars, elapsed time, shots used, and `완료` or `시간 종료`. Remove failure wording. Add a concise first-stage wind/glyph explanation and contextual one-time hints for forecast, Finish, and wind wake.
  - Accept: manual and timeout captures show truthful reasons and matching saved values; zero-shot remainder is not called failure; hints never remain over the aiming surface after dismissal.

Batch gate:

- HUD truth/layout, localization, keyboard focus, pause/settings, reduced motion, and named rendered states pass at both supported resolutions.

### Phase 6: Integrate, audit, and produce delivery evidence

Goal: finish with one coherent implementation, authoritative documentation, a production-style Windows build, and inspectable running-game proof.

Preconditions:

- Phases 0–5 pass their task and batch gates.

Source owners: all task-owned code/resources/tests/docs, `scripts/verify.ps1`, export preset, delivery capture runner, `.agents/evidence`, `docs/test-checklist.md`, `.agents/Documentation.md`

- [x] **6.1** Run the cross-module quality audit and make only small task-scoped corrections.
  - Change: invoke `codebase-quality-auditor` over wind ownership, state transitions, paint authority, replay/save schemas, mechanism resolver, HUD consumers, and generated-data invalidation. Remove obsolete physical-mechanism and clear/fail paths once replacement tests pass.
  - Accept: no competing timer, wind, coverage, terminal, or mechanism-contact owner remains; public contracts have explicit failure paths and no catch-all owner absorbs unrelated responsibilities.
- [x] **6.2** Run the mandatory repository verification and deterministic catalog checks once.
  - Change: run focused failures first, then the full `scripts/verify.ps1`, generated catalog `--check`, replay fixtures, and save migration checks. Explain the final gate's cost and stopping condition before it starts.
  - Accept: all required checks pass without weakening supply-chain or test safeguards; known non-blocking engine warnings are recorded once.
- [x] **6.3** Export and inspect production-style gameplay.
  - Change: export `builds/windows/PaintMountain.exe`, start only the exported
    build through the task-owned background capture path, and capture a compact
    set covering screen-right aiming, map inspection and aim return, live
    ball/paint contact, wind status, surface mechanisms, and both result reasons
    at 1280×720 and 1920×1080. Keep recovery and rest/wake acceptance in their
    focused runtime contracts rather than pretending one still frame proves motion.
  - Accept: the implementing agent visually inspects the compact evidence set;
    it proves the behavior-level checklist without redundant near-identical
    frames, and no ordinary foreground window takes focus.
- [x] **6.4** Close documentation without absorbing unrelated work.
  - Change: update implemented status and checklist evidence links, record exact validation results, mark this plan `done`, and commit only the task-owned documentation closeout.
  - Accept: docs distinguish implemented behavior from future mechanism candidates; `git status --short` leaves unrelated user files untouched; the closeout commit contains only task-owned records.

Completion evidence (2026-08-06):

- Screen-correct aiming, `AIM_LOCKED`/`MAP_INSPECTION`, persistent no-payload
  terrain balls, terrain recovery, deterministic 30-second wind, HUD/debris,
  timed coverage-only results, save format 4, replay format 8, and the three
  flat glyph effects are present in their named owners and focused checks.
- The active version-8 catalog structurally materializes all 30 persisted stages
  under manifest
  `1170c9db2002828a9f719f16ddc36b7b89ee9af17a24526586a2a2ee78317ca7`.
  Stage 04's Uphill Rebound is on the natural route at `t = 0.30` without an
  artificial shelf.
- The final `scripts/verify.ps1` run passed with the explicit Godot path, and the
  current Windows production export succeeded.
- Eight inspected exported-build captures under
  `.agents/evidence/wind-driven-coverage-loop/` cover aim return, map inspection,
  wind status, contact scale, representative glyphs, manual Finish, and timeout
  at 1280×720 and 1920×1080.
- Per user direction, the final validation boundary uses structural
  materialization for all 30 stages plus representative live/glyph checks. It
  does not include a full live-generation sweep of all 30 stages or an
  exhaustive micro-tolerance matrix, and makes no claim that those sweeps ran.

## Validation and Rework Controls

Resolve the approved Godot 4.x console binary through the project-specific environment variable used by the predecessor plan:

```powershell
if ([string]::IsNullOrWhiteSpace($env:PAINT_MOUNTAIN_GODOT)) {
    throw 'Set PAINT_MOUNTAIN_GODOT to the approved Godot 4.x console executable.'
}
$paintMountainGodot = (Resolve-Path -LiteralPath $env:PAINT_MOUNTAIN_GODOT).Path
```

| Cadence | Check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Task loop | One focused check for the changed behavior: screen-right aim, persistent/recovered contact, wind, timed result, one mechanism effect, or camera interaction | The task's implementation is coherent | That behavior or its fixture changes |
| Gameplay integration | Run one ordinary stage and one Splitter stage through aim, paint, wind, resident-ball movement, and result | Core gameplay phases are integrated | A gameplay-rule owner changes |
| Persistence and repeatability | Retry the same stage, replay one attempt, open an existing save, and exercise the agent-facing actions | Runtime schemas and actions are connected | Save/replay/agent or deterministic-input contracts change |
| Final gate | Run `scripts/verify.ps1`, catalog `--check`, release export, then inspect exported-build captures at 1280×720 and 1920×1080 | All tasks and focused checks pass | A final-gate input changes |

Final production commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd -- --check
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
& '.\builds\windows\PaintMountain.exe' --capture-background --capture-screen=wind_aiming --capture-size=1280x720 --capture-output=res://.agents/evidence/wind-driven-coverage-loop/wind_aiming-1280x720.png
```

Validation rules:

- Run the narrowest check that proves the current task.
- Run each broader gate once after its owned behavior is integrated.
- Do not run foreground gameplay or an ad hoc server. Use the background capture path and clean up only positively task-owned processes.
- Before the broad final verification, tell the user its purpose, scope, expected cost, and stopping condition.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Do not rewrite generated catalogs repeatedly during inner-loop work; rebuild after yaw/radius and placement inputs stabilize.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| An existing user-authored worktree change overlaps a task-owned hunk | Preserve the existing change and stage only the task-owned delta; defer that file if separation is unsafe | Do not absorb, revert, or claim the existing change |
| New radius/yaw causes a persisted stage seed to fail admission | Generate a new deterministic accepted seed, increment the catalog/contract version, and record the rejected reason | Never crop a target mask, weaken the range gate, or restore mismatched visual/physical radius |
| Maximum wind makes ordinary legal aiming unusable | Tune only `WindProfile` force while preserving readable strong wind and predictor/live parity | Do not hide predictor mismatch or change the 30-second schedule |
| A resting ball jitters or consumes measurable physics cost | Correct contact/friction tuning and allow Godot's reversible sleeping state; preserve contact/tangent metadata for collision or wind wake | Do not delete it, permanently freeze it, force every body awake, or run duplicate stationary paint writes |
| Terrain recovery visibly pops or repeatedly triggers on valid geometry | Fix the authoritative point/normal or recovery tolerance and preserve tangent/angular motion; retain diagnostics until canonical fixtures are clean | Do not restore the 3m/two-tick deletion path or hide the disappearance behind an effect |
| A flat glyph cannot conform without z-fighting | Tessellate a thin generated mesh from authoritative terrain samples and use a small visual offset | Do not restore a projectile collision volume or add a renderer-specific external dependency |
| A future Splitter child/generation rule proves a worst-case capacity above 21 | Reject that loadout before placement and require a separately approved capacity or split-rule change | Do not silently skip an accepted activation at runtime |
| Save/replay migration cannot prove old fixture preservation | Stop publication, retain the old reader as a versioned migration path, and add a deterministic fixture | Do not discard user best results or accept nondeterministic replay |
| Rendered evidence fails even though numeric tests pass | Treat the visible failure as blocking, fix the responsible owner, and recapture only the affected state | Do not mark a visual task complete from headless evidence |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | The executor must not choose a new product, architecture, dependency, score, ammunition, or UX contract |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: complete.
- Next task: none inside this contract.
- Last completed gate: bounded final verification, Windows production export,
  and inspection of the eight representative captures.
- Update rule: after a checkpoint passes, record its concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every implementation task and its focused acceptance check passes.
- All 30 persisted version-8 stages structurally materialize under the shared
  timed-result, seeded-wind, persistent-projectile, and glyph contracts.
- Representative exported-build evidence proves screen-correct aim, readable
  ball/paint scale, map inspection and aim return, wind UI, flat mechanisms,
  unobstructed HUD, and both stage terminal reasons.
- Durable product/architecture/test/status documents match the implemented behavior.
- The user-directed bounded validation substitution is recorded without
  implying a 30-stage live-generation sweep or exhaustive micro-tolerance matrix.
- Frontmatter status is changed to `done` only after implementation is complete.

Replan when:

- A material discovery invalidates a locked product, architecture, data, UX, safety, or validation decision.

Do not replan or stop for:

- Implementation-local mechanics already bounded by the acceptance outcomes.
- A passing check whose relevant inputs have not changed.
- The documented future mechanism idea portfolio, which remains explicitly out of scope.
