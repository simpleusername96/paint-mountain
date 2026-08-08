---
type: plan
status: active
created: 2026-08-08
scope: implement direct terrain targeting, target-preserving angle and power adjustment, and truthful predicted-contact projectile lifetime
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
  - 2026-08-08-projectile-scale-balance-and-aim-performance.md
---

# Terrain-Targeted Aiming and Truthful Flight - Execution Contract

The player will select a Playable Terrain Surface point by clicking or dragging
in Aim View, vary the launch elevation or power while the other ballistic values
are solved to retain that point, and trust that a current predicted terrain
contact will not be removed by the shorter miss timeout before impact. The work
replaces the current pointer-drag-to-yaw/elevation contract while preserving a
stationary cannon, pre-fire planning, unsteerable projectiles, exact first-contact
prediction, Map Inspection, Shot Follow, and the current HUD hierarchy.

## Purpose

- Objective: make terrain impact selection direct, smooth, and physically
  truthful, including long valid flights that currently disappear at six
  seconds despite a predicted impact marker.
- Deliverable: one integrated human aiming flow, wind-aware inverse solver,
  target/trajectory presentation, predicted-contact lifetime protection,
  focused contracts, updated product/architecture records, and inspected
  Windows-release evidence.
- Completion state: a fresh executor can implement the work from this contract;
  implementation is not complete until all task checks and final gates pass.

## Scope and Boundaries

In scope:

- Aim View top-surface click selection and continuous left-drag retargeting.
- A persistent selected terrain target and latest-only inverse-aim work.
- Lower-left elevation decrease/increase controls in addition to the existing
  power controls; W/S changes elevation and the wheel changes power.
- Bidirectional target retention: an elevation request solves yaw and power;
  a power request solves yaw and elevation.
- Exact predicted surface-contact points, current/stale marker separation, and
  no false current-impact promise.
- Per-shot protection that extends the six-second never-contacted cleanup only
  for a matching current predicted Playable Terrain Surface contact.
- Human aim-transaction readiness, replay/agent compatibility, removal of the
  now-obsolete pointer-aim sensitivity setting, tests, docs, release captures,
  and task-owned evidence.

Out of scope:

- Post-impact path, roll, bounce, paint, mechanism, or coverage prediction.
- Steering after Fire, moving the cannon, changing terrain, target masks,
  scoring, stage balance, wind rules, mechanism behavior, camera bookmarks, or
  the fixed catalog.
- A runtime use of `DirectReachabilityValidator`, exhaustive target-wide
  solving, authored solutions, or automatic stage clearing.
- Target selection in Map Inspection; its click-focus, drag-orbit, and
  wheel-zoom meanings remain unchanged.
- New dependencies, plugins, network services, asset packs, renderer changes,
  physics-rate changes, or a second terrain/paint representation.

Constraints and invariants:

- `StageController` remains the sole Fire/readiness, shot, and result authority.
- `CannonController` remains the canonical current aim and launch owner.
- `TrajectoryPredictionJob` remains the sole exact fixed-60-Hz first-contact
  simulation; inverse solving may nominate candidates but may not implement a
  second collision truth.
- `WindController` remains the sole time-indexed wind schedule.
- `TerrainSurface` remains the canonical top point, normal, cell, triangle, and
  collider identity owner.
- `AimInputController` maps devices to intents; it does not search trajectories.
- `PaintSystem`, the fixed v10 catalog, and the existing open play bounds do not
  change.
- All physics queries are queued to fixed-physics work. Input callbacks only
  capture the newest screen position or control intent.
- Generic forward prediction remains advisory. Fire is withheld only while an
  explicit target/angle/power edit has no committed canonical aim; ordinary
  pending or predicted-miss preview state does not gate Fire.
- Existing whole-number aim keys, generated witnesses, certificate checksums,
  replay format 10, attempt schema 2, and save format 5 remain compatible.

Destructive or irreversible actions:

- None. Do not regenerate or promote a catalog and do not rewrite saved user
  results.

Exact actions requiring owner or user approval:

- Adding/upgrading a dependency, changing terrain or stage balance, widening
  target-contact tolerance above the locked value, changing Fire capacity,
  changing wind behavior, or invalidating the active catalog requires a revised
  contract and explicit approval.

## Locked Experience and Domain Decisions

### Selection and drag

- In Aim View, a left press queues a ray through the active camera. The next
  fixed-physics callback accepts only the first `TerrainSurface` top-body hit
  with a valid canonical `TrajectoryHitIdentity`. Support Shell, apron,
  mechanism, projectile, sky, non-finite, and stale hits are not targets.
- A valid press creates the selected target. While held, only the newest pointer
  position is picked once per physics tick; intermediate positions never form a
  queue. The target marker uses physics interpolation so its rendered movement
  is continuous without smoothing away from the actual surface.
- When the pointer temporarily crosses sky or a non-top surface during drag,
  retain the last valid selected target. Release settles exactly the newest
  valid target and requests immediate solution work.
- The selected target persists through Aim/Map switching, Shot Follow, early or
  automatic return, and repeated shots. Restart creates a fresh target from the
  first current exact terrain prediction of the generated default aim unless a
  user click has already superseded it.
- Map Inspection behavior is unchanged. UI controls consume their own events,
  so clicking a button never selects terrain behind the HUD.

### Angle, power, and branch continuity

- The selected target is a surface point plus normal and canonical hit address;
  it is not the prediction endpoint and not a UI-only marker.
- Elevation is the lower-left `각도` value. Angle buttons and W/S request
  `0.5°` steps. The requested elevation stays fixed while the solver adjusts yaw
  and power to retain the selected target.
- Power buttons retain `2%` steps and the wheel retains `1%` steps. The requested
  power stays fixed while the solver adjusts yaw and elevation to retain the
  selected target.
- Yaw becomes a derived, read-only direction value for human target-locked aim.
  A/D pointer-style yaw adjustment and its shortcut copy are removed. Replay,
  debug, and agent callers retain direct canonical yaw/elevation/power actions.
- The current low/high ballistic branch is initialized from the last committed
  trajectory. Subsequent solves choose the solution nearest that branch and
  last committed elevation. They never silently cross to the other branch.
- A candidate is valid only when the current-context exact prediction first
  contacts the Playable Terrain Surface and its surface contact point is within
  `projectile radius * 0.5` (`1.20 m` for the current root ball) of the selected
  point. Bounds exit, timeout, earlier shell/apron/mechanism/top collision, or a
  farther terrain contact is not a solution.
- Angles remain canonical at `0.1°`. Runtime power becomes canonical at `0.1%`
  so automatic target retention is not limited to whole-percent speed steps.
  Existing whole-percent `AimTuple.stable_key()` strings remain byte-for-byte
  unchanged; fractional keys use a distinct deterministic suffix. Offline
  generation continues to nominate integer power and must reproduce all active
  catalog identities without rematerialization.
- If a clicked target has no solution on the current branch, show a brief
  shape-based rejected target state, restore the prior selected target and
  committed aim, and re-enable Fire. If an angle/power step has no same-branch
  solution, keep the target and prior committed values and show the same denial
  feedback. Do not clamp to another point or branch.

### Pending, prediction, and Fire

- `TerrainAimController` owns selected-target and solve-revision state. An
  explicit human target/angle/power revision marks the canonical aim transaction
  pending. `StageController.fire_readiness_snapshot()` reports
  `aim_revision_pending` and rejects Human Fire until that revision either
  commits a verified solution or restores the last valid committed state.
- This is not generic prediction gating: agent/replay direct aim remains
  immediately committed, a normal forward-preview refresh does not affect Fire,
  and an automatic wind refresh retains the last committed solution until a new
  one can replace it atomically.
- The selected target ring appears immediately. Pending state is communicated
  by the ring shape/center, not calculation text. A current verified prediction
  adds the confirmed center treatment. A rejected request uses an X treatment;
  state never depends on color alone.
- The last complete trajectory dots may remain subdued while work is pending,
  but its old impact ring is hidden. A stale impact marker must never appear to
  be the current selected target.
- `TrajectoryPrediction` carries both projectile-center endpoint and the real
  collision surface point. World-space target and impact visuals use the
  surface point; launch/physics math keeps the center endpoint.

### Flight lifetime truth

- Keep `ProjectileData.never_contacted_timeout = 6.0` as the ordinary miss
  cleanup. Do not blanket-extend all in-bounds misses.
- Add resource-owned predicted-contact grace `0.5 s` and protected hard maximum
  `13.0 s`. When Fire has a prediction matching the current canonical aim and
  expected wind context whose first hit is Playable Terrain Surface, the root
  receives `max(6.0, prediction.duration + 0.5)` capped at `13.0 s` as its
  never-contacted deadline.
- If no matching current terrain prediction exists, the ordinary six-second
  deadline applies. Because stale impact rings are hidden, the UI makes no
  current terrain-contact promise in that case.
- Crossing `PlayBoundsSpec` still terminates immediately even during protected
  flight. Invalid geometry, invalid contact configuration, mechanism
  consumption, and stage cleanup keep their existing authority.
- Prediction/live parity is judged from the same launch origin, canonical aim,
  intended wind tick, radius, damping, fixed step, bounds, and first surface
  contact. A matching predicted terrain contact may not terminate as
  `MISSED_TERRAIN` before its protected deadline.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Direct terrain target | Aim View left drag changes yaw/elevation; a click preserves aim | `src/input/aim_input_controller.gd`; `tests/aim_interaction_test.gd` | Replace Aim View pointer meaning with queued top-only click/drag targeting | 2.1, 3.1 |
| Map interaction | `CameraDirector` queues clicks for focus and uses drag/wheel for orbit/zoom | `src/camera/camera_director.gd` | Preserve Map Inspection exactly; share no target-selection gesture there | 2.1, 3.1 |
| Selected-target authority | No selected target exists; current impact marker is prediction output | `src/cannon/trajectory_preview.gd`; `src/cannon/cannon_controller.gd` | Add domain target/controller and a separate world marker; do not make HUD or preview own target state | 2.1, 3.3 |
| Inverse solving | Generation-only solver scans integer powers/elevations synchronously and omits runtime wind | `src/stage_generation/direct_reachability_validator.gd:902`; `src/wind/wind_controller.gd` | Add bounded wind-aware runtime solver; reuse exact prediction job only for final collision truth | 2.2 |
| Same-target combinations | Aim values are independent; HUD angle is read-only and power alone has buttons | `src/cannon/aim_tuple.gd`; `src/ui/hud/aim_controls.gd`; `scenes/ui/hud/aim_controls.tscn` | Pin the edited elevation or power and solve the other values on the current branch | 2.2, 3.2 |
| Precision | Angles snap to 0.1°, power rounds to integer | `src/cannon/aim_tuple.gd:59` | Use 0.1% runtime power while preserving existing whole-power identities and catalog bytes | 2.3, 4.1 |
| Responsive work | Latest-only predictor advances at most 12 steps and about 1 ms per physics callback | `src/cannon/trajectory_prediction_scheduler.gd` | Extend its latest-work model for target solve requests; no synchronous input or Fire query | 2.2 |
| Fire authority | Fire ignores prediction and checks stage state/capacity/canonical aim | `src/stage/stage_controller.gd:143` | Preserve advisory preview; add only explicit uncommitted-aim revision readiness | 2.3 |
| Surface point truth | Prediction exposes only center endpoint publicly although rest info contains collision point | `src/cannon/trajectory_prediction_job.gd`; `src/cannon/trajectory_prediction.gd` | Publish both center endpoint and exact surface contact; use surface point for markers and target checks | 1.2 |
| Midair deletion | Live no-top root times out at 6 s; predictor can show collisions through 12 s | `src/projectile/paint_projectile.gd:158`; `resources/projectiles/basic_paintball.tres`; `src/cannon/trajectory_prediction_job.gd:8` | Protect a matching predicted terrain contact through duration plus grace; retain immediate bounds exit and six-second unpromised miss | 1.3 |
| Stale promise | Prior arc and impact marker remain subdued while a new context is pending | `src/cannon/trajectory_preview.gd:176`; completed 2026-08-08 plan | Keep only stale dots subdued; hide stale impact, while the selected target remains separate | 3.3 |
| Pointer sensitivity | Persisted setting only scales the pointer angle-drag gesture being removed | `src/input/aim_input_controller.gd`; `src/ui/screens/settings_screen.gd`; `src/autoload/save_system.gd` | Remove the setting/control/key; save v5 merge safely ignores the legacy unknown key | 3.2, 4.1 |
| Replay and agent | Both already record/apply numeric yaw/elevation/power through StageController | `src/replay/replay_recorder.gd`; `src/agent/gameplay_agent_api.gd` | Record committed solved tuples; do not add target coordinates or change schemas | 4.1 |

Readiness statement:

- The current user instruction explicitly supersedes the source-brief and UI
  clauses that prohibit click-to-target solving; Task 1.1 records that limited
  supersession before runtime code changes.
- Product behavior, ownership, precision, branch continuity, failure behavior,
  lifetime policy, dependency boundary, and validation commands are fixed.
- Godot 4.7.1 and the existing Compatibility project/export path are available.
  Remaining unknowns are implementation-local and may not alter visible
  behavior, ownership, tolerance, catalog identity, or acceptance.

## Tasks

### Phase 1: Record the new contract and remove the false impact promise

Goal: make the specification and first-contact/lifetime primitives truthful
before adding the new interaction.

Preconditions:

- Preserve the current user-authored `tests/target_mask_test.gd` modification
  and unrelated untracked evidence; do not stage or rewrite them.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`,
`docs/technical-architecture.md`, `.agents/design/UIUX_GUIDELINES.md`,
`src/cannon/trajectory_prediction.gd`,
`src/cannon/trajectory_prediction_job.gd`, `src/projectile/projectile_data.gd`,
`src/projectile/paint_projectile.gd`, `src/projectile/projectile_manager.gd`,
`src/stage/stage_controller.gd`, `resources/projectiles/basic_paintball.tres`

- [ ] **1.1 Record the approved terrain-targeted aiming supersession.**
  - Change: append the 2026-08-08 user revision to `docs/source-brief.md` and
    update the conflicting interaction, Fire-readiness, marker, lifetime, and
    ownership clauses in the working design/UI/technical specs. State that only
    the named Aim View gesture, target solve, explicit aim-revision readiness,
    stale impact marker, precision, and promised-contact lifetime clauses are
    superseded.
  - Accept: `rg` finds no active statement that Aim View terrain clicks never
    alter aim, pointer drag changes yaw, A/D is a human target-mode control, or
    a current predicted terrain contact may be killed at six seconds.
  - Guard: source-brief clauses for stationary cannon, no in-flight steering,
    advisory generic preview, Map Inspection, and no post-impact preview remain.
- [ ] **1.2 Publish exact prediction surface contact.**
  - Change: add immutable `contact_point` to `TrajectoryPrediction`; populate it
    from the collision rest result in `TrajectoryPredictionJob`; retain
    `endpoint` as the projectile-center position. Update predictors, test
    doubles, preview accessors, and collision-result constructors.
  - Accept: a sphere-cast fixture proves the center/contact offset matches the
    radius/normal and both values are deterministic at 60 Hz.
  - Guard: bounds-exit and timeout predictions have no fabricated contact point,
    and first collision identity/order does not change.
- [ ] **1.3 Protect a current promised terrain contact through impact.**
  - Change: add the locked grace/hard-maximum tuning to `ProjectileData`; have
    `StageController.request_fire()` read only an already complete matching
    current prediction, derive a constant-work root deadline, and pass it
    through `ProjectileManager` into `PaintProjectile`. Keep ordinary miss and
    immediate bounds exit behavior.
  - Accept: a deterministic fixture with predicted top contact after 6.0 s and
    before 12.0 s stays alive and reports the same first top contact instead of
    `MISSED_TERRAIN`; the same unmatched in-bounds miss still times out at 6.0 s.
  - Guard: a predicted or live bounds exit still terminates immediately, and
    Fire performs no trajectory calculation or physics query.

Batch gate:

- Run `tests/prediction_projectile_parity_test.gd`,
  `tests/projectile_settling_test.gd`, `tests/play_bounds_test.gd`,
  `tests/wind_prediction_test.gd`, and `tests/rapid_fire_contract_test.gd` once
  after Tasks 1.2-1.3 pass.

### Phase 2: Add target state and bounded inverse solving

Goal: turn one canonical terrain point and one edited ballistic control into a
verified same-target aim without blocking input.

Preconditions:

- Phase 1 acceptance and batch gate pass.

Source owners: new `src/cannon/terrain_aim_target.gd`,
`src/cannon/terrain_aim_solution.gd`, `src/cannon/terrain_aim_solver.gd`,
`src/cannon/trajectory_prediction_scheduler.gd`, `src/cannon/aim_tuple.gd`,
`src/cannon/cannon_controller.gd`, `src/terrain/terrain_surface.gd`,
`src/stage/stage_controller.gd`

- [ ] **2.1 Establish canonical selected-target state and top-only picking.**
  - Change: create typed immutable target data containing world point, normal,
    top hit address, and stable revision key. Add one reusable queued screen-ray
    picker that accepts only canonical top-body hits and returns no result for
    shell/apron/mechanism/projectile/sky hits.
  - Accept: flat, sloped, triangle-edge, shell, mechanism, sky, and stale-camera
    fixtures return the locked target or rejection identity exactly.
  - Guard: no target owner stores a height map, collider duplicate, or mutable
    terrain sample.
- [ ] **2.2 Implement latest-only wind-aware inverse solve requests.**
  - Change: implement deterministic candidate nomination for pinned elevation
    and pinned power using the shared launch origin, damp/gravity/wind recurrence,
    legal ranges, prior branch, and last committed aim. Extend the existing
    scheduler request model so it owns one replaceable solve/preview operation,
    advances exact candidate `TrajectoryPredictionJob`s under the existing
    12-step/approximately-1-ms callback budget, and publishes only the newest
    target/wind revision.
  - Accept: known flat and sloped targets solve in both pinned directions;
    positive-X target yaw has the correct sign; low/high solutions remain on the
    requested branch; wind seed/tick repeat deterministically; a newer drag or
    wind revision prevents stale publication.
  - Guard: `DirectReachabilityValidator` is never called from runtime, there is
    never more than one exact active job, and no input callback or Fire path
    performs a search or direct-space query.
- [ ] **2.3 Add committed aim revisions and tenth-percent power.**
  - Change: add neutral begin/commit/restore aim-revision methods at the
    StageController/CannonController boundary. Human explicit edits mark Fire
    pending until a same-revision solution commits or restores; direct
    replay/agent/debug `set_aim` stays atomic. Change runtime power
    canonicalization/keying to 0.1% while preserving whole-power stable keys
    and integer offline generation behavior.
  - Accept: Fire cannot launch the prior aim under a newly selected target;
    invalid requests restore the prior committed aim; fractional solved power
    launches, predicts, records, and replays identically; active catalog and
    generated witness identities are unchanged.
  - Guard: generic preview pending/miss never changes Fire readiness and no new
    stage state is introduced.

Batch gate:

- Run `tests/terrain_aim_solver_test.gd`, `tests/prediction_scheduler_test.gd`,
  `tests/stage10_prediction_readiness_test.gd`,
  `tests/rapid_fire_contract_test.gd`,
  `tests/generation_v10_materialization_test.gd`, and
  `tests/baked_stage_layout_test.gd` once after Phase 2 passes.

### Phase 3: Replace Aim View interaction and present target state

Goal: make click, drag, angle, power, pending, confirmation, and rejection
read naturally in the current Command Columns HUD and world view.

Preconditions:

- Phase 2 acceptance and batch gate pass.

Source owners: new `src/cannon/terrain_aim_controller.gd`, new
`src/cannon/terrain_target_preview.gd`, `src/input/aim_input_controller.gd`,
`src/gameplay/gameplay_scene.gd`, `scenes/gameplay/gameplay.tscn`,
`src/cannon/trajectory_preview.gd`, `src/ui/hud/aim_controls.gd`,
`scenes/ui/hud/aim_controls.tscn`, `src/ui/hud_controller.gd`,
`resources/ui/paint_mountain_theme.tres`, `translations/ui.csv`

- [ ] **3.1 Make Aim View click and drag own terrain retargeting.**
  - Change: wire `TerrainAimController`; replace pointer-angle drag with the
    queued latest top pick; preserve click-on-press, drag retention over invalid
    gaps, release settlement, mode/Shot Follow persistence, and default-impact
    initialization. Keep Map Inspection routing unchanged.
  - Accept: clicking three representative top points moves the selected target
    to each point; a long drag publishes only latest revisions and follows the
    surface without backlog; click/drag in Map Inspection changes only camera
    inspection state.
  - Guard: Fire, pause, HUD buttons, and mode-toggle clicks never leak through to
    terrain selection.
- [ ] **3.2 Add target-preserving angle and power controls.**
  - Change: add focusable 40 px minimum angle minus/plus controls to the existing
    lower-left group; route them and W/S to pinned-elevation requests; route
    existing power controls/wheel to pinned-power requests. Show elevation and
    solved power at one decimal, retain derived direction, remove A/D human aim,
    and replace contextual shortcut copy. Remove the Aim Sensitivity Settings
    row, runtime use, translation, default, and merge clamp; save v5 ignores the
    legacy key without a version bump.
  - Accept: angle adjustment changes power/yaw while the selected target remains
    within tolerance; power adjustment changes elevation/yaw with the same
    result; buttons hold-repeat, focus, tooltips, Korean/English fit, and
    Settings layout pass at 1280x720 and 1920x1080.
  - Guard: Fire remains the sole primary action; no duplicate target, branch,
    auto-aim, or explanatory panel is added.
- [ ] **3.3 Separate selected target from exact and stale prediction.**
  - Change: render selected/pending/confirmed/rejected target states with the
    existing blue semantic role plus shape; put impact presentation on
    `contact_point`; hide stale impact/exit markers while keeping permitted
    stale dots subdued. Keep depth testing, camera-distance scaling, and no
    post-impact line.
  - Accept: the selected ring is surface-bound and visible at early/late stage
    scales; confirmed state appears only for the matching target/aim/wind key;
    pending old impact cannot be mistaken for the new target; rejected state is
    legible without color.
  - Guard: markers do not cover HUD controls, disable terrain depth, or create
    a second aim/target authority.

Batch gate:

- Run `tests/aim_interaction_test.gd`, `tests/phase7_ui_test.gd`,
  `tests/shot_feedback_test.gd`, `tests/shortcut_prompt_test.gd`,
  `tests/localization_ui_test.gd`, and
  `tests/trajectory_preview_efficiency_test.gd` once after Phase 3 passes.

### Phase 4: Preserve non-human contracts and add reproducible evidence

Goal: keep direct tuple APIs deterministic and make every reported defect
reproducible without relying on a manual anecdote.

Preconditions:

- Phase 3 acceptance and batch gate pass.

Source owners: `src/replay/`, `src/agent/gameplay_agent_api.gd`,
`src/delivery/delivery_capture_runner.gd`, `tests/`, `docs/test-checklist.md`,
`.agents/Documentation.md`

- [ ] **4.1 Preserve replay, agent, debug, save, and catalog compatibility.**
  - Change: update consumers for fractional power and committed target-solved
    aim events without storing selected-target coordinates. Keep replay format
    10, attempt schema 2, save format 5, and direct tuple action APIs. Prove old
    whole-number actions and catalog resources load unchanged.
  - Accept: record/replay of a target-solved fractional aim produces the same
    first contact and shot observation; agent/debug direct set/fire bypasses the
    human target solver but uses the same canonical launch; old save settings
    load with the removed sensitivity key ignored.
  - Guard: no target selection or solver state enters score, paint, layout,
    replay identity, or agent terrain truth.
- [ ] **4.2 Add focused long-flight and visible-flow evidence states.**
  - Change: add deterministic capture-runner states for selected target,
    dragged target, low/high same-target combinations, target pending, and a
    protected greater-than-six-second terrain impact. Add/update focused tests
    and checklist rows for the complete user report.
  - Accept: every capture state exits zero, writes one native-size PNG and clean
    stderr, and the long-flight test records predicted duration, live first
    contact, and terminal reason sufficient to diagnose parity.
  - Guard: capture helpers stay delivery-only and do not add runtime hints,
    scripted solutions, or stage-specific production coordinates.

Batch gate:

- Run `tests/replay_recorder_v10_test.gd`,
  `tests/replay_presentation_test.gd`, `tests/phase8_debug_test.gd`,
  `tests/shot_follow_camera_test.gd`, and the new target/parity tests once after
  Phase 4 passes.

### Phase 5: Final audit, production build, and rendered QA

Goal: prove the integrated desktop flow and leave one truthful active record.

Preconditions:

- Phases 1-4 and their named gates pass.

Source owners: all task-owned files, `.agents/evidence/terrain-targeted-aiming-2026-08-08/`,
`.agents/Documentation.md`, `docs/test-checklist.md`, this contract

- [ ] **5.1 Run the final repository and quality gates once.**
  - Change: run `scripts/verify.ps1`; load `$codebase-quality-auditor` and audit
    the cross-module changes for competing aim/target/prediction owners,
    catch-all growth, API/schema drift, stale gesture/settings code, and
    reachable failure paths. Correct only small task-scoped findings.
  - Accept: verification and the audit pass with no unresolved task-scope
    blocker; unrelated worktree files remain untouched.
- [ ] **5.2 Export and inspect the running Windows release.**
  - Change: export once, run the named task-owned background capture states, and
    inspect every image directly at 1280x720 Korean and 1920x1080 English.
    Exercise click, drag, angle, power, pending, confirmation, invalid-target,
    Shot Follow, Map return, and the long protected impact in the release build.
  - Accept: no clipping, overlap, blocked world target, stale-impact confusion,
    focus loss, false Fire readiness, visible hitch, or premature promised-shot
    disappearance remains. The mountain, cannon, trajectory, and target stay
    readable at early and late stage scales.
  - Guard: Windows desktop is the product target; mobile layout is not added.
    Use both supported desktop sizes as the Level 3 responsive evidence.
- [ ] **5.3 Close records and commit only task-owned changes.**
  - Change: update implemented truth and test checklist with actual evidence,
    change this plan to `done`, and create coherent scoped commits without
    staging `tests/target_mask_test.gd` or unrelated evidence/catalog staging.
  - Accept: every plan checkbox is backed by recorded evidence, lifecycle
    status is `done`, `git diff --check` passes, and `git status --short` shows
    only preserved unrelated work outside the commits.

## Validation and Rework Controls

All commands run from the repository root in PowerShell. Do not run the complete
`scripts/test.ps1` suite merely to repeat focused evidence; add a missing test to
the focused set only when a named task risk requires it.

```powershell
$paintMountainGodot = (Resolve-Path -LiteralPath 'D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe').Path

foreach ($testScript in @(
  'prediction_projectile_parity_test.gd',
  'projectile_settling_test.gd',
  'play_bounds_test.gd',
  'wind_prediction_test.gd',
  'terrain_aim_solver_test.gd',
  'prediction_scheduler_test.gd',
  'stage10_prediction_readiness_test.gd',
  'rapid_fire_contract_test.gd',
  'generation_v10_materialization_test.gd',
  'baked_stage_layout_test.gd',
  'aim_interaction_test.gd',
  'phase7_ui_test.gd',
  'shot_feedback_test.gd',
  'shortcut_prompt_test.gd',
  'localization_ui_test.gd',
  'trajectory_preview_efficiency_test.gd',
  'replay_recorder_v10_test.gd',
  'replay_presentation_test.gd',
  'phase8_debug_test.gd',
  'shot_follow_camera_test.gd'
)) {
  & $paintMountainGodot --headless --path . --script ("res://tests/{0}" -f $testScript)
  if ($LASTEXITCODE -ne 0) { throw "Failed: $testScript" }
}

powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'

foreach ($capture in @(
  @{ Screen = 'terrain_target_selected'; Size = '1280x720'; Language = 'ko' },
  @{ Screen = 'terrain_target_dragged'; Size = '1280x720'; Language = 'ko' },
  @{ Screen = 'terrain_target_low_arc'; Size = '1280x720'; Language = 'ko' },
  @{ Screen = 'terrain_target_high_arc'; Size = '1920x1080'; Language = 'en' },
  @{ Screen = 'terrain_target_pending'; Size = '1280x720'; Language = 'ko' },
  @{ Screen = 'terrain_target_rejected'; Size = '1280x720'; Language = 'ko' },
  @{ Screen = 'protected_long_flight_impact'; Size = '1280x720'; Language = 'ko' },
  @{ Screen = 'map_inspection'; Size = '1920x1080'; Language = 'en' }
)) {
  $output = "res://.agents/evidence/terrain-targeted-aiming-2026-08-08/{0}-{1}-{2}.png" -f $capture.Screen, $capture.Language, $capture.Size
  & '.\builds\windows\PaintMountain.exe' -- `
    "--capture-screen=$($capture.Screen)" `
    "--capture-output=$output" `
    "--capture-size=$($capture.Size)" `
    "--capture-language=$($capture.Language)" `
    '--capture-background'
  if ($LASTEXITCODE -ne 0) { throw "Capture failed: $($capture.Screen)" }
}
```

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | The task's named focused Godot script only | Its owned source/test input changes | A relevant implementation input changes |
| Phase gate | The named phase batch set | All tasks in that phase pass | A phase-owned input changes |
| Final gate | `scripts/verify.ps1`, quality audit, one Windows release export, eight release captures and direct review | All phase gates pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Do not repeat a passing check merely to regain confidence.
- Treat rendered release evidence as required for the Level 3 player flow;
  headless tests and scene inspection cannot substitute for it.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval before resuming | Do not let the executor choose a new product, architecture, dependency, data, UX, safety, or validation contract |
| A pointer ray hits shell/apron/mechanism/sky or loses top during drag | Reject or retain the last valid target exactly as locked | Do not project to a fake plane, nearest cell, or hidden collider |
| No candidate on the current low/high branch meets target tolerance | Restore the last committed target/aim and show rejected shape feedback | Do not flip branch, widen tolerance, or move the target silently |
| Latest-only solve work approaches a visible stall | Reduce candidates advanced per callback while retaining the 1 ms/12-step caps and immediate marker movement | Do not run synchronously, queue history, use unsafe threads, or publish stale results |
| Fractional-power work changes any whole-power catalog/witness identity | Stop and fix backward key/serialization handling | Do not rebuild/promote the catalog or accept identity drift |
| A current predicted top contact still terminates as `MISSED_TERRAIN` first | Treat as a launch/wind/fixed-step/lifetime parity defect and fix the shared cause | Do not hide it, increase target tolerance, or label it a normal miss |
| Protected shot exits open bounds before the predicted contact | Compare current prediction and live launch context; if prediction also exits, keep escape; otherwise fix parity | Do not add a wall or suppress real bounds exit |
| Target refresh during changing wind cannot finish before every 30-tick epoch | Keep the last committed solution fireable during automatic refresh and publish the new solution atomically when current | Do not block Fire continuously or freeze wind |
| Lower-left controls do not fit supported desktop sizes | Recompose only the existing aim group with shared Theme roles and 40 px controls | Do not shrink required text/targets, move Fire, or add a new panel |
| Removed sensitivity key exists in an old save | Ignore it through the existing known-default merge | Do not bump save version or reject the save |
| Unrelated dirty files overlap a required edit | Stop that file branch and ask before merging ownership | Never revert, stage, or overwrite user-authored work |

Implementation-local discoveries may be handled inside the locked contract only
when they cannot change scope, visible behavior, ownership, architecture,
safety, tolerance, compatibility, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 1.
- Next task: 1.1, record the limited user supersession in the owning specs.
- Last completed gate: Discovery Closure Gate.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit. Do not mirror implementation
  progress in another plan.
- On start or resume, read this contract and inspect the worktree only enough to
  confirm checkpoint inputs, then continue from the first unchecked task whose
  prerequisites pass.
- Treat checked tasks and passing evidence as complete unless a relevant input
  changed or the contract schedules a broader final gate.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check, guard, phase gate, and final gate passes.
- Terrain click/drag, bidirectional same-target adjustment, pending/rejected
  behavior, current marker truth, and long-flight contact work in the running
  release at both supported evidence sizes.
- Prediction/live first contact and termination reason agree for the named
  valid-impact and true-miss fixtures.
- Specs, implemented-state record, test checklist, and lifecycle status describe
  the final code without duplicate authority.
- No placeholder or unresolved material decision remains.

Replan when:

- A material discovery invalidates the locked interaction, solver ownership,
  tolerance, precision compatibility, Fire transaction, lifetime, or validation
  contract.
- Completion would require a dependency, catalog regeneration, schema break,
  terrain/stage/wind change, or destructive cleanup.

Do not replan or stop for:

- Implementation-local math, signal, scene-wiring, or test-fixture mechanics
  already contained by the locked owners and checks.
- A passing check whose relevant inputs have not changed.
