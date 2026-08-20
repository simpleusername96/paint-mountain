---
type: plan
status: superseded
created: 2026-08-20
last_reviewed: 2026-08-20
scope: implement and correct the user-selected Cannon Focus compact shared UI system, close the reported Web paint-queue latency, and migrate all 30 stages to the Red/Green three-ball target-band loop
superseded_by: 2026-08-20-stage-ui-production-refinement.md
supersedes:
  - 2026-08-18-three-ball-target-band-prototype.md
related:
  - ../PLANS.md
  - ../../docs/reports/ui-refinement-2026-08-20/index.html
  - ../../docs/reports/itch-paint-latency-2026-08-20/index.html
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
  - ../evidence/2026-08-20-paint-queue-latency-correction/README.md
  - ../evidence/2026-08-20-all-stage-target-band-migration/README.md
  - ../evidence/2026-08-20-m9-local-release/README.md
  - ../evidence/cross-stage-ui-theme-2026-08-20/README.md
  - ../evidence/2026-08-20-hud-capture-regression/README.md
---

# Cannon Focus Cross-Stage UI Refinement - Execution Contract

Paint Mountain will use the report's selected C, **Cannon Focus**, composition
as one shared Godot UI system. The running mountain, cannon, trajectory, paint,
and authoritative stage values remain primary. Screens use reusable Theme roles
and component scenes instead of screen-local cards, panels, palette copies, or
stage-specific layouts. The same Red/Green target-band and limited three-ball
queue now continues through Stage 30; Stage 06 is not a gameplay-rule boundary.
Work proceeds from shared primitives to application screens, gameplay states,
paint latency, the all-stage rule migration, and one final production gate.

## Purpose

- Objective: replace the current mixed card/panel HUD with the clear, compact,
  icon-first Cannon Focus system shown in
  `docs/reports/ui-refinement-2026-08-20/index.html`.
- Deliverable: one responsive shared UI across Main Menu, Stage Select,
  Briefing, Aim, Map, Shot Follow, Pause, Settings, Result, loading, failure,
  disabled, focus, and transient states, plus deterministic Red/Green
  target-band rules and varied Standard/Impact Burst/Apex Split deals for all
  30 stages.
- Completion state: every task and named gate passes; current Windows and Web
  production renders are inspected; durable implementation truth is recorded;
  the plan is `done` and the task-owned worktree is clean.

## Scope and Boundaries

In scope:

- The canonical Theme, shared UI component scenes/scripts, HUD and application
  screen composition, Korean/English copy fit, focus/accessibility behavior,
  responsive behavior, capture coverage, tests, exports, and local Web journey.
- Stages 1-6 retain their accepted target-band values. Stages 7-30 migrate from
  scalar coverage to deterministic Red/Green target bands and varied deals
  using the existing Standard, Impact Burst, and Apex Split roster. Existing
  terrain and mechanism content remains authoritative.
- Stage-rule materialization, deterministic deal constraints, the immutable
  catalog pointer/bundle, save-result compatibility, agent observations, shared
  UI truth, focused tests, and representative running-game calibration for the
  all-stage migration.
- The completed responsive and Web-performance corrections from the superseded
  prototype plan remain prerequisites and regression guards.

Out of scope:

- New ball kinds, new stages, terrain replacement, mechanism deletion, reroll,
  hold/swap/purchase actions, in-flight steering, physics changes beyond the
  scoped paint-latency correction, paint-authority changes, camera-rule changes,
  new dependencies, fonts, plugins, asset packs, or a second UI/render/capture
  framework.
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

- Adding/upgrading a dependency, font, plugin, or asset pack; adding another
  ball kind or action; destructive work outside obsolete migrated UI files;
  public itch publication or channel/visibility mutation.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Canonical composition | The report has three actual Aim images; the user selected C | report revision 04 and current conversation | Cannon Focus is canonical; A/B remain historical alternatives | 1.1, 3.1 |
| Shared style ownership | Theme exists, while HUD scenes still use panel-specific variations and local overrides | `resources/ui/paint_mountain_theme.tres`, `scenes/ui/` | Extend the Theme; never add a second palette/style owner | 1.2 |
| Full score domain | `CoverageMeter` is vertical 0-100, but `TargetBandMeter` crops to a target-relative range | `src/ui/hud/coverage_meter.gd`, `src/ui/hud/target_band_meter.gd` | Replace both presentation paths with one shared fixed-domain `ScoreScale` | 1.3, 3.2 |
| Signed score truth | `StageController` and `StageScoreSnapshot` preserve signed Paint Score, but `ScoreScale.set_value()` and `ResultPanel.show_target_band_result()` clamp the displayed value to 0-100; `GameplayScene` also publishes legacy total coverage after signed score to the same live scale, and the existing component/shot-feedback tests require those false displays | `src/stage/stage_controller.gd`, `src/stage/rules/stage_score_snapshot.gd`, `src/gameplay/gameplay_scene.gd`, `src/ui/hud_controller.gd`, `src/ui/components/score_scale.gd`, `src/ui/hud/result_panel.gd`, `tests/color_score_rule_test.gd`, `tests/score_scale_contract_test.gd`, `tests/shot_feedback_test.gd` | Keep the rail and marker geometry fixed to 0-100, preserve the authoritative signed numeric value in live/result UI and accessibility, ignore legacy coverage presentation updates for target-band stages, and use a non-color underflow shape when the marker is projected to 0 | 10.1-10.3 |
| Ball explanation | `QueueTokenView` is a non-focusable `PanelContainer` and exposes kind/channel only through default hover tooltip | `queue_token_view.tscn/.gd` | Use shared focusable token controls and one shared description bubble/state owner | 1.4, 3.2 |
| Cannon Focus controls | `AimControls` is one 480 px panel and compact mode hides all angle/power controls | `aim_controls.tscn`, `hud_root_layout.gd` | Compose two shared `ValueStepper`s around the shared Fire action; compact mode reflows rather than hides them | 1.5, 3.1 |
| Stage Select terrain | Stage Select is a card/detail split and `_show_stage_select()` disables the preview world | `stage_select.tscn/.gd`, `app_root.gd` | Preserve paging/focus/loading truth, replace cards with `StageRail`, and publish prepared terrain atomically | 2.2 |
| App and terminal screens | Main Menu, Briefing, Pause, Settings, and Result preserve real actions but use mixed containment | current scenes and running captures | Recompose with the same components/Theme; preserve every state and action | 2.1, 2.3, 3.2-3.4 |
| Cross-stage truth | All 30 stages are data-driven, but the active v10 catalog limits target-band/queue data to 1-6 | `StageCatalog`, `StageData`, `StageCatalogMaterializer`, `StageLayoutRepository` | Preserve 1-6 values; materialize target-band/queue data for 7-30 and remove the active UI/runtime stage-family split | 3.5, 7.1-7.5 |
| Deal variety | `allowed_kinds` permits a special kind but does not require it to appear in a generated deal | `BallDealProfile`, `BallDealGenerator` | From Stage 07, every valid deal contains Standard plus at least one Impact Burst and one Apex Split; final opposite-color Standards remain the correction reserve | 7.2 |
| Catalog migration | The current immutable generated bundle is contract v10 and must not be edited in place | `StageGenerationContract`, `StageCatalogBundleStore`, `build_stage_catalog.gd` | Build and atomically promote a v11 bundle from the reviewed v10 source; retain the old bundle as migration evidence | 7.3 |
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

- [x] **2.1 Refine Main Menu.**
  - Change: keep the prepared preview world dominant; use one shared primary
    Play/Continue action and quiet Stages/Settings/Exit actions without a card
    stack or duplicate explanatory text.
  - Accept: ready, preparing, load-failed, empty-save, locale-switch, and focus-
    restoration states preserve every current action and one primary action.
- [x] **2.2 Recompose Stage Select as real terrain plus `StageRail`.**
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
- [x] **2.3 Refine Pause and Settings.**
  - Change: use one shared interruption surface only because input is blocked;
    align shared rows/actions, remove decorative nesting, and preserve caller
    return, passive synchronization, defaults, persistence, and focus restore.
  - Accept: Gear/Escape parity, pause input barrier, Settings round-trip,
    Korean/English fit, disabled states, and keyboard order pass.
- [x] **2.4 Close application-screen responsive states.**
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

- [x] **3.1 Build the Cannon Focus safe-area composition.**
  - Change: replace the fixed mixed HUD offsets with a container-owned shell:
    Stage/clock/shots/Gear at safe top edges, vertical `ScoreScale` at left,
    horizontal `BallQueue` at upper-right, angle stepper left of Fire, Fire at
    bottom-center, power stepper right of Fire, and at most three compact
    context hints. Remove routine backdrops, rails, and docks. Replace the
    stress fallback that hides angle/power with a compact icon/value reflow.
  - Accept: 1920x1080, 1280x720, 900x500, and 640x360 models retain score
    endpoints, angle, power, Fire, queue truth, status, and a clear central
    cannon/trajectory/mountain view.
- [x] **3.2 Apply the shell to Briefing and Aim.**
  - Change: Briefing keeps the real world with direct objective/ball order and
    Back/Start; Aim uses the Cannon Focus layout and shared tooltip behavior.
  - Accept: Briefing uses horizontal `ScoreScale`; Aim uses vertical; target-
    band values, Red/Green roles, coverage target, shot capacity, fire readiness,
    focus, shortcuts, and locale refresh remain authoritative.
- [x] **3.3 Apply state reductions to Map and Shot Follow.**
  - Change: Map removes aim/Fire-only controls and preserves inspection inputs;
    Shot Follow removes Fire and exposes the legal Return to Cannon action plus
    projectile-family observation. Both keep only relevant scale/status data.
  - Accept: no unavailable action is duplicated; input/focus state agrees with
    `CameraDirector` and `StageController` observations.
- [x] **3.4 Replace the result card with shared `ResultSummary`.**
  - Change: keep the painted mountain as the hero; show direct verdict, value,
    horizontal `ScoreScale`, compact breakdown, and prioritized Next/Retry/
    Same Deal/New Deal/Stages actions without a sheet. Preserve timeout/manual,
    target-band/coverage, previous-best, and has-next variants.
  - Accept: every reachable result variant preserves correct action visibility,
    one primary action, focus entry, authoritative values, and no world-blocking
    container.
- [x] **3.5 Prove all 30 stages through the shared presentation.**
  - Change: add `tests/cross_stage_ui_theme_test.gd` to present every catalog
    stage through Briefing/Aim/Result models. The then-current catalog used
    shared target-band/queue and legacy coverage/mechanism data regions.
  - Accept: every stage uses the canonical Theme/components and fixed 0-100
    scale without a stage-owned layout/color. Phase 7 updates the now-
    superseded active rule assertions without replacing the shared shell.

Phase 3 gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/cross_stage_ui_theme_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_layout_responsive_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_target_band_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/target_band_layout_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/ball_queue_tooltip_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_hud_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/shot_feedback_test.gd
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

- [x] **4.1 Run the complete layout/state matrix.**
  - Change: exercise every app/gameplay state, both locales, accepted sizes,
    640x360 stress, disabled/selected/loading/failure/focus states, queue
    descriptions, and both stage families.
  - Accept: no essential control is below 24x24; routine controls target 40+
    px; focus is visible and ordered; text, values, scale labels, tooltips, and
    actions do not clip, overlap, escape, or rely on color alone.
- [x] **4.2 Capture the representative Windows production matrix.**
  - Change: export Windows and run the existing background capture owner for
    Main Menu, Stage Select, Pause, Settings; Stage 01 Briefing/Aim/Result;
    Stage 03 Aim/Shot Follow/Result; Stage 07 Aim/Result; Stage 30 Aim/Map/
    Result. Capture Korean 1280x720, named 640x360 stress states, and English
    1920x1080 comparison states.
  - Accept: every file is nonblank, correct-state, current-build, and records
    stage/locale/viewport/renderer metadata.
- [x] **4.3 Inspect and correct the running pixels.**
  - Change: compare the matching report target once per state, record P0/P1/P2
    findings, fix a coherent batch, and recapture only invalidated states.
  - Accept: no UI blocker remains; mountain/cannon/trajectory/paint dominate;
    Cannon Focus hierarchy, actual Stage Select terrain, scale endpoints, queue
    descriptions, spacing, typography, and action priority read correctly.
- [x] **4.4 Run the built-Web production UI journey.**
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

- [x] **5.1 Run `$codebase-quality-auditor`.**
  - Change: audit task-owned changes for competing Theme/component owners,
    catch-all HUD growth, duplicated layout logic, stale callers, reachable
    loading/failure/focus gaps, test weakening, and missing all-stage coverage;
    apply only small safe corrections.
  - Accept: no material finding remains in the task-owned surface.
- [x] **5.2 Run the broad production gate once.**
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
- [x] **5.3 Record implemented truth and close the plan.**
  - Change: update `.agents/Documentation.md`, `docs/test-checklist.md`, design
    authority, and the evidence README with only proven behavior, exact Godot/
    renderer/locale/viewport/build hashes, checks, and remaining warnings.
  - Accept: docs agree with runtime and this plan; every task/gate is checked;
    frontmatter becomes `done`.
- [x] **5.4 Finish coherent commits and a clean worktree.**
  - Change: keep plan/design, shared foundation, app screens, gameplay/all-stage,
    and final evidence/records in responsibility-shaped commits with bodies;
    stage no unrelated user work.
  - Accept: `git status --short` is clean and log/diff scope matches this plan.

### Phase 6: Continuous-paint queue latency correction

Goal: close the implementation gap found by comparing the final source with
the itch latency report. M8 bounded the formerly blocking Burst radial raster,
but `SurfacePaintSweep` still drains eagerly one command per physics tick. That
policy can let a three-child Apex family produce work faster than PaintSystem
consumes it and show authoritative paint seconds after contact.

Preconditions:

- The Cannon Focus implementation and Phase 5 gate remain valid.
- `PaintSystem` remains the only mutable paint/coverage authority and canonical
  command order remains unchanged.

- [x] **6.1 Add queue-age and throughput evidence.**
  - Change: expose bounded read-only diagnostics for pending/active command
    count, oldest pending age in physics ticks, and queued/completed totals;
    add a fixed Standard/Apex-like continuous-sweep regression that records
    production and completion rather than checking only an eventual flush.
  - Accept: the old one-command-per-tick policy fails the regression for a
    three-command-per-tick workload, and production diagnostics add no normal
    console output or second paint representation.
- [x] **6.2 Put radial and sweep work behind one incremental budget.**
  - Change: implement deterministic scan/connect/write sweep cursor phases,
    including the existing disconnected-endpoint fallback. Let radial and sweep
    cursors share one bounded work/time budget and continue into later small
    commands while budget remains; acknowledge only complete commands.
  - Accept: no raster slice exceeds the named frame budget in the representative
    workload, small commands can complete more than one per tick, and a large
    command cannot block the process in one eager call.
- [x] **6.3 Prove latency, determinism, order, and authority.**
  - Change: compare completion-barrier and incremental bytes, checksum, target
    count, written/new counts, signal order, disconnected fallback, and
    Red/Green latest-writer behavior. Run the continuous three-producer
    workload and record maximum queue age and post-contact drain behavior.
  - Accept: incremental output is byte/checksum equivalent, every command is
    acknowledged once in canonical order, the representative maximum pending
    age is at most 12 physics ticks, and the queue falls after production stops.
  - Contingency: coalesce only adjacent same-shot/surface/channel sweeps if this
    gate still fails; never cross contact, collider, channel, or command-order
    boundaries.
- [x] **6.4 Record focused latency correction before catalog migration.**
  - Change: run the affected paint/projectile/stage checks and record the old
    failure plus corrected synthetic and real Stage 06 measurements in the itch
    report and a new evidence README. Defer the broad suite, exports, and built-
    Web journey until the all-stage rule inputs are final in Phase 8.
  - Accept: deterministic paint equivalence, queue-age/drain-time guards, and
    the actual six-root/two-Apex workload pass; the report distinguishes the old
    one-command-per-tick cause from the implemented correction without claiming
    a public itch artifact.

### Phase 7: All-stage Red/Green target-band progression

Goal: remove Stage 06 as the active gameplay-rule boundary. Preserve the six
accepted introductory stages, then continue the same latest-writer Red/Green
score puzzle with actual Standard/Impact Burst/Apex Split variety through Stage
30. Existing terrain and mechanisms stay intact.

Locked progression contract:

| Stages | Shots | Allowed/required root kinds | Score pattern and target band |
| --- | ---: | --- | --- |
| 01-06 | existing 4/5/5/6/6/6 | existing teaching profiles | preserve exact current rules and bands |
| 07-15 | 6 | allow all three; require Burst and Apex, Standard remains required | five-pattern cycle below; minimum `7 + floor((n-7)/6)`, maximum `minimum + 4` |
| 16-30 | 7 | same | same formula/cycle |

For Stage 07 onward, the deterministic five-stage cycle is `Both Add`,
`Green Add / Red Subtract`, `Red Add / Green Subtract`, `Green Add / Red
Neutral`, then `Red Add / Green Neutral`, restarting at Stage 12. Every deal
keeps the last two opposite-color Standard balls as a visible correction
reserve. This table is tuning authority for this pass, not a claim of complete
human balance.

Preconditions:

- Phase 6 paint output remains byte/order/ownership equivalent.
- The committed v10 catalog/bundle is the immutable migration source; no file
  inside that bundle is edited in place.

- [x] **7.1 Materialize one target-band contract for every stage.**
  - Change: replace the six-stage-only materializer branch with named,
    deterministic progression helpers for score pattern, target band, shots,
    allowed/required kinds, and default deal seed. Preserve the exact Stage
    01-06 serialized values.
  - Accept: all 30 materialized stages use `TARGET_BAND`, pass
    `has_valid_rule_contract()`, and match the locked table without stage-local
    scripts or copied rule resources.
- [x] **7.2 Make variety a deal invariant, not a possibility.**
  - Change: extend `BallDealProfile` with required kinds and update candidate,
    fallback, validation, diagnostics, and hashing. Stage 07-30 deals require at
    least one Impact Burst and one Apex Split while retaining Standard and both
    paint colors; rejected Fire and split children still consume no token.
  - Accept: at least 16 deterministic seeds for every stage (480 cases) have
    the exact length, permitted/required kinds, both colors, correction reserve,
    and resident-capacity safety; same stage/seed reproduces exact tokens.
- [x] **7.3 Build and atomically promote catalog v11.**
  - Change: increment the serialized generation/catalog contract, build a full
    reviewed thirty-stage bundle from the v10 source, validate every generated
    layout and rule contract, and update only the canonical catalog pointer
    after the new bundle is complete.
  - Accept: the v10 bundle remains byte-unchanged; v11 contains 30 matching
    stage/layout identities and passes manifest, layout, reachability,
    mechanism, resource, and deterministic rebuild checks.
- [x] **7.4 Remove the active legacy-rule presentation split safely.**
  - Change: make Stage Select, Briefing, Aim, Result, HUD, observation, agent,
    retry, timeout, and queue paths present target-band truth for every canonical
    stage. Existing scalar-coverage best records load but are not fabricated
    into Paint Score; they display as no target-band best until replaced.
  - Accept: Stage 07/18/30 expose score band, Red/Green weights, current plus
    next-two queue, actual ball-kind help, Finish/timeout rules, and target-band
    result fields through the same shared owners as Stage 03.
- [x] **7.5 Calibrate representative running stages without overclaiming.**
  - Change: run real Stage 07, 18, and 30 root-fire/paint/result scenarios and
    capture Aim plus Result for each. Check that deals contain both special
    kinds, target bands are readable on the fixed 0-100 scale, paint is live,
    mechanisms still work, and no result path falls back to scalar coverage.
  - Accept: all named journeys run to an authoritative result without error;
    structural checks cover all 30 stages. Record observed playability and any
    remaining balance uncertainty separately from rule correctness.

Phase 7 gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/all_stage_target_band_rule_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/ball_deal_generation_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/cross_stage_ui_theme_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/stage_select_rule_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/target_band_stage_runtime_smoke_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/baked_stage_layout_test.gd
```

### Phase 8: Final audit, production artifacts, and durable closure

Goal: validate the combined UI, paint-latency, and all-stage-rule result once on
final inputs and close the local execution contract without publishing.

- [x] **8.1 Audit the final responsibility boundaries.**
  - Change: use the codebase quality audit on shared UI, paint scheduling,
    stage/deal materialization, catalog, save compatibility, and tests; apply
    only small safe task-owned corrections.
  - Accept: no second paint owner, rule owner, palette, stage-specific UI clone,
    catch-all expansion, silent result conversion, or reachable failure path
    remains.
- [x] **8.2 Run the one broad production gate.**
  - Change: run `scripts/test.ps1`, `scripts/verify.ps1`, fresh Windows and Web
    release exports, and `verify-web-release.ps1` after all source inputs freeze.
  - Accept: all commands pass, artifact hashes are current, and the public itch
    build remains untouched.
- [ ] **8.3 Inspect current Windows and built-Web gameplay.**
  - Change: capture the final named Windows states and use one browser-control
    stack for built-Web Stage 03/07/18/30 real-fire journeys. Inspect paint while
    balls traverse terrain, target-band/queue truth, Result, console, and
    network health; stop the task-owned server afterward.
  - Accept: no seconds-late paint tail, clipped score scale, legacy scalar
    result, missing special kind, relevant console/network error, or stale
    artifact appears.
  - Completed evidence: 22 final Windows release captures were regenerated;
    representative Stage Select, Stage 07/18/30 Aim/Result, English 1920x1080,
    and Korean 640x360 states were inspected without a P0/P1 defect. The final
    Web export and static verifier pass.
  - Remaining evidence: the in-app browser controller could not establish a
    session because its privileged native-pipe bridge was not trusted. No
    second browser stack was used; the final-v11 live Web journey remains open.
- [x] **8.4 Update durable truth and commit coherently.**
  - Change: update the Korean itch report, `.agents/Documentation.md`, design and
    architecture specs, test checklist, evidence, and this plan with measured
    results and explicit balance/publication limits. Commit only task-owned
    changes with explanatory bodies.
  - Accept: documents agree with runtime, task-owned changes are committed, and
    the plan remains `active` only for the explicit 8.3 built-Web journey.
  - Final closure: after 8.3 passes, check every task, set frontmatter to `done`,
    and confirm `git status --short` is clean.

### Phase 9: Player-capture HUD regression correction

Goal: correct the concrete HUD regressions visible in the user's current
running-game captures without changing gameplay rules or creating screen-local
UI owners. This phase supersedes earlier positive visual judgments for the
affected states.

- [x] **9.1 Make Ball Queue one compact shared overlay.**
  - Change: remove the token default white cards and the description panel,
    correct token glyph/letter alignment and spacing, and keep one custom
    hover/focus/press description. Disable the native tooltip while preserving
    full accessibility text.
  - Accept: the current and next-two balls read as one aligned upper-right
    cluster; no white section/card appears; one description is visible at a
    time; keyboard focus and press expose the same information; no native dark
    tooltip duplicates it.
- [x] **9.2 Recompose the shared Aim HUD around the cannon.**
  - Change: move the view-mode action from the isolated left stack into the
    top-right action/status group, make it icon-only with tooltip and accessible
    copy, enlarge the standard vertical 0-100 score scale, remove the redundant
    vertical metric icon, and tighten the bottom angle -> Fire -> power row.
    Hide visual stepper captions while preserving accessible names and use a
    world-readable shared value style.
  - Accept: the left side is owned by the stage identity and a legible fixed
    0-100 scale; all scale endpoints/ticks and the target band remain inside the
    track; bottom controls form one compact sequence with no floating labels;
    no required action, state, or keyboard/accessibility path is removed.
- [x] **9.3 Prove the correction on current production pixels.**
  - Change: update focused component/layout tests, run the shared-UI and full
    project gates once final inputs freeze, create fresh Windows and Web release
    artifacts, and capture queue-hover plus standard/compact Aim states from
    the production-style Windows build. Inspect the actual images, then run the
    codebase-quality audit and make only small safe task-owned corrections.
  - Accept: automated checks pass; current captures show no duplicate ball
    message, white queue panel, clipped/undersized standard scale, isolated
    left mode switch, or loose bottom-control composition. The public itch
    release remains untouched, and the separate live built-Web journey in 8.3
    stays open unless a trusted browser bridge becomes available.

### Phase 10: Signed Paint Score truth on the fixed 0-100 scale

Goal: make live and terminal score presentation agree with the authoritative
signed Paint Score without changing the user-approved complete 0-100 rail,
stage rules, target bands, paint ownership, or result decisions.

Preconditions:

- Phase 9 shared score composition and current production captures remain the
  visual baseline for placement, size, hierarchy, and shared ownership.
- `StageController.score_snapshot()` and `StageScoreSnapshot` remain the sole
  supplied score/result truth; UI code must not reproduce the score formula.

Source owners: `src/ui/components/score_scale.gd`,
`scenes/ui/components/score_scale.tscn`, `src/ui/hud/result_panel.gd`,
`src/ui/components/result_summary.gd`, `src/ui/hud_controller.gd`,
`translations/ui.csv`, `tests/score_scale_contract_test.gd`,
`tests/target_band_result_test.gd`, `tests/hud_target_band_truth_test.gd`,
`src/delivery/delivery_capture_runner.gd`

- [x] **10.1 Separate authoritative value from bounded marker geometry.**
  - Change: let shared `ScoreScale` retain and format the supplied signed score;
    clamp only the marker projection to the fixed 0-100 rail. Draw a compact
    orientation-aware underflow shape at the zero endpoint for negative values,
    preserve all five tick labels, normalize formatted negative zero, and make
    tooltip/accessibility copy report the real signed value and below-zero state.
    Coverage presentation keeps its percent format and the same fixed-domain
    geometry.
  - Accept: the shared component reports `-10.0` as its value and visible copy,
    keeps its marker inside the zero endpoint, exposes a non-color underflow
    state in both presets, maps `100` to the opposite endpoint, and keeps target
    geometry and all tick labels bounded.
  - Guard: do not add a second signed scale, expand the visual domain below
    zero, move score calculation into UI, or change stage clear/star rules.
- [x] **10.2 Preserve signed truth through Result.**
  - Change: remove target-score clamping from `ResultPanel`; pass the supplied
    score unchanged through `ResultSummary` and its shared horizontal
    `ScoreScale`. Keep coverage-only result clamping because coverage is defined
    on 0-100. Preserve verdict, actions, stars, timing, and R/G contribution
    behavior.
  - Accept: a failed target-band result with score `-3.0` visibly and
    accessibly reports `-3.0`; its marker stays at the zero endpoint with the
    underflow shape; the controller's failure result and all result actions are
    unchanged.
- [x] **10.3 Replace the false regression contract and prove production pixels.**
  - Change: update focused score/HUD/result tests so Stage 08's
    `Green Add / Red Subtract` example preserves a negative score while marker
    geometry remains bounded. Add delivery-only negative live/result capture
    states, generate Korean 1280x720 and compact 640x360 Windows-release
    captures, inspect them at native size, and record the evidence plus the clarified shared-component
    contract in the UI spec, implemented-truth record, and test checklist.
  - Accept: focused tests prove formula -> HUD -> Result signed-value continuity;
    current production captures show a readable negative numeric score, complete
    0-100 rail, explicit underflow shape, intact target band, no clipping, and
    no new panel/card/text block.

Phase 10 gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/color_score_rule_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/score_scale_contract_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/target_band_result_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_target_band_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_hud_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/target_band_layout_test.gd
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

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
| Signed Paint Score lies outside the visual rail | preserve the signed numeric/accessibility value, project only the marker to the nearest endpoint, and show the shared orientation-aware overflow shape | never clamp the authoritative value, extend the approved rail, or change result truth |
| Queue description clips or is hover-only | fix shared safe-edge placement and focus/press path | never add screen-local tooltip geometry |
| Stage Select terrain is stale/blank/wrong | retain the previous valid artifact until the newest selected one is ready, then swap atomically | never create generic art, a second renderer, or early GameState commit |
| A stress size cannot fit Priority 3 copy | shorten/wrap/suppress duplicated hints | never hide score endpoints, angle, power, Fire, queue truth, or legal actions |
| Theme variation harms another screen | narrow the semantic variation and migrate intended users | never create another Theme/palette owner |
| `HUDController` grows layout-only branches | move presentation behavior into a component/layout owner | never move StageController/PaintSystem rules into UI |
| Existing visual test encodes a superseded panel/card | update only the visual assertion and preserve behavior/state guards | never delete/weaken a test to pass |
| A Stage 07-30 deal lacks actual kind variety | reject/regenerate it through the shared profile invariant and deterministic fallback | never patch one seed or stage resource by hand |
| A migrated target band is structurally valid but a representative journey exposes poor balance | record the exact stage/deal/result and adjust the shared progression tier in a reviewed batch | never claim all-stage human clearability from seed structure or silently special-case one stage |
| v11 catalog generation fails | leave the v10 pointer/bundle active, fix the shared materializer/validator, and rebuild from scratch | never partially promote or edit generated bundle files in place |
| Public itch proof is requested | stop, present final local artifact/hash/evidence, and obtain explicit authorization | no workflow dispatch, upload, channel/visibility mutation, or public claim without approval |
| Canonical Windows export path is locked by an ambiguous running game instance | do not terminate it; export the same preset to a task-named check executable and run final captures from that artifact | canonical replacement waits until the external instance closes; never kill a process without positive task ownership |

Implementation-local mechanics may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: task checkboxes in this contract.
- Current phase: Phase 8.3 built-Web closure; Phase 10 signed-score correction
  is complete.
- Next task: complete the remaining 8.3 built-Web journey when the trusted
  browser bridge is available, then close the plan frontmatter.
- Last completed gate: the old three-command-per-tick reproduction reached a
  33-tick pending age. The corrected fixed workload reaches at most 1 tick and
  completes up to three commands per drain. The real Stage 06 six-root/two-Apex
  workload processes 57 commands with at most 4 ticks pending, four commands
  per drain, and a 14.818 ms maximum drain. Deterministic bytes/checksum,
  command order, ownership, disconnected fallback, projectile contact, Burst,
  Apex, and score-rule checks pass.
- Phase 7 discovery: the existing Stage 26-30 mechanism loadouts may contain a
  three-child Splitter. Eight retained roots would require 24 residents and
  violate the fixed 21-body safety cap, so the late tier remains seven shots
  (maximum 21) rather than expanding the cap or deleting existing mechanisms.
- Last completed Phase 7 gate: catalog v11 manifest `29c58dab…694e` validates;
  all 30 target-band profiles and 480 deterministic deals pass. The immutable
  v10/v11 migration comparison preserves terrain, target mask, routes,
  mechanisms, decorations, and witnesses. Stage 07/18/30 execute real root
  fire, authoritative target paint, and Result; six production-render captures
  show the shared 0-100 scale and varied queue. Human balance remains unclaimed.
- Phase 8.1 audit: `StageCatalogMaterializer` remains the single rule-data
  transformer; `BallDealProfile/Generator` alone own kind requirements;
  `StageController`, `PaintSystem`, and the shared UI retain their prior narrow
  authorities. v10 is unchanged, v11 is content-addressed, scalar save records
  are preserved without conversion, obsolete stage-rule tests were replaced,
  and `git diff --check` reports no patch defect.
- Phase 8.2 gate: the complete ordered suite and `scripts/verify.ps1` pass.
  Fresh Windows and single-thread Web releases export; Web static verification
  reports 12 files, 8 exact-case references, 51,809,060 raw bytes, and
  18,485,180 gzip bytes below the 18,996,696-byte allowance. The Windows
  executable is 121,978,464 bytes with SHA-256 `B0C2F5CE…9053F`.
- Phase 8.3 partial gate: 22 current Windows captures pass and representative
  later-stage/compact renders were inspected. The final built-Web live journey
  is pending only because the available browser bridge is not trusted; this is
  not converted into a passing browser claim.
- Phase 9.1-9.2 checkpoint: six focused shared-UI tests and six adjacent HUD
  regressions pass. Fresh Windows release captures for Stage 08 Aim, queue
  detail, Map, and 640x360 Aim show one direct queue description, no queue
  cards, a tall fixed 0-100 rail, one top-right mode action, and a compact
  caption-free angle -> Fire -> power composition. The diff-scoped quality
  audit found no competing UI or rule owner; its two local cleanup corrections
  removed obsolete responsive APIs and tied toggle state to camera truth.
- Phase 9.3 gate: the complete ordered suite, `scripts/verify.ps1`, fresh
  Windows/Web releases, and Web static validation pass. Four final Windows
  release captures were inspected at original resolution and close every
  player-reported HUD regression. Windows SHA-256 is `585C0E33…57FEE`; Web is
  12 files and 18,485,674 gzip bytes. Public itch remains untouched, and the
  unrelated 8.3 live built-Web journey remains open.
- Phase 10 discovery: the score rule and `StageController` preserve negative
  Paint Score correctly, but the shared live scale and Result clamp the visible
  value to zero. The fixed 0-100 rail is retained; only marker geometry is
  bounded, while numeric and accessibility truth remain signed.
- Phase 10.1-10.2 checkpoint: `ScoreScale` now keeps the supplied signed value,
  clamps only marker geometry, formats negative zero safely, and draws
  orientation-aware endpoint triangles outside the 0-100 domain. Result no
  longer clamps target-band score. Formula, scale, score snapshot, HUD, and
  Result focused tests pass with the Stage 08-style `-3.0` case.
- Phase 10.3 render gate: the first release capture exposed a second legacy
  total-coverage publication that overwrote the live signed value after R/G
  contributions updated. `HUDController` now ignores that presentation update
  on target-band stages, and the focused shot-feedback guard passes. Three
  regenerated Korean Windows-release captures show `-3.0`, complete 0-100
  rails, endpoint triangles, target bands, R/G contributions, and bounded Aim/
  Result layouts at 1280x720 and 640x360. Evidence is under
  `../evidence/2026-08-20-signed-score-correction/README.md`.
- Phase 10 final gate: the complete ordered test suite, `scripts/verify.ps1`,
  and the final canonical Windows export pass. The final executable is
  121,982,464 bytes with SHA-256 `A5E414B0…673CB5C`. The diff-scoped quality
  audit found no rule duplication, competing score owner, catch-all expansion,
  or untested reachable score/result path. A temporary canonical-path lock was
  handled without terminating the ambiguous running game; the process exited
  naturally, and the canonical export then completed successfully.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and every named phase/final gate passes.
- Current production renders prove the named states, both stage families,
  locales, and responsive sizes.
- Durable design/implementation/test truth agrees with the final runtime.
- Continuous Standard and Apex-family paint stays within the Phase 6 queue-age
  contract without changing final paint bytes, coverage, or ownership.
- All 30 canonical stages use the shared target-band/queue rule; Stages 07-30
  contain actual Standard/Impact Burst/Apex Split deal variety and preserve
  existing terrain/mechanism behavior.
- The v11 catalog is atomically promoted from the immutable v10 source, and old
  scalar-coverage best records are not presented as target-band scores.
- No placeholder, unresolved material decision, or task-owned dirty file
  remains, and frontmatter is `done`.

Replan when:

- A verified material discovery invalidates Cannon Focus hierarchy, shared
  component ownership, the all-stage target-band progression, Stage Select
  artifact path, catalog migration, dependency boundary, or validation path.

Do not replan or stop for:

- Container details, semantic variation names, or concise copy adjustments
  that remain inside the locked contract.
- A passing check whose relevant inputs have not changed.
