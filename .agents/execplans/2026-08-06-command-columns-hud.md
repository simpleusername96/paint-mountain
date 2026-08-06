---
type: plan
status: done
created: 2026-08-06
scope: shared Godot UI theme/component consolidation and Command Columns aiming HUD implementation
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../../docs/concepts/ui-layout-directions-2026-08-06/README.md
  - ../../docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png
  - ../../docs/test-checklist.md
  - 2026-08-06-aim-view-and-coverage-opportunity.md
---

# Command Columns HUD and Shared UI System - Execution Contract

Paint Mountain will replace the current Aim Lock HUD composition with the
user-selected `command-columns-hud.png` direction while preserving every real
gameplay action and state owner. Shared Theme type variations and reusable Godot
component scenes will own visual styling; HUD scenes will own composition; HUD
scripts will continue to display authoritative state and emit typed intent.

## Purpose

- Objective: make the aiming HUD simple, modern, visually quiet, and consistent
  by implementing the selected narrow command-column composition through one
  shared design system instead of per-scene colors, fonts, and control styles.
- Deliverable: semantic font/color/control variations in
  `resources/ui/paint_mountain_theme.tres`, a reusable metric component, a
  component-composed Aim Lock HUD, updated focused contracts and documentation,
  same-viewport reference comparison, and one final production-style build.
- Completion state: the 1280x720 Korean Aim Lock render follows the selected
  left-command/right-status composition; the HUD preserves Gear, Aim Lock/Map
  Inspection, yaw/elevation/power, power steps, Fire, coverage, time, shots,
  resident activity, wind, and Finish; scene-local HUD color/font/icon-state
  overrides are replaced by shared Theme variations; focused behavior checks,
  final repository verification, exported start, and visual comparison pass.

## Scope and Boundaries

In scope:

- The aiming HUD composition in `scenes/ui/hud/hud.tscn` and its existing
  component scenes/scripts.
- Shared semantic Theme type variations for typography, panels, buttons, icon
  buttons, separators, progress, and visible interaction states.
- Pretendard Variable weights implemented through Godot `FontVariation`
  resources owned by the shared Theme.
- One reusable label/value metric component used by the right status rail.
- Focused HUD/layout tests whose existing node paths or visual contracts change.
- The selected-reference register, UI specification, implemented-truth record,
  final checklist, and task-owned visual evidence.

Out of scope:

- The archived Aim View camera work, coverage-opportunity budgeting, target
  curves, stage generation, target-wide first-hit certification, all-stage
  success routes, or gameplay/balance approval.
- Terrain, camera, cannon, trajectory, projectile, paint, mechanism, stage-state,
  save, replay, or wind simulation changes.
- A menu, stage-select, pause, settings, result, or world-art redesign. These
  surfaces may receive inherited shared button typography only when the global
  Theme already owns it; their layouts remain unchanged.
- New dependencies, plugins, external asset packs, generated production art, or
  replacement icons. Existing approved icon assets and the current text-backed
  dynamic wind direction remain in use.
- Pixel-tolerance matrices, exhaustive resolution matrices, or repeated broad
  QA after each component edit.

Constraints and invariants:

- `StageController` remains the sole stage-state, shot, and outcome owner;
  `PaintSystem` remains the sole coverage owner; `HUDController` only coordinates
  presentation and typed intent.
- The selected image is the visual authority for HUD hierarchy, proportions,
  surface treatment, and typography rhythm. It is not runtime evidence and does
  not override real supported functions that the generated image omitted.
- Gear remains a separate, focusable upper-right action adjacent to the status
  rail. Direction and the existing power-step actions remain in the lower-left
  aim component. Their omission from the generated still is not authorization
  to remove functionality.
- Fire remains the sole primary aiming action and Restart remains absent from the
  aiming HUD. Map Inspection hides aim-only controls without hiding the mode
  switch, coverage, stage identity, or Gear.
- Theme variations own reusable font, weight, size, palette, radius, border,
  focus, disabled, hover, pressed, and icon-tint decisions. HUD scenes may retain
  layout-only margins, separation, anchors, and geometry overrides.
- No StyleBox or palette constant is constructed in a HUD script.
- The logical baseline stays 1280x720 with container/anchor behavior for the
  supported 16:9 desktop sizes. The center world view and launch path remain
  unobstructed.

Destructive or irreversible actions:

- None. The ignored local Windows export can be rebuilt from source.

Exact actions requiring owner or user approval:

- Any new dependency, external asset, removed gameplay action, camera change,
  or redesign beyond the aiming HUD requires a contract revision and explicit
  user approval.

## Locked Design and Component Contract

Visual target:

- `docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png`
  at 1280x720, SHA-256
  `1B4AF8DDFF91D5A23238296EC3C886F17CA18E2FC00F2FA93811B50EEEEDCA0F`.
- Left column: joined stage/mode command card at upper-left, vertical absolute
  coverage below it, and a compact aim/power group at lower-left.
- Center: one restrained bottom-center Fire button; no persistent center card or
  helper strip.
- Right column: one narrow segmented run-status rail for time, shots, resident
  activity, wind, countdown/forecast, and Finish. Gear stays beside its upper
  edge because it is a required real action.

Semantic typography at the 1280x720 logical baseline:

| Theme variation | Size | Pretendard weight | Use |
| --- | ---: | ---: | --- |
| `HudCaption` | 14 | 500 | secondary labels and short support text |
| `HudBody` | 16 | 500 | ordinary HUD text and compact controls |
| `HudSection` | 18 | 600 | stage identity and section emphasis |
| `HudValue` | 22 | 600 | status and coverage values |
| `HudMetric` | 28 | 600 | aim and power values |
| `PrimaryButton` | 20 | 600 | Fire and other established primary actions |
| `ScreenTitle` | 32 | 700 | existing full-screen title role when used |

Component ownership:

| Concern | Owner | Contract |
| --- | --- | --- |
| Global tokens and states | `resources/ui/paint_mountain_theme.tres` | Own shared font variations, semantic label/button/panel types, palette, radii, focus, progress, and icon states |
| Repeated label/value block | `scenes/ui/components/hud_metric.tscn`, `src/ui/components/hud_metric.gd` | Display supplied caption/value only; no gameplay state or timer |
| Stage and Gear | `scenes/ui/hud/top_status_bar.tscn`, `src/ui/hud/top_status_bar.gd` | Display stage identity and emit Settings intent |
| Interaction mode | `scenes/ui/hud/camera_interaction_control.tscn`, its script | Display current mode and emit the other-mode request |
| Coverage | `scenes/ui/hud/coverage_meter.tscn`, its script | Display authoritative absolute coverage and target |
| Aim and power | `scenes/ui/hud/aim_controls.tscn`, its script | Display yaw/elevation/power and emit power-step intent |
| Primary action | `scenes/ui/hud/action_buttons.tscn`, its script | Display Fire readiness and emit Fire intent |
| Run status | `scenes/ui/hud/run_status_card.tscn`, its script | Compose shared metrics, display authoritative wind/activity/Finish state, and emit Finish intent |
| Whole layout/state visibility | `scenes/ui/hud/hud.tscn`, `src/ui/hud_controller.gd` | Arrange components and apply state visibility without calculating gameplay values |

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| A project Theme exists but the HUD repeats presentation values | `project.godot` globally loads `paint_mountain_theme.tres`; affected UI scenes contain many `theme_override_colors` and `theme_override_font_sizes` entries | `project.godot:29`; `resources/ui/paint_mountain_theme.tres`; `scenes/ui/hud/*.tscn` | Extend the existing Theme with semantic variations; do not create a second token store | 1.1, 2.1-2.3 |
| Font family is shared but weight roles are absent | The Theme loads `PretendardVariable.woff2` and defines sizes, but no `FontVariation` or weight-specific type exists | `resources/ui/paint_mountain_theme.tres`; Godot 4.7.1 runtime availability verified | Use Theme-owned `FontVariation` resources at weights 500, 600, and 700, with the locked type scale | 1.1 |
| Repeated right-rail metrics are handwritten | Time, shots, and activity are separate label/value node pairs in `run_status_card.tscn` | `scenes/ui/hud/run_status_card.tscn` | Introduce one presentational `HudMetric` component and instance it three times | 1.2, 2.3 |
| Selected visual target is resolved | The user selected the attached `command-columns-hud.png`; the file is a 1280x720 generated concept grounded in current Stage 30 | selected file and `docs/concepts/ui-layout-directions-2026-08-06/README.md` | Treat its layout/surface/type rhythm as binding while preserving supported real controls | 2.1-2.3, 3.1 |
| Current HUD already has correct gameplay ownership | `HUDController` delegates state display to component scripts and emits typed intents; tests protect sole Fire, coverage ownership, interaction mode, wind, and Finish | `src/ui/hud_controller.gd`; `tests/phase7_ui_test.gd`; `tests/phase8_hud_truth_test.gd`; `tests/wind_result_hud_test.gd`; `tests/shot_feedback_test.gd` | Preserve script interfaces and authoritative data paths; change presentation and only the tests whose layout/component paths change | 2.1-2.4 |
| The image omits or simplifies required controls | Current product contracts require Gear, visible interaction mode, yaw/elevation/power, power steps, dynamic wind text, and focus behavior | `.agents/design/UIUX_GUIDELINES.md`; running screenshot `.agents/evidence/ui-quality-audit-2026-08-06/05-aiming.png` | Keep these functions and integrate them unobtrusively into the selected composition | 2.1-2.4 |
| Validation can become repetitive | Repository policy requires `scripts/verify.ps1` after scenes/scripts and final rendered/export evidence, while the user explicitly rejected frequent small QA loops | `AGENTS.md`; `scripts/verify.ps1`; current request | Run parser/import once per implementation batch, four focused HUD scripts once after integration, then one final verify/export/render comparison; rerun only after relevant fixes | 1.3, 2.5, 3.1-3.3 |
| Worktree contains unrelated gameplay changes and evidence | Current `git status --short` lists modified generation/trajectory/tests and untracked gameplay evidence/bundles | repository worktree on 2026-08-06 | Touch, stage, and commit only plan/design/HUD/theme/test/doc/evidence files owned by this contract | all |

Readiness statement:

- Every material product, architecture, dependency, UX, ownership, safety, and
  validation decision is closed.
- Godot `4.7.1.stable.official.a13da4feb` is available at the documented local
  runtime path; no bootstrap or dependency installation is required.
- Remaining unknowns are implementation-local layout mechanics and cannot
  change this contract.

## Tasks

### Phase 1: Shared UI foundation

Goal: make typography and recurring HUD presentation reusable before composing
the selected layout.

Preconditions:

- This contract and the selected-reference/spec updates are committed.
- Unrelated dirty worktree files remain untouched.

Source owners: `resources/ui/paint_mountain_theme.tres`,
`scenes/ui/components/hud_metric.tscn`, `src/ui/components/hud_metric.gd`,
`tests/phase7_ui_test.gd`

- [x] **1.1** Theme-owned semantic typography and control styles
  - Change: add the locked Pretendard weight resources and semantic Theme type
    variations for HUD labels, values, panels, segmented surfaces, icon buttons,
    separators, and primary actions. Preserve the existing global theme path and
    palette.
  - Accept: the Theme loads in Godot 4.7.1, each named type is a valid variation
    of its base control, and affected HUD scenes need no local color/font/icon
    state styling.
  - Guard: base Button/Panel behavior and the existing DebugPanel remain valid.
  - Evidence (2026-08-06): Godot 4.7.1 loaded the Theme; the focused Theme
    contract verified semantic Label/Button variations and 500/600/700 weights.
- [x] **1.2** Reusable metric component
  - Change: add one typed, presentational `HudMetric` component with caption and
    value setters plus theme variations; it must not translate arbitrary runtime
    values, own a timer, or read gameplay singletons.
  - Accept: three instances can carry independent captions/values and expose no
    gameplay mutation signal.
  - Evidence (2026-08-06): `HudMetric` is presentational only; the status tests
    updated and read independent Time, Shots, and Activity instances.
- [x] **1.3** Foundation parse/import checkpoint
  - Change: run one Godot editor import/parse check after 1.1 and 1.2 are merged.
  - Accept: the command exits zero with no `SCRIPT ERROR` or `ERROR:` line.
  - Evidence (2026-08-06): the editor import/parse command exited 0 and
    registered `HudMetric`, `CameraInteractionControl`, `CoverageMeter`, and
    `RunStatusCard` without script/runtime errors.

Phase gate:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
& $paintMountainGodot --headless --path . --editor --quit
```

### Phase 2: Component-composed Command Columns HUD

Goal: reproduce the selected hierarchy while preserving the complete real input
and state contract.

Preconditions:

- Phase 1 tasks and phase gate pass.

Source owners: `scenes/ui/hud/*.tscn`, `src/ui/hud/*.gd`,
`src/ui/hud_controller.gd`, focused HUD tests

- [x] **2.1** Upper-left command and coverage column
  - Change: restyle and arrange Stage, interaction mode, and absolute vertical
    coverage as one narrow upper-left command column. Use the existing target
    icon for the mode control and Theme-owned component variations.
  - Accept: Stage and mode read as one coherent command group; the mode remains
    focusable and Tab-switchable; coverage remains the sole current/target owner
    and fills bottom-to-top.
  - Evidence (2026-08-06): the 1280x720 Stage 30 capture shows the joined Stage
    and Aim Lock command card, target-icon mode action, and absolute 0-100
    bottom-to-top coverage rail with the configured 15% target marker.
- [x] **2.2** Compact lower-left aim and centered Fire
  - Change: arrange direction, elevation, power, and existing power steps in the
    compact lower-left group; resize the one Fire action to the selected
    restrained bottom-center proportion; remove the persistent first-session
    center helper strip from the launch path by keeping its existing bounded
    left-rail presentation.
  - Accept: aim values and both power actions remain readable and operable; Fire
    is the only aiming primary action and its readiness state remains truthful;
    no component intersects the cannon/trajectory area at 1280x720.
  - Evidence (2026-08-06): direction, elevation, power, both step actions, and
    the sole Fire action are readable in the final Aim Lock capture; the bounded
    first-session hint stays on the left rail and the world center stays open.
- [x] **2.3** Segmented right status rail using `HudMetric`
  - Change: replace handwritten time/shots/activity pairs with shared metric
    instances and compose wind, countdown/forecast, and Finish into the selected
    narrow segmented rail. Keep the focusable Gear adjacent to its top edge.
  - Accept: authoritative clock, shots, resident breakdown, wind direction and
    strength, forecast, Finish gating, shortcut, tooltip, and Settings intent all
    update through their existing public interfaces.
  - Evidence (2026-08-06): the right rail renders independent `HudMetric`
    instances for Time, Shots, and Activity, plus text-backed wind, forecast,
    disabled Finish, and the adjacent Gear action without clipping.
- [x] **2.4** State, locale, and focus integration
  - Change: update component paths and focused tests only where the new scene
    composition requires it; preserve Aim Lock/Map Inspection visibility,
    Korean/English refresh, replay exclusion, pause flow, and result replacement.
  - Accept: existing component signals reach `HUDController`; Korean and English
    labels fit; focus order follows Stage/mode, Gear/status Finish, aim steps, and
    Fire without an invisible focus target.
  - Evidence (2026-08-06): focused UI flow, HUD truth, wind/result, and shot
    feedback contracts passed with the component interfaces and shared styles.
- [x] **2.5** One focused integration checkpoint
  - Change: after 2.1-2.4 are merged, run the four existing HUD behavior/layout
    scripts once as a batch. Do not run them after individual spacing edits.
  - Accept: all four commands exit zero without script/runtime errors.
  - Evidence (2026-08-06): all four declared commands exited 0 in one batch;
    no broad suite or per-spacing checks were run.

Phase gate:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
@(
  'res://tests/phase7_ui_test.gd',
  'res://tests/phase8_hud_truth_test.gd',
  'res://tests/wind_result_hud_test.gd',
  'res://tests/shot_feedback_test.gd'
) | ForEach-Object {
  & $paintMountainGodot --headless --path . --script $_
  if ($LASTEXITCODE -ne 0) { throw "HUD integration check failed: $_" }
}
```

### Phase 3: Render comparison, final verification, and closeout

Goal: prove the integrated HUD in the actual Godot renderer once the code is
stable, then record current truth.

Preconditions:

- Phase 2 acceptance and phase gate pass.

Source owners: runtime HUD, `design-qa.md`, task evidence,
`.agents/Documentation.md`, `docs/test-checklist.md`, this contract

- [x] **3.1** Same-state rendered design comparison
  - Change: create one 1280x720 Korean Stage 30 Aim Lock capture using the
    task-owned background path, compare it beside the selected reference, and
    write `design-qa.md`. Inspect alignment, typography, font weight, radii,
    clipping, world obstruction, focus/disabled treatment, and retained
    functions. Capture Map Inspection and one inherited app surface only for the
    named cross-surface/state regressions.
  - Accept: the comparison records `final result: passed`; all P0/P1/P2 findings
    are fixed; any remaining P3 is recorded without repeated polish loops.
  - Guard: source and implementation captures use the same 1280x720 viewport and
    Aim Lock state.
  - Evidence (2026-08-06): `design-qa.md` records the source and final runtime
    capture at the same 1280x720 Korean Stage 30 Aim Lock state, no P0/P1/P2
    finding, and `final result: passed`; the named Map Inspection and main-menu
    regression captures are stored beside it.
- [x] **3.2** One final repository and production gate
  - Change: run `scripts/verify.ps1` once, export the Windows release once, and
    start the exported executable through the production entry path. Rerun only
    if a relevant source or export input changes.
  - Accept: verify, export, and exported start exit cleanly without Godot script
    or runtime errors.
  - Evidence (2026-08-06): the strengthened shot-feedback contract,
    `scripts/verify.ps1`, Windows release export, exported hidden start, and
    exported Stage 30 background capture all exited 0 without Godot script or
    runtime errors. The executable is `builds/windows/PaintMountain.exe` and the
    final image is under the task evidence directory; ignored local start and
    capture logs were reviewed separately.
- [x] **3.3** Quality audit and truthful documentation
  - Change: run `$codebase-quality-auditor` once across the integrated multi-file
    change; make only small task-scoped corrections; update implemented truth,
    checklist evidence, this progress pointer, and plan status.
  - Accept: no competing style owner, catch-all HUD responsibility, duplicated
    gameplay calculation, or stale completion claim remains; the plan is `done`
    only after every named gate passes.
  - Evidence (2026-08-06): the diff-scoped quality audit moved the last
    briefing font/color overrides to shared semantic Theme roles, found no stale
    metric consumer or script-constructed style, and confirmed that `HudMetric`
    remains presentational. `.agents/Documentation.md`, `docs/test-checklist.md`,
    and `design-qa.md` now record the final implementation and release evidence.

Final gate:

```powershell
$paintMountainGodot = 'D:\npjt\cardborne-platformer\.codex-runtime\godot-4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe'
& .\scripts\verify.ps1 -GodotPath $paintMountainGodot
& $paintMountainGodot --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
if ($LASTEXITCODE -ne 0) { throw 'Windows release export failed.' }
$paintMountainExport = (Resolve-Path -LiteralPath '.\builds\windows\PaintMountain.exe').Path
$start = Start-Process -FilePath $paintMountainExport -ArgumentList @('--headless', '--quit-after', '3') -WindowStyle Hidden -Wait -PassThru
if ($start.ExitCode -ne 0) { throw "Exported start failed: $($start.ExitCode)" }
```

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Foundation gate | Godot editor import/parse command in Phase 1 | Theme and reusable component are merged | A parsed/imported foundation file changes |
| Integration gate | Four focused HUD scripts in Phase 2 | All HUD components and wiring are integrated | A tested HUD behavior or path changes |
| Visual gate | Same-state reference/capture comparison plus only the two named regression views | Integrated render is stable | A visible HUD/theme/layout input changes |
| Final gate | `scripts/verify.ps1`, release export, hidden exported start | All implementation, focused checks, and visual QA pass | A final-gate input changes |

Validation rules:

- Run the narrowest code/error check that proves the current implementation
  batch. Do not create a test for each spacing, font-size, or panel adjustment.
- Run each named gate once at its declared checkpoint.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Record a known non-blocking warning once instead of rediscovering it.
- On start or resume, read this contract and inspect the worktree only enough to
  confirm checkpoint inputs, then continue from the first unchecked task whose
  prerequisites are satisfied.
- Treat checked tasks and recorded passing evidence as complete unless a
  relevant input changed or the evidence is missing.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | Do not let an executor choose a new product, architecture, dependency, UX, safety, or validation contract |
| Theme type or `FontVariation` syntax fails under Godot 4.7.1 | Correct serialization using the same Theme/FontVariation design and rerun only the Phase 1 gate | Do not replace Pretendard, add a dependency, or return to scene-local font styling |
| The narrow reference rail clips real Korean/English state | Widen only the affected edge component or allow intentional wrapping while preserving the command-column hierarchy | Do not shrink essential text below the locked type scale or remove state |
| A required current node path is externally consumed | Preserve a compatibility path or update the focused in-repo consumer in the same task | Do not introduce a parallel old/new HUD tree |
| The selected image conflicts with a real product action | Preserve the real action and integrate it using the locked unobtrusive exception | Removing or changing the action requires user approval |
| An unrelated dirty hunk overlaps a task-owned file | Stop that file branch and report the exact overlap | Do not stage, revert, or rewrite the user's hunk |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress

- Canonical progress: the task checkboxes in this contract.
- Current phase: Complete.
- Next task: none inside this contract; further visible tuning requires user
  review of the exported capture.
- Last completed gate: Phase 3 final repository/export and quality closeout.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Next Steps

No implementation task remains. Preserve this record as the completed contract
for the shared Command Columns HUD and use the exported capture for any later
user-directed polish request.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every named phase/final gate passes at its declared cadence.
- `design-qa.md` says `final result: passed` against the selected 1280x720 Aim
  Lock reference.
- Implemented truth and final checklist name the exact build and capture
  evidence.
- Frontmatter status changes to `done` only after implementation completion.

Replan when:

- A material discovery invalidates the locked visual, ownership, dependency,
  functionality, or validation contract.

Do not replan or stop for:

- Implementation-local layout mechanics inside the locked component boundaries.
- A passing check whose relevant inputs have not changed.
- Unrelated dirty worktree files outside this contract.
