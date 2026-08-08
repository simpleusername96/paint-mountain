---
type: plan
status: active
created: 2026-08-08
last_reviewed: 2026-08-09
scope: immediate terrain-target aiming, stable display settings, sparse gameplay HUD, and higher glyph placement
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - 2026-08-08-terrain-targeted-aiming.md
  - 2026-08-08-casual-shared-ui-refresh.md
---

# Immediate Terrain Aim and Sparse HUD - Execution Contract

Keep the player-approved terrain click/drag target flow, but remove exact
collision verification from the input transaction. A valid click must commit the
best deterministic inverse-ballistic candidate immediately. The existing exact
trajectory job remains advisory, latest-only, and never blocks Fire.

At the same time, stop settings synchronization from changing window mode or
size, replace the normal in-game dashboard with a sparse icon-and-number HUD,
and prefer terrain glyphs around the middle and upper-middle of the mountain.

## Product and Architecture Decisions

- Human aim remains terrain-targeted: click or drag chooses a terrain point;
  elevation and power edits preserve that selected point approximately.
- The inverse recurrence may scan its bounded 720 fixed steps synchronously. It
  performs no collision query and returns the best legal candidate immediately.
- Exact first-contact prediction is presentation-only. It may later confirm the
  selected marker or show the actual first impact, but it cannot gate aim or Fire.
- `StageController` remains the only Fire-admission and stage-state owner.
- `CannonController` remains the canonical aim owner. Pending Human revision
  state is deleted because no asynchronous Human transaction remains.
- Settings UI synchronization only copies state into controls and translated
  labels. Display mode and resolution change only for their own setting action
  or a deliberate defaults restore.
- The gameplay mountain is the primary surface. Persistent HUD uses small
  instruments, icons, numbers, symbols, and controls without enclosing rail or
  card panels. Briefing, pause, and result overlays may still use panels.
- Shortcut hints sit next to the value or action they control. They are not a
  separate instruction sentence or detached annotation.
- Glyph placement prefers normalized terrain height 0.55..0.85, then 0.40 or
  above, with deterministic fallback when suitability or separation requires it.
  Existing footprint, slope, visibility, mechanism semantics, and separation
  remain authoritative.

## Verified Causes and Design Evidence

| Concern | Current evidence | Locked response |
| --- | --- | --- |
| Aim delay | `TerrainAimSolver` nominates up to six candidates, then `TrajectoryPredictionScheduler` advances a full exact collision job for each before `TerrainAimController` commits | Commit the first approximate nomination immediately; scheduler owns only the current advisory preview |
| Fire delay | `StageController.fire_readiness_snapshot()` rejects Human Fire while `human_aim_revision_pending()` | Remove pending revision state and gate |
| Display distortion | `SettingsScreen._sync_from_state()` always calls `_sync_display_state_from_settings()`, which calls `window_set_mode()` and `window_set_size()` after every setting change | Split passive control sync from explicit display mutation |
| HUD obstruction | Runtime captures show a 168x506 right rail plus left and bottom panels covering the mountain; 1920x1080 retains fixed-offset bunching | Use edge anchors and borderless instrument groups; remove normal-play context prose |
| Shortcut aesthetics | Current keycaps float inside large text controls or below unrelated copy | Attach `A/D`, `W/S`, wheel, Space, Tab, F, and Esc hints directly to the controlled value/action |
| Glyph height | Burst ties fall back to ascending `surface/z/x` anchor IDs, selecting low/front anchors | Rank candidates by normalized height band before kind score |

Design evidence:

- Baseline runtime captures:
  `.agents/evidence/casual-shared-ui-refresh-2026-08-08/03-aim-stage30-1280x720.png`,
  `05-settings-stage30-1280x720.png`, and
  `06-aim-stage30-1920x1080-en.png`.
- ImageGen edit reference:
  `.agents/evidence/sparse-instrument-hud-2026-08-09/imagegen-target-reference.png`.
- External visual review:
  `.agents/evidence/sparse-instrument-hud-2026-08-09/agy-review.md`.

## Scope and Boundaries

In scope:

- settings display-application ownership and focused regression coverage;
- synchronous approximate terrain target solving and scheduler simplification;
- removal of obsolete `TerrainAimSolution` and Human revision APIs after zero
  production/test references;
- normal gameplay HUD composition, icon assets, responsive anchors, and focused
  UI contracts;
- deterministic height-biased glyph planning, focused placement tests, and a
  promoted baked catalog after explicit alignment for the broad rebuild;
- current source/spec/architecture/implementation records and rendered evidence.

Out of scope:

- direct freeform drag aiming, in-flight steering, new actions, a minimap, or a
  second terrain/coverage representation;
- projectile physics, paint authority, target coverage, stage difficulty,
  mechanism behavior, save format, progression, or production dependencies;
- redesigning briefing, pause, settings form, or result overlays beyond fixes
  required for display stability and normal-game visual continuity.

## Tasks

### 1. Display and Human aim responsiveness

- [x] **1.1 Stable settings synchronization**
  - Split passive display-control refresh from explicit display application.
  - Prove audio, motion, preview, quality, and language changes do not call a
    window mode or size mutation; fullscreen/resolution each apply once.
- [x] **1.2 Immediate terrain target commit**
  - Run the bounded pure inverse recurrence synchronously after the physics pick,
    choose the first legal nomination, and call `StageController.set_aim()` in
    the same physics tick.
  - Keep selected/rejected/confirmed marker states truthful. Invalid targets keep
    the last canonical aim.
- [x] **1.3 One advisory exact prediction owner**
  - Delete the scheduler target branch and Human revision state/gate.
  - Prove rapid latest-only input cannot leave a pending Fire block and that the
    scheduler owns at most one replaceable preview job.

### 2. Sparse gameplay HUD

- [x] **2.1 Instrument composition**
  - Replace stage, coverage, run status, and aim rail panels with borderless,
    edge-anchored icon/number groups. Retain real clickable controls and tooltips.
  - Remove the persistent aim/map context sentence from normal play.
- [x] **2.2 Integrated shortcut hints**
  - Show `A/D` with yaw, `W/S` with elevation, wheel with power, Space with Fire,
    Tab with interaction mode, F with Finish, and Esc with settings/pause.
  - Keep focus targets at least 40px and preserve locale-safe accessible names.
- [x] **2.3 Responsive rendered QA**
  - Inspect the running built game at 1280x720 and 1920x1080 in Korean and
    English. Check mountain occlusion, overlap, clipping, hierarchy, focus, and
    state changes against the ImageGen reference.

### 3. Higher terrain glyphs

- [x] **3.1 Deterministic height preference**
  - Add normalized-height metadata to generic candidates and rank the preferred
    middle/upper-middle band before existing mechanism-specific score.
  - Prove preferred candidates win when suitable and deterministic fallback
    still completes constrained assignments.
- [ ] **3.2 Catalog promotion**
  - After user alignment for the broad generation cost, rebuild all 30 baked
    layouts, run catalog/certificate checks, inspect representative runtime
    stages, and promote exactly one complete content-addressed bundle.

### 4. Contracts and handoff

- [x] **4.1 Current documentation**
  - Record the later UI, display, aim-latency, and glyph-placement decisions in
    the effective source brief and current design/architecture/implementation
    records. Retire stale pending-solver descriptions.
- [ ] **4.2 Final gates**
  - Run focused tests while implementing, then `scripts/verify.ps1`, release
    export, production-style runtime captures, `git diff --check`, and the
    task-scoped codebase quality audit. Commit only task-owned files.

## Validation Cadence

Use focused Godot scripts after each owner changes. Run the project verify gate
once all script/scene/resource edits are coherent. The full 30-stage catalog
rebuild and ordered broad test suite are expensive gates: state their purpose,
cost, impact, and stopping condition and obtain alignment before starting them.

Stop and revise this contract only if current source authority or runtime evidence
contradicts one of the locked product or ownership decisions above.

## Progress

- Current phase: 3.2, awaiting explicit alignment for the broad 30-stage
  catalog rebuild and promotion.
- Completed implementation and evidence: stable Settings display ownership,
  immediate approximate terrain aim, one advisory preview owner, sparse HUD,
  integrated shortcuts, normalized-height glyph ranking, focused contracts,
  Godot verification, Windows release export, and inspected release captures.
- Remaining acceptance work: rebuild and promote one complete catalog bundle,
  run its catalog/certificate checks, inspect representative glyph stages, then
  close 3.2 and 4.2.
- Complete only when every checkbox has named evidence and frontmatter is `done`.
