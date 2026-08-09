---
type: plan
status: active
created: 2026-08-09
scope: Faithfully implement the user-approved Quiet Context UI across every reachable Paint Mountain interface surface
related:
  - ../../docs/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../Documentation.md
  - ../../design-qa.md
---

# Quiet Context UI System - Execution Contract

Paint Mountain will adopt the user-approved `revised-02-context-line.png`
direction as one responsive interface system across Main Menu, Stage Select,
Briefing, Aim View, Map View, Shot Follow, Pause, Settings, and Result. The
implementation will preserve every real action and authoritative gameplay value,
while replacing heavy cards, nested borders, detached dark keycaps, and the
obsolete target-derived yaw readout with direct typography, compact instruments,
hairline separators, one quiet contextual input legend, and filled surfaces only
where interaction hierarchy requires them.

## Purpose

- Objective: make every reachable page feel like the same calm, paper-white,
  edge-aware game interface shown in the approved 1280x720 Aim View reference.
- Deliverable: a shared Theme and component implementation, page-by-page scene
  revisions, updated localization and contracts, current design records, and
  inspected production-build captures.
- Completion state: every task below is checked, the focused UI contracts and
  repository verification pass, the Windows release export starts, required
  Korean and English captures pass Level 4 UI/UX and same-state design QA, and
  this plan is marked `done`.

## Scope and Boundaries

In scope:

- Shared UI tokens, button/panel/progress/focus styles, spacing, typography,
  dividers, shortcut treatment, and responsive containers.
- Main Menu, Stage Select, Briefing, Aim View, Map View, Shot Follow, Pause,
  Settings, shot/mechanism feedback, and manual/timeout Result presentation.
- The exact selected Aim View hierarchy: direct edge status, `remaining /
  maximum` ammunition, separate resident count, wind, Finish, Gear, left
  coverage rail, centered Fire, right-side angle/power steppers, and one bottom
  context legend.
- Korean-first and English responsive fit, focus, hover, pressed, selected,
  disabled, loading, failure, paused, and terminal states reachable through the
  existing product flow.
- Focused UI tests, current design records, production export, captures, and
  source-versus-build design QA.

Out of scope:

- Terrain, camera pose, glyph placement, cannon, paint, physics, stage balance,
  progression, persistence format, audio, or gameplay rule changes.
- New screens, settings, actions, routes, dependencies, plugins, icon packs,
  fonts, or network assets.
- Pixel-copying generated terrain pixels, fabricated values, or removing real
  actions omitted by the generated image. Gear, Finish, Map View, Shot Follow,
  disabled/loading states, and keyboard focus remain functional.
- Mobile-specific layouts; supported output remains Windows desktop with a
  1280x720 logical baseline and the existing responsive stretch contract.

Constraints and invariants:

- `StageController`, `PaintSystem`, `CameraDirector`, `GameState`, and existing
  input owners remain the only rule/state authorities. UI displays supplied
  values and emits narrow intent only.
- `resources/ui/paint_mountain_theme.tres` remains the shared visual token owner;
  reusable styles are not duplicated in screen scripts.
- Repeated input guidance is owned by one shared context-legend component. It
  is visually one sentence-like line with inline input/action pairs, not a row
  of detached dark keycaps or explanatory prose.
- Aim View must not show `↔`, yaw, `A`, `D`, or a horizontal-direction degree.
  Target-derived yaw remains internal gameplay state and may still be supplied
  to `HUDController.update_aim` for API compatibility.
- Use only existing approved Pretendard, Kenney UI, and local icon assets. The
  generated mock is visual evidence, not a production texture.
- Controls remain at least 40 px high where routine interaction requires it;
  icon-only controls keep tooltips/accessibility names and visible focus.
- The mountain and live cause-and-effect chain remain the dominant gameplay
  layer. No persistent panel covers the central routes or impact marker.

Destructive or irreversible actions:

- None. Obsolete scene children and test assertions may be deleted only after
  their replacement component or contract is in place.

Exact actions requiring owner or user approval:

- Adding a dependency, plugin, font, asset pack, new setting, or gameplay
  behavior is not authorized and requires a new user decision.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Selected visual authority | The user selected `docs/concepts/full-ui-refresh-2026-08-09/revised-02-context-line.png`, SHA-256 `715DA06D3825E97B0C89975153289ECC0BF11F41A9C93A5129DC8397E2DDC33A` | Attached 1280x720 image and direct inspection | Treat its UI hierarchy and restraint as the approved target; preserve real functions that the generated still omits | 1.1, 2.1, 4.1 |
| Shared styling | `resources/ui/paint_mountain_theme.tres` owns Pretendard, palette, panels, buttons, focus, and progress; current Kenney depth surfaces create heavier card/button framing than the selected image | Theme inspection and current captures | Keep existing palette/font/assets but flatten routine surfaces, use hairlines and spacing, reserve filled blue for primary actions, and keep a 2 px visible focus state | 1.2 |
| Shortcut language | `ShortcutHint`, six HUD/pause scenes, and `tests/shortcut_prompt_test.gd` currently attach dark keycaps to individual controls | Current Aim/Pause captures and scene/test inspection | Replace detached prompts with one shared responsive `ContextLegend`; keep short inline `Tab`, `Esc`, `F`, or `Space` text only when it is part of the associated action surface | 1.3, 2.1, 3.3 |
| Gameplay HUD | `hud.tscn`, `TopStatusBar`, `RunStatusCard`, `CoverageMeter`, `AimControls`, `ActionButtons`, `CameraInteractionControl`, and `HUDController` own visible composition and intents | Source inspection plus current Stage 30 capture | Match the approved 24 px edge rhythm, center Fire, move aim/power above the legend, remove visible yaw, keep Gear/Finish/status truthful, and switch the legend by Aim/Map/Follow state | 2.1, 2.2, 2.3 |
| Main Menu and Stage Select | `main_menu.tscn`, `stage_select.tscn`, their scripts, and `AppRoot` own the full navigation path, loading/failure states, paging, and focus | Current captures and source inspection | Remove giant enclosing cards; keep direct title/content, repeated stage objects as restrained selection rows/tiles, one selected accent, one primary action, and real paging/loading behavior | 3.1, 3.2 |
| Briefing, Pause, Settings, Result, and transient feedback | HUD child scenes and `settings.tscn` own one modal/terminal surface each; Settings already uses passive state synchronization and explicit display mutation | Current captures, scenes/scripts, and current implementation record | Retain a single containment surface only where interruption or grouping requires it; remove inner border stacks, use dividers/spacing, preserve focus and paused input barriers, and do not change setting application behavior | 3.3, 3.4 |
| Responsive and localized behavior | `project.godot` uses 1280x720 logical canvas-items/expand; translations, Theme, and existing UI tests cover Korean/English and settings geometry | Project settings, translation CSV, current tests | Check Korean 1280x720 and English 1920x1080 for all core surfaces, plus Korean 1600x900 Settings/Stage Select; no clipping, overlap, or screen escape is acceptable | 4.1, 4.2 |
| Render and delivery path | `DeliveryCaptureRunner` supports Main Menu, Stage Select, Briefing, Aim/Map/Follow, Pause, Settings, and manual/timeout Result; export preset is `Windows Desktop` | Runner and export preset inspection; Godot 4.7.1 resolved through `GODOT_BIN` | Use the existing task-owned background capture path and the built Windows executable; do not add a second capture implementation | 4.2 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety,
  and validation decision is closed.
- `GODOT_BIN` resolves to the approved Godot 4.7.1 console executable; the
  focused test, verification, export, and capture command shapes were verified
  against current scripts and `export_presets.cfg`.
- Remaining unknowns are implementation-local layout mechanics and cannot
  change this contract.

## Tasks

### Phase 1: Canonical direction and shared primitives

Goal: establish one durable visual contract and reusable primitive layer before
screen composition changes.

Preconditions:

- Approved reference path and hash match the Discovery Closure table.
- No other `status: active` ExecPlan exists.

Source owners: `.agents/design/UIUX_GUIDELINES.md`,
`.agents/design/VISUAL_REFERENCES.md`, `resources/ui/paint_mountain_theme.tres`,
`scenes/ui/components/`, `src/ui/components/`

- [x] **1.1 Register the approved Quiet Context direction**
  - Change: add the selected image and its approved/forbidden qualities to the
    visual register and update the UI spec so it supersedes the current heavy
    shared-casual surface treatment without changing interaction authority.
  - Accept: both active specs name the exact image, direct edge hierarchy,
    single context legend, minimal containment, primary-action rule, and yaw
    exclusion without turning generated world pixels into requirements.
- [x] **1.2 Rebuild shared Theme roles for quiet paper instruments**
  - Change: update the existing Theme's neutral surfaces, buttons, primary,
    disabled, separators, progress, type variations, focus, and stage-selection
    roles. Add only responsibility-shaped variations required by several
    screens.
  - Accept: Theme inspection shows Pretendard and the locked palette remain
    shared; routine controls are visually flatter, primary actions remain blue,
    disabled/focus states are distinct without color alone, and no screen needs
    duplicated palette/style overrides.
  - Guard: debug-overlay styling remains unchanged unless a shared parent style
    would otherwise make it unreadable.
- [x] **1.3 Replace detached shortcut badges with one context legend primitive**
  - Change: implement a shared context-legend component with Aim, Map, Follow,
    Briefing, and Pause content modes using existing mouse-wheel imagery and
    localized action labels; remove obsolete detached hint placement from
    composing scenes.
  - Accept: the component renders one shallow line, uses inline input/action
    pairs, exposes no standalone dark keycap tile, ignores pointer input, and
    updates immediately with locale and presentation mode.
  - Guard: Space, Tab, F, and Escape input behavior remains owned by existing
    input/controller code.

Batch gate:

- Run `tests/shortcut_prompt_test.gd` and `tests/localization_ui_test.gd` after
  their assertions are updated to the new primitive; both must pass before
  moving page compositions to the new Theme.

### Phase 2: Faithful gameplay HUD

Goal: reproduce the approved Aim View hierarchy while preserving all real
Aim/Map/Follow, wind, Finish, coverage, and Fire behavior.

Preconditions:

- Phase 1 acceptance and batch gate pass.

Source owners: `scenes/ui/hud/hud.tscn`, `scenes/ui/hud/*.tscn`,
`src/ui/hud_controller.gd`, `src/ui/hud/*.gd`, `translations/ui.csv`

- [x] **2.1 Recompose the 1280x720 Aim View**
  - Change: place direct stage/mode status at upper left, time/ammunition/
    resident/wind/Finish/Gear along the top edge, coverage at the left edge,
    Fire at bottom center, angle/power at bottom right, and the Aim legend under
    a hairline across the safe bottom edge.
  - Accept: a Korean Stage 30 running capture matches the selected reference's
    information hierarchy and spacing, contains `7 / 7`, and keeps the complete
    mountain, trajectory, target, cannon, and flag readable.
  - Guard: Finish remains disabled before the first launch, Gear and Escape open
    the same Pause flow, and Fire remains the sole aiming primary action.
- [x] **2.2 Remove visible yaw and keep target-preserving steppers truthful**
  - Change: delete the direction caption/value/divider and all display updates
    from `AimControls`; retain elevation/power step signals, hold repeat,
    boundaries, tooltips, and `HUDController.update_aim` compatibility.
  - Accept: Aim View contains no `↔`, yaw degree, A, or D; W/S and wheel/direct
    buttons still change the selected target's legal angle/power immediately.
  - Guard: `AimInputController`, `TerrainAimController`, and ballistics are not
    changed by this presentational task.
- [x] **2.3 Apply the system to Map View, Shot Follow, Briefing, feedback, and Result**
  - Change: give each presentation state the same edge instruments and one
    state-specific legend/action lane; simplify Briefing, shot summary,
    mechanism callout, and Result to one containment level with the world still
    visible.
  - Accept: Map hides aim/Fire and shows map guidance; Follow shows only the real
    return action and Follow legend; Briefing keeps Start/Back; manual and
    timeout Result retain Retry/Next/Stages and truthful coverage metadata.
  - Guard: state transitions, stored aim, active projectiles, paint, and result
    data are unchanged.

Batch gate:

- Run `tests/phase8_aiming_composition_test.gd`,
  `tests/phase8_hud_truth_test.gd`, `tests/wind_result_hud_test.gd`, and
  `tests/phase7_user_qa_contract_test.gd` once after Phase 2 task checks pass.

### Phase 3: One system across application and modal pages

Goal: apply the selected restraint, hierarchy, and state language to every
non-gameplay page without changing navigation or settings semantics.

Preconditions:

- Phase 2 acceptance and batch gate pass.

Source owners: `scenes/ui/screens/*.tscn`, `src/ui/screens/*.gd`,
`src/app/app_root.gd`, `translations/ui.csv`

- [x] **3.1 Recompose Main Menu**
  - Change: remove the large brand card, place title/subtitle and actions
    directly over the preview with one restrained readability treatment, keep
    Play as the sole filled primary action, and flatten secondary navigation.
  - Accept: ready, loading, and load-failure states remain readable and
    focusable; the preview world is dominant; Korean and English text does not
    clip.
- [x] **3.2 Recompose Stage Select**
  - Change: replace the two giant panels with direct heading, one restrained
    repeated stage-selection region, a divider-led detail region, quiet pager,
    and one primary Start action.
  - Accept: eight stages per page, selected state, target/best/mechanism data,
    page 1/page 2 navigation, loading/retry, keyboard focus, and all-open stage
    behavior remain functional with no nested card wall.
- [x] **3.3 Recompose Pause and Settings**
  - Change: keep the full-viewport paused barrier but use one compact Pause
    surface and one Settings surface with direct section headings, hairline
    separation, aligned fields, restrained controls, and a single action lane.
  - Accept: Pause exposes Continue/Restart/Settings/Stage Select/Main Menu;
    Settings exposes every existing control, Close/Defaults, and caller return;
    opening or changing non-display settings does not mutate window geometry.
  - Guard: settings persistence, explicit fullscreen/resolution mutation, focus
    restoration, and paused input blocking remain unchanged.
- [x] **3.4 Remove remaining cross-page surface drift**
  - Change: eliminate scene-local palette/type duplication made obsolete by the
    new Theme and align result, modal, stage, menu, and HUD action states with
    the same spacing, radius, focus, disabled, and divider rules.
  - Accept: visual inspection finds no third-level border nesting, cramped
    Korean control, ambiguous label ownership, unsupported action, or detached
    dark shortcut tile on any reachable page.

Batch gate:

- Run `tests/phase7_ui_test.gd`, `tests/localization_ui_test.gd`, and
  `tests/shortcut_prompt_test.gd` once after all Phase 3 task checks pass.

### Phase 4: Responsive production evidence and closeout

Goal: prove the selected image was translated into a coherent running game, not
only into scene coordinates.

Preconditions:

- Phases 1-3 and their named checks pass.

Source owners: `tests/`, `src/delivery/delivery_capture_runner.gd`,
`design-qa.md`, `.agents/evidence/quiet-context-ui-system-2026-08-09/`,
`.agents/Documentation.md`, this plan

- [ ] **4.1 Update focused contracts and pass repository verification**
  - Change: update only tests invalidated by the approved presentation contract,
    preserving behavior assertions; run the named focused batch and
    `scripts/verify.ps1`.
  - Accept: every named test and verification command exits zero without a
    `SCRIPT ERROR` or recurring runtime error.
- [ ] **4.2 Export, capture, compare, and correct the running build**
  - Change: build `Windows Desktop`, start the built executable through the
    existing background capture path, and save separate captures for Korean
    1280x720 Main Menu, Stage Select, Briefing, Aim, Map, Follow, Pause,
    Settings, manual Result, and timeout Result; add English 1920x1080 Main
    Menu, Stage Select, Aim, Settings, and Result plus Korean 1600x900 Stage
    Select and Settings.
  - Accept: every image is the requested size and state, contains no clipping or
    overlap, and the Aim capture passes same-state comparison against the exact
    selected reference in one combined visual input. P0/P1/P2 design-QA issues
    are fixed and `design-qa.md` says `final result: passed`.
  - Guard: captures come from the production executable without debug overlay;
    concept images never substitute for runtime evidence.
- [ ] **4.3 Record current truth and close the contract**
  - Change: update `.agents/Documentation.md`, record Level 4 UI/UX evidence and
    any non-blocking P3 notes, mark this plan `done`, and commit only task-owned
    files.
  - Accept: documentation names the approved system, implementation owners,
    tests, export, and captures; no unchecked task remains and no active plan
    falsely describes completed work as pending.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | `& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/<task-owned-test>.gd` | A task changes a named scene/script contract | A relevant scene, script, Theme, translation, or assertion changes |
| Phase 1 gate | `shortcut_prompt_test.gd`, `localization_ui_test.gd` | Tasks 1.1-1.3 pass | Shared primitive or localization input changes |
| Phase 2 gate | `phase8_aiming_composition_test.gd`, `phase8_hud_truth_test.gd`, `wind_result_hud_test.gd`, `phase7_user_qa_contract_test.gd` | Tasks 2.1-2.3 pass | Gameplay-HUD input changes |
| Phase 3 gate | `phase7_ui_test.gd`, `localization_ui_test.gd`, `shortcut_prompt_test.gd` | Tasks 3.1-3.4 pass | App-screen/modal input changes |
| Repository gate | `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN` | Task 4.1 focused checks pass | Project source/resource/settings input changes |
| Final export | `& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'` | Repository gate passes | Export-owned input changes |
| Final rendered evidence | `Start-Process builds/windows/PaintMountain.exe -WindowStyle Hidden -ArgumentList @('--','--capture-background','--capture-screen=<state>','--capture-size=<size>','--capture-language=<locale>','--capture-output=<absolute-path>') -PassThru -Wait` | Final export passes, once per named state/size | Visible owner or capture-state input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Run the production export and rendered evidence once after all source and
  contract changes are substantially complete.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Record existing unrelated worktree files once and do not stage, modify, or
  clean them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain required approval before resuming | Do not let implementation select a new product, dependency, UX direction, or gameplay contract |
| A generated-image detail conflicts with a real supported function | Preserve the real function and apply the approved visual principle to it | Do not remove Gear, Finish, Map, Follow, loading, disabled, or accessibility behavior |
| The target layout clips at a supported desktop size | Recompose with containers/anchors and preserve hierarchy; do not shrink essential text below its Theme role | Replan only if the approved hierarchy itself cannot fit 1280x720 |
| A shared Theme change harms debug or unrelated production UI | Add the narrowest responsibility-shaped variation or local layout exception | Do not create a second palette/token registry |
| A focused test encodes the superseded visual contract | Update only the presentational assertion and retain its behavior guard | Do not weaken state, input, persistence, or authority assertions |
| The production capture is wrong-state, blank, cropped, or missing | Reject it, correct the capture prerequisite or implementation, and recapture that state only | Do not claim visual evidence from scene inspection or headless layout tests |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 4 - Responsive production evidence and closeout.
- Next task: 4.1 - Update focused contracts and pass repository verification.
- Last completed gate: Phase 3; Korean 1280x720 runtime captures cover Main
  Menu, Stage Select, Briefing, Aim, Map, Follow, Pause, Settings, and Result.
  Gameplay HUD, target-preserving aiming, navigation, localization, settings
  geometry, and the shared context legend pass their focused contracts. The
  approved Aim reference and runtime were also reviewed in a same-size combined
  comparison input.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, repository gate, export, capture, and design-QA gate
  named by this contract passes.
- No placeholder or unresolved material decision remains.
- Durable direction and implementation truth are recorded in their owning
  active specs/record.
- Frontmatter status is changed to `done` only after implementation completion.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.

## Anti-Rework Execution Rules

- On start or resume, read this contract and inspect the worktree only enough to
  confirm checkpoint inputs, then continue from the first unchecked task whose
  prerequisites are satisfied.
- Treat checked tasks and recorded passing evidence as complete unless a
  relevant input changed, the evidence is missing, or this contract schedules a
  broader final gate.
- Run each check at its declared cadence. Do not repeat a passing check merely
  to regain confidence.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Mark a task complete only after its acceptance check passes; run and record a
  guard only when that task names one.
- Update task checkboxes and the progress pointer together after a checkpoint.
- If reality contradicts a material decision, stop that branch and revise this
  contract before continuing. Handle implementation-local mechanics within the
  locked contract without reopening planning.
