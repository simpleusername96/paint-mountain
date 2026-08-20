---
type: plan
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: refine the approved Quiet Context interface into one clear modern Compact Overlay shared-component system across every reachable screen and all 30 stages without changing gameplay rules
related:
  - ../PLANS.md
  - 2026-08-18-three-ball-target-band-prototype.md
  - 2026-08-09-quiet-context-ui-system.md
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
---

# Cross-Stage Compact Overlay UI Refinement — Execution Contract

## Purpose

Refine the existing Paint Mountain interface into the clear, modern, world-first
system shown in `docs/reports/ui-refinement-2026-08-20/index.html`. The mountain,
cannon, trajectory, paint, and real stage data remain primary. Persistent
information moves into compact direct edge components, current actions move into one
compact shared action group, and explanatory copy is removed from normal play.
Screens compose shared components directly over the world; decorative panels,
cards, sheets, and section surfaces do not define the layout.

This contract applies the same theme and component grammar to Main Menu, Stage
Select, Briefing, Aim, Map, Shot Follow, Pause, Settings, Result, loading,
failure, disabled, and transient-feedback states. It covers all 30 stages:
Stages 1–6 keep their Red/Green target-band and three-ball truth, while Stages
7–30 keep their established coverage/mechanism truth inside the same shared
visual system.

The separate active prototype plan has only its exact-public-artifact boundary
remaining. The user explicitly requested this separately scoped concurrent
plan. Local UI implementation may proceed, but it must not overwrite, republish,
or relabel the artifact being proved by that plan. Any future itch publication
still requires its own current-turn authorization.

## Outcome and deliverables

- One project Theme owner with semantic type variations for hierarchy, state,
  focus, icons, and compact direct overlays.
- One shared responsive composition for every application and gameplay state.
- One shared `ScoreScale` whose complete 0–100 domain, five labels, target
  segment/threshold, and current marker never clip or change range.
- Every visible presentational structure resolves to a shared component;
  screens own structural Containers and arrangement only.
- No stage-specific UI copies or stage-owned colors/layouts.
- Truthful target-band presentation for Stages 1–6 and coverage presentation
  for Stages 7–30.
- Automated theme, state, localization, focus, bounds, and all-stage coverage
  contracts.
- Production Windows and Web builds plus personally inspected running-game
  captures for the named representative states and stages.
- Updated design authority, implementation record, and test checklist after the
  runtime implementation is proven.

## Verified evidence and working model

| Evidence | Verified fact | Applicability and effect on this plan |
| --- | --- | --- |
| Latest 2026-08-20 running-game captures | Current UI fits the common target sizes, but unrelated card shapes, detached status blocks, a full-width help strip, oversized Briefing cards, and a weak Result hierarchy compete with the world | Preserve the responsive foundation; recompose hierarchy and visual rhythm rather than replacing navigation or game rules |
| `docs/reports/ui-refinement-2026-08-20/index.html` revision 02 | Four current-to-TO-BE comparisons and a deterministic shared-component diagram define the no-panel, icon-first, complete 0–100 direction | Treat component grammar, complete scale, restraint, and hierarchy as the target; generated microcopy, numbers, icons, and world pixels are non-authoritative |
| `.agents/design/UIUX_GUIDELINES.md` | Quiet Context already locks warm white `#FFFDFC`, navy `#172538`, action blue `#2584FF`, gray `#C9CDD2`, danger `#D94C4C`, Pretendard, 24 px safe margin, Korean-first copy, and one blue primary action | Keep these values. Add semantic variations and layout rules; do not introduce a second palette or font system |
| [Lonely Mountains](https://lonelymountains.com/), [art of rally](https://artofrally.com/), [Nintendo Switch Sports Golf](https://www.nintendo.com/jp/ichikara/as8sa/index.html), and [Monument Valley level selection](https://interfaceingame.com/screenshots/monument-valley-level-selection-menu/) | Comparable released games demonstrate world-dominant HUD occupancy, direct thin instruments, an explicit complete scale, and visual stage navigation | Borrow the low-occupancy and information-expression principles only; retain Paint Mountain interaction, assets, data, copy, palette, and component ownership |
| `.agents/execplans/2026-08-09-quiet-context-ui-system.md` | Theme, shared HUD components, `ContextLegend`, app screens, and the production capture runner already exist | Refine existing owners. Do not build a parallel UI layer or a second capture path |
| Active three-ball prototype plan and `.agents/Documentation.md` | Stages 1–6 use target-band/queue truth and recent responsive containers; the previous scope explicitly excluded an all-30-stage migration | Preserve the M7 container fixes and extend the visual contract to the entire catalog in this plan |
| `src/stage/stage_catalog.gd`, `src/app/stage_layout_repository.gd`, current generated catalog | All 30 stages are data-driven and share the gameplay scene/HUD owners | Test all 30 data variants through shared presentation; do not edit generated stage resources merely to apply a theme |
| Godot 4.7 [Using Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html) | Containers own child layout and reflow across size changes | Use container-owned geometry and size flags; do not restore fixed per-resolution offsets |
| Godot 4.7 [GUI skinning](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_skinning.html) and [theme type variations](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_theme_type_variations.html) | A cascading Theme and shared type variations are the maintainable way to apply repeated roles | Keep `paint_mountain_theme.tres` canonical and remove obsolete scene-local style duplication only after equivalent shared roles exist |
| Godot 4.7 [Control](https://docs.godotengine.org/en/4.7/classes/class_control.html) and [multiple resolutions](https://docs.godotengine.org/en/4.7/tutorials/rendering/multiple_resolutions.html) | Control supports explicit focus/accessibility relationships; responsive UI needs a base design size plus adaptive layout | Preserve keyboard focus, add truthful accessibility names/relationships where absent, and validate the current resolution matrix rather than pixel-scaling one still |

### Competing directions considered

- **Keep the current responsive UI and only change colors:** rejected because
  the primary defects are hierarchy, panel area, and disconnected composition.
- **Copy the TO-BE stills pixel-for-pixel:** rejected because generated text,
  values, icons, and world details are not runtime truth, and fixed coordinates
  would regress smaller sizes and localization.
- **Create separate prototype and legacy HUD scenes:** rejected because Stages
  1–6 and 7–30 need one maintainable visual system; conditional data regions
  already express the rule difference.
- **Keep one panel or rail surface around each information group:** rejected
  because the user's correction requires direct overlays and because repeated
  surfaces consume the mountain without adding interaction meaning. A shared
  contrast scrim supplies readability without a boundary.
- **Redesign stage/world art together with UI:** rejected because the request is
  interface refinement and the current world is the approved visual anchor.
- **Adopt a new UI package, font, or asset pack:** rejected because existing
  Godot Controls, Pretendard, Kenney subset, and project icons are sufficient
  and new production dependencies require explicit approval.

## Locked decisions

### Visual language

- The direction name is **Compact Overlay**, a refinement of Quiet
  Context rather than a replacement brand.
- Preserve the approved palette and Pretendard. New color literals may not be
  added to individual screens; reusable states belong to Theme variations.
- The live world is the primary layer. Persistent HUD uses direct icons, values,
  one complete thin scale, whitespace, and at most one shared contrast scrim.
  Gameplay, Briefing, Stage Select, and Result use no decorative panel, card,
  sheet, dock surface, full-width guide, or section container.
- One filled blue primary action is visible per state. Selection uses outline,
  check/icon, and a quiet tint so it does not compete with the current action.
- Routine corner radius is 10–14 px for interactive controls only. Pause,
  Settings, and blocking error states may use one shared interruption surface;
  it is not reused as normal gameplay chrome.
- Motion, where existing behavior permits it, is 120–180 ms and must not delay
  input readiness, state truth, or focus.

### Information hierarchy

- Priority 1: current objective/terminal verdict and the next legal action.
- Priority 2: score or coverage, target band, current/next ball, ammunition,
  elevation, and power.
- Priority 3: shortcuts, explanation, mechanism prose, and duplicated context.
- At constrained sizes, suppress or wrap Priority 3 first, then shorten
  Priority 2 labels while keeping values; never hide Priority 1.
- Prefer icons and values. Visible text is limited to stage identity, a short
  unit, a terminal reason, or a one- or two-word action unless ambiguity,
  destructive consequence, localization, or accessibility requires more.
- The central route, cannon, trajectory, impact area, and active projectile
  family must remain unobstructed in Aim, Map, and Shot Follow.

### Stage and state truth

- `StageController` remains the only owner of stage state, shot progression,
  readiness, clear, and failure decisions. HUD scripts present observations and
  emit existing intents only.
- Stages 1–6 show target-band, Red/Green split, three-ball order, and special-
  ball states only when the authoritative stage data supports them.
- Stages 7–30 show their established coverage, ammunition, mechanism, and
  result fields. They do not receive invented Red/Green targets.
- `PaintSystem` remains the only paint/coverage authority. No UI animation or
  placeholder value may predict coverage ahead of authoritative publication.
- Stage resources and generated catalogs supply values only. They do not own
  theme colors, spacing, or scene variants.

### Responsive, input, and accessibility contract

- Base design size remains 1280×720 with the current canvas-items/expand setup.
- Accepted matrix: 1280×720, 1280×800, 1366×768, 1600×900, 1920×1080 in Korean
  and English. Stress matrix: 640×360, 1024×576, and 1024×768.
- Logical safe margin is 24 px at accepted sizes and may compress to 12 px at
  the 640×360 stress size. Essential controls remain inside the viewport.
- `ScoreScale` retains the full 0–100 domain and visible 0/25/50/75/100 labels
  at every accepted size. At stress size it may reduce its physical width, but
  may not crop an endpoint, hide a label, or zoom to the target range.
- Routine controls are at least 40 px high and target 44 px where composition
  permits. Focus outline is at least 2 px and remains visible for keyboard and
  controller navigation.
- Normal text targets 4.5:1 contrast, large text and non-text UI 3:1. State is
  never communicated by color alone. Icon-only controls require an accessible
  name and tooltip.
- Existing mouse, keyboard, controller, shortcut, focus-restoration, pause, and
  first-Fire behavior remains unchanged.

### Dependencies and authority

- No production dependency, plugin, network service, new font, new asset pack,
  gameplay rule, save schema, stage catalog rewrite, or paint-system change is
  authorized by this plan.
- Existing Pretendard, approved icons, Kenney subset, Control nodes, Theme, and
  capture runner are the only production building blocks.
- Publishing to itch.io, changing visibility, or modifying fastrun-manager
  registration remains outside this plan and requires explicit authorization.

## Architecture ownership

| Responsibility | Canonical owner | Must not absorb |
| --- | --- | --- |
| Shared visual roles, palette, type, focus, surfaces, spacing tokens | `resources/ui/paint_mountain_theme.tres` | Stage data, state rules, per-screen geometry |
| Every visible presentation primitive and its narrow behavior | `scenes/ui/components/`, `src/ui/components/` | Whole-screen state orchestration, game rules, scene-local visual styling |
| Gameplay composition and state visibility | `scenes/ui/hud/`, `src/ui/hud/`, `src/ui/hud_controller.gd` | Shot admission, scoring, paint authority |
| Main Menu, Stage Select, Settings, Pause composition | `scenes/ui/screens/`, `src/ui/screens/` | Gameplay state decisions |
| Localized user-facing copy | `translations/ui.csv` and existing copy owners | Layout-only labels encoded in scripts |
| Stage values and family selection | `StageData`, `StageCatalog`, `StageLayoutRepository` | Theme or stage-specific scene copies |
| Production capture states | `src/delivery/delivery_capture_runner.gd` | A second screenshot harness |
| Runtime evidence | `.agents/evidence/cross-stage-ui-theme-2026-08-20/` | Design authority or generated concept assets |

Before expanding any large owner, the implementing agent must identify its
existing responsibility and prefer a smaller component or Theme variation over
adding another whole-screen conditional to `HUDController`.

## Tasks

### Phase 1 — Register the refinement and establish shared primitives

Goal: make the direction durable and implement reusable visual roles before
screen-by-screen composition changes.

Source owners: `.agents/design/UIUX_GUIDELINES.md`,
`.agents/design/VISUAL_REFERENCES.md`, `resources/ui/paint_mountain_theme.tres`,
`scenes/ui/components/`, `src/ui/components/`, `tests/phase7_ui_test.gd`

- [x] **1.1 Record Compact Overlay in the design authority.** Add the revised
  report, component-system SVG, external comparative references, and four
  target images to the visual register with explicit user-directed qualities
  and non-authoritative generated details. Update UI guidance for direct
  overlays, the fixed 0–100 scale, shared-component-only composition,
  icon-first copy reduction, stage-family truth, and accessibility.
  - Accept: future implementers can select Theme roles and layouts without
    treating generated numbers, labels, icons, or world pixels as requirements.
- [ ] **1.2 Extend the canonical Theme.** Add only shared semantic variations
  needed by the named components: primary/secondary/quiet/danger actions,
  selected/completed/locked stage nodes, score scale, compact metric/value,
  short hint, contrast scrim, interruption surface, and focus.
  - Accept: palette/font remain canonical; a static Theme contract finds no
    duplicate scene-local palette for the new roles; disabled, focus, selected,
    and completed remain distinguishable without color alone.
- [ ] **1.3 Build or refine responsibility-shaped primitives.** Reuse current
  components first and converge competing owners:
  - enhance `hud_metric` as `MetricReadout`;
  - merge `target_band_meter` and `coverage_meter` behind one shared
    `ScoreScale` API with a fixed 0–100 visual domain;
  - move/refine `queue_rail` and `queue_token_view` as shared `BallQueue`;
  - make `aim_controls` compose shared `ValueStepper` controls;
  - make `action_buttons` compose shared `ActionControl` controls;
  - replace `stage_card_button` with shared `StageRail` nodes;
  - refine `context_legend` into shared `ContextHints` with at most three
    icon/action pairs;
  - replace `result_panel` with direct shared `ResultSummary`; and
  - provide shared `StageIdentity` and non-interactive `ContrastScrim`.
  - Accept: each primitive has one clear presentation responsibility, receives
    values through narrow typed setters/signals, ignores pointer input when
    decorative, and does not query global gameplay state. A static ownership
    check finds no screen-local StyleBox, palette, font, icon, or duplicate
    component structure for these roles.

Phase gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/shared_ui_component_ownership_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/score_scale_contract_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/localization_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/shortcut_prompt_test.gd
```

### Phase 2 — Recompose application, selection, and interruption screens

Goal: make every non-gameplay screen use the same hierarchy before changing the
high-frequency HUD.

Source owners: `scenes/ui/screens/*.tscn`, `src/ui/screens/*.gd`,
`scenes/ui/components/stage_rail*.tscn`, `translations/ui.csv`

- [ ] **2.1 Refine Main Menu.** Keep the preview world dominant, reduce
  decorative containment, and expose one clear Play/Continue action plus quiet
  Settings/Exit navigation. Preserve ready, loading, load-failure, and focus
  restoration states.
- [ ] **2.2 Recompose Stage Select as world plus StageRail.** Remove the card
  list/detail split. Let the selected stage's existing world preview carry the
  identity and place eight shared numbered nodes, page chevrons, compact direct
  facts, and the single Start action at safe edges. Preserve 1–30 paging,
  lock/completion/best score/mechanism truth, keyboard focus, all-open
  development behavior, loading, and retry.
  - Accept: selected, completed, available, and locked states use the shared
    state grammar; Start is the sole filled blue action.
- [ ] **2.3 Refine Pause and Settings.** Use one shared compact interruption
  surface only where input blocking needs containment, plus aligned fields and
  shared actions. Preserve paused
  input blocking, caller return, explicit display mutation, passive setting
  synchronization, defaults, persistence, and focus restoration.
- [ ] **2.4 Close responsive and localized screen states.** Use Containers and
  ScrollContainer fallback where necessary; do not resize essential type below
  its Theme role to make fixed geometry fit.

Phase gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/screen_responsive_layout_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/stage_select_rule_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/localization_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/essential_ui_copy_test.gd
```

### Phase 3 — Recompose the shared gameplay shell and all states

Goal: make the live mountain primary while preserving every state, action, and
stage-family value.

Source owners: `scenes/ui/hud/*.tscn`, `src/ui/hud/*.gd`,
`src/ui/hud_controller.gd`, `scenes/ui/components/context_legend.tscn`,
`translations/ui.csv`

- [ ] **3.1 Build the shared gameplay shell.** Use one safe-area composition of
  direct `StageIdentity`, `MetricReadout`, complete `ScoreScale`, conditional
  `BallQueue`, lower `ValueStepper`/`ActionControl`, and at most three
  `ContextHints`. Use `ContrastScrim` only where measured contrast requires it;
  do not add a top bar, objective panel, right rail, bottom dock, or full-width
  legend.
  - Accept: central mountain, cannon, trajectory, target, impact area, and
    projectile family remain readable at every matrix size.
- [ ] **3.2 Apply the shell to Briefing and Aim.** Briefing keeps the real world
  visible with objective and ball order at the edges. Aim exposes elevation,
  power, Fire, current goal, ammunition, and queue without a rule panel or
  full-width tutorial surface.
- [ ] **3.3 Apply state reductions to Map and Shot Follow.** Map removes aiming
  controls and shows only map-relevant guidance. Shot Follow removes Fire and
  shows the legal return action plus projectile/family observation. Neither
  state duplicates unavailable actions.
- [ ] **3.4 Refine feedback and Result.** Keep transient shot/mechanism feedback
  near its owner and short-lived. Result places direct verdict/value,
  `ScoreScale`, compact breakdown, and prioritized Next/Retry/Stages shared
  actions over an optional edge scrim. It uses no result card or sheet and keeps
  the painted mountain as the result hero.
- [ ] **3.5 Prove both stage families through the same components.** Add a
  focused `tests/cross_stage_ui_theme_test.gd` that iterates the current catalog
  and presents all 30 stages through Briefing/Aim/Result models. Assert that
  Stages 1–6 expose only valid target-band/queue fields, Stages 7–30 expose only
  valid coverage/mechanism fields, every stage resolves the canonical Theme,
  every score/coverage presentation retains the fixed 0–100 visual domain, and
  no stage resource supplies layout or color overrides.

Phase gate:

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/cross_stage_ui_theme_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_layout_responsive_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/hud_target_band_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/target_band_layout_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_hud_truth_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_aiming_composition_test.gd
```

### Phase 4 — Cross-stage, locale, focus, and rendered correction pass

Goal: use current runtime pixels to correct composition before broad delivery
work.

Source owners: task-owned UI scenes/scripts/tests,
`src/delivery/delivery_capture_runner.gd`,
`.agents/evidence/cross-stage-ui-theme-2026-08-20/`

- [ ] **4.1 Run the complete layout/state matrix.** Exercise every app state
  and the all-30-stage model test at accepted and stress sizes in Korean and
  English. Check bounds, overlap, clipping, minimum controls, focus order,
  focus visibility, disabled/selected/completed states, long copy, tooltips,
  and live accessibility names.
- [ ] **4.2 Capture the representative Windows production matrix.** Export the
  Windows release, then create task-owned background captures for:
  - Main Menu, Stage Select, Pause, and Settings;
  - Stage 01 Briefing/Aim/Result for the baseline target-band family;
  - Stage 03 Aim/Shot Follow/Result for Apex Split and three-child queue/load;
  - Stage 07 Aim/Result for the first legacy coverage family;
  - Stage 30 Aim/Map/Result for late-game coverage/mechanism density;
  - Korean 1280×720 for every named state, Korean 640×360 stress captures for
    Stage Select/Stage 03 Aim/Settings, and English 1920×1080 for Main Menu,
    Stage Select, Stage 03 Aim, Settings, and both Result variants.
- [ ] **4.3 Personally inspect and correct the running pixels.** Compare the
  four matching states with the TO-BE report in one visual input per state.
  Record P0/P1/P2 findings, fix them in a coherent batch, and recapture only
  invalidated states. Generated TO-BE images never count as runtime proof.
- [ ] **4.4 Run the Web production UI journey.** Export Web, run static release
  validation, load `$npjt-port-guard`, resolve the fastrun manager's current
  `codex` lane, and serve the built artifact through that registered lane. In
  one browser-control stack, exercise launch, resize, fullscreen, Main Menu,
  Stage Select, Stage 03 Aim/Pause/Settings/Result, Stage 07 Aim/Result, focus,
  and Korean/English switching. Stop only task-owned server/browser helpers.
  - Accept: no clip/overlap, stale focus, input interception, console error, or
    missing resource occurs. Record the exact lane/URL and artifact hash in the
    evidence README; never hardcode the current port into durable source.

Representative capture command shape:

```powershell
Start-Process builds/windows/PaintMountain.exe -WindowStyle Hidden -ArgumentList @(
  '--',
  '--capture-background',
  '--capture-screen=<state>',
  '--capture-stage=<stage>',
  '--capture-size=<size>',
  '--capture-language=<locale>',
  '--capture-output=<absolute-evidence-path>'
) -PassThru -Wait
```

### Phase 5 — Quality audit, broad gates, records, and handoff

Goal: prove the multi-file UI change did not create competing owners or regress
the production path.

- [ ] **5.1 Run `$codebase-quality-auditor`.** Audit task-owned changes for
  duplicated palette/layout overrides, catch-all HUD growth, competing state
  owners, unreachable failure/loading states, test weakening, and missing
  all-stage validation. Apply only small safe task-scoped corrections.
- [ ] **5.2 Run the broad repository gate once.** Announce scope and expected
  cost before starting. Run after implementation, focused tests, captures, and
  audit are stable:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
& $env:GODOT_BIN --headless --path . --export-release 'Web' 'builds/web/index.html'
pwsh -NoProfile -File scripts/verify-web-release.ps1 -ReleaseDirectory builds/web
```

- [ ] **5.3 Record implemented truth.** Update `.agents/Documentation.md` and
  `docs/test-checklist.md` with only proven runtime behavior, link the evidence
  README, record exact Godot version/renderer/locale/viewport/artifact hashes,
  and mark this plan `done` only when every acceptance check passes.
- [ ] **5.4 Commit coherent task-owned batches.** Keep foundation, app screens,
  gameplay/all-stage migration, and final evidence/records separable when their
  ownership supports it. Each commit body states what changed. Do not stage or
  rewrite unrelated user work.

## Validation and rework controls

| Cadence | Check | Run when | Rerun only after |
| --- | --- | --- | --- |
| Inner loop | One named Godot test with `--quit-after 7200` | A task changes its scene/script/Theme/translation contract | A relevant input or assertion changes |
| Phase gate | Exact commands listed under that phase | All tasks in that phase pass local checks | A phase-owned input changes |
| Render correction | Named production capture subset | A visible batch is coherent | A visible owner or capture prerequisite changes |
| Web journey | Built Web artifact on the protected codex lane | Windows render correction and Web export pass | Web-visible source/export input changes |
| Broad gate | `scripts/test.ps1`, `scripts/verify.ps1`, both exports, Web verifier | Implementation and quality audit are substantially complete | A production, test, project, or export input changes |

Rules:

- Keep implementation and validation separate. Use focused checks while
  building and run the broad gate once near completion.
- A passing check remains current until a relevant input changes.
- Rerun a failed check only after an implementation change or new hypothesis
  can produce different evidence.
- Save large logs and screenshots under the task evidence directory and link
  them from its README; do not paste them into this plan.
- Headless contracts support visual judgment but never replace current
  running-game captures.

## Acceptance checks

- [ ] Main Menu, Stage Select, Briefing, Aim, Map, Shot Follow, Pause, Settings,
  Result, loading, failure, disabled, and transient-feedback states use one
  coherent Theme and hierarchy.
- [ ] All 30 current stages resolve the canonical Theme and correct conditional
  target-band or coverage presentation without stage-specific UI copies.
- [ ] Every score/coverage visualization shows the complete 0–100 axis with
  visible 0/25/50/75/100 labels, an in-bounds current marker, and an in-bounds
  target segment/threshold at every accepted and stress size.
- [ ] Every visible presentational structure is a shared component or Theme
  role; gameplay, Briefing, Stage Select, and Result contain no decorative
  panel/card/sheet and no scene-local StyleBox, palette, font, or icon copy.
- [ ] The mountain, cannon, trajectory, target/impact area, active projectile,
  and painted result remain the dominant gameplay layer at accepted sizes.
- [ ] Each state exposes at most one filled blue primary action and preserves
  every real action, focus path, shortcut, tooltip, loading/error path, and
  state transition.
- [ ] Korean and English pass the accepted size matrix with no clipping,
  overlap, screen escape, or ambiguous label ownership. Stress sizes retain all
  Priority 1 information and legal actions.
- [ ] Focus, disabled, selected, completed, target-band, Red/Green, and danger
  states are distinguishable without color alone and meet the locked contrast/
  target-size contract.
- [ ] Focused tests, all-stage contract, codebase quality audit, broad suite,
  verification, Windows/Web exports, Web static validation, Windows rendered
  matrix, and built-Web journey pass.
- [ ] `.agents/Documentation.md`, design authority, test checklist, evidence,
  and this plan agree with implemented truth.

## Regression guards and predetermined contingencies

| Trigger | Required response | Forbidden response |
| --- | --- | --- |
| A generated-image detail conflicts with current gameplay or copy | Preserve real behavior/data and apply only its hierarchy/spacing principle | Removing a real action or inventing a value to match the image |
| Stages 1–6 and 7–30 require different data fields | Use conditional regions inside the shared component/API | Forking the whole HUD or adding stage-number conditionals to Theme |
| A supported size clips | Recompose with Containers, priority collapse, wrapping, or bounded scrolling | Shrinking essential text below its role or moving controls off-screen |
| A `ScoreScale` endpoint, tick, marker, or target segment clips | Correct the shared component's clamping, label reserve, or minimum geometry and rerun every caller | Zooming the scale to the current target range or fixing one screen locally |
| A Theme variation harms another screen | Narrow the semantic variation and migrate intended users explicitly | Creating a second Theme/palette owner |
| A screen needs a visual role not exposed by a shared component | Add or refine the smallest responsibility-shaped shared component, then migrate every current user | Adding scene-local StyleBox, icon, palette, font, card, or panel styling |
| `HUDController` begins accumulating layout-only branches | Move presentation behavior into a responsibility-shaped component | Moving StageController decisions into UI code |
| A test encodes the superseded presentation | Update only its visual assertion while retaining behavior/state guards | Deleting or weakening a test to make the gate pass |
| A production capture is blank, wrong-state, clipped, or stale | Reject it, fix the prerequisite/implementation, and recapture that state | Claiming scene inspection or a generated still as runtime proof |
| The Web artifact exposes an input/focus issue | Fix the smallest UI/input-owner defect and rerun the affected journey | Changing paint/gameplay, enabling Web threads, or adding a shell overlay without evidence |
| Existing active prototype publication work overlaps the same artifact | Stop the publication branch, preserve both plans' evidence, and coordinate a new artifact boundary | Overwriting or republishing the artifact under proof |
| A dependency, font, asset pack, gameplay rule, save schema, or public-state change appears necessary | Stop and request explicit authorization with the minimal evidence | Expanding this plan's authority |

## Progress and next step

- [x] 2026-08-20 discovery: inspected current implementation record, design
  authority, completed Quiet Context plan, active target-band plan, shared UI
  owners, representative tests, latest running-game captures, and relevant
  Godot 4.7 primary documentation.
- [x] 2026-08-20 corrected direction package: inspected four external game UI
  references, replaced the panel-heavy concepts with four Compact Overlay
  current-to-TO-BE comparisons, added a deterministic shared-component system
  diagram, and locked the complete 0–100 score-scale contract in the report,
  design authority, and this plan.
- [ ] Current phase: Phase 1.
- [ ] Next task: 1.2, extend the canonical Theme roles before changing screen
  compositions.

Checkpoint rule: after each numbered phase gate passes, update this section in
the same commit with the completed task boxes, concise validation evidence, and
the next task. Do not create a separate progress plan.

## Completion and stop conditions

Complete only when:

- Every task and acceptance check passes.
- Every named state and both stage families have current production rendered
  evidence, and all 30 stages pass the shared presentation contract.
- Windows/Web production checks and the built-Web journey pass.
- Durable design and implementation truth is recorded in its canonical owner.
- Frontmatter status changes to `done` and no implementation task remains.

Replan when:

- A verified material fact invalidates the locked visual hierarchy, stage-
  family split, component ownership, dependency boundary, or validation path.

Stop and ask the user when:

- Completion requires a new dependency/font/asset pack, gameplay or save
  change, destructive action, public itch action, or a visible direction that
  materially departs from Compact Overlay.

Do not stop or replan for:

- Implementation-local Container choices, semantic variation names, or small
  copy wrapping adjustments that remain inside this contract.
- A passing check whose relevant inputs have not changed.
