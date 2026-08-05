---
type: plan
status: active
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

Paint Mountain will become a deterministic timed coverage puzzle: screen-right input moves the predicted and real landing point right, paintballs remain on the mountain and can be reawakened by strong wind, wind changes on a readable 20-second schedule, the player ends a 90/120/180-second run manually or by timeout, coverage is the sole score, the three existing mechanisms are terrain-conforming circular glyphs, and gameplay controls no longer cover the mountain. Work begins only after the concurrent ballistic-range and layout-preparation slice reaches a clean committed checkpoint.

## Purpose

- Objective: turn the user's revised rules into one coherent, learnable, replayable gameplay loop instead of layering wind and a timer over the old clear/fail rules.
- Deliverable: revised product contracts, screen-correct aiming, persistent paintball motion states, seeded wind physics and cues, timed coverage results, three surface-glyph mechanisms, edge-aligned HUD, compatible save/replay/agent observations, focused tests, and production-rendered evidence.
- Completion state: all thirty stages run under the new loop; the same stage retry reproduces wind and physics inputs; every valid mountain-top traversal paints; completion and timeout produce the same authoritative coverage calculation; and exported 1280×720 and 1920×1080 captures prove the required states.

## Scope and Boundaries

In scope:

- Positive-yaw semantics and screen-space aim acceptance.
- Paintball physical/visual scale and paint footprint scale.
- Paintball `FLYING`, `CONTACTING`, `RESTING`, and terminal lifecycle.
- One data-driven, fixed-tick, seeded wind schedule and its predictor/physics consumers.
- 90/120/180-second stage durations, manual Finish, coverage-only score, and star thresholds.
- Burst, Splitter, and Uphill Rebound as terrain-conforming circular glyphs.
- Right-edge HUD, world wind debris, result presentation, accessibility labels, and reduced decorative motion.
- Save, replay, attempt observation, agent/debug API, localization, generation admission, tests, docs, export, and rendered evidence affected by these rules.

Out of scope:

- Implementing the nine additional mechanism candidates in the audit report.
- Changing terrain family generation except where the new projectile radius, yaw convention, or flat-glyph placement invalidates an admission contract.
- Replacing the concurrent asynchronous layout preparer or its three-entry cache.
- Unlimited ammunition, steering a projectile in flight, online services, new dependencies, plugins, or external asset packs.
- Mobile layout or a new art direction unrelated to wind and mechanism readability.

Constraints and invariants:

- `StageController` remains the sole owner of the stage state machine, timer, Finish action, and result decision.
- `PaintSystem` remains the only authoritative paint mask and coverage source. No second scoring representation is allowed.
- Game rules use the fixed 60 Hz physics tick. Render delta and wall-clock time do not decide wind, scoring, replay, or terminal state.
- The player still chooses yaw, elevation, and power before firing and never steers a projectile in flight.
- Existing per-stage ammunition remains 4–7 shots. Fire and wind wake share two moving-family slots, so at most two root shot families may be moving concurrently.
- Every valid playable mountain-top contact paints visually; only overlap with the scoreable target mask increases coverage.
- Paintballs have no finite paint payload and never terminate because paint is depleted.
- The same stage and accepted layout seed produce the same wind schedule on retry and replay.
- Flat mechanism glyphs do not participate in projectile collision. Activation derives from an authoritative mountain-top contact inside the glyph footprint.
- Compatibility rendering, Windows desktop, typed GDScript where practical, and no production dependency additions remain mandatory.

Destructive or irreversible actions:

- Generated stage catalogs and reachability evidence may be replaced only after their version changes and their deterministic rebuild command passes. These artifacts are reproducible; no save data is deleted.
- Existing save data is migrated in place. The implementation must not clear user best results.

Exact actions requiring owner or user approval:

- None inside this contract. Any external asset pack, dependency, change to ammunition policy, change to the coverage-only score, or implementation of additional mechanism kinds requires a new user decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Concurrent work | The active ballistic plan owns `CannonBallistics`, range admission, `AppRoot`, layout preparation, and shared docs | Active sibling plan and live dirty worktree | Do not edit or commit overlapping owners until that slice is committed; rebase this plan on its final contract | 0.1 |
| Horizontal aim | Input makes right drag/D increase yaw, while positive yaw launches toward world `-X`; tests check numbers, not screen direction | `aim_input_controller.gd`, `cannon_ballistics.gd`, `aim_interaction_test.gd` | Positive yaw means screen-right in the fixed aiming camera; keep right drag and D positive and change the shared ballistic/visual convention, then prove it by projection | 1.1 |
| Scale | Current radii are 0.90/1.50/2.10m and current scale capture does not show a live contact comparison | Projectile resource and runtime capture | Use 1.20m ball, 1.40m continuous/settle paint, 1.75m impact paint; visible and collision radius remain identical | 1.2 |
| Paint disappearance | There is no payload; slow/sleep/lifetime paths immediately free the body | `paint_projectile.gd`, `projectile_data.gd` | Slow or sleeping on valid terrain becomes `RESTING`; only consumed, escaped, invalid penetration, or 30 continuous non-resting seconds since the last valid-top contact terminates before stage end | 2.1 |
| Contact paint | Valid top contact emits paint; containment and mechanism bodies do not | Contact validator and paint projectile | Paint every valid playable top traversal, including non-scoreable top; score only through the existing target mask; suppress duplicate writes while stationary | 2.2 |
| Wind | No current owner, data, physics, UI, or replay contract exists | Repository search and architecture audit | Add 1,200-tick keyframes: hold ticks 0–1,079, ease ticks 1,080–1,199, commit at 1,200; forecast from tick 1,020; strong threshold 0.75; predictor and physics use the same scheduled launch tick | 2.3–2.5 |
| Stage result | Target coverage auto-clears and zero shots auto-fails; no timer/Finish | `StageController`, `StageData`, result HUD | Timer starts when the first queued root actually spawns; stage tiers are 90/120/180 seconds; no coverage/shot auto-terminal; Finish or timeout snapshots coverage; coverage is the sole score | 3.1–3.3 |
| Resting shots and observations | Shot observations seal when families terminate; resting balls can later wake | Stage controller, replay, agent API | Moving-root capacity ignores resting balls; add an attempt-level observation with wind/wake/result events; keep per-shot observations as initial motion diagnostics | 3.4 |
| Mechanism form | All three mechanisms are 8–10m physical 3D bodies and `GimmickBase` requires their physics bodies | Mechanism scenes/base and runtime captures | Replace `GimmickBase` with a glyph presentation/charge base plus `TerrainMechanismResolver`; selection remains query-only | 4.1 |
| Mechanism effects | Burst does not consume, Splitter creates three children, Bumper redirects downstream | Mechanism scripts and phase 5 tests | Burst consumes after ordered paint; Splitter keeps three route-aligned children; Bumper migrates to `UPHILL_REBOUND` using local terrain gradient | 4.2–4.4 |
| Mechanism count | Stage count already grows from 0 to 6 | `StageProgressionData` | Keep the count curve; replace placement checks with glyph overlap, slope projection, and screen-size checks | 4.5 |
| HUD occlusion | Horizontal observation controls cover the upper-right mountain | HUD scenes and runtime capture | Use a right-edge vertical tool rail, adjacent compact status card, and lower-right Finish; leave center/top-center clear | 5.1–5.3 |
| Persistence/replay | Save stores coverage/stars; replay format 7 lacks wind and Finish; agent lacks both | GameState, ReplayRecorder, GameplayAgentApi | Save format 4 preserves prior results and adds metadata for the best-coverage run; replay format 8 records wind and Finish tick; agent/debug expose the same snapshot | 3.4, 5.4 |
| Additional mechanisms | Nine non-overlapping candidates are documented | Audit report | Do not implement them in this slice; collect evidence from the revised core three first | Out of scope |

Readiness statement:

- Every material product, architecture, data, UX, ownership, safety, and validation decision for this slice is closed.
- The approved Godot 4.7.1 console binary and the repository's build, test, export, and background-capture paths are available.
- Remaining unknowns are implementation-local calibration details constrained by numeric outcomes and rendered acceptance below; they cannot change this contract.

## Tasks

### Phase 0: Establish the uncontested authority and baseline

Goal: begin from the concurrent generation slice without losing its work and make the user's latest rules authoritative before gameplay code changes.

Preconditions:

- The active `2026-08-06-ballistic-terrain-preparation.md` work has stopped all task-owned Godot processes, committed its coherent changes, and recorded its validation result.
- `git status --short` has been reviewed; unrelated user changes remain untouched.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`, `docs/technical-architecture.md`, `docs/test-checklist.md`, `.agents/Documentation.md`, this plan

- [ ] **0.1** Preserve the concurrent slice and establish the successor baseline.
  - Change: record the predecessor commit hash and inspect its final `CannonBallistics`, `ProjectileRangeConstraint`, `StageLayoutPreparer`, generated-catalog version, and changed docs. Update this plan only if names moved without changing the locked behavior.
  - Accept: no uncommitted file owned by the predecessor is staged or overwritten; its focused tests pass at the recorded commit.
- [ ] **0.2** Record the latest user supersession in product and technical contracts.
  - Change: append the wind, persistent paintball, timed coverage result, flat-glyph mechanism, Burst consumption, uphill rebound, scale, and edge-HUD decisions to `source-brief.md`; update interpretations and checklist rows; mark the old physical-3D mechanism and clear/fail clauses as superseded only in the named scope.
  - Accept: source brief, design spec, architecture, checklist, implementation status, and this plan use the same terms and do not claim the new behavior is implemented.
- [ ] **0.3** Remove stale scale assertions before adding new ones.
  - Change: update or retire old default-value assertions in `projectile_settling_test.gd` and any test that still expects the pre-recovery 0.52/4/6/4m values.
  - Accept: one canonical projectile resource defines production scale, tests load it, and no test embeds an incompatible legacy scale.

Batch gate:

- The repository imports headlessly and the predecessor's range/preparer tests still pass before the new yaw or radius contract is applied.

### Phase 1: Make aim direction and scale truthful

Goal: the same positive-yaw contract drives input, text, cannon pose, generation range, preview, and actual impact, and the live ball/paint proportion matches the user's direction.

Preconditions:

- Phase 0 passes.

Source owners: `src/cannon/cannon_ballistics.gd`, `src/cannon/cannon_controller.gd`, `src/input/aim_input_controller.gd`, `src/cannon/trajectory_predictor.gd`, `src/stage_generation/projectile_range_constraint.gd`, `resources/projectiles/basic_paintball.tres`, projectile scenes/materials, aim tests, delivery capture runner

- [ ] **1.1** Define positive yaw as aiming-camera screen right.
  - Change: reverse the shared yaw transform in launch direction, launch origin, cannon visual rotation, and analytic range fan while leaving right drag and D as positive input. Update directional copy to derive from the same sign convention.
  - Accept: from a fixed aiming camera, right drag and D both increase the projected screen X of the preview endpoint; left drag and A decrease it; preview and actual first contact agree within the existing physical tolerance at left, center, and right aims.
  - Guard: do not special-case the mouse or change only a label; all human, agent, replay, solver, and generator callers share the same yaw meaning.
- [ ] **1.2** Apply the revised physical and paint scale.
  - Change: set the production ball radius to `1.20m`, continuous and settle paint radii to `1.40m`, and impact paint radius to `1.75m`; update split-child spacing/radius derivation and collision/visible-mesh parity.
  - Accept: resource, collision shape, visible mesh, contact sampling, predictor clearance, reachability admission, and tests use the new values; no hidden visibility shell changes the apparent collision radius.
- [ ] **1.3** Rebuild radius/yaw-dependent generated evidence.
  - Change: increment the generation contract/catalog version, regenerate deterministic stage catalogs, and refresh direct reachability and containment evidence affected by the new physical radius and yaw fan.
  - Accept: catalog check passes, every stage remains runtime-ready, and no target pixel is cropped to make admission pass.
- [ ] **1.4** Replace the false scale capture with measurable rendered evidence.
  - Change: make `scale_contact` hold a real live projectile against a representative stage-04 top surface with its continuous trail and first-impact mark visible in the same frame; record screen-space ball and paint widths in capture metadata.
  - Accept: at 1280×720 and 1920×1080 the ball silhouette is identifiable, the continuous paint width is 1.10–1.30 times the visible ball diameter, and the impact mark is 1.35–1.70 times it.

Batch gate:

- Screen-space aim, projectile contact, analytic range, generated catalog, and scale-capture checks pass together before wind changes the trajectory recurrence.

### Phase 2: Add deterministic wind and persistent paintballs

Goal: wind affects both predicted and real motion, resting balls remain paint-capable and can wake only in strong wind, and all valid top traversal paints without duplicate stationary work.

Preconditions:

- Phase 1 passes and generated layouts are valid for the new radius/yaw contract.

Source owners: new `src/wind/wind_profile.gd`, new `src/wind/wind_controller.gd`, new `resources/wind/standard_wind.tres`, `src/stage/stage_data.gd`, `src/projectile/paint_projectile.gd`, `src/projectile/projectile_manager.gd`, `src/projectile/projectile_data.gd`, `src/cannon/cannon_ballistics.gd`, `src/cannon/trajectory_predictor.gd`, paint/contact tests

- [ ] **2.1** Replace deletion-on-settle with an explicit projectile lifecycle.
  - Change: add `FLYING`, `CONTACTING`, `RESTING`, and terminal state/reason data. Low speed or sleeping on a valid top freezes the body as `RESTING` instead of freeing it. `CONSUMED`, bounds/backstop escape, penetration rejection, or 30 continuous seconds since the last valid-top contact may terminate it; for a ball that has never contacted valid top, count from spawn. The 30-second clock does not run while `RESTING`. Stage result terminates all remaining bodies after the score snapshot.
  - Accept: a resting ball remains visible and queryable for the full stage, uses no active rigid-body simulation while resting, and reports an exact transition/terminal reason.
- [ ] **2.2** Guarantee paint on every valid playable-top traversal.
  - Change: emit impact on first valid top contact and distance-based sweeps for every subsequent traversed segment, whether or not the segment is scoreable. Keep the target mask solely inside `PaintSystem` coverage calculation. Suppress identical stationary writes after the resting spot is painted.
  - Accept: a ball crossing target and non-target top leaves one continuous visible trail; only target overlap changes coverage; containment walls, backstop, selection shapes, and glyph query shapes never paint.
- [ ] **2.3** Add the seeded fixed-tick wind owner.
  - Change: add typed `StageData.wind_profile` and point every current stage at `standard_wind.tres`. `WindProfile` owns tuning and `WindController` owns an upfront schedule, current/next vectors, interval tick, interpolation, and signals. Seed from stage ID, accepted layout seed, and profile version. Keyframes are 1,200 ticks apart: hold the current vector on interval ticks 0–1,079, ease to the next on 1,080–1,199, and commit it at 1,200. Show the forecast from tick 1,020. Initial strength is 0.25–0.55, later strength is 0.20–1.00 with adjacent absolute change at most 0.40, heading changes are 30–100 degrees, and every schedule has at least one strength `>= 0.75` by run tick 3,600.
  - Accept: identical stage/retry inputs produce byte-identical wind targets, interpolation samples, and schedule checksum for at least 180 seconds; pause advances no wind ticks; target commits occur exactly every 1,200 physics ticks.
- [ ] **2.4** Apply the same wind sample to prediction and live physics.
  - Change: add wind acceleration to the shared fixed-step recurrence and rigid-body force path. The predictor samples scheduled transitions that occur during a flight. Wind-aware predictions use the existing 20Hz cadence and are stamped with aim, wind schedule checksum, and an exact future launch slot on the next three-tick boundary; an accepted Fire queues the root spawn for that stamped tick, at most 50ms later. Any aim or launch-slot mismatch invalidates the result.
  - Accept: Fire never spawns from a prediction stamped for another tick. In calm, hold, and easing phases across three seeded directions, predicted first contact and actual first contact remain inside the existing contact tolerance; added launch latency is at most three physics ticks. At maximum wind, a canonical three-second shot shifts laterally by 4–8m relative to calm without making every legal aim leave the mountain.
  - Guard: do not send continuous wind through `queue_desired_velocity()`, which remains an instantaneous mechanism effect.
- [ ] **2.5** Wake resting balls only under readable strong wind.
  - Change: at normalized strength `>= 0.75`, project wind onto local terrain tangents. Fire and wake acquire the same two moving-family slots. Within one tick, process terminal/freeze first, then current family-state transitions, then reserved Fire spawns in ascending shot ID, then wake candidates by greatest positive tangent acceleration and ascending shot ID. Wake uses only remaining slots and retries on the next tick. Wake all eligible descendants in each selected family, then apply a bounded impulse plus continuous tangent acceleration. Weak wind moves airborne balls but never wakes resting ones.
  - Accept: strengths below 0.75 leave the fixture ball resting; strong wind never creates a third moving family; a same-tick Fire reserves its valid slot before automatic wake; replay reproduces the same ordering; a queued resting family wakes when a slot becomes free and moves 2–8m across a representative slope in three seconds while continuous paint resumes without a gap.
- [ ] **2.6** Make persistent projectile capacity truthful.
  - Change: because a generation-0 root can split at most once and generation-1 children cannot split, derive capacity as `maximum_shots * 3` when the stage contains any Splitter and `maximum_shots` otherwise. Keep Splitter's current unlimited-per-stage charge semantics and per-projectile one-activation rule. Reject any future loadout whose proven bound exceeds 24. Count a family against the two moving slots only while any descendant is moving; Fire and wind wake both use those slots.
  - Accept: the current maximum is 21 projectiles, every admitted Splitter activation fits without a hidden runtime rejection, resting families do not consume a moving slot, Fire plus wake never exceeds two moving families, and the hard cap is never exceeded.

Batch gate:

- Wind schedule, predictor parity, projectile rest/wake, continuous paint, pause, and capacity tests pass for at least one no-mechanism stage and one Splitter stage.

### Phase 3: Replace clear/fail with a timed coverage result

Goal: a run begins when the first queued root actually launches and ends only by Finish or timeout, with coverage as the sole score and deterministic attempt-level evidence.

Preconditions:

- Phase 2 passes.

Source owners: `src/stage/stage_controller.gd`, `src/stage/stage_data.gd`, `src/stage_generation/stage_progression_data.gd`, new `src/stage/attempt_observation.gd`, `src/projectile/projectile_manager.gd`, `src/autoload/game_state.gd`, `src/autoload/save_system.gd`, `src/replay/replay_recorder.gd`, `src/replay/replay_presentation_controller.gd`, `src/agent/gameplay_agent_api.gd`, result/stage tests

- [ ] **3.1** Add the stage clock and Finish action to `StageController`.
  - Change: add `StageData.duration_seconds`. `StageProgressionData` writes 90 seconds for stages 1–10, 120 for 11–20, and 180 for 21–30 when it builds the catalog; runtime `StageController` reads only the serialized `StageData` value. Record `run_start_tick` when the first queued root actually spawns; that tick is elapsed tick 0 and starts wind. Timeout is evaluated at `run_start_tick + duration_seconds * 60`. Add `finish_stage` for human, replay, and agent origins. Replace `STAGE_CLEAR`/`STAGE_FAILED` terminal decisions with `FINISHING` and `RESULT`, preserving `BRIEFING`, `AIMING`, and `PAUSED` behavior.
  - Accept: briefing, pre-fire aiming, and queued first-Fire latency consume no run time; pause freezes clock/wind/physics; Finish is unavailable before the first root spawns and available afterward; target coverage and zero shots never auto-end the run.
- [ ] **3.2** Snapshot one authoritative coverage score.
  - Change: Finish or timeout records its physics tick, rejects later actions, cancels queued-but-unspawned Fire without consuming ammunition, drains all accepted paint commands through that tick, freezes remaining balls, and reads final coverage from `PaintSystem`. If a Finish action is accepted on the timeout tick before terminal evaluation, its reason is manual Finish; otherwise timeout wins. Use coverage percentage as the displayed and persisted score; use existing star thresholds as grades only.
  - Accept: commands after the terminal tick cannot change the result; manual and timeout paths with the same paint mask produce the same score/stars; no time, shot, wind, or mechanism bonus changes the score.
- [ ] **3.3** Preserve ammunition planning without forced waiting.
  - Change: retain generated 4–7 shot budgets and the shared two moving-family slots. When ammunition is zero, aiming/fire disables but time, wind, resting balls, queued wakes, and Finish remain active. When wind occupies both slots, Fire reports that moving-family capacity is full rather than consuming ammunition.
  - Accept: the player can wait for strong wind to wake a resting family or finish immediately; zero ammunition is never labeled failure; Fire and wake cannot race into a third moving family.
- [ ] **3.4** Add attempt-level replay and observation truth.
  - Change: add `AttemptObservation` schema 1 for shots, wind targets/transitions, rest/wake episodes, mechanism activations, terminal tick/reason, paint checksum, and final coverage. Keep per-shot observations for initial motion diagnostics, but do not use them as stage terminal authority. Upgrade replay to format 8 with wind profile version, seed, complete keyframe list, schedule checksum, run-start tick, scheduled Fire ticks, and Finish action; expose the same fields through the agent/debug API.
  - Accept: record/replay produces the same wind events, mechanism events, final mask checksum, terminal tick, and coverage; moving-root capacity does not depend on whether a resting shot observation is sealed.
- [ ] **3.5** Migrate saved results without loss.
  - Change: move save format to version 4. Preserve existing `coverage` and `stars`; add elapsed seconds, shots used, and terminal reason only as metadata for the best-coverage run, not as score tie-breakers. Replace the saved best-run bundle only when new coverage exceeds the previous coverage by more than `0.0001` percentage points; an equal score preserves the previous metadata.
  - Accept: a version-3 fixture loads with identical best coverage/stars; lower or equal coverage cannot replace the best result or its metadata; a clean install receives valid defaults.

Batch gate:

- Manual Finish, timeout, no-ammunition waiting, pause/resume, restart, save migration, replay determinism, and agent-action tests pass under one seeded 180-second simulation.

### Phase 4: Convert the core mechanisms to flat terrain glyphs

Goal: Burst, Splitter, and Uphill Rebound read as circular terrain markings, activate only from real mountain contact, and produce the promised effects.

Preconditions:

- Phase 3 passes, including attempt-level activation recording and persistent projectile capacity.

Source owners: new `src/mechanisms/terrain_mechanism_resolver.gd`, new `src/mechanisms/terrain_glyph_mechanism.gd`, obsolete `src/mechanisms/gimmick_base.gd`, `src/mechanisms/mechanism_data.gd`, mechanism scripts/scenes/resources, `src/projectile/paint_projectile.gd`, `src/gameplay/gameplay_scene.gd`, new `src/stage_generation/mechanism_loadout_planner.gd`, `src/stage_generation/route_graph_resolver.gd`, `src/stage_generation/mechanism_placement_generator.gd`, phase 5 mechanism tests and capture fixtures

- [ ] **4.1** Replace physical mechanism bodies with one surface-glyph contract.
  - Change: replace `GimmickBase` with `TerrainGlyphMechanism`, which owns presentation, selection, charges/cooldown, and a narrow effect interface but no projectile body. Add a data-owned `glyph_radius` fixed to `4.0m` for all three migrated kinds; the rendered circle, activation footprint, and query-only selection footprint use that value. Build terrain-conforming circular ring/icon meshes offset only enough to avoid z-fighting. `PaintProjectile` submits base top paint first, then emits a typed valid-top-contact event; `TerrainMechanismResolver` evaluates the center/radius and invokes the glyph effect. Delete the obsolete physical-body base and scenes after migrated tests pass.
  - Accept: a projectile cannot collide with a glyph in midair; a top contact inside the visible circle activates exactly once per allowed charge/cooldown; an equally close contact outside does not; visible and activation footprints align on representative slopes.
- [ ] **4.2** Make Burst a consuming bomb glyph.
  - Change: use one fixed-tick command order: base impact paint suborder 0, 14m Burst mark suborder 1, charge consumption, then projectile `CONSUMED`. Consume only after both paint intents are accepted into the authoritative queue.
  - Accept: one hit produces both marks with the required sort keys and stable final mask checksum, removes the incoming ball after paint acceptance, records reason `burst_consumed`, and cannot reactivate when spent.
- [ ] **4.3** Make Splitter's three directions readable and useful.
  - Change: refactor mechanism loadout into two deterministic passes: build terrain/route topology and generic glyph candidate anchors first, then choose mechanism kinds and materialize typed placements. During the second pass, admit Splitter only when an anchor has three distinct, reachable, valid-top branch witnesses. Their predicted first-top contacts must be pairwise at least 8m apart and launch headings at least 15 degrees apart. Store those targets and draw matching arrow spokes. If an anchor fails, choose another valid kind before typed placement is created; if no assignment can fill the required count, reject that generated candidate. Keep split recursion disabled.
  - Accept: fixture and running capture show three visually distinct branches; all three arrows match their child launches and three distinct valid-top targets; capacity never silently rejects a valid activation.
- [ ] **4.4** Replace Bumper with Uphill Rebound.
  - Change: migrate `BUMPER` data/replay values to `UPHILL_REBOUND`. Sample the authoritative height field at center plus/minus the glyph radius on local X and Z, compute the central-difference gradient, and admit the glyph only when horizontal grade is at least 0.08. Store the steepest-ascent tangent, align the glyph arrow, and apply a tangent-plus-normal-lift impulse. A flatter candidate is rejected with no arbitrary fallback direction.
  - Accept: every admitted glyph has grade `>= 0.08`; arrow, stored tangent, sampled higher side, and actual post-contact velocity agree; the ball gains local elevation over the next measured segment; approaching from another side does not reverse the promised uphill direction.
- [ ] **4.5** Keep the count curve and replace placement acceptance.
  - Change: retain 0, 1, 2, then gradual growth to 6 glyphs. Replace the current kind-first physical-pad construction with generic candidate anchors followed by deterministic kind assignment. Validate minimum glyph separation, projected slope distortion, valid top footprint, camera-readable screen diameter, and kind-specific effect witnesses before typed placement/catalog materialization.
  - Accept: small stages contain 0–2 glyphs, large stages may contain up to 6, no glyph overlaps another or leaves valid top terrain, and each placed effect has a reachable/useful route witness.

Batch gate:

- Updated mechanism tests, stage generation admission, prediction/contact ordering, attempt observation, and 1280×720 mechanism captures pass for all three kinds.

### Phase 5: Expose time, wind, completion, and observation without covering the mountain

Goal: the player can read and act on the new rules while the mountain and trajectory remain the dominant visual surface.

Preconditions:

- Phase 4 passes; runtime signals and result fields are stable.

Source owners: HUD scenes/scripts, result panel, pause/settings, translations, new wind cue presentation owner, procedural mesh/particle resources, delivery capture runner, `.agents/design/*`

- [ ] **5.1** Move observation tools to a right-edge vertical rail.
  - Change: reserve the final 264 logical pixels of the 1280×720 reference viewport (`x=1016..1279`) for Settings, Follow, Wide, Cannon, 1×, 2×, and Pause, stacked as restrained icon buttons plus the adjacent status/result cards. Keep keyboard focus order, accessible names, Korean/English tooltips, and current enable/selected states. Camera composition keeps the summit, predicted first contact, and active ball at `x<=992`, leaving a 24px gap to the reserved zone.
  - Accept: at 1280×720 and 1920×1080 every right-side control stays inside the proportional reserved zone; summit, predicted path/first contact, active ball, coverage rail, aim panel, Fire, and results do not overlap it; the result drawer is at most 240 logical pixels wide; no label clips in Korean or English.
- [ ] **5.2** Add one compact run-status card and Finish action.
  - Change: place remaining time, remaining shots, moving/resting ball counts, current wind arrow/strength, next-change countdown, and the three-second next-direction preview beside the right rail. Project the wind arrow through the active camera so it agrees with screen motion. Place Finish at lower right, separated from Fire, enable it only after the first root spawns, and bind the `finish_stage` action to `F` by default.
  - Accept: every displayed value comes from the same StageController/WindController/ProjectileManager snapshot used by replay and agent APIs; the UI never predicts state locally; Finish has mouse and keyboard access.
- [ ] **5.3** Add restrained world wind cues.
  - Change: use pooled procedural low-poly leaf/debris particles with no collision or paint participation. Drive direction and speed from the current wind vector. Add a brief gust/wake cue without camera shake.
  - Accept: particles visibly agree with the HUD arrow in calm, side wind, and strong wind; they do not obscure glyphs or trajectory; disabling reduced decorative motion hides/limits particles without changing physics or UI wind information.
- [ ] **5.4** Replace clear/fail result copy with coverage results.
  - Change: show final coverage, prior best, stars, elapsed time, shots used, and `완료` or `시간 종료`. Remove failure wording. Add a concise first-stage wind/glyph explanation and contextual one-time hints for forecast, Finish, and wind wake.
  - Accept: manual and timeout captures show truthful reasons and matching saved values; zero-shot remainder is not called failure; hints never remain over the aiming surface after dismissal.

Batch gate:

- HUD truth/layout, localization, keyboard focus, pause/settings, reduced motion, and named rendered states pass at both supported resolutions.

### Phase 6: Integrate, audit, and produce delivery evidence

Goal: finish with one coherent implementation, authoritative documentation, a production-style Windows build, and inspectable running-game proof.

Preconditions:

- Phases 0–5 pass their task and batch gates.

Source owners: all task-owned code/resources/tests/docs, `scripts/verify.ps1`, export preset, delivery capture runner, `.agents/evidence`, `docs/test-checklist.md`, `.agents/Documentation.md`

- [ ] **6.1** Run the cross-module quality audit and make only small task-scoped corrections.
  - Change: invoke `codebase-quality-auditor` over wind ownership, state transitions, paint authority, replay/save schemas, mechanism resolver, HUD consumers, and generated-data invalidation. Remove obsolete physical-mechanism and clear/fail paths once replacement tests pass.
  - Accept: no competing timer, wind, coverage, terminal, or mechanism-contact owner remains; public contracts have explicit failure paths and no catch-all owner absorbs unrelated responsibilities.
- [ ] **6.2** Run the mandatory repository verification and deterministic catalog checks once.
  - Change: run focused failures first, then the full `scripts/verify.ps1`, generated catalog `--check`, replay fixtures, and save migration checks. Explain the final gate's cost and stopping condition before it starts.
  - Accept: all required checks pass without weakening supply-chain or test safeguards; known non-blocking engine warnings are recorded once.
- [ ] **6.3** Export and inspect production-style gameplay.
  - Change: export `builds/windows/PaintMountain.exe`, start only the exported build through the task-owned background capture path, and capture `aim_screen_right`, `scale_contact`, `wind_aiming`, `resting_reawakened`, `surface_mechanisms`, `timed_result`, and `timeout_result` at 1280×720 and 1920×1080.
  - Accept: the implementing agent visually inspects every image; all facts claimed in `docs/test-checklist.md` have separate running-game evidence; no ordinary foreground window takes focus.
- [ ] **6.4** Close documentation and commit the coherent slice.
  - Change: update implemented status and checklist evidence links, record exact validation results, mark this plan `done`, and commit only task-owned changes.
  - Accept: docs distinguish implemented behavior from future mechanism candidates; `git status --short` leaves unrelated user files untouched; the commit is scoped to this execution contract.

## Validation and Rework Controls

Use this approved binary in PowerShell:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
```

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `& $paintMountainGodot --headless --path . --script res://tests/aim_screen_direction_test.gd` and the one phase-owned focused test | Relevant owner parses and its narrow behavior is complete | That owner or fixture changes |
| Phase 1 gate | Aim screen direction, projectile contact/scale, range constraint, and `build_stage_catalog.gd -- --write` followed by `-- --check` | Tasks 1.1–1.4 pass | Yaw, radius, generation profile, or catalog input changes |
| Phase 2 gate | `wind_schedule_test.gd`, `wind_prediction_parity_test.gd`, `projectile_rest_wake_test.gd` including same-tick Fire/wake order, and continuous-paint test | Tasks 2.1–2.6 pass | Wind/profile/projectile/paint input changes |
| Phase 3 gate | `timed_coverage_loop_test.gd`, replay-format fixture, agent contract test, and save migration test | Tasks 3.1–3.5 pass | Stage/replay/save/agent contract changes |
| Phase 4 gate | Updated `phase5_mechanism_test.gd`, mechanism placement test, and three named mechanism captures | Tasks 4.1–4.5 pass | Mechanism data/resolver/placement/visual changes |
| Phase 5 gate | HUD truth/layout tests plus named 1280×720 and 1920×1080 background captures | Tasks 5.1–5.4 pass | Visible HUD/cue/result input changes |
| Final gate | `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $paintMountainGodot`, catalog `--check`, release export, then exported-build captures | Every phase gate passes | A final-gate input changes |

Final production commands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --script res://scripts/build_stage_catalog.gd -- --check
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
& '.\builds\windows\PaintMountain.exe' --capture-background --capture-screen=wind_aiming --capture-size=1280x720 --capture-output=res://.agents/evidence/wind-driven-coverage-loop/wind_aiming-1280x720.png
```

Validation rules:

- Run the narrowest check that proves the current task.
- Run each phase gate once after its tasks pass.
- Do not run foreground gameplay or an ad hoc server. Use the background capture path and clean up only positively task-owned processes.
- Before the broad final verification, tell the user its purpose, scope, expected cost, and stopping condition.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Do not rewrite generated catalogs repeatedly during inner-loop work; rebuild after yaw/radius and placement inputs stabilize.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| The concurrent predecessor changes a shared file or contract named here | Rebase onto its committed result, preserve its behavior, and update path/symbol references only | Stop if its final product decision contradicts positive-yaw or physical-radius decisions; do not silently choose a third contract |
| New radius/yaw causes a persisted stage seed to fail admission | Generate a new deterministic accepted seed, increment the catalog/contract version, and record the rejected reason | Never crop a target mask, weaken the range gate, or restore mismatched visual/physical radius |
| Maximum wind sends every legal canonical aim outside the mountain | Tune only `WindProfile` acceleration within the locked 4–8m three-second deflection outcome | Do not reduce strength semantics, hide predictor mismatch, or change the 20-second schedule |
| A resting ball jitters or consumes measurable physics cost | Freeze it and preserve contact/tangent metadata; wake through the explicit state transition | Do not delete it or run duplicate stationary paint writes |
| A flat glyph cannot conform without z-fighting | Tessellate a thin generated mesh from authoritative terrain samples and use a small visual offset | Do not restore a projectile collision volume or add a renderer-specific external dependency |
| A future Splitter child/generation rule proves a worst-case capacity above 24 | Reject that loadout before placement and require a separately approved capacity or split-rule change | Do not regenerate the same deterministic placement indefinitely or silently skip an activation at runtime |
| Save/replay migration cannot prove old fixture preservation | Stop publication, retain the old reader as a versioned migration path, and add a deterministic fixture | Do not discard user best results or accept nondeterministic replay |
| Rendered evidence fails even though numeric tests pass | Treat the visible failure as blocking, fix the responsible owner, and recapture only the affected state | Do not mark a visual task complete from headless evidence |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | The executor must not choose a new product, architecture, dependency, score, ammunition, or UX contract |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 0, waiting for the separately scoped ballistic terrain preparation checkpoint.
- Next task: 0.1, record and preserve the predecessor result.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record its concise evidence, check the task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- All thirty stages use the timed coverage result and seeded wind without losing deterministic restart/replay.
- Rendered evidence proves screen-correct aim, readable ball/paint scale, wind cues, rest/wake, all three flat mechanisms, unobstructed HUD, and both terminal reasons.
- Durable product/architecture/test/status documents match the implemented behavior.
- Frontmatter status is changed to `done` only after implementation is complete.

Replan when:

- A material discovery invalidates a locked product, architecture, data, UX, safety, or validation decision.

Do not replan or stop for:

- Implementation-local mechanics already bounded by the acceptance outcomes.
- A passing check whose relevant inputs have not changed.
- The documented future mechanism idea portfolio, which remains explicitly out of scope.
