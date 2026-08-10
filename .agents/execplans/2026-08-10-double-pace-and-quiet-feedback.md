---
type: plan
status: done
created: 2026-08-10
scope: double active gameplay pace, shorten difficulty-tier wall-clock limits, and retire passive gameplay message UI while preserving authoritative observations and results
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/ART_DIRECTION.md
  - 2026-08-09-remove-wind-system.md
---

# Double Pace and Quiet Feedback - Execution Contract

Paint Mountain will run active board play at two times the former simulation
pace while the stage clock remains real wall time. Stage limits become 60, 90,
and 120 seconds across the three ten-stage difficulty tiers. Passive shot-summary
and mechanism-message cards are removed completely because they duplicate
visible world and coverage feedback and obscure the mountain. Actionable and
terminal interfaces remain.

## Purpose

- Objective: reduce waiting during ball flight and mechanisms, shorten the run
  contract, and remove non-actionable message overlays without changing scoring
  or deleting diagnostic truth.
- Deliverable: a Godot 4.7.1 Windows build with two-times active simulation,
  wall-clock tier limits, no `ShotSummary` or `MechanismInfoCard`, synchronized
  prediction, current documentation, tests, and inspected runtime captures.
- Completion state: focused and repository checks pass, release screenshots show
  the quiet HUD in briefing/aim/follow states, the scoped commit is pushed, and
  this plan is `done`.

## Scope and Boundaries

In scope:

- Apply `Engine.time_scale = 2.0` only during active `AIMING` board play,
  including Shot Follow and Map View, and restore `1.0` in briefing, finishing,
  result, app teardown, and non-gameplay screens.
- Keep the project physics tick fixed at 60 Hz. Use a 1/30-second active
  simulation step in ballistic prediction and damped sampling so the preview
  models the live scaled physics step.
- Reduce tick-counted first-impact camera hold from 48 to 24 physics ticks so it
  changes from 0.8 to 0.4 wall seconds at 60 Hz. Delta-driven cameras, particles,
  and other active effects inherit the two-times time scale.
- Change canonical fallback duration tiers to 60 seconds for Stages 01-10,
  90 seconds for Stages 11-20, and 120 seconds for Stages 21-30.
- Keep the stage clock tick-counted at 60 real physics ticks per second, starting
  on the first accepted launch and unaffected by `Engine.time_scale`.
- Delete the shot-summary and mechanism-info scene/script components, HUD nodes,
  facade methods, gameplay calls, and message-only localization keys.
- Retain mechanism description keys stored in typed `MechanismData`; they remain
  domain metadata even though the passive card no longer renders them.
- Preserve sealed `ShotObservation`, mechanism activation agent/attempt events,
  paint, coverage, score, Finish, timeout, result, and persistence rules.
- Preserve briefing Start/Back and objective, Return to Cannon, Finish, Results,
  loading/failure, pause/settings, and context-sensitive control legend.

Out of scope:

- A player-facing speed toggle, new menu setting, replacement notification,
  toast, banner, sound, mechanic, dependency, or asset.
- Changing the fixed 60 Hz physics-tick project setting, terrain geometry,
  coverage thresholds, shots, mechanisms, scoring, or result ownership.
- Deleting `ShotObservation`, `MechanismData.description_key`, mechanism world
  labels, diagnostic exports, or agent events because their former UI consumer
  is removed.
- Regenerating the stage catalog unless a focused runtime check proves that the
  scaled fixed-step contract makes the current catalog unloadable or unplayable.

Constraints and invariants:

- `StageController` remains the sole owner of state, clock, shot progression,
  Finish/timeout admission, and result snapshots.
- `PaintSystem` remains the sole runtime coverage representation.
- Active physics and the advisory predictor use the same damping, gravity,
  radius, collision layers, bounds, and scaled fixed-step order.
- The wall clock advances one tick per real 60 Hz physics callback; it never
  derives elapsed time from scaled `delta`.
- Passive UI removal must not disconnect observation recording, mechanism
  effects, audio, camera shake, paint, scoring, or final results.
- Historical plans and evidence remain history. Active product and design docs
  describe the new current contract.

Destructive actions:

- Delete only the two obsolete HUD component scenes/scripts and their generated
  UIDs after every live reference is removed.
- Remove only message-exclusive translation rows. Keep mechanism names and
  description metadata used by resources or non-message contracts.

Approval boundary:

- The user explicitly approved this plan and implementation. Any proposal to
  remove actionable/terminal UI, change scoring, change the fixed 60 Hz tick, or
  regenerate/rebalance the stage catalog requires a new decision.

## Discovery Closure

| Concern | Verified owner and current behavior | Locked decision | Tasks |
| --- | --- | --- | --- |
| Active pace | `GameplayScene._on_state_changed` currently restores 1.0 in Aiming and Result; `AppRoot` restores 1.0 on teardown | Add one `GameplayPace` constants owner; Aiming uses 2.0, non-active surfaces use 1.0 | 2.1 |
| Physics precision | `project.godot` fixes physics at 60 Hz; live physics receives scaled delta while `TrajectoryPredictionJob` and damped ballistics use 1/60 | Keep 60 Hz and change active prediction recurrence to 1/30; retain a 12-simulation-second horizon | 2.2 |
| Camera/effects | Follow impact hold is 48 callbacks; camera smoothing and particle lifetime are delta/time-scale driven | Use 24 callbacks for the hold; allow delta-driven presentation to inherit active pace | 2.3 |
| Run clock | `StageController` increments `_elapsed_run_ticks` by one and derives duration ticks from the engine tick rate | Preserve that wall-clock owner and change only progression seconds | 2.4 |
| Duration tiers | `StageProgressionData` returns 90/120/180 and `StageData` uses those values unless explicitly overridden | Replace tiers with 60/90/120; retain explicit test-only overrides | 2.4 |
| Shot message | `ShotSummary` is a 1.2-second top-center card fed by sealed `ShotObservation` | Delete the UI consumer and keep recording the observation | 3.1 |
| Mechanism messages | `MechanismInfoCard` shows a briefing description and a 1.2-second activation card; it overlaps the coverage rail and duplicates the world glyph/objective | Delete both passive render paths; keep world selection focus and activation gameplay/effects/events | 3.2 |
| Localization | `hud.summary_*` and `mechanism.activated` are message-only; mechanism descriptions are serialized data | Delete only the four message-only keys and rebuild translation resources | 3.3 |
| Retained UI | Briefing, run status, coverage, aim controls, Return to Cannon, context legend, pause/settings, and result own actions or terminal facts | Keep them and prove their state visibility after deletion | 3.4 |
| Validation | Existing direct tests, verify script, Windows export, and delivery capture runner cover gameplay and HUD | Add a pace contract test; update feedback/UI/localization checks; inspect briefing, aiming, and post-impact release captures | 2.1-5.2 |

Readiness statement:

- Product behavior, simulation ownership, clock semantics, UI deletion boundary,
  retained data, documentation, and validation evidence are decided.
- Remaining unknowns are implementation-local compatibility failures. A catalog
  invalidation is the only discovered condition that requires replanning.

## Tasks

### Phase 1: Record the authoritative revision

- [x] **1.1** Append the bounded 2026-08-10 pace, duration, and passive-message
  supersession to `docs/source-brief.md`.
  - Accept: it distinguishes scaled simulation time from wall-clock stage time,
    names the deleted cards, and names retained internal/action UI contracts.
  - Evidence: `docs/source-brief.md` contains the dated limited supersession.
- [x] **1.2** Synchronize active design, architecture, UI guidance, implementation
  status, and QA wording without rewriting historical evidence.
  - Accept: no current-tense active document claims 90/120/180 durations,
    one-times active play, or passive shot/mechanism cards.
  - Evidence: active design, architecture, UI, art, implementation, and QA
    sections now state the fixed pace, wall clock, and quiet-feedback boundary.

### Phase 2: Implement active pace and wall-clock limits

- [x] **2.1** Add `GameplayPace` and apply it at gameplay state boundaries.
  - Accept: Aiming uses 2.0; briefing, finishing, result, and app teardown use
    1.0; debug slow motion restores the active baseline.
  - Evidence: `gameplay_pace_test.gd`, `phase4_state_test.gd`, and
    `phase8_debug_test.gd` passed.
- [x] **2.2** Align prediction and ballistic sampling with scaled 60 Hz physics.
  - Accept: prediction step is 1/30, horizon remains 12 simulation seconds,
    parity/readiness checks pass, and the project setting remains 60 Hz.
  - Evidence: pace, Stage 10 readiness, prediction parity, and long-flight live
    contact checks passed; predicted/live contact differed by 0.165 sim seconds.
- [x] **2.3** Align tick-counted camera presentation.
  - Accept: first-impact hold is 24 callbacks/0.4 wall seconds and existing
    Return-to-Cannon behavior remains.
  - Evidence: `shot_follow_camera_test.gd` passed the 24-tick hold and
    camera-only return contract.
- [x] **2.4** Change and test duration tiers.
  - Accept: stages 1/10 = 60, 11/20 = 90, 21/30 = 120; the StageController
    timer remains tick-counted and independent of scaled delta.
  - Evidence: `stage30_progression_test.gd` and the first-launch/pause/manual/
    timeout `phase4_state_test.gd` passed.

Phase gate: run the pace, progression, state, prediction parity/readiness, and
shot-follow camera tests. Stop if a current baked layout cannot load or if live
prediction and launch no longer satisfy representative readiness/parity checks.

### Phase 3: Delete passive message UI

- [x] **3.1** Delete ShotSummary presentation and wiring.
  - Accept: scene/script/node/facade/call sites are absent while sealed
    observations still reach `AttemptRecorder`.
  - Evidence: the scene/script/UID, HUD node/method, gameplay call, and obsolete
    shot-result connection are absent; quiet-feedback tests passed.
- [x] **3.2** Delete MechanismInfoCard presentation and wiring.
  - Accept: briefing selection still focuses the chosen glyph; activation still
    emits agent/attempt events and effects/audio/shake, with no card call.
  - Evidence: selection retains camera focus and activation retains all non-HUD
    calls; the card scene/script/UID and facade calls are absent.
- [x] **3.3** Remove message-only localization and rebuild generated translations.
  - Accept: `hud.summary_split`, `hud.summary_balls`, `hud.summary_direct`, and
    `mechanism.activated` are absent; mechanism titles/descriptions still load.
  - Evidence: CSV and regenerated English/Korean resources omit all four keys;
    `localization_ui_test.gd` proves their absence and retained descriptions.
- [x] **3.4** Update HUD, localization, and feedback contracts.
  - Accept: tests assert both obsolete nodes are absent and actionable/terminal
    HUD state remains visible and non-overlapping.
  - Evidence: shot feedback, Phase 7 UI, HUD truth, user-QA, and localization
    focused checks passed.

Phase gate: run `shot_feedback_test.gd`, `phase7_ui_test.gd`,
`phase8_hud_truth_test.gd`, `phase7_user_qa_contract_test.gd`, and
`localization_ui_test.gd` once their inputs stabilize.

### Phase 4: Integrate and inspect the running game

- [x] **4.1** Run repository validation.
  - Accept: all changed-contract focused checks and `scripts/verify.ps1` exit 0;
    any unrelated whole-suite baseline limitation is reproduced and recorded.
  - Evidence: all pace, prediction, state, catalog, HUD, localization, and debug
    focused checks plus final `scripts/verify.ps1` passed; the two unchanged
    whole-suite defects are recorded in the evidence README.
- [x] **4.2** Export and inspect release evidence.
  - Accept: Windows release export/start succeeds; 1280x720 Korean briefing,
    aiming, and post-impact captures contain no message cards, preserve required
    controls, and show no overlap, clipping, or empty replacement panel.
  - Evidence: the final Windows export and three hidden release captures exited
    0 with empty stderr; native visual inspection passed every named criterion.
- [x] **4.3** Record evidence and implemented status.
  - Accept: the evidence README lists exact commands, outcomes, screenshots,
    visual findings, and limitations without unmeasured performance claims.
  - Evidence: `.agents/evidence/double-pace-and-quiet-feedback-2026-08-10/README.md`
    contains the final automated, audit, export, hash, and visual record.

### Phase 5: Audit and publish

- [x] **5.1** Run `$codebase-quality-auditor` on the stabilized cross-module diff
  and apply only small task-scoped corrections.
  - Accept: no competing pace owner, stale message path, clock/prediction
    mismatch, reachable failure, or unrelated responsibility creep remains.
  - Evidence: the audit corrected Pause camera mutation and state-insensitive
    debug pace restoration; focused regressions and final verification passed.
- [x] **5.2** Complete and publish.
  - Accept: plan status is `done`, task-owned files alone are committed, the
    worktree is clean, and the tracking branch is pushed.
  - Evidence: the scoped completion commit contains only the files listed by
    this plan and is pushed to the tracking branch.

## Validation and Rework Controls

| Cadence | Check | Run when | Rerun only after |
| --- | --- | --- | --- |
| Inner loop | Direct Godot tests named in Phase 2 or 3 | The corresponding source parses | A relevant source/test change |
| Repository gate | `scripts/verify.ps1` | All source/scene/resource changes stabilize | A project input changes |
| Release gate | Windows release export and hidden release capture | Repository gate passes | A release-visible input changes |
| Visual gate | Native inspection of three named captures | Each capture exists | A visible HUD/camera input changes |
| Audit gate | `$codebase-quality-auditor` | Diff and evidence stabilize | A correction changes audited code |

Tests must restore global `Engine.time_scale` before exit. Expensive export and
capture checks run once after implementation stabilizes. A failed gate reruns
only after a relevant correction or a new evidence-producing hypothesis.

## Predetermined Contingencies

| Trigger | Required response | Boundary |
| --- | --- | --- |
| Existing baked catalog fails only because of the 1/30 active predictor step | Stop Phase 2, record the failing witness, and replan catalog version/regeneration with user approval | Do not silently weaken readiness or regenerate thirty stages |
| A non-message consumer uses a mechanism description key | Retain that key and narrow deletion to message-exclusive rows | Do not delete domain metadata for UI cleanliness |
| A remaining call needs shot/mechanism facts | Route it directly from the owning observation/event contract | Do not recreate a hidden HUD facade |
| Release capture exposes new empty space | Leave the mountain unobstructed unless an existing retained control is misaligned | Do not invent replacement copy or decoration |
| Two-times pace causes tunneling or prediction/live divergence | Stop publication and report the exact stage/shot witness | Do not raise physics tick or relax collision/readiness without approval |

## Progress and Next Steps

- Canonical progress: the checkboxes in this plan.
- Current phase: complete.
- Next task: none.
- Last completed gate: scoped commit and tracking-branch publication.
- Update rule: check and annotate a task only after its acceptance evidence exists.

## Completion and Stop Conditions

Complete when every task and gate passes, active docs describe the current
contract, runtime/release evidence has been inspected, the quality audit passes,
the plan is `done`, and the scoped pushed commit leaves a clean worktree.

Replan only for a proved catalog invalidation, tunneling/parity regression,
fixed-tick change, scoring/mechanism change, new dependency, or a request to
remove retained actionable/terminal interfaces.
