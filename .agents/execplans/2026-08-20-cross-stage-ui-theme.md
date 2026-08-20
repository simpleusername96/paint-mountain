---
type: plan
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: implement the user-selected Cannon Focus compact shared UI system across every reachable Paint Mountain screen and all 30 stages without changing gameplay rules
supersedes:
  - 2026-08-18-three-ball-target-band-prototype.md
related:
  - ../PLANS.md
  - ../../docs/reports/ui-refinement-2026-08-20/index.html
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../evidence/2026-08-20-m7-responsive-ui/README.md
  - ../evidence/2026-08-20-m8-web-latency/README.md
  - ../evidence/2026-08-20-m9-local-release/README.md
---

# Cannon Focus Cross-Stage UI Refinement - Execution Contract

Paint Mountain will use the report's selected C, **Cannon Focus**, composition
as one shared Godot UI system. The running mountain, cannon, trajectory, paint,
and authoritative stage values remain primary. Screens use reusable Theme roles
and component scenes instead of screen-local cards, panels, palette copies, or
stage-specific layouts. Work proceeds from shared primitives to application
screens, then gameplay states, rendered correction, and one final production
gate.

## Purpose

- Objective: replace the current mixed card/panel HUD with the clear, compact,
  icon-first Cannon Focus system shown in
  `docs/reports/ui-refinement-2026-08-20/index.html`.
- Deliverable: one responsive shared UI across Main Menu, Stage Select,
  Briefing, Aim, Map, Shot Follow, Pause, Settings, Result, loading, failure,
  disabled, focus, and transient states for all 30 stages.
- Completion state: every task and named gate passes; current Windows and Web
  production renders are inspected; durable implementation truth is recorded;
  the plan is `done` and the task-owned worktree is clean.

## Scope and Boundaries

In scope:

- The canonical Theme, shared UI component scenes/scripts, HUD and application
  screen composition, Korean/English copy fit, focus/accessibility behavior,
  responsive behavior, capture coverage, tests, exports, and local Web journey.
- Stages 1-6 retain target-band, Red/Green contribution, and three-ball queue
  truth. Stages 7-30 retain coverage and mechanism truth. Both use the same
  presentation owners.
- The completed responsive and Web-performance corrections from the superseded
  prototype plan remain prerequisites and regression guards.

Out of scope:

- Gameplay rules, stage values, physics, paint authority, camera rules, save
  schema, new stages, new dependencies, fonts, plugins, asset packs, or a second
  UI/render/capture framework.
- Public itch upload, channel mutation, visibility change, or deployed-artifact
  claim without a new explicit user authorization after the final local Web
  artifact is proven.

Constraints and invariants:

- `StageController` remains the sole stage-state and result owner;
  `PaintSystem` remains the sole paint/coverage owner; UI displays supplied
  truth and emits typed intent only.
- `resources/ui/paint_mountain_theme.tres` remains the only palette, font, and
  semantic style owner. Screens may arrange shared components but may not copy
  their StyleBoxes, colors, fonts, icons, or behavior.
- Pretendard, the Compatibility renderer, the 1280x720 logical baseline, fixed
  60 Hz physics, existing local icons, and existing Godot 4.7.1 runtime remain.
- Aim uses Cannon Focus: vertical `ScoreScale` at the left, horizontal
  `BallQueue` at the upper-right, and `angle -> Fire -> power` around the lower
  cannon region. The compact layout may reduce copy and physical lengths but
  may not hide angle, power, Fire, queue truth, or score endpoints.
- `ScoreScale` has a fixed 0-100 domain with visible 0/25/50/75/100 labels.
  Aim, Map, and Shot Follow use the vertical preset; Briefing and Result use the
  horizontal preset.
- Ball descriptions contain queue position, kind, paint role, and short
  behavior. Hover, keyboard focus, and press/touch reveal equivalent content;
  the accessible description is not tooltip-only.
- Stage Select reuses `AppRoot._preview_world` and the newest ready selected
  `StageRuntimeArtifact`; selection never commits `GameState` before Start and
  never creates a second renderer or generic landscape.
- One filled blue primary action is visible per state. Persistent gameplay,
  Briefing, Stage Select, and Result use no decorative panel/card/sheet/dock.
- User-facing text remains Korean-first and concise. Essential or risky actions
  retain visible labels; routine status favors icons plus values.

Destructive or irreversible actions:

- Obsolete UI scenes/scripts may be deleted only after every current caller is
  migrated, focused tests pass, and `rg` proves no remaining reference. Git
  history remains the recovery path.

Exact actions requiring owner or user approval:

- Adding/upgrading a dependency, font, plugin, or asset pack; changing gameplay
  or saved data; destructive work outside obsolete migrated UI files; public
  itch publication or channel/visibility mutation.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Canonical composition | The report has three actual Aim images; the user selected C | report revision 04 and current conversation | Cannon Focus is canonical; A/B remain historical alternatives | 1.1, 3.1 |
| Shared style ownership | Theme exists, while HUD scenes still use panel-specific variations and local overrides | `resources/ui/paint_mountain_theme.tres`, `scenes/ui/` | Extend the Theme; never add a second palette/style owner | 1.2 |
| Full score domain | `CoverageMeter` is vertical 0-100, but `TargetBandMeter` crops to a target-relative range | `src/ui/hud/coverage_meter.gd`, `src/ui/hud/target_band_meter.gd` | Replace both presentation paths with one shared fixed-domain `ScoreScale` | 1.3, 3.2 |
| Ball explanation | `QueueTokenView` is a non-focusable `PanelContainer` and exposes kind/channel only through default hover tooltip | `queue_token_view.tscn/.gd` | Use shared focusable token controls and one shared description bubble/state owner | 1.4, 3.2 |
| Cannon Focus controls | `AimControls` is one 480 px panel and compact mode hides all angle/power controls | `aim_controls.tscn`, `hud_root_layout.gd` | Compose two shared `ValueStepper`s around the shared Fire action; compact mode reflows rather than hides them | 1.5, 3.1 |
| Stage Select terrain | Stage Select is a card/detail split and `_show_stage_select()` disables the preview world | `stage_select.tscn/.gd`, `app_root.gd` | Preserve paging/focus/loading truth, replace cards with `StageRail`, and publish prepared terrain atomically | 2.2 |
| App and terminal screens | Main Menu, Briefing, Pause, Settings, and Result preserve real actions but use mixed containment | current scenes and running captures | Recompose with the same components/Theme; preserve every state and action | 2.1, 2.3, 3.2-3.4 |
| Cross-stage truth | All 30 stages are data-driven; 1-6 use target-band/queue, 7-30 use coverage/mechanism fields | `StageCatalog`, `StageData`, `StageLayoutRepository` | Conditional data regions inside shared components; no stage-specific UI copies | 3.5 |
| Existing responsive work | M7 container/contrast work and accepted-size evidence pass, but its stress fallback hides essential aim controls | superseded prototype plan and M7 evidence | Preserve its safe-area/focus fixes; replace only the conflicting fallback | 3.1, 4.1 |
| Existing Web performance work | M8 removed measured paint/projectile stalls and M9.1-9.3 proved local artifacts | M8/M9 evidence | Do not reopen completed optimization; run one final built-Web regression journey after UI changes | 4.4, 5.2 |
| Validation path | Shared Godot 4.7.1 and project scripts/presets exist; CLI supports all named flags | installed binary `4.7.1.stable`, `scripts/*.ps1`, `export_presets.cfg` | Use focused headless checks, background captures, then one broad/export gate | all phases |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership,
  safety, and validation decision is closed.
- Required runtime, scripts, presets, source assets, and capture owners are
  available. No bootstrap or external dependency is required.
- Existing external comparisons and Godot 4.7 primary documentation already
  resolve the decisions they can affect; no new visual or dependency research
  remains.
- Remaining choices are implementation-local Container geometry, Theme
  variation names, and small copy fit adjustments inside the locked behavior.

## Tasks

### Phase 1: Canonical decision and shared component foundation

Goal: make every later screen a composition of stable reusable owners.

Preconditions:

- Worktree and current branch are inspected; unrelated user changes are left
  untouched.
- Report images remain composition evidence, not runtime truth.

Source owners: `docs/source-brief.md`, `.agents/design/UIUX_GUIDELINES.md`,
`.agents/design/VISUAL_REFERENCES.md`, `resources/ui/paint_mountain_theme.tres`,
`scenes/ui/components/`, `src/ui/components/`, `translations/ui.csv`

- [x] **1.1 Lock Cannon Focus and consolidate plan authority.**
  - Change: record C as canonical in the report/design authority and make this
    the sole active UI/release contract; retain the superseded prototype plan
    as history and carry its completed evidence/remote approval boundary here.
  - Accept: no active plan or design source still calls A the default; the old
    plan is lifecycle-valid and points here; no completed task was reopened.
- [x] **1.2 Extend the canonical Theme and ownership contract.**
  - Change: add only the semantic variations required for direct overlay,
    vertical/horizontal scale, queue token/description, value stepper, primary/
    secondary/quiet action, stage node states, result summary, contrast scrim,
    interruption surface, disabled, hover, pressed, and focus.
  - Accept: a focused Theme/ownership test proves all shared scenes inherit the
    canonical Theme and no new screen-local palette/font/StyleBox owner exists.
- [x] **1.3 Implement shared `ScoreScale`.**
  - Change: add `scenes/ui/components/score_scale.tscn` and
    `src/ui/components/score_scale.gd`; support vertical-live and horizontal-
    summary presets, fixed 0-100 mapping, five labels, current marker, target
    range/threshold, and optional Red/Green contribution values. Migrate and
    retire `CoverageMeter` and `TargetBandMeter` only after callers pass.
  - Accept: `tests/score_scale_contract_test.gd` proves both presets, endpoints,
    target/marker bounds, 0/100 clamping, and both stage-family models.
- [x] **1.4 Implement shared `BallQueue`.**
  - Change: add shared queue and focusable token scenes/scripts. One queue owner
    controls horizontal/vertical arrangement, token order/state, hover/focus/
    press description visibility, accessible text, pin/dismiss behavior, and
    safe-edge placement. Reuse existing ball/channel truth and shape drawing.
  - Accept: `tests/ball_queue_tooltip_test.gd` proves three-token ordering,
    native focus, pointer/focus/press equivalence, Escape/dismiss, accessible
    description, and no essential hover-only state.
- [x] **1.5 Implement the remaining shared primitives.**
  - Change: enhance/rehome `MetricReadout` and `ContextHints`; add reusable
    `ValueStepper`, `ActionControl`, `StageRail`, `ResultSummary`, and
    `ContrastScrim`. `AimControls`, app screens, and Result must compose these
    owners rather than reproduce their internals.
  - Accept: `tests/shared_ui_component_ownership_test.gd` finds one production
    owner for each primitive, verifies routine target sizes/focus names, and
    finds no duplicate legacy caller after migration.

Phase 1 gate, from repository root:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/score_scale_contract_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/ball_queue_tooltip_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/shared_ui_component_ownership_test.gd
```

### Phase 2: Application and interruption screens

Goal: use the shared hierarchy outside gameplay and prove the real selected
terrain before changing the high-frequency HUD.

Preconditions:

- Phase 1 tasks and gate pass.

Source owners: `scenes/ui/screens/`, `src/ui/screens/`, `src/app/app_root.gd`,
`src/app/stage_runtime_artifact.gd`, `src/app/stage_runtime_preparer.gd`,
`translations/ui.csv`

- [ ] **2.1 Refine Main Menu.**
  - Change: keep the prepared preview world dominant; use one shared primary
    Play/Continue action and quiet Stages/Settings/Exit actions without a card
    stack or duplicate explanatory text.
  - Accept: ready, preparing, load-failed, empty-save, locale-switch, and focus-
    restoration states preserve every current action and one primary action.
- [ ] **2.2 Recompose Stage Select as real terrain plus `StageRail`.**
  - Change: remove the card/detail split. Activate `_preview_world` in
    `_show_stage_select()`, let `_set_menu_preview_if_visible()` serve visible
    Stage Select, and publish only the newest selected ready artifact from
    `_on_stage_selection_changed()`/artifact callbacks. Keep the previous valid
    terrain until the newest artifact is ready. Compose eight numbered shared
    nodes, page chevrons, compact facts, Back, and one Start action.
  - Accept: node changes update the actual selected terrain without a generic,
    stale, or blank landscape; paging, selected/completed/locked states,
    preparation failure/retry, focus, all-open development behavior, and the
    no-commit-before-Start invariant pass.
- [ ] **2.3 Refine Pause and Settings.**
  - Change: use one shared interruption surface only because input is blocked;
    align shared rows/actions, remove decorative nesting, and preserve caller
    return, passive synchronization, defaults, persistence, and focus restore.
  - Accept: Gear/Escape parity, pause input barrier, Settings round-trip,
    Korean/English fit, disabled states, and keyboard order pass.
- [ ] **2.4 Close application-screen responsive states.**
  - Change: use Containers and bounded scrolling at the current breakpoints;
    suppress only redundant Priority 3 copy.
  - Accept: 1280x720, 1920x1080, and 640x360 stress models show every Priority
    1 action/state without clip, overlap, or off-screen focus.

Phase 2 gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/screen_responsive_layout_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/stage_select_rule_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/localization_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/essential_ui_copy_test.gd
```

### Phase 3: Cannon Focus gameplay shell and all states

Goal: keep the mountain/cannon cause-and-effect chain primary in every gameplay
state while retaining every authoritative value and action.

Preconditions:

- Phase 2 tasks and gate pass.

Source owners: `scenes/ui/hud/`, `src/ui/hud/`, `src/ui/hud_controller.gd`,
`scenes/ui/components/`, `src/ui/components/`, `translations/ui.csv`

- [ ] **3.1 Build the Cannon Focus safe-area composition.**
  - Change: replace the fixed mixed HUD offsets with a container-owned shell:
    Stage/clock/shots/Gear at safe top edges, vertical `ScoreScale` at left,
    horizontal `BallQueue` at upper-right, angle stepper left of Fire, Fire at
    bottom-center, power stepper right of Fire, and at most three compact
    context hints. Remove routine backdrops, rails, and docks. Replace the
    stress fallback that hides angle/power with a compact icon/value reflow.
  - Accept: 1920x1080, 1280x720, 900x500, and 640x360 models retain score
    endpoints, angle, power, Fire, queue truth, status, and a clear central
    cannon/trajectory/mountain view.
- [ ] **3.2 Apply the shell to Briefing and Aim.**
  - Change: Briefing keeps the real world with direct objective/ball order and
    Back/Start; Aim uses the Cannon Focus layout and shared tooltip behavior.
  - Accept: Briefing uses horizontal `ScoreScale`; Aim uses vertical; target-
    band values, Red/Green roles, coverage target, shot capacity, fire readiness,
    focus, shortcuts, and locale refresh remain authoritative.
- [ ] **3.3 Apply state reductions to Map and Shot Follow.**
  - Change: Map removes aim/Fire-only controls and preserves inspection inputs;
    Shot Follow removes Fire and exposes the legal Return to Cannon action plus
    projectile-family observation. Both keep only relevant scale/status data.
  - Accept: no unavailable action is duplicated; input/focus state agrees with
    `CameraDirector` and `StageController` observations.
- [ ] **3.4 Replace the result card with shared `ResultSummary`.**
  - Change: keep the painted mountain as the hero; show direct verdict, value,
    horizontal `ScoreScale`, compact breakdown, and prioritized Next/Retry/
    Same Deal/New Deal/Stages actions without a sheet. Preserve timeout/manual,
    target-band/coverage, previous-best, and has-next variants.
  - Accept: every reachable result variant preserves correct action visibility,
    one primary action, focus entry, authoritative values, and no world-blocking
    container.
- [ ] **3.5 Prove all 30 stages through the shared presentation.**
  - Change: add `tests/cross_stage_ui_theme_test.gd` to present every catalog
    stage through Briefing/Aim/Result models.
  - Accept: Stages 1-6 expose only valid target-band/queue fields; Stages 7-30
    expose only valid coverage/mechanism fields; every stage uses the canonical
    Theme/components and fixed 0-100 scale; no stage resource owns layout/color.

Phase 3 gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/cross_stage_ui_theme_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_layout_responsive_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_target_band_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/target_band_layout_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/ball_queue_tooltip_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_hud_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_aiming_composition_test.gd
```

### Phase 4: Responsive, locale, accessibility, and rendered correction

Goal: correct actual production pixels and interaction states before the broad
repository/export gate.

Preconditions:

- Phases 1-3 and their gates pass.

Source owners: task-owned UI scenes/scripts/tests,
`src/delivery/delivery_capture_runner.gd`,
`.agents/evidence/cross-stage-ui-theme-2026-08-20/`

- [ ] **4.1 Run the complete layout/state matrix.**
  - Change: exercise every app/gameplay state, both locales, accepted sizes,
    640x360 stress, disabled/selected/loading/failure/focus states, queue
    descriptions, and both stage families.
  - Accept: no essential control is below 24x24; routine controls target 40+
    px; focus is visible and ordered; text, values, scale labels, tooltips, and
    actions do not clip, overlap, escape, or rely on color alone.
- [ ] **4.2 Capture the representative Windows production matrix.**
  - Change: export Windows and run the existing background capture owner for
    Main Menu, Stage Select, Pause, Settings; Stage 01 Briefing/Aim/Result;
    Stage 03 Aim/Shot Follow/Result; Stage 07 Aim/Result; Stage 30 Aim/Map/
    Result. Capture Korean 1280x720, named 640x360 stress states, and English
    1920x1080 comparison states.
  - Accept: every file is nonblank, correct-state, current-build, and records
    stage/locale/viewport/renderer metadata.
- [ ] **4.3 Inspect and correct the running pixels.**
  - Change: compare the matching report target once per state, record P0/P1/P2
    findings, fix a coherent batch, and recapture only invalidated states.
  - Accept: no UI blocker remains; mountain/cannon/trajectory/paint dominate;
    Cannon Focus hierarchy, actual Stage Select terrain, scale endpoints, queue
    descriptions, spacing, typography, and action priority read correctly.
- [ ] **4.4 Run the built-Web production UI journey.**
  - Change: export Web, validate the release, load `$npjt-port-guard`, use the
    fastrun manager `codex` lane, and exercise launch, resize, fullscreen, Main
    Menu, Stage Select, Stage 03 Aim/Pause/Settings/Result, Stage 07 Aim/Result,
    focus, queue descriptions, and language switching in one Chrome DevTools
    stack. Stop task-owned helpers.
  - Accept: no missing resource, console error, stale focus/terrain, input
    interception, layout failure, or regression of the recorded M8 paint/
    projectile responsiveness boundary. Record lane, URL, artifact hash, and
    observations without hardcoding a port in source.

### Phase 5: Quality, broad gates, durable truth, and handoff

Goal: prove the cross-module UI change is maintainable and production-ready.

Preconditions:

- Phase 4 passes and rendered correction is stable.

- [ ] **5.1 Run `$codebase-quality-auditor`.**
  - Change: audit task-owned changes for competing Theme/component owners,
    catch-all HUD growth, duplicated layout logic, stale callers, reachable
    loading/failure/focus gaps, test weakening, and missing all-stage coverage;
    apply only small safe corrections.
  - Accept: no material finding remains in the task-owned surface.
- [ ] **5.2 Run the broad production gate once.**
  - Change: after announcing cost/scope, run:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

  - Accept: suite, verification, both exports, and Web static verifier pass on
    the final inputs.
- [ ] **5.3 Record implemented truth and close the plan.**
  - Change: update `.agents/Documentation.md`, `docs/test-checklist.md`, design
    authority, and the evidence README with only proven behavior, exact Godot/
    renderer/locale/viewport/build hashes, checks, and remaining warnings.
  - Accept: docs agree with runtime and this plan; every task/gate is checked;
    frontmatter becomes `done`.
- [ ] **5.4 Finish coherent commits and a clean worktree.**
  - Change: keep plan/design, shared foundation, app screens, gameplay/all-stage,
    and final evidence/records in responsibility-shaped commits with bodies;
    stage no unrelated user work.
  - Accept: `git status --short` is clean and log/diff scope matches this plan.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | one named Godot test with `--quit-after 7200` | a task changes its scene/script/Theme/translation contract | that input or assertion changes |
| Phase gate | exact commands listed under that phase | all phase tasks pass their acceptance checks | a phase-owned input changes |
| Render correction | named production capture subset | a visible batch is coherent | a visible owner/capture prerequisite changes |
| Web journey | built Web artifact on protected `codex` lane | Windows pixels and Web export are current | a Web-visible source/export input changes |
| Final gate | `scripts/test.ps1`, `scripts/verify.ps1`, both exports, Web verifier | implementation, pixels, and audit are stable | a production/test/project/export input changes |

Validation rules:

- On start/resume, read this contract and inspect the worktree only enough to
  confirm the next unchecked task's inputs.
- Treat checked tasks and recorded passing evidence as current until a relevant
  input changes or the final gate becomes due.
- Run the narrowest check that proves the current task. Do not use headless
  success as visual proof.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can change the result.
- Update task checkboxes and the single progress pointer together after each
  checkpoint. Do not mirror task state in another progress document.
- Save large logs/captures under the task evidence directory and link them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| Material fact contradicts this contract | stop the affected branch and update the contract | executor may not choose a new UX, architecture, dependency, gameplay, or validation contract |
| Generated-image detail conflicts with runtime truth | preserve real behavior/data and apply only hierarchy/spacing | never invent/remove an action/value to match a still |
| Shared scale clips | fix shared label reserve/clamping/minimum geometry and rerun callers | never zoom to the target range or patch one screen |
| Queue description clips or is hover-only | fix shared safe-edge placement and focus/press path | never add screen-local tooltip geometry |
| Stage Select terrain is stale/blank/wrong | retain the previous valid artifact until the newest selected one is ready, then swap atomically | never create generic art, a second renderer, or early GameState commit |
| A stress size cannot fit Priority 3 copy | shorten/wrap/suppress duplicated hints | never hide score endpoints, angle, power, Fire, queue truth, or legal actions |
| Theme variation harms another screen | narrow the semantic variation and migrate intended users | never create another Theme/palette owner |
| `HUDController` grows layout-only branches | move presentation behavior into a component/layout owner | never move StageController/PaintSystem rules into UI |
| Existing visual test encodes a superseded panel/card | update only the visual assertion and preserve behavior/state guards | never delete/weaken a test to pass |
| Public itch proof is requested | stop, present final local artifact/hash/evidence, and obtain explicit authorization | no workflow dispatch, upload, channel/visibility mutation, or public claim without approval |

Implementation-local mechanics may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: task checkboxes in this contract.
- Current phase: Phase 2.
- Next task: 2.1, refine Main Menu with shared action hierarchy.
- Last completed gate: Phase 1; `phase7_ui_test`, `score_scale_contract_test`,
  `ball_queue_tooltip_test`, and `shared_ui_component_ownership_test` passed on
  Godot 4.7.1 on 2026-08-20. The shared HUD now uses the fixed-domain
  `ScoreScale`, focusable horizontal `BallQueue`, `ValueStepper`, and
  `ActionControl`; the cropped score and legacy queue owners were retired.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and every named phase/final gate passes.
- Current production renders prove the named states, both stage families,
  locales, and responsive sizes.
- Durable design/implementation/test truth agrees with the final runtime.
- No placeholder, unresolved material decision, or task-owned dirty file
  remains, and frontmatter is `done`.

Replan when:

- A verified material discovery invalidates Cannon Focus hierarchy, shared
  component ownership, stage-family split, Stage Select artifact path,
  dependency boundary, or validation path.

Do not replan or stop for:

- Container details, semantic variation names, or concise copy adjustments
  that remain inside the locked contract.
- A passing check whose relevant inputs have not changed.
