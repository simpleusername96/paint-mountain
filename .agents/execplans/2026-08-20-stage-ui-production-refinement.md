---
type: plan
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: correct the audited compact UI defects and replace the unmeasured Stage 07-30 rule cycle with an evidence-backed five-chapter Red/Green progression
supersedes:
  - 2026-08-20-cross-stage-ui-theme.md
related:
  - ../PLANS.md
  - ../../docs/reports/ui-refinement-audit-2026-08-20/index.html
  - ../../docs/reports/stage-design-analysis-2026-08-20/index.html
  - ../../docs/reports/itch-paint-latency-2026-08-20/index.html
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../evidence/2026-08-20-full-ui-audit/README.md
---

# Stage and UI Production Refinement - Execution Contract

Paint Mountain will retain the selected Cannon Focus theme and the completed
continuous-paint Web latency correction, then correct the defects visible in
the current full-screen audit and replace the late-stage five-rule loop with a
measured five-chapter progression. Stage 01-06 remain exact. Stage 07-30 use
both Red and Green as direct score inputs, stage-specific special-ball
requirements, and per-stage target bands. All visual changes stay in shared
Theme, component, and layout owners; no screen-local UI system is introduced.

## Purpose

- Objective: turn the two 2026-08-20 audits into one executable contract and
  implement every locally actionable P0/P1 issue without reopening accepted
  world art, physics, or paint ownership.
- Deliverable: an immutable v12 stage catalog, balance evidence, corrected
  shared UI at 1280x720 and 640x360, current Windows/Web release artifacts, and
  full-viewport proof for every named critical state.
- Completion state: all task checkboxes and gates pass, the inherited built-Web
  live journey is either proven or remains the sole explicit external blocker,
  the plan records truthful limits, scoped commits are pushed, and the
  task-owned worktree is clean.

## Scope and Boundaries

In scope:

- Stage 07-30 color-score patterns, target bands, deal-kind requirements,
  chapter intent, immutable catalog migration, structural deal tests, physical
  score sampling, and representative automated clear witnesses.
- Compact Briefing, Aim, Ball Queue detail, Shot Follow return, Stage Select,
  Result, Settings, and Pause presentation through existing shared owners.
- Korean-first copy fit, icon/shape plus R/G cues, keyboard focus, pointer
  hover, press/touch equivalence, accessibility names, overflow, clipping, and
  supported 1280x720 and 640x360 layouts.
- The only unfinished task inherited from the superseded plan: a live built-Web
  Stage 03/07/18/30 real-fire regression journey after final source inputs.
- Focused tests, the project suite, verification, Windows/Web exports, static
  Web validation, release screenshots, durable implementation truth, commits,
  and push.

Out of scope:

- Changes to Stage 01-06 authored score rules, bands, shot counts, or ball-kind
  availability; new stages, ball kinds, mechanisms, terrain families, fonts,
  dependencies, plugins, asset packs, or a second UI/capture framework.
- In-flight steering, score-formula ownership changes, a second paint/coverage
  representation, dynamic difficulty adjustment, or claims that automation
  proves fun or human-perceived balance.
- Public itch upload, channel mutation, visibility change, or deployed-artifact
  claims. Local Web output and local browser checks do not authorize publishing.

Constraints and invariants:

- `StageController` remains the sole stage-state, shot, finish, and result
  owner. `PaintSystem` remains the sole mutable paint mask and coverage owner.
  UI displays supplied state and never recomputes game rules.
- `StageCatalogMaterializer` applies authored challenge data; a dedicated
  typed stage-challenge owner supplies the late-stage table. Existing geometry,
  terrain seed, route, mechanism, decoration, and entry-witness payloads remain
  byte- or checksum-equivalent through the v11-to-v12 migration.
- A deal's `required_kinds` means those root kinds must occur in the finite
  deal. It does not claim that the player must use them in one unique solution.
- Stage 07-30 never use a zero Red or Green weight. `BOTH_ADD`,
  `GREEN_ADD_RED_SUBTRACT`, and `RED_ADD_GREEN_SUBTRACT` are the only late-stage
  patterns. Color meaning always also uses R/G text, sign, and ball-kind shape.
- Every Stage 07-30 deal permits all three existing ball kinds, contains at
  least one authored special kind, retains at least one Standard, contains both
  colors, and keeps the final opposite-color Standard correction reserve.
- `resources/ui/paint_mountain_theme.tres` remains the only font, palette,
  focus, and semantic style owner. Shared component scripts/scenes own their
  behavior and dimensions. Screens only compose them.
- The complete 0-100 `ScoreScale` is preserved. Compact Briefing uses the live
  vertical preset so stage identity and score never compete for one row.
- Persistent gameplay, Briefing, Stage Select, and Result do not add decorative
  cards, panels, sheets, or explanatory prose. Pause and Settings may retain one
  interruption surface because they block gameplay input.
- One browser-control stack is used for the final live Web journey. A task-owned
  server under `D:\npjt` must use the fastrun manager's `codex` lane after
  loading the repository port guard.

Destructive or irreversible actions:

- The active catalog pointer may move from a newly verified content-addressed
  v12 bundle only after the complete staged bundle verifies. The immutable v11
  bundle remains recoverable and is not edited or deleted.
- No existing UI scene or script is deleted by this contract.

Exact actions requiring owner or user approval:

- Dependency, plugin, font, asset-pack, ball-kind, or action additions;
  destructive work outside the named generated catalog promotion; public itch
  publication or any remote release mutation.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| Current UI quality | The current Windows release audit is 78/100 and contains 16 uncropped full-viewport states. Compact Briefing is the only blocking overlap; queue detail, Shot Follow CTA, compact type, and Pause density are the remaining P1/P2 defects. | `docs/reports/ui-refinement-audit-2026-08-20/index.html`, `.agents/evidence/2026-08-20-full-ui-audit/` | Preserve the theme and fix the named states in shared owners only. | 2.1-3.3, 5.4 |
| Briefing overlap | `HudRootLayout` selects a horizontal summary scale in every Briefing and places it at the same compact top-left used by `TopStatusBar`. | `src/ui/hud/hud_root_layout.gd`, `src/ui/hud_controller.gd`, 640x360 capture 13 | Compact Briefing uses the shared vertical scale below a reduced stage identity; standard Briefing keeps the horizontal summary. | 2.1 |
| Ball detail | `BallQueue` owns one custom detail but its 14 px type is right-aligned across a 420 px owner, visually detached from the active token and half-sized after compact window scaling. | `ball_queue.gd/.tscn`, `ball_queue_token.gd`, capture 05 | Anchor a one- or two-line minimum-16-physical-pixel equivalent detail directly below the active token; hover/focus/press remain equivalent and native tooltips remain disabled. | 2.2 |
| Shot Follow obstruction | `ReturnToCannon` is a 240x52 centered text action over the observed projectile/terrain contact. | `hud.tscn`, `hud_controller.gd`, capture 07 | Reuse `ActionControl` as a compact icon-led safe-edge action at bottom-right; keep visible Korean text only when it fits without occupying the observation center. | 2.3 |
| Compact screen readability | Stage rule, Result contributions/actions, and Settings group context render too small or disappear below the fold at 640x360. | captures 12, 15, 16; `StageSelectScreen`, `ResultSummary`, `SettingsScreen` | Add shared compact type/spacing presets, preserve essential values, and verify focus-follow in Settings; do not create cards or screen-local StyleBoxes. | 3.1-3.3 |
| Pause density | The one interruption surface is valid but taller than its content and the background Gear remains visible under dimming. | `pause_overlay.tscn/.gd`, `HUDController`, capture 08 | Make the surface content-fit and hide the background settings Gear for Pause/Settings, restoring it on return. | 3.3 |
| Current stage quality | The stage audit is 63/100: late rules use an unrelated five-stage cycle, bands change every six stages without score-distribution evidence, ten stages have a direct zero color, and all late deals require both special kinds. | `docs/reports/stage-design-analysis-2026-08-20/index.html`, materializer, all-stage tests | Preserve Stage 01-06; align Stage 07-30 with four six-stage chapters and remove all late neutral rules. | 1.1-1.4, 4.1-4.2 |
| Chapter structure | Mechanism counts already change at 7/13/19/25 and route/shot/time steps occur inside those ranges. | `StageProgressionData` | Use five chapters total: 01-06 introduction, 07-12 ball-role consolidation, 13-18 polarity control, 19-24 route/mechanism combination, 25-30 mastery. | 1.2, 1.4 |
| Late rule and ball table | The current late table is implicit formula code. | `StageCatalogMaterializer._materialize_target_band_rule()` | Move late challenge intent to one typed owner with an explicit 24-row table. Chapter roles use the table below; all kinds remain allowed and the required special column varies by stage. | 1.2 |
| Band calibration | Current structural tests validate 480 deals but no physical per-stage final-score distribution. The new v11 default/New Deal baseline completed 48 authoritative Results and cleared 17; Stage 18-30 sampled scores were 0.6-9.0, contradicting the first unmeasured late-band draft. | `all_stage_target_band_rule_test.gd`, `prototype_playable_witness_test.gd`, `../evidence/2026-08-20-stage-ui-production-refinement/v11-score-baseline.json` | Use the evidence-adjusted initial bands below, then allow one v12 measured calibration pass: keep width 4 and move endpoints by at most 2 points. Replan rather than silently widening beyond that bound. | 1.1, 4.1 |
| Human balance | No human sessions measure misunderstanding, retries, or perceived difficulty. | stage audit limitation | Automated evidence may prove structure, runtime scoring, and bounded clear witnesses only. Record human playtest as a separate follow-up; never label it complete balance. | 4.2, 6.1 |
| Existing Web latency work | The superseded plan already proves bounded paint-command age, deterministic paint bytes, exports, and static Web validation. Only the live browser journey remains open because the prior native bridge was unavailable. | superseded ExecPlan Phases 6, 8, 9, 10 and related evidence | Preserve the optimization, rerun regression checks once after final inputs, and carry the live Web task unchanged. Do not publish. | 5.3, 5.5 |

Locked provisional Stage 07-30 table. Bands may change only through the bounded
single calibration pass in Task 4.1. `B` means Impact Burst, `S` means Apex
Split, and `B+S` means both must occur in the finite root deal.

| Stage | Chapter role | Score pattern | Initial band | Required special |
| --- | --- | --- | --- | --- |
| 07 | broad-paint consolidation | R+ G+ | 8-12 | B |
| 08 | branch-paint consolidation | R+ G+ | 9-13 | S |
| 09 | Green polarity practice | G+ R- | 7-11 | B |
| 10 | Red polarity practice | R+ G- | 5-9 | S |
| 11 | Green combination | G+ R- | 7-11 | B+S |
| 12 | Red chapter mastery | R+ G- | 9-13 | B+S |
| 13 | Green route control | G+ R- | 6-10 | B |
| 14 | Red route control | R+ G- | 6-10 | S |
| 15 | two-color recovery | R+ G+ | 9-13 | B+S |
| 16 | Green seven-shot control | G+ R- | 7-11 | S |
| 17 | Red precision control | R+ G- | 3-7 | B |
| 18 | three-route chapter mastery | R+ G+ | 1-5 | B+S |
| 19 | broad five-mechanism plan | R+ G+ | 1-5 | B |
| 20 | Green branch selection | G+ R- | 0.5-4.5 | S |
| 21 | Red rebound selection | R+ G- | 1-5 | B |
| 22 | Green mixed mechanism plan | G+ R- | 1-5 | B+S |
| 23 | Red mixed mechanism plan | R+ G- | 3-7 | B+S |
| 24 | five-mechanism mastery | R+ G+ | 1-5 | B+S |
| 25 | Green mastery opening | G+ R- | 3-7 | B |
| 26 | Red mastery opening | R+ G- | 0.5-4.5 | S |
| 27 | two-color recovery mastery | R+ G+ | 4-8 | B+S |
| 28 | Green full-system mastery | G+ R- | 2-6 | B+S |
| 29 | Red full-system mastery | R+ G- | 2-6 | B+S |
| 30 | final three-ball mastery | R+ G+ | 4-8 | B+S |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership,
  safety, and validation decision is closed.
- The shared Godot 4.7.1 runtime, catalog builder, tests, release presets,
  capture runner, current audit evidence, and current primary/external research
  are available. No dependency or bootstrap is required.
- Prior external research already covers the UI and progression decisions used
  here. Current source and rendered evidence are now the stronger evidence
  layer, so no additional Web research is required for implementation.
- Remaining choices are implementation-local geometry, shared Theme variation
  names, and values inside the explicit one-pass band calibration bound.

## Tasks

### Phase 1: Baseline and authored stage challenge contract

Goal: replace the implicit late-stage formula with explicit, versioned, testable
chapter intent without changing Stage 01-06 or generated world geometry.

Preconditions:

- The v11 catalog verifies, the current worktree is inspected, and unrelated
  user changes remain untouched.

Source owners: `src/stage_generation/stage_catalog_materializer.gd`,
`src/stage_generation/stage_progression_data.gd`,
`src/stage_generation/stage_generation_contract.gd`,
`src/ball/ball_deal_profile.gd`, `src/ball/ball_deal_generator.gd`,
`scripts/build_stage_catalog.gd`

- [x] **1.1 Record the current physical score baseline.**
  - Change: extend the existing playable-witness runner only enough to accept a
    requested deal seed, then run Stage 07-30 with the v11 default and first New
    Deal seed. Save compact machine-readable R/G/score, per-shot score, clear,
    and duration evidence under the task evidence directory.
  - Accept: 48 deterministic physical runs finish and the evidence distinguishes
    sampled results from structural validity and human balance.
- [x] **1.2 Add the explicit five-chapter challenge owner.**
  - Change: add one typed stage-challenge progression owner for the locked
    24-row table; make the materializer consume it; preserve the six exact
    introductory rows; require no zero-weight color after Stage 06; apply the
    stage-specific special-kind column without changing deal capacity rules.
  - Accept: every Stage 07-30 row matches this contract, both colors have a
    non-zero direct weight, each deal contains its authored required special(s),
    and the final two correction Standards remain opposite colors.
- [x] **1.3 Build and atomically promote immutable catalog v12.**
  - Change: increment the generation contract, dry-build from verified v11,
    verify the staged content-addressed v12 bundle, compare v11/v12 non-rule
    payloads, and only then publish the catalog pointer.
  - Accept: all 30 v12 stages validate; terrain/layout/routes/mechanisms/
    decorations/entry witnesses remain equivalent; the v11 bundle is unchanged;
    interrupted or invalid staging cannot replace the pointer.
- [x] **1.4 Record chapter and terminology truth.**
  - Change: update source brief supersession, design spec, technical ownership,
    implemented-status record, and tests so “Paint Score,” “contribution,”
    “required kind,” five chapters, and the Stage 01-06 preservation boundary
    have one consistent meaning. Remove stale scalar-coverage statements.
  - Accept: docs agree with runtime and do not claim that structural deals or
    automation prove player difficulty or fun.

Batch gate:

- Run the catalog dry build/check, all-stage rule/deal tests, bundle migration
  comparison, and representative Stage 06/07/12/18/24/30 runtime smoke once.

### Phase 2: Shared live-HUD correction

Goal: make Briefing, Aim, queue detail, and Shot Follow clear at standard and
compact sizes while keeping the mountain and projectile unobstructed.

Preconditions:

- Phase 1 catalog and rule truth passes so UI fixtures use final score signs,
  bands, and deal requirements.

Source owners: `resources/ui/paint_mountain_theme.tres`,
`scenes/ui/components/ball_queue*.tscn`, `src/ui/components/ball_queue*.gd`,
`scenes/ui/components/score_scale.tscn`, `src/ui/components/score_scale.gd`,
`scenes/ui/hud/hud.tscn`, `src/ui/hud/hud_root_layout.gd`,
`src/ui/hud_controller.gd`, `scenes/ui/components/action_control.tscn`

- [x] **2.1 Remove the compact Briefing collision.**
  - Change: let `HudRootLayout` own a distinct compact Briefing composition:
    reduce nonessential mode copy, use the shared vertical 0-100 scale below
    stage identity, keep the terrain visible, and keep Back/Start at the safe
    lower edge.
  - Accept: Stage identity, current score, R/G contributions, all five ticks,
    target band, queue, Gear, and actions are bounded and pairwise non-overlapping
    at 640x360 Korean/English and 1280x720.
- [x] **2.2 Attach readable queue detail to the active ball.**
  - Change: enhance `BallQueue` and `BallQueueToken` shared compact presets so
    tokens and R/G signs remain legible and the one custom description appears
    directly below its active token in one or two lines. Keep hover, focus,
    press/pin, Escape dismissal, and accessibility text equivalent.
  - Accept: no white card/section or native duplicate tooltip appears; detail is
    at least 16 physical pixels at 640x360, stays inside the safe viewport, and
    never overlaps the queue or top status row.
- [x] **2.3 Move Shot Follow return out of the observation center.**
  - Change: add a compact preset to the existing `ActionControl` use and place
    Return to Cannon at the lower safe edge in `HudRootLayout`; keep one clear
    focusable action and preserve its localized/accessibility copy.
  - Accept: the root ball, projected contact, and central terrain are clear at
    both named sizes; the action remains discoverable by pointer and keyboard.

Batch gate:

- Run shared UI ownership, queue interaction, score-scale, responsive HUD, and
  Cannon Focus composition tests; capture compact Briefing, queue detail, Aim,
  and Shot Follow from the current debug runtime for visual correction.

### Phase 3: Shared compact screen and interruption correction

Goal: keep essential stage, result, and settings information readable at the
small viewport and make Pause a tight, unambiguous interruption.

Preconditions:

- Phase 2 shared Theme and compact primitives are stable.

Source owners: `resources/ui/paint_mountain_theme.tres`,
`src/ui/screens/stage_select_screen.gd`, `src/ui/components/stage_rail.gd`,
`src/ui/components/result_summary.gd`, `src/ui/hud/result_panel.gd`,
`src/ui/screens/settings_screen.gd`, `src/ui/screens/pause_overlay.gd`,
`src/ui/hud_controller.gd`

- [x] **3.1 Raise compact Stage Select rule and rail readability.**
  - Change: use shared compact world-readout and rail presets, retain the actual
    selected terrain, prioritize stage number, target band, R/G signs, shots,
    and Start, and move lower-value detail to tooltip/accessibility copy.
  - Accept: the selected terrain stays dominant; essential rule and stage nodes
    are comfortably legible and bounded at 640x360 without a card or panel.
- [x] **3.2 Raise compact Result hierarchy.**
  - Change: enhance `ResultSummary` and shared action compact presets so signed
    score, complete scale, R/G contributions, stars/time/shots, and primary/
    secondary actions remain readable; remove only redundant prose.
  - Accept: Clear and Failure share one hierarchy, negative values remain
    truthful, all score endpoints and actions are bounded, and no result panel
    or explanatory body is introduced.
- [x] **3.3 Tighten Settings and Pause interruption behavior.**
  - Change: make Settings compact group headings and current controls readable,
    keep footer actions visible, verify scroll follows keyboard focus, make the
    Pause surface content-fit, and hide the background Gear whenever Pause or
    Settings blocks gameplay.
  - Accept: every Settings control is reachable by keyboard at 640x360, focus
    scrolls it into view, Pause contains no excess blank height, and background
    Gear is restored only after the interruption closes.

Batch gate:

- Run screen responsive/layout, focus, locale, settings persistence, Pause, and
  result tests; capture Stage Select, Settings, Pause, Clear, and Failure at
  640x360 and 1280x720.

### Phase 4: Measured band calibration and bounded witnesses

Goal: use physical execution to adjust the authored bands once and separate
automated reachability evidence from future human balance evidence.

Preconditions:

- The v12 rule/deal contract and final UI truth are active.

Source owners: `tests/prototype_playable_witness_test.gd`,
`tests/target_band_stage_runtime_smoke_test.gd`, task-owned measurement runner,
`src/stage_generation/stage_challenge_progression.gd`

- [ ] **4.1 Measure v12 and perform at most one bounded band calibration.**
  - Change: run the same 48 physical default/New Deal samples on v12; compare
    score spread and clear outcomes with v11; adjust per-stage endpoints once
    only when the sampled center misses the authored band, keeping width 4-6
    and each endpoint within 2 points of the locked initial table; rebuild and
    reverify the catalog if any value changes.
  - Accept: evidence records before/after values, rules, deals, samples, and the
    exact reason for every accepted or rejected endpoint change. No band is
    widened or moved to disguise a missing runtime path.
- [ ] **4.2 Prove representative chapter clear witnesses.**
  - Change: keep Stage 06 as the preserved boundary and require at least one
    deterministic physical clear witness for Stage 12, 18, 24, and 30, including
    settled per-shot scores and authoritative Result. Record alternate sampled
    outcomes without calling them failures of structural validity.
  - Accept: five boundary/mastery stages reach real target paint and Result;
    each late chapter has one bounded clear witness; the evidence explicitly
    states that human retry rate, comprehension, and fun remain unmeasured.

Batch gate:

- Rerun the all-stage rule/deal test, migration comparison, representative
  runtime smoke, and chapter witness test only after final calibrated inputs.

### Phase 5: Quality, production, render, and inherited Web closure

Goal: validate the combined stage/UI result on final inputs and inspect actual
production pixels without publishing.

Preconditions:

- Phases 1-4 pass and source inputs are frozen.

Source owners: `scripts/test.ps1`, `scripts/verify.ps1`, `export_presets.cfg`,
`src/delivery/delivery_capture_runner.gd`, `scripts/verify-web-release.ps1`

- [ ] **5.1 Run the diff-scoped codebase quality audit.**
  - Change: inspect shared UI, stage challenge, catalog migration, tests, and
    docs for responsibility creep, competing owners, catch-all expansion,
    contract breaks, and untested reachable failures; apply only small safe
    task-owned corrections.
  - Accept: no second UI style, score, paint, stage-state, or stage-challenge
    owner exists and no public/shared contract changed without a guard.
- [ ] **5.2 Run focused and broad project gates once.**
  - Change: run changed focused tests, then `scripts/test.ps1` and
    `scripts/verify.ps1` once after final inputs freeze.
  - Accept: all checks pass with no new parse/import/runtime errors; a failure
    is rerun only after a relevant fix.
- [ ] **5.3 Export and statically verify current production artifacts.**
  - Change: create fresh Windows and Web release exports, run the project Web
    verifier, record sizes/hashes, and confirm the completed paint queue-age and
    deterministic-byte regression guards still pass.
  - Accept: release artifacts are current, static Web limits pass, and the
    public itch build remains untouched.
- [ ] **5.4 Capture and inspect all critical full viewports.**
  - Change: create one task-owned background capture batch with no crops for
    Stage Select, Briefing, Aim, queue detail, Map, Shot Follow, Pause, Settings,
    Clear, and Failure at 1280x720 plus every affected compact state at 640x360;
    include Stage 07/12/18/24/30 rule/queue/result representatives.
  - Accept: original-size inspection shows no overlap, clipping, detached queue
    detail, central CTA, unreadable compact rule/contribution, excess Pause
    height, hidden terrain, wrong sign, neutral late color, or incomplete scale.
- [ ] **5.5 Complete the inherited live built-Web journey.**
  - Change: after loading the port guard, reuse/start the final built Web app on
    the assigned codex lane and use one browser-control stack for Stage
    03/07/18/30 real-fire journeys. Inspect paint while balls traverse terrain,
    queue/rule truth, Result, console, and network health; stop task-owned
    helpers afterward.
  - Accept: no seconds-late paint tail, stale artifact, missing required ball,
    wrong color sign, relevant console/network error, or scale/layout regression
    appears. If the trusted browser transport is still unavailable, record this
    as the sole external blocker and do not convert static evidence into a live
    browser pass.

### Phase 6: Durable closure, commits, and push

Goal: make the final implementation, evidence, and project memory agree.

Preconditions:

- Every locally executable Phase 5 gate passes.

Source owners: this plan, `.agents/Documentation.md`,
`.agents/design/UIUX_GUIDELINES.md`, `docs/design-spec.md`,
`docs/technical-architecture.md`, `docs/test-checklist.md`, task evidence

- [ ] **6.1 Update durable truth and evidence indexes.**
  - Change: record final catalog identity, stage table/calibration, UI behavior,
    artifact hashes, screenshot index, automated evidence limits, and any live
    Web blocker in their existing owners.
  - Accept: current runtime, docs, reports, plan, and evidence do not contradict
    each other; the pre-change reports remain historical audit evidence.
- [ ] **6.2 Commit and push scoped work.**
  - Change: create coherent task-owned commits with short explanatory bodies,
    exclude unrelated changes, push the current branch, and confirm status.
  - Accept: every task-owned change is committed and pushed; the worktree is
    clean except for explicitly named unrelated user files.
- [ ] **6.3 Close the execution contract.**
  - Change: check every completed task and set this plan to `done` only if the
    inherited live Web journey also passes. Otherwise leave it `active` with
    5.5 as the sole unchecked task and an exact resumption instruction.
  - Accept: plan state truthfully matches the final evidence.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner stage loop | relevant rule/deal/materialization test through `$env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/<test>.gd` | after a stage owner changes | that owner or its fixture changes |
| Inner UI loop | relevant shared component/layout test through the same Godot command shape | after a shared UI owner changes | that owner, Theme, locale, or fixture changes |
| Stage phase gate | catalog dry build/check, v11/v12 migration comparison, all-stage rules/deals, representative runtime smoke | after Phase 1 and after the single Phase 4 calibration | a stage/catalog input changes |
| UI phase gate | shared ownership, queue, scale, HUD/screen responsive, result, Settings, and Pause tests plus one debug capture batch | after Phases 2-3 | a UI/Theme/copy input changes |
| Final gate | code quality audit, `scripts/test.ps1`, `scripts/verify.ps1`, Windows/Web release exports, static Web verifier, production capture batch, live Web journey | after all source inputs freeze | a final-gate input changes |

Validation rules:

- Run the least expensive check that can prove the current claim.
- The 48-run physical sweeps are costly. Run once for v11, once for initial
  v12, and one final representative gate only if calibration changes inputs.
- Use original full-view screenshots for pixel claims; use crops only for
  internal diagnosis and never as the final evidence set.
- `scripts/verify.ps1` runs once when the implementation is substantially
  complete and again only if a later source, project setting, export input, or
  test owned by this task changes.
- Record known warnings once. Do not rerun a passing gate for reassurance.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain approval when the correction changes product, architecture, dependency, safety, or evidence scope | Do not improvise a new stage loop or UI system |
| A v12 sample needs a band move greater than 2 points or width other than 4 | keep the authored value, record the miss, and replan the stage/aim/deal rather than making the target trivial | calibration cannot hide an unproven runtime path |
| A chapter mastery stage has no clear witness after the one calibration | preserve structural validity and stop the clear claim; diagnose aim/deal/stage interaction separately | do not claim balance or widen without evidence |
| Compact type cannot be made readable without hiding an essential value/action | retain the essential value/action and reflow shared composition; escalate only if the supported 640x360 contract itself must change | do not silently drop score endpoints, queue, Fire, or navigation |
| A shared component change breaks another state | correct the shared preset and rerun the affected phase gate | do not add a screen-local clone |
| Catalog staging or verification fails | leave the v11 pointer active and retain staging evidence | never partially promote or edit the immutable bundle |
| Trusted browser control is unavailable | finish all local/static gates, record the exact transport blocker, and leave only Task 5.5 open | do not use two browser stacks or claim a live pass |
| Public itch proof/publication is requested | stop and obtain explicit authorization after presenting the local artifact/hash/evidence | no upload or remote mutation under this contract |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 4 measured band calibration and bounded witnesses.
- Next task: Task 4.1, measure the v12 physical score distribution once.
- Last completed gate: Phases 2-3 pass focused Korean/English layout, focus,
  shared-owner, score, queue, Pause, Settings, and gameplay-flow tests. Current
  debug renders under
  `../evidence/2026-08-20-stage-ui-production-refinement/ui-preview/` prove the
  compact vertical Briefing scale, attached queue detail, one-row Cannon Focus,
  lower-right Shot Follow return, terrain-backed Stage Select, compact Settings,
  content-fit Pause, and readable Result hierarchy before production export.
  The explicit typed 24-row challenge resource now drives Stage 07-30 with no
  direct neutral color and stage-specific special requirements. Immutable
  catalog v12 manifest `5e54530e...68fcf70` is active; the 92-file v11 bundle
  remains unchanged. All 30 v11/v12 world/layout comparisons, 480 deals, and
  Stage 01-07 plus Stage 12/18/24/30 runtime smoke pass.
- Update rule: after each phase checkpoint, record concise evidence, check its
  tasks, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and every named guard/phase/final gate passes.
- Stage 01-06 are unchanged; Stage 07-30 have no direct neutral color and match
  the final explicit chapter table and required-kind evidence.
- Automated samples and clear witnesses are recorded without being mislabeled
  as human balance or fun evidence.
- Current production full-view captures prove the named standard and compact
  states, and current release artifacts/hashes are recorded.
- Durable docs agree with runtime, task-owned commits are pushed, and no
  placeholder or unresolved material decision remains.
- Frontmatter changes to `done` only when Task 5.5 also passes. If browser
  transport remains unavailable, the plan remains `active` solely for 5.5.

Replan when:

- A material discovery invalidates the locked stage table, calibration bound,
  shared-owner design, safety boundary, or required validation path.

Do not replan or stop for:

- Implementation-local layout geometry, shared Theme variation names, or test
  fixture mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
