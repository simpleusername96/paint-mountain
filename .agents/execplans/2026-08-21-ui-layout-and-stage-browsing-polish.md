---
type: plan
status: active
created: 2026-08-21
scope: Cross-surface UI spacing and icon alignment, Aim and Stage Select composition, and smooth latest-selection stage preparation
related:
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../Documentation.md
  - 2026-08-21-uiux-image-parity.md
---

# UI Layout and Stage Browsing Polish - Execution Contract

Paint Mountain keeps the approved icon-first visual system, but repairs the visible density and alignment defects in the current production captures and removes full Gameplay construction from each intermediate Stage Select choice. Work proceeds through shared component geometry, the named Stage Select and Aim/Map layouts, latest-only stage preparation, and one production validation pass.

## Purpose

- Objective: make the interface consistently spaced and visually centered, with particular attention to Stage Select and the Aim screen's left edge, while keeping rapid stage browsing responsive.
- Deliverable: corrected shared UI components and affected screen compositions, a latest-selection preparation path, focused regression coverage, current Windows rendered evidence, and a scoped commit.
- Completion state: all task checks, the focused and broad gates, production export, rendered desktop/compact review, and the stage-browsing timing gate pass; the plan is then marked `done`.

## Scope and Boundaries

In scope:

- Shared icon centering and internal spacing for `ActionControl`, `ValueStepper`, `StageRuleSummary`, and `AimScoreStatus`.
- Composition spacing for Stage Select, Aim, Map/Follow compact score, Pause actions, and Result actions where the shared changes are reachable.
- Main Menu action-row ownership and the compact Result spine at the user-reported 713x1026 Windows viewport.
- Stage Select selection dispatch, preview reuse, latest-request settlement, artifact readiness, and hidden Gameplay preparation timing.
- Korean and English layout, focus, loading/disabled/selected states, 1280x720 and 640x360 evidence, and the existing Windows delivery path.

Out of scope:

- New visual themes, fonts, icons, controls, gameplay rules, stage data, score/paint math, camera behavior, Web publication, or external dependencies.
- Replacing the approved icon-first TO-BE composition or adding containment panels to gameplay overlays.
- Refactoring Gameplay systems beyond what is required to stop per-selection construction.

Constraints and invariants:

- `StageController` remains the stage-state and result authority; `PaintSystem` remains the paint and coverage authority.
- Stage selection remains provisional until Start, the latest selection wins, the last valid preview remains visible until a replacement is ready, and Start never enters a stale stage.
- UI uses the existing Theme, shared component owners, 8 px rhythm, 24/12 px safe margins, 44/40 px routine targets, and 56/48 px primary targets.
- Existing monochrome icon source pixels and provenance remain unchanged; visual centering is implemented by the component geometry.

Destructive or irreversible actions:

- None. Historical evidence and prior completed plans remain untouched.

Exact actions requiring owner or user approval:

- Adding dependencies or asset packs, changing gameplay/stage rules, publishing, pushing, merging, or changing remote visibility.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Cramped and inconsistent component spacing | `AimScoreStatus` draws its bar, current value, paint total, and R/G cues with independent hard-coded starts inside 600x164/300x164 rectangles; `StageRuleSummary` uses 6-10 px group advances; `ValueStepper` uses 4 px gaps | Current 1280x720 and 640x360 captures under `.agents/evidence/2026-08-21-uiux-image-parity/`; source inspection | Keep direct overlays and recompose each shared owner on one 8 px rhythm with explicit group gaps and aligned icon/text columns | 1.2, 1.3, 2.1, 2.2 |
| Icons look off-center inside controls | `ActionControl`, `ValueStepper`, and `TopStatusBar` use imported textures through Button's raw full-canvas bounds; alpha bounds are offset inside several 100x100 sources | ImageMagick read-only alpha-bound inspection; `ActionControl`, stepper, and status sources | Add one shared centered texture view that crops transparent source padding symmetrically without modifying asset files, and use it in all three owners | 1.1 |
| Aim left edge lacks hierarchy | `HudRootLayout` places a 600x164 score control at (24,84); `AimScoreStatus` mixes a 62 px-indented bar with 2 px-indented metric rows | `03-aim-entry-stage08-ko-1280x720.png`, `15-aim-center-stage08-ko-640x360.png`, source | Preserve the success-range-only model but align its range, current marker, paint total, and R/G rows to one left spine with larger vertical separation; keep compact truth visible | 1.3, 2.2 |
| Stage Select information and actions are visually dense | `SelectedInfo` uses 4 px vertical separation; rule facts are one tightly advanced draw row; compact and standard layouts share a 64 px rail lane | Stage Select desktop/compact captures and `stage_select_screen.gd`/scene | Increase hierarchy gaps inside existing safe rectangles, keep the terrain dominant, and preserve the ten-node rail plus one Aim primary | 1.2, 2.1 |
| Stage browsing hitches on every choice | `_on_stage_selection_changed` immediately requests the stage; artifact completion calls `_prepare_hidden_gameplay`, which instantiates and adds the full Gameplay scene. Existing release telemetry shows about 53 ms from `artifact_ready` to `gameplay_binding_started` and another about 20 ms to `gameplay_world_bound` in the same process frame | `src/app/app_root.gd`; `.agents/evidence/2026-08-20-m9-local-release/*.stdout.log`; `stage_runtime_preparer.gd` | Separate selection/preview readiness from full Gameplay binding, coalesce rapid choices to the latest stage, and never construct intermediate Gameplay scenes | 3.1, 3.2 |
| Persisted layout hydration blocks browsing despite asynchronous I/O | Production timing isolated 112-158 ms main-thread gaps between threaded resource completion and each `layout_ready`; `StageLayoutBakeCodec.hydrate()` validates hashes and reconstructs the full `TerrainTopTopology` synchronously | Phase 3 failed timing receipts; `stage_layout_repository.gd`; `stage_layout_bake_codec.gd`; `terrain_top_topology.gd`; architecture requirement at `docs/design-spec.md:394-398` | Restore the documented single pure layout worker for immutable hydration, publish only the latest selected identity, and join the worker on repository exit | 3.2, 3.3 |
| Preview replacement adds avoidable churn | `_set_preview_stage` frees and recreates preview ground, dressing root, shader material, and their children on each ready stage | `app_root.gd`, `open_play_environment.gd`, `environment_dressing.gd` | Reuse preview roots and material; update stage-owned geometry/data in place while retaining the prior valid preview until the replacement artifact is ready | 3.1 |
| Existing tests prove fit but not visual rhythm or browse cost | Responsive tests check bounds, target sizes, and non-overlap; readiness test waits for one stage but does not exercise rapid changes or synchronous dispatch cost | `hud_layout_responsive_test.gd`, `screen_responsive_layout_test.gd`, `stage_selection_readiness_test.gd` | Add component alignment and rapid latest-selection assertions, then use production telemetry and rendered captures for the temporal/pixel claims | 1.4, 2.3, 3.3, 4.2 |
| User evidence disproves the completed icon claim | `ActionControl`, `ValueStepper`, and the top Settings button normalize alpha bounds but leave `Button.icon_alignment` at its left default; the rendered Play glyph centroid is about 12 px left of the blue control center in the 713x1026 release capture | User screenshots and `.agents/evidence/2026-08-21-responsive-ui-correction/before/`; current component scripts | Keep alpha-bound normalization, explicitly center icon-only Button content horizontally and vertically, and assert the actual Button alignment contract | 5.1 |
| Main Menu primary action crowds the following row | `MenuActionItem._apply_layout()` always allocates a 44/40 px action row, while Play's `ActionControl` minimum is 56/48 px; `configure()` changes the role without recomputing the row | Main Menu source and 713x1026 release capture | Size each menu row from the configured action role and reapply layout after role changes; preserve one larger primary without overflow | 5.2 |
| Compact Result abandons the approved right spine | `HudRootLayout._apply_compact_layout()` assigns Result to the full safe viewport and `ResultPanel` expands its summary at the top, obscuring the mountain in a tall desktop window | User 713x1026 Failure screenshot, matching release capture, current Result owners, approved icon-first Result reference | Keep Result right-aligned, cap it to a minority of viewport width, bound its height to content, and retain the complete summary/actions without clipping | 5.3 |
| Prior rendered evidence omitted the failing aspect ratio | Final evidence covered 1280x720 and 640x360 only, so two landscape endpoints passed while the 713x1026 desktop resize path remained wrong | Prior evidence README and responsive test viewport lists | Add 713x1026 plus a neighboring tall desktop case to focused layout tests and make 713x1026 Main Menu, Aim, and Failure production renders mandatory | 5.4, 6.1 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety, and validation decision is closed.
- Godot 4.7.1, the repository wrappers, current capture harness, export preset, and ImageMagick inspection tool are available; no bootstrap or dependency change is required.
- Remaining unknowns are implementation-local. The timing contingency below predetermines the only escalation path if preview reuse alone does not meet the frame budget.

No external research is required: current source, production captures, release telemetry, the approved local UI spec, and Godot 4.7.1 project behavior directly resolve the task.

## Tasks

### Phase 1: Shared alignment and spacing foundation

Goal: make component content visually centered and give related values a consistent internal rhythm before recomposing screens.

Preconditions:

- Current visual receipts and alpha-bound measurements above remain unchanged.

Source owners: `src/ui/components/`, `scenes/ui/components/`, `src/ui/hud/top_status_bar.gd`, `resources/ui/paint_mountain_theme.tres`

- [x] **1.1 Center semantic icons without changing source assets.**
  - Change: add one narrowly owned texture-centering helper and apply it to `ActionControl`, stepper buttons, and the top status Settings button; preserve theme state colors, focus, tooltip, and target geometry.
  - Accept: each normalized texture's visible alpha bounds are centered within one source pixel, and rendered icons sit on their control center within one logical pixel.
  - Guard: source icon hashes do not change.
- [x] **1.2 Re-space compact rule and action primitives.**
  - Change: align icon/text baselines and use at least 8 px label/value gaps and 16 px logical group separation in `StageRuleSummary`, steppers, Pause actions, and Result actions where space permits; scale the same relationships in compact mode.
  - Accept: component geometry tests prove intentional center/baseline alignment, target sizes, and no overlap at both supported evidence sizes.
- [x] **1.3 Recompose `AimScoreStatus` internals.**
  - Change: use one left spine, distinct range/current/paint/role rows, consistent icon boxes, and a less cramped compact preset without changing authoritative inputs or score semantics.
  - Accept: endpoint, marker, paint total, and R/G cues remain complete; row bounds do not intersect and their icon/value centers differ by at most one pixel.
- [x] **1.4 Add focused component contracts.**
  - Change: extend the existing score/shared-component tests with icon normalization, row-spacing, and visual-center assertions.
  - Accept: `shared_ui_component_ownership_test.gd`, `score_scale_contract_test.gd`, and the new or extended focused alignment checks pass.

Batch gate:

- Godot 4.7.1 headless import/parse plus the focused component tests above.

### Phase 2: Stage Select and Aim/Map screen composition

Goal: remove the visible crowding in the named screens while preserving world dominance and every real action.

Preconditions:

- Phase 1 acceptance and batch gate pass.

Source owners: `stage_select_screen.gd`, `stage_select.tscn`, `hud_root_layout.gd`, `hud.tscn`, `aim_controls.gd`, `aim_controls.tscn`

- [x] **2.1 Rebalance Stage Select hierarchy.**
  - Change: increase identity-to-rule and rule-group space, keep arrows and Aim clear of the rail, and preserve selected/loading/ready/failed geometry in standard and compact layouts.
  - Accept: Korean and English at 1280x720 and 640x360 retain ten rail nodes, complete stage identity/rules, at least 12 px between unrelated action groups, and no overlap or clipping.
- [x] **2.2 Rebalance Aim, Map, and Follow edge layouts.**
  - Change: give the left score block a deliberate width/height and top separation, align compact Map/Follow values to the same spine, and make angle -> Fire -> power a centered row with consistent stepper gaps.
  - Accept: the mountain/cannon remain readable; score, queue, top status, and lower controls do not overlap; one primary remains; no component receives less than its minimum geometry.
- [x] **2.3 Strengthen responsive and focus checks.**
  - Change: add pairwise group-gap, shared-center, safe-area, focus-order, and Korean/English fit assertions to the existing screen/HUD tests.
  - Accept: `screen_responsive_layout_test.gd`, `hud_layout_responsive_test.gd`, `localization_ui_test.gd`, and `essential_ui_copy_test.gd` pass.

Batch gate:

- One background capture batch for Stage Select, Aim entry/center, Map, Follow, Pause, and Clear at 1280x720 and 640x360; inspect only the affected states before advancing.

### Phase 3: Smooth latest-selection stage browsing

Goal: keep every rail/arrow choice immediate and stop constructing discarded Gameplay scenes.

Preconditions:

- Phase 2 acceptance passes so performance changes are measured against final layout inputs.

Source owners: `src/app/app_root.gd`, `src/app/stage_layout_repository.gd`, `src/app/stage_runtime_preparer.gd`, `src/terrain/environment_dressing.gd`, `src/terrain/open_play_environment.gd`, `tests/stage_selection_readiness_test.gd`, `src/delivery/delivery_capture_runner.gd`

- [x] **3.1 Reuse the preview presentation.**
  - Change: retain preview ground, dressing root, and shader material; update the latest ready artifact in place and keep the previous valid preview visible until then.
  - Accept: preview identity, mesh, ground, and dressing all match the final selected stage; no preview root is destroyed/recreated per choice; preview publication stays below one 16.67 ms frame in the production timing scenario.
- [x] **3.2 Coalesce Gameplay preparation to the latest selection.**
  - Change: separate lightweight selection/artifact requests from full hidden Gameplay binding, use one generation-owned settle request, cancel stale work, and preserve Start/stale-result truth.
  - Accept: a rapid Stage 01 -> 02 -> 03 sequence updates the rail immediately, prepares only Stage 03 Gameplay, never commits `GameState` before Start, and enters Stage 03 after one Start action.
- [x] **3.3 Add timing and stale-work regression evidence.**
  - Change: extend the readiness/delivery scenario with compact timing markers for selection dispatch, preview publication, Gameplay binding count, and final readiness.
  - Accept: direct selection dispatch is under 8 ms, production preview publication is under 16.67 ms, artifact slices retain their existing 8/12 ms budgets, no intermediate Gameplay instantiation marker appears, and the exported background sequence's maximum present interval is no more than twice its warmed baseline maximum. Absolute present intervals are not used as a 60 FPS proxy because the non-focusable off-desktop capture window is consistently presented near 30 FPS even when idle.

Batch gate:

- `stage_selection_readiness_test.gd`, `stage_runtime_preparer_test.gd`, `phase7_ui_test.gd`, and the production Windows stage-browse timing scenario pass once.

### Phase 4: Production validation, quality audit, and handoff

Goal: prove the final UI and temporal behavior through the repository's strongest required gates without repeating settled checks.

Preconditions:

- Phases 1-3 and their named batch gates pass.

Source owners: `scripts/test.ps1`, `scripts/verify.ps1`, export preset, delivery capture runner, `.agents/evidence/`

- [x] **4.1 Run the broad project gates once.**
  - Change: run the ordered suite and `scripts/verify.ps1` after implementation stabilizes.
  - Accept: both commands exit successfully with no new Godot error or warning owned by this task.
- [x] **4.2 Export and inspect production evidence.**
  - Change: export the Windows release, run one task-owned background capture/timing batch, and inspect desktop/compact pixels plus the rapid browse telemetry.
  - Accept: UIUX Gate Level 4 blockers are absent in named states; the rendered icon centers, spacing, Aim left hierarchy, and Stage Select interaction agree with this contract; timing thresholds in 3.3 pass.
- [x] **4.3 Run `$codebase-quality-auditor`, close truth, and commit.**
  - Change: audit task-owned multi-file/public UI owners, apply only small safe corrections, update `.agents/Documentation.md` and this plan with actual evidence, mark the plan done, and commit only task-owned changes with a short explanatory body.
  - Accept: no competing UI/layout or stage-preparation owner remains, `git diff --check` passes, and the scoped commit exists.

### Phase 5: User-reported icon and tall-window correction

Goal: correct the exact defects visible in the user's production screenshots without reopening stage-preparation behavior or the approved icon-first theme.

Preconditions:

- The user screenshots and the matching 713x1026 release reproduction are the before evidence; prior 1280x720 and 640x360 passes remain valid only for inputs not changed by this phase.

Source owners: `src/ui/components/action_control.gd`, `src/ui/components/menu_action_item.gd`, `src/ui/components/value_stepper.gd`, `src/ui/hud/top_status_bar.gd`, `src/ui/hud/hud_root_layout.gd`, `src/ui/hud/result_panel.gd`, responsive UI tests

- [x] **5.1 Center icon-only Button content in the real control.**
  - Change: set horizontal and vertical icon alignment in the three icon Button owners while retaining centered alpha regions, focus rings, roles, source assets, and minimum targets.
  - Accept: component tests assert centered alignment and 713x1026 production pixels show Play and Fire glyphs centered within one rendered pixel of their control centers.
- [x] **5.2 Give Main Menu roles truthful row geometry.**
  - Change: recompute `MenuActionItem` after configuration and allocate its primary/routine row from the configured `ActionControl` edge plus an explicit shared gap.
  - Accept: Play no longer exceeds its row; all four action rectangles are disjoint with at least 12 logical px between visible control bounds at standard and compact/tall sizes.
- [x] **5.3 Restore the compact right-side Result spine.**
  - Change: replace the full-safe-viewport Result rectangle with a right-aligned, width-capped, content-height-bounded spine and make compact summary/action minimums agree with that rectangle.
  - Accept: at 713x1026 the Result occupies no more than 54% of viewport width and 66% of viewport height, remains inside safe margins, shows the full 0-100 axis and reachable actions, and leaves the mountain visible across the opposite side.
- [x] **5.4 Cover the rejected aspect ratio.**
  - Change: add 713x1026 and one neighboring tall desktop viewport to the shared screen/HUD responsive matrices, including role-row, icon alignment, Result occupancy, safe-area, and overlap assertions.
  - Accept: the focused component and responsive tests pass in Korean and English.

Batch gate:

- Run only the affected shared-component, screen-responsive, HUD-responsive, copy, and localization tests after the phase implementation stabilizes.

### Phase 6: Corrective production proof and handoff

Goal: replace the invalid acceptance claim with evidence that exercises the exact rejected window and preserves the desktop baseline.

Preconditions:

- Phase 5 acceptance and its focused batch gate pass.

Source owners: Windows release export, delivery capture runner, `.agents/evidence/2026-08-21-responsive-ui-correction/`, project documentation

- [x] **6.1 Inspect exact production states.**
  - Change: export once, then capture Main Menu, Aim, and target-band Failure at 713x1026 plus one 1280x720 Aim/Result regression pair.
  - Accept: the four user-reported defect classes are absent under UIUX Gate Level 4; no clipping, overlap, off-center glyph, full-screen Result sheet, or lost mountain hero remains.
- [ ] **6.2 Run the final project gates and quality audit.**
  - Change: run the ordered suite, `scripts/verify.ps1`, and `$codebase-quality-auditor` once after the production pixels pass; apply only small task-scoped corrections.
  - Accept: all gates pass, no shared-UI competing owner or reachable responsive failure remains, and `git diff --check` passes.
- [ ] **6.3 Correct durable truth and commit.**
  - Change: update the evidence README and `.agents/Documentation.md` to retract the invalid two-landscape acceptance claim, mark this plan done, and commit only correction-owned files.
  - Accept: documentation names the 713x1026 evidence and the scoped commit exists.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | Named focused Godot script tests in each task | After a coherent owner-level edit | A relevant owner or assertion changes |
| Phase gate | The batch gate named under that phase | All tasks in the phase pass | A phase-owned input changes |
| Final gate | `pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN`; `pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN`; Windows release export and one background evidence batch | All phases pass | A final-gate input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Rerun a failed check only after a relevant implementation change or a new hypothesis can produce new evidence.
- A headless layout check cannot substitute for rendered spacing or icon alignment, and a screenshot cannot substitute for browse timing.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let implementation choose a new product, architecture, dependency, data, UX, safety, or validation contract |
| Reused preview publication still exceeds 16.67 ms in production | Build the latest preview presentation off-tree in bounded steps and atomically swap it after completion | Preserve the last valid frame; do not remove terrain/dressing or weaken the timing threshold |
| The background capture's maximum present interval exceeds twice its warmed baseline | Split stacked main-thread publication across frames, then reduce bounded runtime-artifact slice budgets only if the peak remains attributable to task-owned work | Do not treat the background window's absolute ~30 FPS cadence as foreground frame-rate evidence |
| Full Gameplay binding still blocks an active rapid-browse interval | Delay binding until the selected stage has settled; if it still intrudes, defer binding to Start while keeping the preview visible and Start in a truthful loading state until entry completes | Do not reintroduce per-choice binding or commit selection early |
| A larger component cannot fit compact geometry at approved text/target sizes | Reflow duplicate metadata or stack semantic rows inside the same owner | Do not shrink routine/primary targets, hide score truth, or add horizontal scrolling |

Implementation-local discoveries may be handled inside the locked contract when they cannot change scope, visible behavior, ownership, architecture, safety, or acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 6, corrective production proof and handoff.
- Next task: 6.2 run the final project gates and quality audit.
- Last completed gate: focused shared-component/copy/localization/responsive tests pass in Korean and English, including 713x1026 and 768x1024. The Windows release export and five production captures pass: Main Menu, Aim, and target-band Failure at 713x1026 plus Aim and Failure at 1280x720. The Play alpha bounds are centered within 0.5 rendered px, Fire is centered, and the tall Result spine occupies about 48% of the viewport width while preserving the opposite world side. Evidence: `.agents/evidence/2026-08-21-responsive-ui-correction/production/`.
- Update rule: after a checkpoint passes, record concise evidence, check the task, and advance this pointer in the same edit.
- Resume rule: read this contract and the current worktree, then continue from the first unchecked task whose prerequisites are satisfied. Treat checked work and passing evidence as current unless its owned input changed.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and named gate passes.
- Production pixels and timing prove the user-visible claims.
- Durable implemented truth is updated, the plan is `done`, and task-owned changes are committed.
- No placeholder or unresolved material decision remains.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
