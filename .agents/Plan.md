---
type: plan
status: active
created: 2026-08-02
scope: complete the Paint Mountain playable vertical slice after repository bootstrap
related:
  - Prompt.md
  - ../docs/source-brief.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
  - ../docs/test-checklist.md
---

# Paint Mountain Vertical Slice Execution Plan

The repository now launches the complete three-stage gameplay scene with progression, persistence foundations, replay, and an in-process agent API. The remaining presentation and delivery phases complete the application shell, final QA, export, and running-game evidence.

## Purpose

- Objective: deliver the playable vertical slice defined in `docs/design-spec.md`.
- Final artifact: a Windows-oriented Godot project with three tested stages, save/replay/debug support, complete UI flow, and seven separate screenshots.
- Completion state: every checked requirement in `docs/test-checklist.md` passes and `.agents/Documentation.md` records observed results and performance.

## Pre-plan Evidence Already Verified

| Source or path | Verified fact | Decision affected | Freshness boundary |
| --- | --- | --- | --- |
| `docs/source-brief.md` | The verbatim user directive specifies Godot 4.x/GDScript, three stages, mechanisms, UX, architecture, limits, phases, and acceptance criteria | Highest-authority product and technical requirement source | Recheck only if the user revises scope |
| `project.godot` | Compatibility renderer and 60 Hz physics are configured | Runtime baseline | Recheck after project-setting changes |
| `scenes/bootstrap/bootstrap.tscn` | A dependency-free 3D project entry exists | Phase 1 complete | Retire after gameplay entry passes smoke checks |
| Local Godot 4.7.1 console binary | The project can be imported and run headlessly | Validation path | Recheck when engine version changes |

## Locked Decisions

| Topic | Final decision | Rationale |
| --- | --- | --- |
| Terrain and paint mapping | One heightfield-style mesh per stage mapped in world X/Z to a 512×512 mask | Brief requirement; reliable coverage and finite downhill flow |
| Paint authority | `PaintSystem` owns the only paint mask; the shader and coverage read that state | Prevents visual/score drift and overlap double-counting |
| Physics | Fixed 60 Hz, rigid bodies with CCD, seeded deterministic inputs, maximum eight simultaneous balls and one split generation | Predictability and performance contract |
| Stage flow | One `StageController` owns the explicit state machine and cleanup | Prevents state logic and restart behavior from spreading |
| Content configuration | Typed Godot Resources own stage, projectile, mechanism, result, and tutorial values | Required data-driven content boundary |
| Replay | Store stage/version/seed and shot inputs; add low-frequency transform capture only if cross-session resimulation fails | Minimal deterministic-first replay contract |
| AI hook | In-process observation/action/event interfaces call the same gameplay commands as human input | Keeps future automation independent of UI |
| Dependencies | Use only Godot built-ins for the vertical slice | Minimal external dependency requirement |

## Rejected Alternatives

| Alternative | Why it was viable | Why it was rejected |
| --- | --- | --- |
| Per-stamp decal nodes | Direct visual authoring | Cannot provide cheap authoritative coverage and scales poorly |
| Full fluid simulation | Rich paint motion | Violates scope and modest-hardware target |
| Orthographic/tabletop gameplay | Easy whole-stage framing | Violates the required distant mountain scale relationship |
| Recording every replay transform by default | Robust playback | Unnecessary storage until deterministic resimulation is proven insufficient |

## Current State

Already true:

- A Git repository, agent environment, active specs, plan, README, verification script, and runnable 3D bootstrap scene exist.
- The bootstrap view establishes a perspective camera, small foreground cannon proxy, and distant dominant mountain proxy.

Remaining implementation:

- All gameplay, paint, mechanisms, content, menus, settings, saving, replay, debug tools, presentation, tuning, exports, screenshots, and acceptance evidence.

## Scope

In scope:

- Phases 2–8 and every deliverable in `docs/test-checklist.md`.

Out of scope:

- Every excluded monetization, online, multiplayer, customization, live-service, story, inventory, and content-expansion system in `docs/design-spec.md`.

Destructive or irreversible actions:

- None planned.

Actions requiring owner approval:

- Adding or upgrading external dependencies or asset packs; replacing the selected engine/renderer; destructive repository cleanup; publishing or distributing a build.

## Architecture and Ownership

| Concern | Final owner | Interface or invariant |
| --- | --- | --- |
| Global progression/settings/results | `src/autoload/game_state.gd`, `src/autoload/save_system.gd` | Versioned local save; no stage rules |
| Stage state and result decisions | `src/stage/stage_controller.gd` | Sole stage-state authority |
| Stage configuration | `src/stage/stage_data.gd` and `resources/stages/*.tres` | Typed data; no stage-specific globals |
| Cannon and preview | `src/cannon/cannon_controller.gd` | Preview and launch share one ballistic parameter source |
| Projectile lifetime | `src/projectile/paint_projectile.gd`, `projectile_manager.gd` | Bounded, CCD-enabled, manager reports settled |
| Paint and coverage | `src/paint/paint_system.gd` plus terrain shader | One mask for visuals and scoring |
| Mechanisms | `src/mechanisms/gimmick_base.gd` and three subclasses | Common activation/reset contract |
| Cameras | `src/camera/camera_director.gd` | Named modes and smooth transitions |
| Human UI | `src/ui/*` and separate screen scenes | Presentation only; no game rules |
| Replay and AI access | `src/replay/replay_recorder.gd`, `src/agent/gameplay_agent_api.gd` | Inputs/events independent of UI |

## Tasks

### Phase 2: Cannon and projectile sandbox

- [x] Create typed projectile tuning Resource, cannon controller, trajectory sampler, projectile manager, rigid-body paintball, and a sandbox stage.
- [x] Use the same gravity, muzzle transform, elevation, and power conversion for preview and launch.
- [x] Validate CCD impacts, bounce, roll, slide, stop, lifetime/out-of-bounds termination, and repeated-shot equivalence. Paint-payload termination remains owned by Phase 3 when deposits consume payload.

Acceptance: one aim tuple repeatedly follows an effectively identical initial flight and settles without orphan bodies.

Guard: no paint, menus, or mechanisms are added before the sandbox physics is stable.

### Phase 3: Authoritative paint system

- [x] Implement a batched 512×512 runtime paint mask, eligible mask, world X/Z mapping, circular/path stamps, finite payload depletion, and throttled coverage calculation.
- [x] Bind the mask to the terrain shader and implement impact splash, contact trail, final puddle, and bounded deterministic downhill flow.
- [x] Add debug mask/eligible/recent-stamp visualization and overlap tests.

Acceptance: visuals and reported coverage change from the same mask, overlap is counted once, excluded surfaces never count, and clearing paint resets both views.

Guard: no per-stamp scene nodes or full fluid simulation.

### Phase 4: Stage loop, cameras, and gameplay HUD

- [x] Implement `StageController` states, shot accounting, clean restart, clear/failure decisions, and state-driven HUD visibility.
- [x] Implement briefing, aiming, projectile follow, wide, cannon, and result camera modes with 0.3–0.7 second transitions and constrained briefing orbit/zoom.
- [x] Build briefing, aiming, observation, result, pause, and settings screen foundations using anchors/containers.

Acceptance: the player can inspect, aim, fire, observe, settle, retry, clear, and fail with no illegal fire or stale temporary state.

Guard: the aiming composition keeps the cannon small and the mountain dominant at 16:9 desktop resolutions.

### Phase 5: Three mechanisms

- [x] Implement the shared data-driven activation/reset contract.
- [x] Add one-charge Burst direct-mask paint, one-generation Splitter with controlled payload, and cooldown-limited directional Bumper impulse.
- [x] Add distinct low-poly silhouettes/state feedback and reset/duplicate-trigger tests. Audio cues remain in the Phase 7 presentation batch.

Acceptance: every mechanism affects the authoritative gameplay systems exactly once per eligible trigger and restarts cleanly.

Guard: implement no fourth mechanism and never allow more than eight active balls.

### Phase 6: Three stages, progression, save, replay, and AI hook

- [x] Build First Descent, Burst Basin, and Split Ridge as StageData-backed scenes with fixed cannon/camera/bounds/mask/result/tutorial data.
- [x] Implement versioned saves for unlocks, best coverage/stars, and settings.
- [x] Implement deterministic-first attempt replay and the in-process observation/action/event API.
- [x] Tune and record at least one reliable successful shot sequence per stage.

Acceptance: all stages select, load, clear/fail, unlock, persist, replay, and expose UI-independent agent actions.

Guard: stage-specific logic stays out of global controllers and replay does not silently diverge.

### Phase 7: Menus and presentation

- [ ] Complete main menu, stage select, stage briefing, gameplay, result, pause, and settings interfaces as separate screens.
- [ ] Add low-poly art cleanup, readable mechanism silhouettes, restrained particles/shake, generated or properly licensed audio, and pooled frequent effects.
- [ ] Validate UI hierarchy, clipping, focus, hover/press feedback, and common 16:9 resolutions.

Acceptance: the complete menu-to-game-to-result flow is usable, uncluttered, and visually consistent without debug overlays.

Guard: no fake storefront, dense simulator dashboard, oversized result obstruction, or unlicensed asset.

### Phase 8: Debugging, delivery, and final QA

- [ ] Complete the release-disabled debug overlay/actions and shot-result log export.
- [ ] Add automated smoke/state/mask/save/replay checks plus repeated manual restart, bounds, split-limit, solution, and result checks.
- [ ] Create and run a Windows export preset, measure 1920×1080 performance, and fix recurring errors or frame collapse.
- [ ] Capture the seven exact full-resolution screenshots from the running release configuration and finalize README/spec/architecture/checklist status.

Acceptance: every item in `docs/test-checklist.md` has observed evidence and all required deliverables exist separately.

Guard: do not mark the slice complete while a required stage, state, screenshot, save/replay path, or production-style check is missing.

## Verification

Inner loop:

- `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath <Godot-console.exe>`
- Targeted Godot test scene or script checks added with the owning subsystem.

Final gates:

- Headless import and runtime smoke pass with no recurring errors.
- Windows export builds and launches through its production entry path.
- Manual checks pass at 1280×720, 1600×900, and 1920×1080.
- Saves survive a normal restart; replay reproduces each tested attempt within recorded tolerance.
- All seven screenshot files pass exact-name and 1920×1080 dimension checks.
- `git diff --check` reports no whitespace errors.

## Predetermined Error Handling and Contingencies

| Trigger | Required response | Limit / escalation point |
| --- | --- | --- |
| GPU mask readback causes frame instability | Batch stamps and throttle coverage readback; retain 512×512 | Escalate before adopting a second mask or new dependency |
| Cross-session deterministic replay diverges | Record transforms at a low fixed frequency and interpolate playback | Keep gameplay simulation input record as primary metadata |
| Split activation would exceed eight balls | Spawn only the remaining allowed children and preserve total payload accounting | Never raise the cap without measured approval |
| Required effect asset is unavailable | Use a simple generated placeholder with clear provenance | Ask before adding an external pack |
| Production export cannot be created | Preserve the editor/runtime smoke result and report the exact export-template blocker | Do not claim final delivery complete |

## Progress

- [x] Phase 1: repository, agent environment, project config, bootstrap scene, and smoke path.
- [x] Phase 2: cannon and projectile sandbox.
- [x] Phase 3: paint system.
- [x] Phase 4: stage loop, cameras, and HUD.
- [x] Phase 5: mechanisms.
- [ ] Phase 6: content, save, replay, and AI hook.
- [ ] Phase 7: presentation.
- [ ] Phase 8: delivery and final QA.

## Next Steps

1. Build the two remaining StageData resources and stage selection/loading path in Phase 6.
2. Place Burst in Burst Basin and Splitter plus Bumper in Split Ridge without stage-specific controller rules.
3. Add progression/save, deterministic attempt replay, the in-process agent API, and verified shot routes.

## Completion Criteria

- [ ] Every user-visible requirement in `docs/test-checklist.md` passes.
- [ ] Every regression guard and final validation gate passes.
- [ ] No placeholder, duplicate authority, unbounded simulation path, or unreported limitation remains.
- [ ] `Documentation.md` and the user-facing deliverables describe observed current behavior.

## Stop Conditions

Complete when: the exported playable slice and all evidence meet the acceptance checklist.

Escalate only when: an external dependency, asset license, destructive change, engine/renderer replacement, or revised product decision requires user authority.

Do not stop when: a safe in-scope implementation or verification path remains.

## Handoff

```text
Goal: Complete the Paint Mountain playable vertical slice.
Read first: AGENTS.md, .agents/Prompt.md, .agents/Documentation.md, .agents/Plan.md.
Execute exactly: Start with the first unchecked phase and keep its acceptance/guard contract.
Validate with: scripts/verify.ps1 plus the subsystem and manual gates named above.
Stop when: docs/test-checklist.md is fully evidenced or a named approval boundary is reached.
```
