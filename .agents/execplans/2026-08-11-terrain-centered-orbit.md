---
type: plan
status: done
created: 2026-08-11
scope: fixed-center spherical camera behavior for every interactive terrain-inspection state
related:
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../design/UIUX_GUIDELINES.md
  - ../Documentation.md
  - ../../docs/test-checklist.md
---

# Terrain-Centered Orbit - Execution Contract

Paint Mountain's Briefing and in-run Map Inspection currently share orbit input but can move their focus through terrain or mechanism clicks, and the generic safety solver can replace the requested focus. This contract fixes both interactive inspection states to one terrain visual center and lets only spherical yaw, pitch, and radius change, while preserving Aim View, Shot Follow, Result, cannon aim, and stage rules.

## Purpose

- Objective: make every interactive terrain-inspection camera orbit one immutable terrain visual center with conventional direct-grab input.
- Deliverable: a single `CameraDirector` spherical-orbit contract, updated callers and tests, aligned product documentation, and inspected production-render captures.
- Completion state: focused and full validation pass, the Windows release shows centered Briefing and Map Inspection, documentation records observed truth, and this plan is `done`.

## Scope and Boundaries

In scope:

- Briefing terrain inspection and the Map Inspection interaction available from Aim View.
- The terrain-owned visual-center query, orbit initialization, yaw/pitch/radius limits, direct render updates, and camera-clearance correction that preserves the pivot and orbit direction.
- Removal of terrain-click and mechanism-click focus changes from inspection.
- Capture fixtures, camera regressions, source/design/UI contracts, implemented-state record, and test checklist.

Out of scope:

- Aim View composition or terrain-target aiming, Shot Follow, Result presentation, stage-select preview, cannon transforms, projectile behavior, terrain generation, HUD layout, and new assets.

Constraints and invariants:

- `CameraDirector` remains the sole camera-mode and interaction owner; `TerrainSurface` only exposes its cached visual center.
- The pivot is the AABB center of the cached playable-top vertices plus the visible terrain base at the ground join, not the stage origin, an authored camera target, a click hit, virtual summit headroom, or the buried support-shell center.
- Drag changes yaw and pitch, wheel changes requested radius, and clearance may increase only the effective radius along the same spherical ray. The pivot never changes during inspection.
- Horizontal and vertical direct-grab signs, pitch and distance clamps, Aim View state, committed aim, fixed 60 Hz physics, and the Compatibility renderer remain unchanged.
- No production dependency, plugin, asset, schema migration, or network action is introduced.

Destructive or irreversible actions:

- None.

Exact actions requiring owner or user approval:

- None inside this contract. Publishing or changing itch.io remains outside scope.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Interactive inspection paths | Briefing starts in `MAP_INSPECTION`; Aim View can toggle into the same mode | `CameraDirector.set_mode`, `set_interaction_mode`, `GameplayScene._on_state_changed` | Apply one orbit implementation to both states; no other camera mode changes | 1.1, 2.1 |
| Drifting focus | Short terrain clicks queue a physics pick; mechanism clicks call `focus_briefing_target`; delivery capture explicitly refocuses | `CameraDirector._unhandled_input`, `_focus_inspection_from_screen`; `GameplayScene._on_mechanism_selected`; `DeliveryCaptureRunner._capture_map_inspection` | Remove inspection focus picking and all focus-changing callers | 1.2 |
| Terrain center | `TerrainSurface` already caches the real playable-top vertices and owns the render bounds whose buried shell must not bias framing | `TerrainSurface.playable_top_world_points`, `render_world_aabb` | Cache the actual top XZ/Y bounds plus the visible ground-join base as the canonical visual center; exclude virtual headroom and buried shell | 1.1 |
| Spherical motion and safety | Orbit math is spherical, but generic safety changes Y and presentation focus, and updates through the fixed-physics solver | `CameraDirector._apply_inspection_orbit`, `_resolve_safe_pose`, `safe_position_for` | Resolve inspection pose directly; clearance changes radius only along the selected ray; generic safety stays for non-inspection modes | 1.1 |
| Input direction | Current direct-grab signs match the user's earlier correction | `tests/map_inspection_direction_test.gd`, implemented record | Preserve the signs and assert them with the fixed pivot | 2.1 |
| Product conflict | Active source/design/UI documents still state that inspection clicks change focus | `docs/source-brief.md`, `docs/design-spec.md`, `.agents/design/UIUX_GUIDELINES.md` | Record the explicit 2026-08-11 supersession and align derived specs | 3.1 |
| Rendered proof | The release-only delivery runner supports Briefing and Map Inspection at requested sizes | `DeliveryCaptureRunner`, `export_presets.cfg`, `docs/test-checklist.md` | Export Windows release and inspect Korean Stage 02 captures at 1280x720 plus Stage 30 Map Inspection at 1920x1080 | 2.2 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Godot 4.7.1, repository scripts, the existing delivery runner, and Windows export preset are available; no bootstrap is required.
- Remaining unknowns are implementation-local camera math or test tolerances and cannot change this contract.

## Tasks

### Phase 1: One fixed-center spherical orbit

Goal: make every interactive terrain inspection use the same immutable visual-center pivot.

Preconditions:

- Discovery Closure is complete and the working tree is clean.

Source owners: `src/terrain/terrain_surface.gd`, `src/camera/camera_director.gd`, `src/gameplay/gameplay_scene.gd`, `src/delivery/delivery_capture_runner.gd`

- [x] **1.1** Center and constrain the orbit.
  - Change: expose the cached presentation-landmark center; initialize Briefing and Map Inspection from that point; update yaw/pitch/radius directly; keep clearance correction on the same center-to-camera ray.
  - Accept: both states always look at the same visual center after drag and zoom, settle without the generic inspection safety loop, and remain within pitch/radius bounds and terrain clearance.
  - Guard: Aim View, Shot Follow, Result, and committed cannon aim remain unchanged.
- [x] **1.2** Remove focus drift inputs and callers.
  - Change: remove click-to-refocus state, physics picking, mechanism-selection camera movement, and capture-only refocus.
  - Accept: a click without drag does not change the inspection pivot; drag and wheel still orbit and zoom; repository search finds no inspection-focus mutation API or caller.

### Phase 2: Regression and production evidence

Goal: prove controls, camera safety, mode isolation, and final rendering.

Preconditions:

- Phase 1 acceptance checks pass.

Source owners: `tests/map_inspection_direction_test.gd`, `tests/camera_safety_test.gd`, `.agents/evidence/terrain-centered-orbit-2026-08-11/`

- [x] **2.1** Strengthen camera contracts.
  - Change: assert fixed visual-center focus in Briefing and Map Inspection, direct-grab directions, spherical-ray preservation, zoom bounds, click immutability, camera clearance, and unchanged cannon aim.
  - Accept: focused direction, safety, aiming-composition, aim-interaction, and Shot Follow tests pass.
- [x] **2.2** Validate and inspect the production result.
  - Change: run repository verification and the complete suite, export Windows release, capture final Briefing and Map Inspection states, and inspect every PNG at native size.
  - Accept: all checks exit 0; captures show the complete mountain centered around a stable orbit target with no clipping, floating-ground edge, focus artifact, or debug overlay.

### Phase 3: Durable requirement and completion truth

Goal: ensure later work cannot restore click-driven focus drift.

Preconditions:

- Phase 2 acceptance passes.

Source owners: `docs/source-brief.md`, `docs/design-spec.md`, `.agents/design/UIUX_GUIDELINES.md`, `.agents/Documentation.md`, `docs/test-checklist.md`, this contract

- [x] **3.1** Align requirement and design authorities.
  - Change: record the user's fixed-center terrain-inspection supersession and replace derived click-focus wording with the spherical-orbit contract.
  - Accept: all active requirement/design documents agree that inspection has no pan or click refocus and does not affect aim.
- [x] **3.2** Record verified completion.
  - Change: record only passing implementation and capture facts, check every task, add completion evidence, and set this plan to `done`.
  - Accept: no unchecked task, stale active-plan status, placeholder, or unsupported deployment/approval claim remains.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Godot editor parse; `map_inspection_direction_test.gd` | Camera/terrain/test implementation compiles | A relevant implementation input changes |
| Phase gate | `camera_safety_test.gd`, `aim_interaction_test.gd`, `phase8_aiming_composition_test.gd`, `shot_follow_camera_test.gd`, and `scripts/verify.ps1` | Phase 1 and focused assertions pass | A camera owner or test changes |
| Final gate | full `scripts/test.ps1`; fresh `Windows Desktop` release export; background release captures for Stage 02 Briefing and Map Inspection at 1280x720 and Stage 30 Map Inspection at 1920x1080 | All source and documentation changes settle | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Run the production-style final gate once because repository policy requires built-render evidence for player-facing camera changes.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not choose a different product, ownership, or camera-interaction contract silently |
| A stage's visual center lies outside its cached presentation landmarks or is non-finite | Fail the focused contract and correct the terrain-owned center calculation from the same cached landmarks | Do not fall back to stage-specific coordinates or camera bookmarks |
| Requested radius cannot clear terrain along an allowed orbit ray | Increase only the effective radius up to the existing stage-derived maximum and fail the safety test if that remains insufficient | Do not move the pivot, add panning, change terrain, or alter the camera FOV |
| Fixed-center Briefing framing conflicts with the existing safe region | Increase the shared initial framing distance using the existing presentation landmarks | Do not shift the pivot or add per-stage framing coordinates |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: none; user review or a separately authorized itch.io deployment.
- Last completed gate: Diff-scoped code-quality audit and completion-truth review.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.

## Completion Evidence

- `scripts/verify.ps1`, the focused fixed-center/direction test, camera safety
  across Stages 01/10/20/30, aim interaction, Aim View composition, Shot Follow,
  and the complete ordered Godot suite pass with Godot 4.7.1.
- A fresh `Windows Desktop` release export passes. The first full-suite attempt
  was stopped by nested Windows PowerShell promoting the intentional invalid-
  geometry fixture warning to a native command error; the test itself exited 0,
  and the canonical script passed when invoked directly in the current shell.
- The implementing agent inspected three Korean release captures at native size:
  Stage 02 Briefing and Map Inspection at 1280x720, plus Stage 30 Map Inspection
  at 1920x1080. All show complete centered terrain with no clipping,
  floating-ground edge, unintended focus artifact, or debug overlay.
- `docs/source-brief.md`, `docs/design-spec.md`,
  `.agents/design/UIUX_GUIDELINES.md`, `README.md`,
  `.agents/Documentation.md`, and `docs/test-checklist.md` agree on the fixed-
  center spherical-orbit contract. The diff-scoped code-quality audit found no
  competing owner, responsibility creep, reachable focus-drift path, or missing
  task-owned validation.
- The itch.io upload and project visibility were not changed.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material decision remains.
- The source brief, derived design specs, implemented record, and checklist describe the same verified behavior.
- Frontmatter status is changed to `done` only after implementation is complete.

Replan when:

- A material discovery invalidates the fixed-center, spherical-motion, ownership, or validation contract.

Do not replan or stop for:

- Implementation-local camera math already contained by this contract.
- A passing check whose relevant inputs have not changed.
