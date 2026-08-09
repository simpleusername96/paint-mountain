---
type: plan
status: blocked
created: 2026-08-09
scope: complete retirement of wind gameplay, presentation, data, diagnostics, tests, and active documentation while preserving the non-wind coverage loop
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - 2026-08-06-wind-driven-coverage-loop.md
---

# Remove the Wind System - Execution Contract

Paint Mountain will no longer contain a wind gameplay or presentation system. The current deterministic implementation is retired as a documented product experiment because it changes simulation outcomes without establishing a sufficiently legible player-controlled planning decision. Persistent paintballs, mechanism impulses, the stage clock, Finish, coverage scoring, terrain generation, and gravity/collision trajectory prediction remain authoritative.

## Purpose

- Objective: remove every active wind-owned rule, interface, resource, visible cue, diagnostic field, fixture, and test without weakening the remaining planning and coverage loop.
- Deliverable: a Godot 4.7.1 project whose runtime, generated resources, UI, agent observation, attempt logs, tests, active specs, and production evidence contain no live wind contract.
- Completion state: source and exported gameplay run without wind nodes or resources; the aiming HUD has a compact time/shots/residents/Finish layout; focused and repository checks pass; a production capture has been visually inspected; the decision and consequences are recorded; this plan is `done`.

## Scope and Boundaries

In scope:

- Record the 2026-08-09 user supersession and the truthful retirement rationale.
- Remove `WindProfile`, `WindSnapshot`, `WindController`, `CannonWindFlag`, their resource, scene nodes, UI, localization, physics, prediction, aiming, capture, observation, and test contracts.
- Remove unused wind resource references from the active catalog and every tracked generated catalog resource so no retained resource points at a deleted path.
- Change attempt observation schema 2 to schema 3 by removing the wind schedule and transition event; retain a generic projectile wake event for mechanism impulses without a wind episode field.
- Keep the attempt terrain seed sourced directly from `GeneratedStageLayout.terrain_seed`.
- Simplify the aiming status card to time, remaining/maximum shots, resident activity, and Finish.
- Update active product, design, architecture, implementation, QA, and acceptance documents while preserving completed wind plans and historical evidence as history.

Out of scope:

- Removing or redesigning persistent projectiles, mechanism impulses, stage duration, timeout, Finish, coverage, paint, terrain generation, or gravity/collision prediction.
- Adding replacement weather, random forces, new mechanisms, packages, plugins, assets, services, or dependencies.
- Rewriting completed historical plans, handoffs, or evidence to pretend wind never existed.
- Claiming measured CPU, GPU, memory, or FPS savings without a controlled profile.

Constraints and invariants:

- `StageController` remains the sole stage-state, clock, shot-progression, and result owner.
- `PaintSystem` remains the only authoritative paint mask and coverage owner.
- `ProjectileManager` retains resident lifecycle and mechanism-driven wake publication; `PaintProjectile` retains mechanism impulse behavior.
- `TrajectoryPredictionScheduler` and `TerrainAimSolver` remain bounded gravity/collision prediction owners, with no zero-wind compatibility abstraction.
- `StageData.terrain_seed` and `GeneratedStageLayout.terrain_seed` remain terrain-generation facts and must not be removed with the wind seed.
- Active specs describe the wind-free current contract. Completed plans and evidence remain historical and non-authoritative.
- No production dependency or engine-setting change is permitted.

Destructive or irreversible actions:

- Delete wind source/resource files, wind-only tests, and the task-owned ignored wind audit captures after confirming exact paths.
- Remove wind-only serialized lines from tracked catalogs; do not delete terrain catalogs or layouts.

Exact actions requiring owner or user approval:

- None beyond the wind retirement and cleanup explicitly approved in the current conversation. Any proposal to remove the persistent-ball/timer/coverage loop or to add a replacement mechanic requires a new user decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Product authority | `docs/source-brief.md` has later wind supersessions beginning in the 2026-08-06 coverage-loop revision | `docs/source-brief.md`; explicit 2026-08-09 user decision | Append a new limited supersession; preserve earlier text as history | 1.1, 4.1 |
| Runtime force and wake | `WindController`, `PaintProjectile`, and `ProjectileManager` apply per-tick acceleration and strong-episode wake | `src/wind/`, `src/projectile/paint_projectile.gd`, `src/projectile/projectile_manager.gd` | Delete wind force/wake only; retain mechanism wake with a two-argument generic signal | 2.1 |
| Aim and prediction | Aim nomination caches a 720-tick wind horizon; prediction jobs and publication keys include schedule/tick identity | `src/cannon/terrain_aim_solver.gd`, `trajectory_prediction_job.gd`, `trajectory_prediction_scheduler.gd`, `cannon_controller.gd` | Remove wind inputs and invalidation; keep bounded latest-first gravity/collision prediction | 2.2 |
| Stage composition and data | Gameplay requires a valid wind profile and owns wind nodes; `StageData` defaults to `standard_wind.tres` | `src/gameplay/gameplay_scene.gd`, `scenes/gameplay/gameplay.tscn`, `src/stage/stage_data.gd` | Remove the nodes, field, startup/reset wiring, and resource | 2.3 |
| Diagnostic schema | Attempt schema 2 requires `wind_schedule` and wind transition; terrain seed is incorrectly populated from the wind schedule seed | `src/stage/attempt_observation.gd`, `src/stage/attempt_recorder.gd` | Schema 3 rejects schema 2, contains no wind field/event, and receives terrain seed directly from generated layout | 2.4 |
| Agent contract | Gameplay observation exposes a `wind` dictionary and accepts `WindController` | `src/agent/gameplay_agent_api.gd` | Remove the field and configuration dependency; schema version follows AttemptObservation v3 | 2.4 |
| HUD and world cue | Run status displays wind and the cannon-side flag presents the same snapshot | `scenes/ui/hud/run_status_card.tscn`, `src/ui/hud/run_status_card.gd`, gameplay scene | Remove both; compact the right-edge card without adding replacement copy | 3.1 |
| Delivery capture | Aiming aliases currently route through wind checks and separate weak/strong flag states | `src/delivery/delivery_capture_runner.gd` | Keep generic `aiming`, burst, split, arc, and projectile captures; delete wind-only routes and checks | 3.2 |
| Serialized resources | One active catalog and 155 tracked generated resources contain an unused `standard_wind.tres` dependency | `resources/stages/catalog.tres`, `resources/generated_stage_catalogs/**` | Remove only the wind dependency lines from all retained catalogs | 2.3 |
| Validation | Baseline `scripts/verify.ps1` passed with shared Godot 4.7.1; export and background capture commands are established | `scripts/verify.ps1`, `scripts/test.ps1`, export preset, prior completed plans | Run focused checks during implementation, one complete suite, repository verify, release export/start, and one 1280x720 Korean Aim View capture | 2.1-5.2 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- The shared Godot 4.7.1 runtime, PowerShell scripts, Windows export preset, `git`, and authenticated `gh` are available; the pre-change repository verification passed.
- Remaining unknowns are implementation-local call-site cleanup and cannot change this contract.

## Tasks

### Phase 1: Establish the authoritative retirement decision

Goal: make the approved wind-free direction explicit before production contracts change.

Preconditions:

- Clean starting worktree and the successful pre-change `scripts/verify.ps1` result are confirmed.
- This contract is the only active ExecPlan.

Source owners: `docs/source-brief.md`, `.agents/execplans/2026-08-09-remove-wind-system.md`

- [x] **1.1** Record the limited user supersession.
  - Change: append the exact retirement scope, rationale, retained non-wind loop, and historical-evidence rule to `docs/source-brief.md` without rewriting earlier directives.
  - Accept: the newest supersession explicitly removes wind physics, wake, aim/prediction coupling, UI/world cues, diagnostics, resources, captures, and tests while retaining persistent balls, mechanisms, timer, Finish, coverage, terrain seed, and gravity prediction.
  - Evidence: `docs/source-brief.md` now contains `Later User Supersession (2026-08-09): Remove Wind` with each named boundary and the no-performance-claim limitation.

### Phase 2: Remove wind from runtime and data contracts

Goal: produce one wind-free gameplay model with no compatibility abstraction.

Preconditions:

- Task 1.1 passes.

Source owners: `src/wind/`, `resources/wind/`, `src/projectile/`, `src/cannon/`, `src/gameplay/gameplay_scene.gd`, `scenes/gameplay/gameplay.tscn`, `src/stage/`, `src/agent/gameplay_agent_api.gd`, stage catalogs

- [x] **2.1** Remove force and strong-wind wake while preserving mechanism wake.
  - Change: delete wind configuration, acceleration integration, strong-episode state, and strong-wind wake; narrow projectile and manager wake signals/events to projectile plus reason.
  - Accept: projectile settling and mechanism impulse tests pass, and `src/projectile/` has no `Wind*`, `wind`, `gust`, or `strong_episode` contract.
  - Guard: a resting projectile receiving `queue_desired_velocity` still becomes moving and publishes `mechanism_impulse`.
  - Evidence: `projectile_settling_test.gd` passed and the live identifier scan is empty; generic mechanism wake remains covered.
- [x] **2.2** Simplify aim and prediction to gravity/collision inputs.
  - Change: remove wind horizons, launch wind ticks, schedule identities, dynamic wind buckets/epochs, refresh entry points, and corresponding call arguments while retaining current-only bounded publication and target-preserving angle/power edits.
  - Accept: `terrain_aim_solver_test.gd`, `prediction_scheduler_test.gd`, `aim_interaction_test.gd`, and `stage10_prediction_readiness_test.gd` pass with wind-free fixtures.
  - Guard: current aim/context matching still prevents Fire from consuming stale prediction.
  - Evidence: the four named focused checks plus prediction/projectile and long-flight parity passed.
- [x] **2.3** Remove scene, stage-resource, and serialized catalog dependencies.
  - Change: remove wind nodes and setup from gameplay, remove `StageData.wind_profile`, delete wind source/resource files, and mechanically delete only `resources/wind/standard_wind.tres` dependency lines from the active and tracked generated catalogs.
  - Accept: `rg` finds no active resource or scene reference to `res://src/wind` or `res://resources/wind`, and fixed catalog/materialization checks load successfully.
  - Evidence: source/resource scans are empty; fixed catalog, generation, materialization, repository, and Windows export loads passed.
- [x] **2.4** Publish wind-free observation schema 3.
  - Change: remove wind configuration, schedule data, transition event, agent observation field, and strong episode field; pass the generated terrain seed directly to `AttemptRecorder`; retain generic mechanism wake records.
  - Accept: updated `attempt_observation_test.gd`, `phase8_debug_test.gd`, and relevant agent/debug tests prove JSON-safe schema 3, terrain-seed truth, event order, and no wind keys.
  - Guard: schema 2 input is rejected rather than ambiguously interpreted as schema 3.
  - Evidence: `attempt_observation_test.gd` and the corrected persistent-resident `phase8_debug_test.gd` passed with schema 3 and the generated terrain seed.

Batch gate:

- Run `scripts/verify.ps1`; stop the phase at the first parser, resource-load, or startup error and repair only the owning Phase 2 input before rerunning.

### Phase 3: Remove player-facing and delivery wind surfaces

Goal: leave a compact, truthful status HUD and usable production capture paths.

Preconditions:

- Phase 2 batch gate passes.

Source owners: `scenes/ui/hud/run_status_card.tscn`, `src/ui/hud/run_status_card.gd`, `src/ui/hud_controller.gd`, `scenes/ui/hud/hud.tscn`, `translations/ui.csv`, `src/delivery/delivery_capture_runner.gd`

- [x] **3.1** Remove wind UI and compact the status card.
  - Change: delete the WindGroup, wind formatter/state, HUD façade method, localization keys, and cannon flag; move Finish next to resident activity and shrink both the component and its right-edge instance from 540 px to 384 px without changing other HUD hierarchy.
  - Accept: focused UI/localization tests pass; the rendered Korean Aim View shows time, shots, activity, and Finish with no gap, clipping, overlap, or wind cue.
  - Evidence: focused UI/localization/HUD checks passed; the inspected 1280x720 release capture meets the stated layout criteria.
- [x] **3.2** Remove wind-only delivery capture behavior.
  - Change: route `aiming`, `aiming_burst`, and `aiming_split` through a generic aiming capture; delete weak/strong wind flag screens, deterministic wind seeking, wind freezing, zero-wind fixture calls, and wind arguments in arc helpers.
  - Accept: the exported application produces an `aiming` background PNG at 1280x720 and exits 0; requesting a removed wind-only screen is not part of the supported capture contract.
  - Evidence: the clean-cache Windows release produced the named PNG with exit 0 and empty stderr through the generic `aiming` route.

Batch gate:

- Run the focused UI, localization, capture-source, and shortcut checks once after both tasks pass.

### Phase 4: Synchronize active documentation and tests

Goal: prevent stale current-state documents or fixtures from restoring wind while keeping historical evidence honest.

Preconditions:

- Phases 2 and 3 pass their gates.

Source owners: `.agents/Documentation.md`, `.agents/design/*.md`, `docs/design-spec.md`, `docs/technical-architecture.md`, `docs/test-checklist.md`, `design-qa.md`, `scripts/test.ps1`, `tests/`

- [x] **4.1** Record the implemented retirement and update active specs.
  - Change: add a `Context`, `Decision`, `Rationale`, `Consequences`, and `Limitations` retirement section to the active implementation record; remove wind from current product/design/architecture/UI/acceptance claims; label retained wind-era evidence as pre-removal history where ambiguity exists.
  - Accept: active current-tense sections consistently describe the wind-free contract; completed wind plans/evidence remain present and are not promoted into current authority.
  - Guard: no document claims measured performance savings or that wind had no mechanical effect.
  - Evidence: the source brief, implementation record, active specs, design guidance, and checklist now separate current contract from historical evidence.
- [x] **4.2** Remove or update wind fixtures and suite entries.
  - Change: delete wind-only tests, remove them from `scripts/test.ps1`, and update mixed tests for schema 3, gravity-only prediction, generic mechanism wake, HUD layout, localization, agent facts, and delivery source contracts.
  - Accept: `rg` finds no active runtime/test/translations wind identifiers outside explicitly historical docs/evidence/plans, and all retained tests parse.
  - Evidence: wind-only tests and suite entries are gone; mixed tests pass and the exact active-code scan is empty.
- [x] **4.3** Remove task-owned transient wind audit output.
  - Change: delete only `reports/wind-feature-audit-2026-08-09/` after resolving it inside the repository; preserve committed historical evidence under `.agents/evidence/`.
  - Accept: the exact transient directory is absent and no other report/evidence directory changed.
  - Evidence: the ignored report directory and its task-created import/cache derivatives are absent; committed historical evidence is intact.

### Phase 5: Validate and publish

Goal: prove the wind-free source, release build, and rendered HUD, then publish one scoped change.

Preconditions:

- All implementation and documentation tasks pass their acceptance checks.

Source owners: repository checks, export preset, `.agents/evidence/wind-retirement-2026-08-09/`, git branch `agent/remove-wind-system`

- [x] **5.1** Run final automated and production gates.
  - Change: run the focused changed-contract tests, then `scripts/test.ps1`, `scripts/verify.ps1`, Windows release export, and a hidden exported-app start/capture only once after their inputs stabilize.
  - Accept: every task-reached focused command, repository verification, export, and capture exits 0; the exported Aim View capture exists at 1280x720; no error-level Godot output or retained wind resource-load error appears. The whole-suite runner may retain only failures proven unchanged from `HEAD` and recorded in evidence.
  - Discovery update: the whole-suite runner is not green because unchanged `phase6_content_test.gd` expects legacy IDs and unchanged `camera_safety_test.gd` references an absent constant. The runner reached all changed contracts before that barrier; remaining changed-contract tests were run directly and passed.
  - Evidence: `scripts/verify.ps1`, Windows release export, and clean-stderr release capture passed; `.agents/evidence/wind-retirement-2026-08-09/README.md` records commands and the baseline limitation.
- [x] **5.2** Inspect rendered evidence and audit the cross-module change.
  - Change: inspect the native capture for status-card alignment, text fit, clipping, unsupported wind cues, target/trajectory visibility, and Finish state; run `$codebase-quality-auditor` and apply only small safe task-scoped corrections.
  - Accept: UI/UX Level 2 blockers are absent and the quality audit finds no reachable wind path, competing owner, schema mismatch, or stale active contract.
  - Evidence: native-size review found no gap, clipping, overlap, or retired cue; the diff-scoped quality audit found no responsibility creep or unmatched changed consumer.
- [ ] **5.3** Commit and publish the scoped branch.
  - Change: inspect the final diff, stage only task-owned files, commit tersely, push `agent/remove-wind-system`, and open a draft PR against the remote default branch.
  - Accept: worktree is clean; commit, remote branch, and draft PR URLs resolve; no unrelated file is included.
  - Evidence: implementation commit `a9b47d1` and both `master` and `agent/remove-wind-system` resolve on `origin`; the remote was initialized from the existing local history.
  - Blocker: GitHub MCP and local `gh` both return pull-request permission errors for the configured personal access token. Browser fallback requires separate user approval, so the draft PR remains the only unfinished action.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Direct Godot scripts for the task-owned tests named in Tasks 2.1-4.2 | The corresponding owner compiles | Relevant implementation input changes |
| Phase 2 gate | `& '.\scripts\verify.ps1'` | Tasks 2.1-2.4 pass | A runtime/resource input changes |
| Phase 3 gate | Direct `phase7_ui_test.gd`, `localization_ui_test.gd`, `phase7_user_qa_contract_test.gd`, and capture-source contract tests | Tasks 3.1-3.2 pass | A UI/capture input changes |
| Full test gate | `& '.\scripts\test.ps1' -GodotPath $env:GODOT_BIN` | All source/test changes stabilize | A source/resource/test input changes |
| Repository gate | `& '.\scripts\verify.ps1'` | Full test gate passes | A project source/resource/settings input changes |
| Final export | `& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'` | Repository gate passes | An export-owned input changes |
| Final rendered evidence | `Start-Process builds/windows/PaintMountain.exe -WindowStyle Hidden -ArgumentList @('--','--capture-background','--capture-screen=aiming','--capture-stage=stage_30','--capture-size=1280x720','--capture-language=ko','--capture-output=<absolute-evidence-path>') -PassThru -Wait` | Final export passes | A visible or capture-owned input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Mark a task complete only after its acceptance check passes; record concise evidence beside the checkbox before advancing.
- Treat checked tasks and recorded passing evidence as complete unless a relevant input changed.
- Do not repeat the full suite, export, or rendered capture merely to regain confidence.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not select a new product, architecture, dependency, data, UX, safety, or validation contract during implementation |
| Removing wind reveals a non-wind caller of a narrowed interface | Preserve the non-wind behavior with the smallest responsibility-correct signature and add/update its focused test | Do not restore a zero-wind `Wind*` compatibility object |
| A retained generated catalog fails after deleting the wind resource | Remove only the serialized unused wind dependency from that retained resource and rerun its catalog check | Do not delete terrain layouts or keep the wind resource as a loader shim |
| A historical document is the only remaining wind match | Preserve it when it is clearly past-tense and non-authoritative; add a short pre-removal qualifier only if authority is ambiguous | Do not rewrite completed history or evidence |
| Production capture exposes an empty right-edge gap or overlap | Adjust only RunStatusCard width/offsets within the existing HUD ownership and recapture once | Do not redesign unrelated HUD surfaces |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 5, blocked only on draft PR creation.
- Next task: grant pull-request permission or explicitly approve a logged-in browser fallback, then open the draft PR from `master` to `agent/remove-wind-system`.
- Last completed gate: implementation commit `a9b47d1` and both required remote branch pushes.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.
- Anti-rework rule: on resume, read this contract and inspect the worktree only enough to confirm checkpoint inputs, then continue from the first unchecked task whose prerequisites pass.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- Active runtime, resources, tests, localization, delivery capture paths, and current-tense authoritative docs contain no live wind contract.
- Historical wind plans and evidence remain available as non-current history.
- No placeholder or unresolved material decision remains.
- Frontmatter status is `done`, the branch is committed and clean, and the draft PR is open.

Replan when:

- A material discovery requires removing the persistent-ball/timer/coverage loop, changing terrain generation, adding a replacement mechanic, keeping a wind compatibility layer, or changing the validation contract.

Do not replan or stop for:

- Implementation-local signature cleanup already contained by this contract.
- A passing check whose relevant inputs have not changed.
