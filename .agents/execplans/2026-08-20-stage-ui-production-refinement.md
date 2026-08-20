---
type: plan
status: done
created: 2026-08-20
last_reviewed: 2026-08-21
scope: correct the audited compact UI defects and replace the unmeasured Stage 07-30 rule cycle with a statically certified five-chapter Red/Green progression
supersedes:
  - 2026-08-20-cross-stage-ui-theme.md
related:
  - ../PLANS.md
  - ../../docs/reports/ui-refinement-audit-2026-08-20/index.html
  - ../../docs/reports/stage-design-analysis-2026-08-20/index.html
  - ../../docs/reports/itch-paint-latency-2026-08-20/index.html
  - ../../docs/reports/ui-refinement-2026-08-21/index.html
  - ../../docs/reports/stage-design-analysis-2026-08-21/index.html
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../Documentation.md
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../evidence/2026-08-20-full-ui-audit/README.md
  - ../evidence/2026-08-21-stage-ui-final/README.md
---

# Stage and UI Production Refinement - Execution Contract

Paint Mountain will retain the selected Cannon Focus theme and the completed
continuous-paint Web latency correction, then correct the defects visible in
the current full-screen audit and replace the late-stage five-rule loop with a
statically certified five-chapter progression. Stage 01-06 remain exact. Stage 07-30 use
both Red and Green as direct score inputs, stage-specific special-ball
requirements, and per-stage target bands. All visual changes stay in shared
Theme, component, and layout owners; no screen-local UI system is introduced.

## Purpose

- Objective: turn the two 2026-08-20 audits into one executable contract and
  implement every locally actionable P0/P1 issue without reopening accepted
  world art, physics, or paint ownership.
- Deliverable: an immutable v13 stage catalog with all-stage static feasibility
  sidecars, corrected
  shared UI at 1280x720 and 640x360, current Windows/Web release artifacts, and
  full-viewport proof for every named critical state.
- Completion state: all task checkboxes and gates pass, the inherited built-Web
  live journey is either proven or remains the sole explicit external blocker,
  the plan records truthful limits, scoped commits are pushed, and the
  task-owned worktree is clean.

## Scope and Boundaries

In scope:

- Stage 07-30 color-score patterns, target bands, deal-kind requirements,
  chapter intent, immutable catalog migration, structural deal tests, pure-data
  feasibility certificates, and one bounded runtime regression per shared ball
  mechanic rather than per-stage automated play.
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
  byte- or checksum-equivalent through the v12-to-v13 migration.
- `StageClearFeasibilityAnalyzer` is an offline pure-data owner. It may inspect
  `StageData`, `BakedStageLayoutData`, the hydrated immutable topology,
  `ProjectileRangeConstraint`, ball capability declarations, and generated
  deals. It must not instantiate gameplay, a physics world, `StageController`,
  projectiles, or `PaintSystem`. Its content-addressed sidecar certificate is
  verification evidence, not a second runtime score or paint authority.
- A late challenge's `required_kinds` means those root kinds must occur in the
  finite deal and at least one accepted paint command from each required kind
  must be recorded before clear. Stage 07-30 clear also requires nonzero target
  paint from both Red and Green. These are `StageController` checks over
  authoritative paint and shot observations, not screen-owned rules. They do
  not create a fourth ball type or change Stage 01-06.
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
  v13 bundle only after the complete staged bundle and all feasibility sidecars
  verify. The immutable v12 bundle remains recoverable and is not edited or
  deleted.
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
| Band calibration | Current structural tests validate 480 deals but no physical per-stage final-score distribution. The v11 default/New Deal baseline completed 48 authoritative Results and cleared 17; the v12 pass completed 48 Results and cleared 46 without moving a band. | `all_stage_target_band_rule_test.gd`, historical `prototype_playable_witness_test.gd`, `../evidence/2026-08-20-stage-ui-production-refinement/v11-score-baseline.json`, `v12-score-calibration.json` | Retain the consumed v12 bands. Future catalog acceptance uses a reproducible score-domain certificate rather than repeated model-driven physical sweeps. | 1.1, 4.1, 4.3 |
| False-positive diversity clear | The v12 sample reached 46/48 clears, but Stage 12 cleared after one Red-only shot while its authored Burst+Split and Green subtractive role were unused. Band reachability alone therefore does not satisfy the user's Red/Green and varied-ball directive. | `../evidence/2026-08-20-stage-ui-production-refinement/v12-score-calibration.json` | Keep the measured bands unchanged and add a v13 late-stage participation requirement over authoritative target-color coverage and shot observations. Certify its logical inputs statically; do not tune bands by repeatedly playing stages. | 4.2-4.4 |
| Per-stage runtime cost | Replaying two deals for every late stage exercises the same shared physics and paint implementations 48 times, produces seed-specific outcomes, and still cannot prove human balance. The existing target rasterizer already admits every target pixel through the pure ballistic envelope, while the baked layout retains physical default and summit entry witnesses. | `TargetMaskRasterizer`, `ProjectileRangeConstraint`, `BakedStageLayoutData`, Godot 4.7 `PhysicsDirectSpaceState3D` documentation | Add one immutable sidecar per stage that binds target/layout hashes, full target ballistic-envelope admission, connected target structure, score-domain witness, 16 deterministic deals, both colors, correction reserve, and required-kind capability coverage. Keep runtime checks only at shared mechanic and platform boundaries. | 4.3-4.4, 5.5 |
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
- The static certificate proves rule/data/ballistic-envelope feasibility, not
  exact rigid-body trajectories, fun, retry rate, or human comprehension. Those
  evidence boundaries are locked and cannot be weakened in reports.
- Remaining choices are implementation-local certificate serialization,
  checksumming, and shared Theme variation names.

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

### Phase 4: Static feasibility certification and bounded mechanic evidence

Goal: make catalog acceptance a fast, reproducible pure-data proof for all 30
stages and retain runtime only where shared physics behavior or platform timing
cannot be established statically.

Preconditions:

- The v12 calibration evidence and final UI truth are available.

Source owners: `src/stage_generation/stage_clear_feasibility_analyzer.gd`,
`src/stage_generation/stage_clear_feasibility_certificate.gd`,
`src/stage_generation/stage_catalog_bundle_store.gd`,
`scripts/build_stage_catalog.gd`, `tests/stage_clear_feasibility_test.gd`,
`tests/target_band_stage_runtime_smoke_test.gd`

- [x] **4.1 Measure v12 and perform at most one bounded band calibration.**
  - Change: run the same 48 physical default/New Deal samples on v12; compare
    score spread and clear outcomes with v11; adjust per-stage endpoints once
    only when the sampled center misses the authored band, keeping width 4-6
    and each endpoint within 2 points of the locked initial table; rebuild and
    reverify the catalog if any value changes.
  - Accept: evidence records before/after values, rules, deals, samples, and the
    exact reason for every accepted or rejected endpoint change. No band is
    widened or moved to disguise a missing runtime path.
- [x] **4.2 Require real late-stage color and special-ball participation.**
  - Change: add typed Stage 07-30 clear requirements to generated `StageData`;
    require nonzero Red and Green target coverage and a recorded target-coverage
    change from every stage-specific required special kind. `StageController`
    evaluates the requirements from `PaintSystem` and sealed `ShotObservation`
    data, publishes readiness/result truth, and keeps Stage 01-06 unchanged.
  - Accept: an in-band Red-only or Standard-only late attempt cannot Finish or
    clear; both-color and required-kind participation plus an in-band score can.
    The HUD only displays supplied readiness/result facts.
- [x] **4.3 Certify all-stage clear feasibility without gameplay runtime.**
  - Change: build `StageClearFeasibilityCertificate` sidecars from immutable
    stage/layout inputs only. For every stage, recompute target connectivity,
    bind the generator's fail-closed full-target `ProjectileRangeConstraint`
    contract plus deterministic boundary/center samples, and bind target,
    coverage, layout, rule, capability, and deal checksums; construct an
    in-band Red/Green score-domain witness; and validate 16 deterministic deals
    for both colors, Standard correction reserve, required special kinds, and a
    minimum shot-cover selection. Include sidecar descriptors in the
    content-addressed manifest and atomically promote v13 with v12 world/layout
    content unchanged.
  - Accept: a single headless pure-data test validates 30/30 certificates and
    480/480 deals without instantiating gameplay, a physics world, projectiles,
    `StageController`, or `PaintSystem`; tampering with a rule, deal profile,
    target mask, coverage metadata, ball capability, or certificate fails
    bundle verification.
- [x] **4.4 Keep only shared-mechanic runtime boundaries.**
  - Change: replace chapter-by-chapter clear witnesses with the existing bounded
    Standard contact, Impact Burst, Apex Split, finish-readiness, and
    representative target-band runtime smoke checks. Remove the 48-run sweep
    from the active gate; retain v11/v12 JSON only as historical calibration
    evidence.
  - Accept: each shared ball/paint/finish behavior has one focused runtime
    regression, Stage 01-06 behavior remains unchanged, and no active gate
    launches one gameplay attempt per stage. Reports distinguish static
    feasibility from exact physics and human balance.

Batch gate:

- Run catalog dry build/check, v12/v13 migration comparison, the all-stage
  static feasibility test, and the small shared-mechanic runtime set once after
  final catalog inputs.

### Phase 5: Quality, production, render, and inherited Web closure

Goal: validate the combined stage/UI result on final inputs and inspect actual
production pixels without publishing.

Preconditions:

- Phases 1-4 pass and source inputs are frozen.

Source owners: `scripts/test.ps1`, `scripts/verify.ps1`, `export_presets.cfg`,
`src/delivery/delivery_capture_runner.gd`, `scripts/verify-web-release.ps1`

- [x] **5.1 Run the diff-scoped codebase quality audit.**
  - Change: inspect shared UI, stage challenge, catalog migration, tests, and
    docs for responsibility creep, competing owners, catch-all expansion,
    contract breaks, and untested reachable failures; apply only small safe
    task-owned corrections.
  - Accept: no second UI style, score, paint, stage-state, or stage-challenge
    owner exists and no public/shared contract changed without a guard.
- [x] **5.2 Run focused and broad project gates once.**
  - Change: run changed focused tests, then `scripts/test.ps1` and
    `scripts/verify.ps1` once after final inputs freeze.
  - Accept: all checks pass with no new parse/import/runtime errors; a failure
    is rerun only after a relevant fix.
- [x] **5.3 Export and statically verify current production artifacts.**
  - Change: create fresh Windows and Web release exports, run the project Web
    verifier, record sizes/hashes, and confirm the completed paint queue-age and
    deterministic-byte regression guards still pass.
  - Accept: release artifacts are current, static Web limits pass, and the
    public itch build remains untouched.
- [x] **5.4 Capture and inspect all critical full viewports.**
  - Change: create one task-owned background capture batch with no crops for
    Stage Select, Briefing, Aim, queue detail, Map, Shot Follow, Pause, Settings,
    Clear, and Failure at 1280x720 plus every affected compact state at 640x360;
    include Stage 07/12/18/24/30 rule/queue/result representatives.
  - Accept: original-size inspection shows no overlap, clipping, detached queue
    detail, central CTA, unreadable compact rule/contribution, excess Pause
    height, hidden terrain, wrong sign, neutral late color, or incomplete scale.
- [x] **5.5 Complete the inherited live built-Web journey.**
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

- [x] **6.1 Update durable truth and evidence indexes.**
  - Change: record final catalog identity, stage table/calibration, UI behavior,
    artifact hashes, screenshot index, automated evidence limits, and any live
    Web blocker in their existing owners.
  - Accept: current runtime, docs, reports, plan, and evidence do not contradict
    each other; the pre-change reports remain historical audit evidence.
- [x] **6.2 Commit and push scoped work.**
  - Change: create coherent task-owned commits with short explanatory bodies,
    exclude unrelated changes, push the current branch, and confirm status.
  - Accept: every task-owned change is committed and pushed; the worktree is
    clean except for explicitly named unrelated user files.
- [x] **6.3 Close the execution contract.**
  - Change: check every completed task and set this plan to `done` only if the
    inherited live Web journey also passes. Otherwise leave it `active` with
    5.5 as the sole unchecked task and an exact resumption instruction.
  - Accept: plan state truthfully matches the final evidence.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner stage loop | relevant rule/deal/materialization test through `$env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/<test>.gd` | after a stage owner changes | that owner or its fixture changes |
| Inner UI loop | relevant shared component/layout test through the same Godot command shape | after a shared UI owner changes | that owner, Theme, locale, or fixture changes |
| Stage phase gate | catalog dry build/check, v12/v13 migration comparison, 30 static feasibility sidecars/480 deals, shared Standard/Burst/Split/finish runtime regressions | after Phase 4 certificate inputs freeze | a stage/catalog/capability input changes |
| UI phase gate | shared ownership, queue, scale, HUD/screen responsive, result, Settings, and Pause tests plus one debug capture batch | after Phases 2-3 | a UI/Theme/copy input changes |
| Final gate | code quality audit, `scripts/test.ps1`, `scripts/verify.ps1`, Windows/Web release exports, static Web verifier, production capture batch, live Web journey | after all source inputs freeze | a final-gate input changes |

Validation rules:

- Run the least expensive check that can prove the current claim.
- The completed v11/v12 48-run sweeps are historical calibration evidence and
  are not active validation gates. Do not launch per-stage gameplay sweeps.
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
| A stage cannot produce a static in-band score witness or deal cover | reject the bundle and correct its authored rule, band, or deal contract; never compensate with a seed-specific gameplay script | certificate acceptance cannot be replaced by model play |
| A static certificate passes but a shared mechanic regression fails | fix the shared mechanic or narrow the certificate claim; do not add 30 stage-specific runtime tests | runtime is reserved for physics behavior the certificate does not claim |
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
- Current phase: complete.
- Next task: none. Resume only for a new user-requested scope or public itch
  publication authorization.
- Last completed gate: Phases 2-3 pass focused Korean/English layout, focus,
  shared-owner, score, queue, Pause, Settings, and gameplay-flow tests. Current
  debug renders under
  `../evidence/2026-08-20-stage-ui-production-refinement/ui-preview/` prove the
  compact vertical Briefing scale, attached queue detail, one-row Cannon Focus,
  lower-right Shot Follow return, terrain-backed Stage Select, compact Settings,
  content-fit Pause, and readable Result hierarchy before production export.
  Task 4.1 completed 48/48 v12 Results and 46 clears without moving any band.
  The same evidence exposed a product-contract miss: Stage 12 could clear with
  Red target paint only and without using its required Burst+Split roots, so
  Phase 4 now includes the v13 participation correction before witness claims.
  The explicit typed 24-row challenge resource now drives Stage 07-30 with no
  direct neutral color and stage-specific special requirements. Immutable
  catalog v13 manifest `3dc3d250...10b35` is active; immutable catalog v12
  manifest `5e54530e...68fcf70` remains recoverable. All 30 v12/v13
  world/layout comparisons, 30 sealed static feasibility sidecars, 480 deals,
  the tamper guard, and the focused participation contract checks pass.
  A cancelled v13 48-run sweep produced no accepted evidence and is not an
  active gate.
  Standard contact paint, Impact Burst, Apex Split, finish readiness, and the
  representative Stage 01-07 plus late chapter-boundary runtime smoke all pass;
  no active test launches one gameplay attempt per stage.
  The Task 5.1 quality audit found no competing rule/UI owner and corrected one
  local failure path: locale refresh now preserves the specific disabled Finish
  reason. Its focused copy regression passes.
  `scripts/test.ps1` and `scripts/verify.ps1` pass on the frozen v13 inputs. The
  suite also corrected its generic state-lifecycle fixture to Stage 01 so the
  independent Stage 07-30 participation policy is not bypassed or duplicated.
  Fresh local Windows/Web release exports pass the static Web verifier after
  historical v9-v12 catalog bundles were excluded from production packaging.
  Web gzip is 17,483,722 bytes; the public itch build remains untouched.
  Twenty-eight final full-view production captures now cover the full primary
  and compact journeys plus late-stage representatives. Original-size review
  corrected compact top-row/Result overlap and queue-description contrast;
  the regenerated batch passes visual inspection. A final built-Web journey
  entered and fired Stage 03/07/18/30, showed paint and score after each Fire,
  returned no relevant console/network error, and exposed one Web-only missing
  glyph issue. `BallGlyphPainter` and `StageRuleSummary` now render the same
  shared vector ball shapes in Stage Select and Ball Queue; final Web Stage
  01/07/30 and current-build Stage 30 Fire rechecks pass without missing glyphs.
  Durable specs, evidence, checklist, and Korean UI/stage/latency reports now
  describe the v13 static-first boundary and final artifacts. Commits
  `f89a168`, `2348019`, `749e020`, `c3dfc6b`, and `03f0242` were pushed to
  `origin/codex/three-ball-target-band-prototype`; this closing update records
  the completed execution contract.
- Update rule: after each phase checkpoint, record concise evidence, check its
  tasks, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check and every named guard/phase/final gate passes.
- Stage 01-06 are unchanged; Stage 07-30 have no direct neutral color and match
  the final explicit chapter table and required-kind evidence.
- Static feasibility certificates and bounded shared-mechanic runtime checks are
  recorded without being mislabeled as exact per-stage physics, human balance,
  or fun evidence.
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
