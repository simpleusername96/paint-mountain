---
type: plan
status: done
created: 2026-08-07
last_reviewed: 2026-08-07
scope: surface-area coverage, target-paint legibility, contextual shortcut prompts, resolution-stable manual aim, advisory trajectory prediction, and stable Fire admission
source: user runtime feedback on 2026-08-07
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/ART_DIRECTION.md
  - 2026-08-07-target-coverage-and-safe-aim-framing.md
  - 2026-08-07-cannon-shot-observation.md
  - ../evidence/2026-08-07-aim-performance-product-audit.md
---

# Truthful Surface Coverage and Responsive Aiming - Execution Contract

Paint Mountain will score the painted physical area of the Target Area on the
canonical Playable Terrain Surface, make scored and unscored paint visually
distinguishable, keep the on-screen percentage synchronized with visible paint,
and expose every release-build gameplay shortcut where it is useful. Manual
mouse aim will use resolution-stable motion with retained sub-step input.
Trajectory prediction will remain truthful but advisory: it will no longer
control Fire admission or blank the interface while a newer preview is being
prepared. Runtime prediction will be latest-only, fixed-physics, and cooperatively
bounded so a wind forecast cannot repeatedly monopolize one frame.

This plan responds to the user's observed Stage 10 behavior. It does not add a
profiler, FPS counter, timing trace, click-to-target solver, movable cannon,
second paint mask, screen-space score, new asset pack, or exhaustive stage
solution work.

## Purpose

- Objective: make the amount painted, the number shown, the aim response, the
  impact preview, and the Fire button tell one understandable story.
- Deliverable: coverage metric version 2, a schema-compatible fixed-layout
  catalog migration, visually distinct target/non-target paint, synchronized
  paint/coverage publication, contextual keycaps, resolution-stable manual aim,
  prediction-independent Fire admission, one bounded runtime prediction job,
  focused regression contracts, updated product/architecture documents, and
  exported-build visual evidence.
- Completion state: a player can tell which paint scores; equal physical Target
  Area surface contributes equally regardless of slope; slow mouse movement is
  retained; aim does not change sensitivity with resolution; prediction work
  cannot toggle Fire; Stage 10's changing-wind window cannot start a full
  prediction every three physics ticks; and Tab, Space, F, and Escape are visible
  in the contexts where they act.

## Verified Current Evidence

### Coverage meaning and presentation

- `PaintSystem._write_paint_value()` writes the authoritative paint mask on all
  valid Playable Terrain Surface, but increments `_painted_target_pixels` only
  where the immutable target mask crosses the same threshold
  (`src/paint/paint_system.gd:482-503`). This correctly preserves visible
  non-target paint, but the shader currently renders target and non-target paint
  with the same final blue (`src/paint/terrain_paint.gdshader:44-62`). A player
  therefore cannot tell which blue pixels contribute to the HUD.
- `PaintSystem.coverage_percent()` divides raw target texel count by raw target
  texel count (`src/paint/paint_system.gd:607-610`). The 512-square mask is an XZ
  projection. Every texel has equal weight even when its canonical triangle is
  steep and represents materially more 3D surface than a flat texel.
- On a one-height-per-XZ triangle, physical surface area divided by projected XZ
  area is `1 / abs(normal.y)`. The current canonical topology already supplies
  the exact triangle normal used by paint reconstruction. No camera data or
  alternate geometry is needed.
- Visible paint texture publication is capped at 10 Hz while coverage publication
  is independently capped at 5 Hz (`src/paint/paint_system.gd:19-20,175-186`).
  The visible mask can therefore lead its percentage even when the counter is
  internally correct.
- The previous completed coverage plan explicitly locked raw texel counting.
  The user's new runtime report is direct contradictory evidence; the completed
  historical plan remains `done`, and this plan supersedes only that metric and
  its visual interpretation.

### Shortcut discovery

- Fire displays only `발사`, Aim/Map displays only its mode name, and Shot Follow
  displays only `대포로 돌아가기`. Their Space or Tab mappings exist only in a
  four-second Stage 01 hint or tooltips. The reviewed 1280x720 release captures
  show no persistent Space or Tab cue.
- Finish already shows `[F]`, but it is implemented separately. Gear/Escape is
  icon-only. A direct `R` restart shortcut exists in gameplay without a visible
  affordance even though the current UI contract keeps Restart in the pause menu.
- Debug-only F3 is not a release gameplay shortcut and must not be advertised.

### Mouse aim

- Mouse motion uses `InputEventMouseMotion.relative`, manually multiplies it by
  a viewport/logical-size ratio, accumulates it, and flushes once per rendered
  frame (`src/input/aim_input_controller.gd:93-113,162-167,190-197`). Godot 4.7
  provides unscaled `screen_relative` specifically for resolution-independent
  mouse aiming.
- Each flush starts again from the already snapped cannon value. `AimTuple`
  rounds yaw and elevation to 0.1 degrees (`src/cannon/aim_tuple.gd:49-60`), so a
  remainder smaller than the next canonical step is discarded instead of being
  retained across frames. This can make slow motion feel sticky or uneven.
- Every accepted aim change clears the current prediction and emits a null
  preview before the scheduler publishes a replacement
  (`src/cannon/cannon_controller.gd:41-72,114-122`). The impact marker therefore
  disappears and reappears as part of normal dragging instead of behaving like
  one continuously updated tool.

### Stage 10 hitch and Fire flicker

- The wind HUD receives a snapshot every physics tick. Gameplay forwards every
  snapshot to `TrajectoryPredictionScheduler.request_latest()`
  (`src/gameplay/gameplay_scene.gd:348-359`).
- The scheduler's changing-wind context advances every three physics ticks
  (`src/cannon/trajectory_prediction_scheduler.gd:4,120-142`). It immediately
  changes the cannon's expected context, which publishes a null prediction.
  `StageController` treats that null as non-fireable, and `ActionButtons` changes
  `disabled`, label, and tooltip on every transition. This is the direct cause
  of the visible enabled/disabled blinking and of clicks rejected between two
  apparently ready frames.
- The dynamic period begins before the visible three-second wind blend. The
  predictor horizon is 720 fixed steps, or 12 seconds. When that horizon first
  reaches the next transition, the prediction epoch starts changing every three
  ticks. With the current 30-second interval and three-second transition, this
  begins about 15 seconds after the first shot and can continue through the
  transition. Three deliberately aimed shots can plausibly reach this window.
- One synchronous prediction may run up to 720 `cast_motion` queries. The current
  preserved worktree version also contains endpoint rest-contact probes needed
  by collision-parity recovery. Repeating the complete job every three ticks is
  structurally unsuitable for the rendered interaction path even without a
  timing measurement.
- Additional resident balls and paint contacts add ordinary physics work and can
  amplify the hitch, but they do not explain the Fire button oscillation. The
  prediction/readiness coupling explains both symptoms with one causal chain.

## External Design and Engine Basis

- Godot 4.7 recommends `InputEventMouseMotion.screen_relative` for mouse aiming
  that must behave consistently across resolutions:
  <https://docs.godotengine.org/en/4.7/tutorials/inputs/mouse_and_input_coordinates.html>.
- Godot input accumulation is enabled by default; disabling it trades more input
  callbacks for more precision. This plan keeps the default and fixes coordinate
  choice and remainder loss first:
  <https://docs.godotengine.org/en/4.4/classes/class_input.html>.
- Godot separates rendered-frame work from fixed physics work and recommends
  physics-dependent operations in fixed processing:
  <https://docs.godotengine.org/en/4.7/tutorials/scripting/idle_and_physics_processing.html>.
- Godot's active scene tree and physics simulation are not generally thread-safe
  by default. This plan uses a cooperative main-thread job instead of moving
  `PhysicsDirectSpaceState3D` queries to an unsafe worker:
  <https://docs.godotengine.org/en/4.6/tutorials/performance/thread_safe_apis.html>.
- Microsoft's current Xbox accessibility guidance recommends alternate digital
  input for analog actions, adjustable mouse sensitivity, and consistent,
  labeled interaction prompts. The project already has keyboard aim; this plan
  exposes it and adds a bounded sensitivity setting:
  <https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/107>
  and
  <https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112>.

## Locked Product Decisions

### 1. Coverage means painted physical Target Area surface

- The canonical player-facing term is **Target Area surface coverage**. It is the
  unique painted physical area of the immutable Target Area divided by its total
  physical area on the Playable Terrain Surface.
- Camera projection, distance, occlusion, and current view never affect score.
  A screen-space pixel ratio is rejected because moving the camera would change
  the apparent answer.
- The 512-square `target_mask` remains the immutable eligibility map. The
  512-square paint mask remains the only mutable visual/scoring truth. No second
  mutable coverage image, triangle atlas, or full-mask recurring scan is added.
- Each target texel receives an immutable area weight from its canonical
  triangle: projected texel area multiplied by `1 / abs(normal.y)`. The catalog
  builder stores the total target surface area and metric version. At runtime,
  `PaintSystem` adds the same weight only on the first paint-threshold crossing.
  Overlap still counts once.
- Support Shell, bottom, apron, mechanisms, decorations, and airborne travel
  remain unpaintable or unscored exactly as before.
- Current target and star percentages remain unchanged for the first metric-2
  release. This task changes what the percentage truthfully measures; it does
  not quietly rebalance thirty stages at the same time.

### 2. Scored paint must be visually identifiable

- Dry Target Area remains a restrained neutral cue, but it must be readable in
  the authored Aim View.
- Target paint uses the current saturated paint color. Valid non-target paint
  remains visible in the same hue family but is lighter and less saturated.
  Both sample the same paint and target masks; this is classification, not a
  second visual-paint authority.
- The coverage rail tooltip and result explanation state that the percentage is
  the painted physical surface inside the visibly marked Target Area.
- Coverage publication is coalesced with the same dirty presentation batch that
  publishes visible paint. The number and texture cannot intentionally advance
  on different cadences.

### 3. Fire admission is independent of trajectory prediction

- `StageController` remains the sole Fire owner. A legal canonical AimTuple may
  Fire when the board is editable, shots remain, root capacity remains, no
  result is pending, and the action origin is allowed.
- A current trajectory prediction is advisory presentation, not a Fire
  prerequisite. A legal shot may miss the mountain and then use the existing
  apron, Support Shell, open-bounds, or never-contacted-timeout rules.
- This applies equally to Human, Replay, Agent, and Debug origins. Prediction
  scheduling can never make replay admission or agent actions depend on render
  cadence.
- Remove prediction `pending` and `invalid` from Fire-button reasons. Prediction
  status moves beside the world preview as a restrained `갱신 중` / `UPDATING`
  cue. The Fire button changes only for real stage rules such as capacity,
  shots, pause, action lock, or terminal result.
- Fire never computes a prediction, waits for one, or rechecks a changing wind
  context after the readiness snapshot.

### 4. Manual aim stays exact and responsive

- Preserve manual yaw/elevation/power, stationary cannon, no in-flight steering,
  left-drag aim, wheel power, A/D/W/S fallback, and Map View's separate orbit.
- Use `screen_relative` directly. Delete manual viewport/logical-size scaling.
- Keep an unsnapped requested yaw/elevation accumulator in `AimInputController`.
  Publish only changed canonical 0.1-degree AimTuples, but retain the fractional
  remainder so slow input is never lost.
- Do not spring-smooth or delay the authoritative aim. Cannon and HUD follow the
  canonical value on the rendered frame; interpolation that creates a second
  lagging gameplay aim is rejected.
- Add `aim_sensitivity_percent` to Settings with a 100% default and a 50-150%
  range. It scales mouse drag only; keyboard steps remain deterministic.
- Keep Godot's global accumulated-input default. Do not increase event volume as
  a substitute for fixing coordinate and scheduling errors.

### 5. Prediction is latest-only and cooperatively bounded

- Refactor the existing algorithm into one `TrajectoryPredictionJob`. The job is
  the sole step/collision implementation. `TrajectoryPredictor.predict_motion()`
  remains a synchronous offline/test wrapper that drives the same job to
  completion; runtime scheduler advances it incrementally.
- Runtime advances at most 24 simulation steps per fixed physics callback. It
  holds at most one active job and one newest pending key. A stale job never
  publishes, and no history or per-aim cache grows.
- During continuous aim input, nominate the newest aim at most once per 12
  physics ticks. Mouse release, a final keyboard/button change, stage entry, and
  returning to Aim View nominate the latest key immediately for the next fixed
  callback.
- Stable wind reuses a completed prediction. A changing or forecast-changing
  wind uses 30-tick preview buckets, with immediate nominations at transition
  start and end. The 60 Hz wind physics and HUD flag remain unchanged.
- Keep the last completed preview visible but subdued while its replacement is
  pending. Atomically replace the full arc and impact/exit marker only when the
  newest job completes. Never emit a null merely because a newer wind bucket
  exists.
- Direct-space queries stay on the fixed main-thread path. No worker thread,
  approximate second predictor, or input-callback query is permitted.

### 6. Shortcuts are persistent and contextual

- Add one Theme-owned `HudKeycap` style and one reusable presentational
  `ShortcutHint` component. It owns no input or gameplay rule.
- Show `[Space]` on Fire, `[Tab]` on Aim/Map, `[Tab]` on Return to Cannon, `[F]`
  on Finish through the same component, and `[Esc]` beside Gear and on Continue
  in the pause menu.
- Add one 14 px context line near the existing lower-left controls:
  `드래그 조준 · A D W S · 휠 파워` in Aim View and
  `드래그 회전 · 휠 확대` in Map View. Tooltips remain supplementary.
- Remove the four-second first-session control hint after persistent prompts are
  present. Do not duplicate the same instructions in a central tutorial panel.
- Remove the hidden direct `R` restart shortcut. Restart remains a visible pause
  menu action. Keep F3 debug-only and unadvertised.
- Escape must both open the pause menu and activate Continue from that menu.
  Buttons keep accessible names, focus styling, and mouse activation.
- Use text keycaps rather than inventing new keyboard/mouse icons or adding an
  asset dependency. Key names remain the physical legends `Tab`, `Space`, `F`,
  `Esc`, and `A D W S` in both locales.

## Domain and Ownership Contract

| Term/owner | Meaning and responsibility | Must not absorb |
| --- | --- | --- |
| `Target Area` | Immutable subset of Playable Terrain Surface eligible for score | Camera visibility or mutable paint |
| `Target surface coverage` | Unique painted physical Target Area area / total Target Area physical area | Screen pixels or non-target paint |
| `PaintSystem` | Sole mutable paint mask, threshold crossings, weighted numerator, coverage publication | Stage goals, HUD text, or a second mask |
| `TargetSurfaceCoverage` | Pure metric-version and canonical normal-to-area calculation | Paint state or texture publication |
| `StageController` | Board rules and constant-work Fire admission | Prediction computation or HUD layout |
| `CannonController` | Canonical aim and last completed prediction presentation state | Fire acceptance or device input |
| `AimInputController` | Pointer/key mapping, unsnapped input remainder, interaction start/end | Physics queries or alternate aim truth |
| `TrajectoryPredictionJob` | One resumable implementation of fixed-step integration and collision queries | Fire rules, threads, or paint prediction |
| `TrajectoryPredictionScheduler` | Latest key, job budget, wind/interaction nominations, atomic publication | Wind generation or a prediction history |
| `ShortcutHint` | Theme-aligned visible key legend | Input handling or action availability |

## Rejected Alternatives

| Alternative | Why it is rejected |
| --- | --- |
| Keep raw XZ texel coverage and only change the label | Does not correct steep-surface underweighting and leaves the player's reported mismatch intact |
| Score apparent screen pixels | Score would change with camera mode, distance, occlusion, and resolution |
| Score all visible blue paint | Removes the approved Target Area planning rule and makes non-target traversal authoritative |
| Add a second triangle coverage atlas | Creates competing mutable paint/coverage truth and a larger schema than the current one-height surface needs |
| Keep prediction as the Fire gate but hide pending UI | A click can still race a context change; replay and agent admission still depend on presentation work |
| Recompute prediction synchronously on Fire or mouse motion | Recreates the reported stall in the input call stack |
| Move physics-space prediction to a worker | The active scene/physics path is not thread-safe by default and would add ordering risk |
| Disable accumulated input globally | Increases callback volume without fixing resolution scaling, remainder loss, or prediction coupling |
| Smooth the cannon with a spring | Adds aim latency and makes the visible cannon disagree with the authoritative tuple |
| Show one permanent global controls banner | Consumes world space and presents irrelevant actions during Map View and Shot Follow |

## Version and Persistence Decisions

- Add `TargetSurfaceCoverage.METRIC_VERSION = 2`.
- Bump `PaintSurfaceTuning.CONTRACT_VERSION` from 4 to 5.
- Bump `BakedStageLayoutData.BAKED_LAYOUT_SCHEMA_VERSION` from 2 to 3 and persist
  `coverage_metric_version`, `total_target_surface_area`, and its deterministic
  checksum in the semantic payload.
- Bump `StageGenerationContract.CONTRACT_VERSION`, all StageData/profile versions,
  and the active catalog from 9 to 10. Regenerate metadata from the same canonical
  seed and inputs. Height, footprint, topology, target-mask, placement, cannon,
  and bounded witness identities must remain unchanged; only schema/coverage
  metadata and dependent payload hashes may change.
- Bump `ReplayRecorder.FORMAT_VERSION` from 9 to 10,
  `ShotObservation.SCHEMA_VERSION` from 5 to 6, and
  `AttemptObservation.SCHEMA_VERSION` from 1 to 2. Store the coverage metric
  version in shot, attempt, result, replay, and agent observations. Reject old
  replays clearly instead of comparing different scoring meanings.
- Bump `SaveSystem.SAVE_VERSION` from 4 to 5. Preserve selected stage and all
  settings. Move version-1 coverage bests into a `legacy_best_results` envelope,
  start current metric-2 bests empty, and never compare the two metrics. Add the
  bounded mouse-sensitivity setting during the same migration.

## Ordered Implementation Tasks

### [x] Task 1 - Record the superseding product contract

- Add the approved metric, advisory-prediction, open-miss Fire, contextual
  shortcut, and resolution-stable aim clauses to `docs/source-brief.md`.
- Update `docs/design-spec.md`, `docs/technical-architecture.md`,
  `.agents/design/UIUX_GUIDELINES.md`, `.agents/Documentation.md`, and
  `docs/test-checklist.md` without rewriting completed historical plans.
- Define the current terms exactly as in the ownership table above. Remove
  present-tense claims that prediction readiness gates Fire or raw texels are
  the final coverage meaning.

### [x] Task 2 - Implement and persist surface-area coverage

- Add `src/paint/target_surface_coverage.gd` as the pure metric owner.
- Extend the fixed-layout builder/data/codec/manifest and
  `GeneratedStageLayout` with validated metric-2 total surface area metadata.
- Change `PaintSystem` counters from target-pixel count to target-surface area,
  using the already reconstructed canonical triangle normal on first threshold
  crossing. Keep pixel counts as development diagnostics only if an existing
  test requires them; they must not drive gameplay or HUD.
- Co-publish coverage with dirty paint presentation and force the same final
  batch before result sealing.
- Migrate catalog, replay, observation, agent, result, and save schemas exactly
  as specified above. Preserve the v9 physical terrain identities while
  atomically promoting v10.

### [x] Task 3 - Make scoring legible in the world and HUD

- Adjust the existing terrain shader so dry target, painted target, and painted
  non-target are distinguishable at gameplay distance while support surfaces
  remain unpainted.
- Update coverage tooltip/result copy and use one visible Target Area explanation
  in briefing or rail hover/focus, not a persistent central panel.
- Capture target and non-target paint together in Aim View before accepting
  contrast. Review Korean and English at 1280x720 and 1920x1080.

### [x] Task 4 - Decouple Fire and refactor prediction state

- Change `StageController.fire_readiness_snapshot()` to use only stage-rule
  admission. Remove prediction from its fireable boolean and readiness-change
  key. Keep preview status in a separate narrow snapshot/signal.
- Rename or retire ambiguous `CannonController.is_aim_valid()` usage so
  mechanical `AimTuple.is_valid()` and prediction hit/miss are not conflated.
- Update HUD, replay, agent, capture, and focused tests to consume the same
  prediction-independent Fire rule. A predicted miss remains visibly marked but
  may be fired as a normal gameplay miss.
- Keep the last complete preview while a new key is pending; publish pending
  styling without clearing the trajectory to null.

### [x] Task 5 - Make manual aim resolution-stable

- Replace manual pointer scaling with `screen_relative` and add the unsnapped
  requested-angle accumulator.
- Emit interaction start/end intent to the scheduler without putting pointer
  state in `StageController` or `CannonController`.
- Add and persist mouse sensitivity. Apply it only to pointer aim.
- Preserve keyboard, wheel, Map View, Shot Follow return, focus, and replay
  behavior. Remove no legal yaw/elevation/power range.

### [x] Task 6 - Bound runtime trajectory work

- Refactor the current predictor into the single resumable job plus synchronous
  compatibility wrapper. Preserve current collision identity and endpoint-rest
  parity behavior; do not simplify the existing worktree recovery diff away.
- Implement 24-step fixed-tick advancement, one newest pending key, 12-tick
  interactive nominations, 30-tick forecast buckets, immediate settle/entry/
  transition-boundary nominations, and atomic newest-only publication.
- Remove `DYNAMIC_WIND_BUCKET_TICKS = 3` from the runtime contract and separate
  60 Hz wind/HUD snapshots from prediction nominations.
- Add structural tests that count simulation steps and publications, not wall
  time, FPS, or profiler samples.

### [x] Task 7 - Add contextual shortcuts and remove hidden actions

- Add the Theme keycap style and reusable hint component, then place the locked
  hints on Fire, Aim/Map, Return, Finish, Gear, pause Continue, and the aim/map
  context line.
- Remove the transient first-session hint and direct gameplay `R` restart.
- Route Escape through the pause overlay while paused so the visible keycap is
  truthful in both directions.
- Validate mouse hit regions, keyboard focus order, tooltip/accessibility text,
  and Korean/English fit without reducing required control heights.

### [x] Task 8 - Integrate, audit, and hand off

- Add focused fixtures for weighted coverage, publication synchronization,
  legal-miss Fire, aim remainder/resolution behavior, prediction job bounds,
  Stage 10 changing-wind readiness stability, contextual shortcut presence,
  pause Escape, replay/schema rejection, and fixed-catalog identity.
- Run `scripts/verify.ps1` once after the implementation is coherent, then run
  the Windows release export and production-style start path.
- Use the task-owned background capture path for Stage 01 target/non-target
  paint, Stage 10 Aim View with shortcuts, Stage 10 changing-wind preview
  pending, Shot Follow return with Tab, Korean 1280x720, and English 1920x1080.
- Inspect every running-game capture directly. Use the codebase quality auditor
  for cross-module ownership, stale failure paths, schema consumers, and
  duplicate prediction/coverage authorities. Make only small task-scoped fixes.

## Acceptance Checks

### Coverage

- A fixture containing equal projected target patches at 0 degrees and 60
  degrees assigns the 60-degree patch twice the physical-area weight. Painting
  either patch increments only its unique weight, and repainting it adds zero.
- Camera mode, FOV, viewport size, and camera position cannot change the result.
- Painted non-target terrain remains visible but contributes zero. In the
  rendered Aim View it is clearly less saturated than scored target paint.
- One dirty presentation batch publishes both visible paint and its current
  weighted percentage. Result sealing publishes the final batch first.
- V10 layouts reproduce every v9 physical/target/cannon checksum named above and
  add valid metric-2 metadata. A corrupt total/checksum fails closed.

### Aim, prediction, and Fire

- Several sub-0.1-degree pointer deltas accumulate to the same canonical result
  as one combined delta. Equivalent physical `screen_relative` motion produces
  the same aim at 1280x720 and 1920x1080.
- Input callbacks and Fire execute no `PhysicsDirectSpaceState3D` query.
- Runtime predictor advancement never exceeds 24 simulation steps in one fixed
  callback, owns at most one active job and one pending key, and never publishes
  a stale result.
- A legal aim can Fire before its newest preview completes. The actual shot uses
  current aim and wind. A miss exits or times out through existing open rules.
- During the Stage 10 changing-wind fixture, prediction status may change but
  Fire readiness never alternates because of it. Readiness changes only for
  shots, capacity, pause/action lock, or terminal state.
- The preview remains visible but subdued while updating and swaps the complete
  newest arc atomically. It never flashes empty during ordinary drag or wind
  refresh.

### Shortcut and UI

- Aim View visibly exposes drag/A-D-W-S/wheel, Space, Tab, F when available, and
  Escape without covering the cannon, trajectory, mountain route, or impact.
- Map View shows its relevant drag/wheel and Tab prompts only. Shot Follow shows
  only Return with Tab plus status; it does not expose aim/Fire hints.
- Pause shows Continue with Escape; Escape resumes. No release gameplay surface
  advertises or accepts direct R restart.
- Korean and English controls remain inside the viewport at 1280x720 and
  1920x1080, preserve 40 px minimum interactive height, and retain visible focus.

## Regression Guards

- `StageController` remains the sole stage/Fire/result authority.
- `PaintSystem` remains the sole mutable paint and coverage owner.
- `WindController` remains the sole wind truth; flag, HUD, preview, and live
  physics consume it without generating their own wind.
- Target and paint masks remain 512 square and share the existing UV/XZ mapping.
- Metric weights are immutable metadata, not a second mutable mask.
- Replay, agent, human, and debug actions use the same legal-aim Fire contract.
- The predictor keeps fixed 60 Hz damping/gravity/wind order, real ball radius,
  first collision/bounds exit, and current collision identity/parity behavior.
- Map View never changes cannon transform or aim. Shot Follow never steers a ball.
- No new dependency, plugin, network service, asset pack, renderer, physics tick,
  exhaustive solver, candidate search, or runtime terrain generation is added.
- Existing user-authored modifications in `src/cannon/trajectory_predictor.gd`
  and `tests/target_mask_test.gd`, plus unrelated untracked historical PNGs,
  must not be reverted, staged, or overwritten as cleanup.

## Focused Validation Commands

Use the configured Godot 4.7.1 console binary. The final implementation may add
the named new scripts, but it must not add timing assertions.

```powershell
$paintMountainGodot = (Resolve-Path -LiteralPath 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe').Path

foreach ($testScript in @(
  'target_surface_coverage_test.gd',
  'paint_queue_determinism_test.gd',
  'coverage_publication_test.gd',
  'aim_interaction_test.gd',
  'prediction_scheduler_test.gd',
  'stage10_prediction_readiness_test.gd',
  'rapid_fire_contract_test.gd',
  'shot_follow_camera_test.gd',
  'shortcut_prompt_test.gd',
  'localization_ui_test.gd',
  'pause_settings_flow_test.gd',
  'baked_stage_layout_test.gd',
  'generation_v10_materialization_test.gd',
  'replay_recorder_v10_test.gd',
  'replay_presentation_test.gd'
)) {
  & $paintMountainGodot --headless --path . --script ("res://tests/{0}" -f $testScript)
  if ($LASTEXITCODE -ne 0) { throw "Failed: $testScript" }
}

powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

## Predetermined Contingencies

| Trigger | Required response | Stop boundary |
| --- | --- | --- |
| Physical-area weighting makes a named target texel lack a valid upward canonical normal | Reject the baked layout as corrupt and fix the common topology/codec path | Do not clamp arbitrary bad geometry into score |
| Target/non-target blue remains indistinguishable in running Aim View | Increase only their shared shader value/saturation separation and re-review both stage scales | Do not hide non-target paint or add a second mask |
| A v10 build changes a v9 height, target, placement, cannon, or witness identity | Stop catalog promotion and fix serialization/build determinism | Do not accept terrain changes as incidental migration |
| A single runtime prediction job still visibly blocks a frame | Lower only the per-tick simulation-step budget and allow a longer preview-pending state | Do not restore Fire gating, synchronous input work, or unsafe threads |
| Continuous drag cancels every prediction before completion | Keep the newest nomination and guarantee an immediate settled/release job; show the stable pending cue | Do not queue aim history or publish stale arcs |
| Advisory preview and actual shot diverge during a wind transition | Treat the actual shot as truth, retain the pending cue, and refresh at the next locked bucket/boundary | Do not block Fire or fabricate wind interpolation |
| Persistent keycaps crowd the 1280x720 world view | Keep action keycaps on their controls and shorten only the context line | Do not remove Space/Tab discovery or shrink below HudCaption |
| Save migration finds metric-1 best results | Preserve them under the legacy envelope and start metric-2 comparison empty | Do not silently relabel old percentages as metric 2 |
| The preserved `trajectory_predictor.gd` diff changed after this plan was written | Stop predictor refactoring, inspect the new diff, and update the preservation contract before editing | Do not overwrite or stage unknown work |
| A material fact contradicts a locked ownership or product decision | Stop the affected task, update this plan and source documents, and ask only if user-visible scope or authority changes | Do not silently choose a second score, aim, wind, or Fire path |

## Progress

- Tasks 1-8 are complete. Coverage metric 2, v10 fixed layouts, synchronized
  publication, target/non-target paint classification, advisory prediction,
  resolution-stable aim, sensitivity, and contextual keycaps are implemented.
- The scheduler advances at most 24 prediction steps per fixed callback, owns
  one active job plus one newest pending request, uses 12-tick aim nominations
  and 30-tick wind buckets, and deduplicates unchanged 60 Hz wind HUD snapshots.
- Focused coverage, catalog, paint, prediction, Fire, aim, shortcut, pause,
  localization, observation, replay, persistence, mechanism, settlement, and
  Shot Follow contracts passed without FPS/timing/profiler assertions.
- The codebase quality audit found and corrected two stale paths: prediction
  context changes no longer emit false mechanical-aim invalidity, and identical
  wind snapshots no longer re-nominate an already owned prediction context. No
  unresolved task-scope ownership or competing-authority finding remains.
- `scripts/verify.ps1`, Windows release export, exported-build start, and five
  native-size running-release captures passed with Godot 4.7.1. The implementing
  agent inspected every capture and corrected English Aim-card localization and
  the world-space pending-label scale before acceptance.

## Next Steps

No implementation task remains in this ExecPlan. Further balance or feel changes
should start from user play against the v10 release rather than altering this
completed metric, Fire, prediction, or input contract implicitly.

## Stop Conditions

- Stop before adding or upgrading any dependency, plugin, asset pack, renderer,
  physics backend, network service, or external process.
- Stop before deleting, reverting, staging, or rewriting unrelated worktree
  changes or historical evidence.
- Stop before changing terrain geometry, target shape, cannon placement, wind
  rules, stage targets, projectile tuning, or mechanism behavior merely to make
  these acceptance checks pass.
- Stop before adding a screen-space score, second mutable paint/coverage mask,
  target solver, click-to-target aim, in-flight steering, or movable cannon.
- Stop and ask if implementation would discard current user-authored predictor
  work, invalidate current physical catalog identities, or require a destructive
  save migration rather than the preserved legacy envelope.
