---
type: plan
status: done
created: 2026-08-21
canonical_for: Execution of the user-approved 2026-08-21 Paint Mountain UIUX TO-BE images in the running Godot project
scope: Shared UI primitives, Main Menu, Stage Select plus Briefing, live gameplay HUD, Pause, Settings, Results, responsive layout, accessibility, tests, and production capture evidence
source:
  - ../../docs/source-brief.md
  - ../../docs/reports/uiux-correction-spec-2026-08-21/index.html
related:
  - ../design/DESIGN.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../Documentation.md
  - 2026-08-18-three-ball-target-band-prototype.md
  - 2026-08-20-cross-stage-ui-theme.md
  - 2026-08-20-stage-ui-production-refinement.md
---

# UIUX TO-BE Image Parity

## Purpose

Replace the current inconsistent, panel-heavy Paint Mountain interface with the
exact visual hierarchy and interaction model approved in the selected 2026-08-21
TO-BE images. This is a production Godot UI replacement, not a new mockup and
not a web prototype. The work must preserve game rules, authoritative score and
paint data, stage preparation, navigation, keyboard/gamepad access, Korean and
English localization, and the existing Windows/Web delivery paths.

The plan is complete only when each named runtime screen matches its selected
TO-BE reference in structure, emphasis, containment, alignment, and action
language at 1280x720 and 640x360, and the result is proven with separate images
from the production-style Windows build.

## Authority and verified evidence

### Product and design authority

1. The user's latest direction in the current conversation is authoritative for
   the named UI surfaces. It replaces the earlier vertical 0-100 Aim scale,
   standalone Briefing screen, text-button, and white routine-action guidance.
2. `docs/source-brief.md` owns durable product requirements. Task 5.1 records
   this latest supersession before final handoff.
3. `.agents/design/UIUX_GUIDELINES.md` and
   `.agents/design/VISUAL_REFERENCES.md` still describe the superseded vertical
   live score scale and standalone Briefing. Task 5.1 corrects those conflicts.
4. `docs/reports/uiux-correction-spec-2026-08-21/index.html` is the complete
   screen-by-screen correction specification. The selected TO-BE image files
   below are literal composition targets subject only to authoritative runtime
   data, localized strings, and responsive geometry.
5. `.agents/Documentation.md` and the current code are implemented truth. The
   historical `2026-08-21-stage-ui-final` captures prove the AS-IS state only;
   they do not prove conformance.

### Selected image set

These are the only TO-BE images used for production parity. Earlier Aim
alternatives, the old Stage Select concept, and standalone Briefing image are
rejected references and must not reappear in runtime or acceptance evidence.

| Runtime state | Selected image | SHA-256 |
| --- | --- | --- |
| Main Menu hover/focus | `01-main-menu-hover-tobe-v2.png` | `4B6EB2442BD0CD79234E5F3870041DD2C11889A69FBD5E049FE3A2F1E134B0C2` |
| Stage Select plus Briefing | `02-stage-select-briefing-tobe-v2.png` | `767B94473A1C7A786185629EE013862C0C4F0A0084059ED7A3E1FF7A0BA45FF9` |
| Aim | `04-aim-score-bar-tobe-v6.png` | `5C79D14247F553C296224C2141097C5D7B9C142328553F8372216ECD3D619875` |
| Special-ball detail | `05-ball-detail-tobe.png` | `45767BEE71FE9EF5C8AFAF93C6BAC5B6B5F7ED1690B9481968B64874D2714227` |
| Map Inspection | `06-map-tobe.png` | `C9E31569F40AB88799197D6F80006FC920F85686478AD9B492F98E8DCEC04CE8` |
| Shot Follow | `07-shot-follow-tobe.png` | `41F0A592A8C33954F62316AAE74FE4B421DA9486634C471ECC091FB0626F2989` |
| Pause | `08-pause-tobe.png` | `AFE8A0259B8A76FFFA3A2CDE8A07DCBAC7E756B87DCAA30004312F29BAC742AB` |
| Settings | `09-settings-tobe.png` | `0460700BFFAC306571EA156C8917888ACAE8453BDDF81D14FB5455BBC21ACAB8` |
| Clear | `10-clear-tobe.png` | `75A97FCF3CF6C2CA5163906FBF9BBEC83AADE76835E7053E1DBC568ABAD4456B` |
| Failure | `11-failure-tobe.png` | `6C8CECA75349C93C486DE39651151FEB51A2CB32213E46B6519B37BD5AAAD2F6` |

All files are under
`docs/reports/uiux-correction-spec-2026-08-21/assets/tobe/`.

### Local implementation evidence inspected

- Shared UI owners: `resources/ui/paint_mountain_theme.tres`, `ActionControl`,
  `ValueStepper`, `ScoreScale`, `BallQueue`, `StageRail`, `ResultSummary`, and
  the common scrims.
- Screen owners: Main Menu, Stage Select, Pause, Settings, the HUD scene and
  controller, `HudRootLayout`, Aim controls, run status, mode control, and
  Result panel.
- Application and world-preview owners: `src/app/app_root.gd`, the asynchronous
  layout/runtime preparers, `StageRuntimeArtifact`, the gameplay environment,
  and the existing noninteractive preview viewport.
- Runtime and release proof owners: `tests/capture_app_frame.gd`,
  `tests/capture_gameplay_frame.gd`,
  `src/delivery/delivery_capture_runner.gd`, `scripts/test.ps1`,
  `scripts/verify.ps1`, export presets, and prior production recapture scripts.
- Focused UI contracts: shared component ownership, essential copy,
  localization, viewport/locale responsiveness, score scale, ball queue,
  stage-rule truth, selection readiness, application flow, and delivery
  capture tests.

### External evidence decision

No new external research is required for implementation. The approved report
already records current primary accessibility, game-UI, Godot control, and
container sources and explains their applicability. The user has selected exact
local images after several reference-backed iterations; new examples cannot
override or improve that locked direction. Current runtime owners and rendered
parity are now the strongest evidence layers.

## Prior ExecPlan merge and exclusion decisions

There is no other active ExecPlan. This document becomes the single active
progress owner for the work below.

Carry forward these still-relevant local requirements from the superseded and
completed UI plans:

- use one shared Theme/component family across all UI surfaces;
- keep Stage Select responsive while asynchronous preparation runs, reuse the
  selected `StageRuntimeArtifact`, and do not commit `GameState` selection until
  Start succeeds;
- preserve authoritative target-band, signed R/G, queue, result, and localization
  data rather than reproducing it in screen scripts;
- make pointer hover, keyboard focus, and press/touch expose the same ball detail;
- preserve 1280x720 and 640x360 fit, focus visibility, state truth, Windows/Web
  release compatibility, and separate production capture evidence;
- preserve all-stage rule/data behavior and the validated stage catalog.

Do not carry forward these outdated or separately authorized tasks:

- the vertical live 0-100 `ScoreScale` and standalone Briefing presentation;
- the eight-node paging UI when it conflicts with the approved full-width stage
  line; paging may remain an internal catalog window but must not be visible;
- remote itch publication and deployed-artifact proof from
  `2026-08-18-three-ball-target-band-prototype.md`; publication still requires
  separate explicit authorization;
- human balance validation, game-rule tuning, terrain regeneration, paint or
  physics redesign, new projectile kinds, and catalog rebuilds;
- new dependencies, plugins, network services, asset packs, or a parallel UI
  renderer.

The unchecked remote publication items remain excluded, not silently completed.
The later local M9/Web journey already supersedes the old local-browser gap;
this plan reruns affected local regression paths but does not publish.

## Locked design and interaction decisions

### Shared action and icon contract

- Every action control contains no visible verb text. Its visible content is a
  semantic icon from one repository-owned monochrome family under
  `assets/ui/icons/actions/`. Use only the needed PNG members from the already
  approved Kenney Game Icons source archive whose recorded SHA-256 is
  `7A86D8D58E0B851E22004B3C70BF90B003632BBF9AC633424DAA3BB17D9E7E4E`;
  normalize size through `ActionControl`, not by redrawing screen-local icons.
  Existing approved Paint Mountain icons may be reused only when their style and
  state treatment remain coherent with that family.
- Each icon-only control keeps a localized `accessibility_name` and tooltip.
  Main Menu is the only normal screen that may reveal its localized action label:
  that label is a sibling presentation layer to the right of the icon, not text
  inside the button.
- Do not use emoji, miscellaneous Unicode symbols, CSS-like drawings,
  handcrafted SVGs, or screen-local custom icon drawing. Record every newly
  bundled archive member and its hash in `docs/asset-licenses.md`; do not import
  the complete pack.
- `ActionControl` owns semantic action kind, localized accessible copy,
  icon assignment, minimum target, readiness, selected state, and the five
  shared visual roles: Routine, Primary, Selected, Destructive, and World.
- Routine normal state is transparent. Hover and press use restrained navy/blue
  translucency; focus is the shared 2 px ring. Primary is the only filled blue
  action and is circular. Standard targets are routine 44 px and primary 56 px;
  compact targets are 40 px and 48 px.
- A screen has at most one filled-blue primary action. White containment is
  limited to Settings, genuine blocking/confirmation information, and the open
  special-ball detail card.

### Main Menu

- Keep the title and right-side prepared terrain hero. Remove every subtitle,
  tagline, meta sentence, and visible idle action label.
- Use a left vertical icon rail in order Play, Stage Select, Settings, Quit.
  Hover or focus reveals exactly the current item's localized label to the
  right using a 160 ms slide/fade; labels appear sequentially as focus moves.
  Pointer exit returns to icons only after 100 ms so moving between button and
  revealed label does not flicker.
- Preserve passive startup focus behavior, asynchronous Play readiness, retry
  behavior, keyboard order, Web Quit suppression, and preview-safe composition.

### Stage Select plus Briefing

- One screen owns selection and the complete pre-play briefing. Gameplay enters
  Aim directly; no standalone Briefing actions or separate UI screen is visible.
  `StageController` may retain its internal `BRIEFING` transition only long
  enough for `GameplayScene` to atomically enter Aiming after presentation.
- Show the actual selected prepared terrain with sky and ground using the
  existing preview viewport and gameplay environment assets. Never use a generic
  landscape image and never build a second terrain representation.
- Back is a top-left routine icon. The upper information row shows concise stage
  identity and authoritative rule summary/queue data only.
- Previous/next stage icons flank the terrain. They, stage-line click, keyboard
  navigation, and pointer drag all call one selection function. Selection
  updates preview and preparation without committing the saved selected stage.
- The StageRail spans the safe width. Its baseline is a thin neutral line;
  evenly distributed nodes are hollow neutral circles, selected is a blue
  filled/outlined circle, and stage number is below. The current viewport shows
  ten consecutive stages when available; movement at a window edge shifts the
  window without a visible page-range label or rail-owned pager buttons.
- Start is the single bottom-right blue Aim/target icon. It stays disabled with
  honest accessibility/tooltip state until the selected artifact is ready.
  No terrain blank frame or synchronous rebuild is allowed between Start and Aim.

### Live score and gameplay HUD

- Add one `AimScoreStatus` shared component. In Aim it shows only:
  1. a horizontal minimum-to-maximum success bar using the authoritative target
     band as its entire visual domain;
  2. three star-grade segments inside the band;
  3. the unclamped signed current Paint Score, with a left/right arrow when it is
     below/above the success range;
  4. a paint-drop icon plus authoritative total painted target percentage;
  5. red splat and green circle shape cues plus each signed stage weight.
- The component must preserve signed score and zero weights. Color is never the
  only cue. It contains no terrain silhouette, 0-100 axis, prose explanation,
  persistent labels, or white background.
- Map and Shot Follow retain their approved compact value-only score readout;
  they do not show Aim's range bar. Map hides Aim controls and Fire; Follow shows
  only the compact bottom-right return icon in addition to edge status.
- Preserve the approved Aim composition outside score: horizontal queue at the
  upper-right, top edge run status/settings, angle then centered Fire then power
  around the lower cannon. Fire remains the one filled blue primary.
- Finish, settings, Map selection, return, and all stepper controls become icon
  actions with transparent routine normal state. Data values and units remain
  text because they communicate state, not verbs.

### Ball detail

- `BallDetailCard` is a shared warm-white information card anchored under the
  active queue token: 296x88 with 16 px padding at standard, maximum 280 px wide
  with at least 14 physical-pixel text at compact.
- Hover, focus, and press show identical localized copy. Press pins/unpins.
  Escape dismisses. Pointer movement between token and card must not close it;
  card exit closes only when not pinned and no trigger remains active.
- The old transparent detached description label is removed. Exactly one card
  is visible and it never clips the viewport or obscures the primary action.

### Pause, Settings, and Results

- Pause uses a full navy translucent input-blocking scrim, a centered white
  title, and one centered horizontal icon rail. Resume is the only filled blue
  primary; Restart, Settings, Stage Select, and Main Menu are transparent routine
  icons. Remove the white pause sheet and all button text.
- Settings keeps one warm-white form sheet. Close is a fixed top-right X icon;
  Defaults is an undo icon beside the title. Remove the footer actions. At
  1280x720 the approved composition uses a 56 px horizontal/48 px vertical sheet
  inset, 44 px horizontal/30 px top content padding, and a 52 px column gap;
  compact uses 12 px inset/padding, one column, and scrolls content only while
  header actions stay fixed. Labels, controls, and values share column baselines
  on an 8 px grid.
- Clear and Failure share one right-side navy gradient shell and identical
  content/track/action anchors. The mountain remains the left hero. Clear uses
  Next as the single primary arrow; Failure uses Same Deal as the single primary
  retry. Other real actions are routine icons. Failure adds one concise reason/
  target-gap line immediately below score. Negative score remains unclamped.

### Layout and responsive contract

- Structural containers own internal alignment; each screen/layout owner owns
  external anchors. Components never write parent positions, and screens never
  restyle component internals.
- Use an 8 px baseline grid. Standard safe margin is 24 px and compact is 12 px.
  Shared row center and edge alignment error is at most 1 px.
- The logical baseline remains 1280x720. Physical window breakpoints drive the
  compact preset; shared density scaling keeps at least 14 px compact body text
  and 20 px key values. No child clips or crosses its viewport/surface.
- Focus order follows visible order and every reachable icon action shows the
  unobscured shared 2 px focus ring.

## Architecture and ownership

| Concern | Sole production owner | Required change |
| --- | --- | --- |
| Action icon/state contract | `ActionControl`, Theme, shared SVG assets | Replace text/glyph behavior; add semantic roles and assets |
| Main hover/focus reveal | Main Menu screen/component | Animate sibling label only; preserve app signals/readiness |
| Stage line interaction | `StageRail` | Draw line/nodes, own click/drag/focus, emit selected stage intent |
| Stage preview and preparation | `AppRoot`, existing preparers/preview viewport | Add gameplay sky/ground parity and preserve prepared artifact handoff |
| Live Aim score | new `AimScoreStatus` | Present supplied snapshot/rule data only |
| Result scale | existing horizontal `ScoreScale` | Retain result-only summary responsibility; retire vertical-live usage |
| Queue detail | `BallQueue`, new `BallDetailCard` | Own trigger/card state and accessible copy |
| Whole HUD layout/state | `HudRootLayout`, `HUDController` | Select presets, anchor components, bind authoritative state |
| Navigation and stage lifecycle | `AppRoot`, `GameplayScene`, `StageController` | Remove visible standalone Briefing without moving rule ownership |
| Pause/Settings/Result composition | respective screen/component owners | Recompose with shared action and alignment contracts |
| Durable product/design truth | source brief and design/implementation docs | Record the approved supersession and implemented status |
| Delivery proof | capture runners and task evidence | Produce separate production frames and comparison sheets |

`StageController` remains the sole owner of stage state, shots, and results.
`PaintSystem` remains the sole coverage/paint authority. UI components receive
snapshots and emit intent only. The preview reuses prepared runtime artifacts
and cannot become a gameplay or coverage owner.

## Ordered execution tasks

### Phase 1 — Shared action, icon, and Theme foundation

Goal: close the icon-only and surface rules before any screen composes them.

- [x] **1.1 Add the shared semantic icon family.** Copy only the closest matching
  white 2x PNG members (and the 1x Play member, which the archive omits at 2x)
  from the already verified Kenney Game Icons archive for
  play, back/previous, next, stage list, home, close, quit/power, finish/check,
  return-to-cannon, settings, retry/same-deal, new-deal, and defaults/undo; reuse
  the existing approved paint and target icons for Fire and Aim/Map. Preserve
  source pixels, apply state color by multiplying the white source through the
  Godot Theme, and record each
  bundled member in the asset ledger.
- [x] **1.2 Replace `ActionControl`'s text/glyph contract.** Add semantic icon and
  visual-role configuration, localized accessible name/tooltip, readiness, 44/40
  routine sizing, 56/48 primary sizing, and state forwarding. Delete
  `set_compact_glyph` and any visible action text fallback.
- [x] **1.3 Correct the shared Theme.** Add transparent Routine, blue circular
  Primary, translucent Selected, and restrained Destructive variations. Remove
  white normal surfaces from icon actions, steppers, HUD modes, Finish, and world
  quiet actions while preserving white form/input and ball-information surfaces.
- [x] **1.4 Update component contract tests.** Assert zero visible action text,
  no Unicode/emoji action glyphs, one shared icon asset family, minimum sizes,
  2 px focus, and transparent routine normal state.

Focused gate:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/shared_ui_component_ownership_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/cross_stage_ui_theme_test.gd
```

### Phase 2 — Main Menu and Stage Select plus Briefing

Goal: reproduce the first two approved TO-BE compositions and remove the
duplicate pre-play screen.

- [x] **2.1 Recompose Main Menu.** Replace the action column with icon controls
  and one reusable hover/focus reveal item; implement the 160 ms slide/fade and
  delayed close; retain readiness, retry, focus, Web Quit, and preview-safe
  behavior. Add capture hooks for idle, hover, and keyboard focus.
- [x] **2.2 Rebuild `StageRail`.** Make it full-width, line-and-node based,
  evenly distribute ten visible stages, support click, pointer drag, keyboard,
  and selected focus, and remove visible page arrows/range. Preserve completed
  and enabled truth through shape/stroke and accessibility copy.
- [x] **2.3 Recompose Stage Select.** Add terrain-side previous/next icons, the
  concise top identity/rule row, full-width bottom rail, and bottom-right primary
  Aim icon. Route every selection path through one method and keep selection
  provisional until Start.
- [x] **2.4 Match the preview world.** Reuse the selected prepared terrain and
  existing gameplay sky/ground assets in the noninteractive preview viewport;
  update them in place when selection changes and preserve the last valid frame
  while a new artifact prepares.
- [x] **2.5 Merge the visible Briefing flow.** Remove `BriefingActions` and its
  layout/test/capture path. On prepared gameplay presentation, enter Aim once
  through the controller's existing transition before player input is admitted.
  Preserve internal state ownership and prevent double transition or early Fire.
- [x] **2.6 Update flow, selection, preview, responsive, localization, and
  capture tests.** Prove arrow/click/drag equivalence, provisional selection,
  ten-node windows, no visible Briefing screen, no blank preview, and both sizes.

Focused gate:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/stage_selection_readiness_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/stage_select_rule_truth_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/screen_responsive_layout_test.gd
```

### Phase 3 — Aim score, live HUD, and ball detail

Goal: reproduce Aim, Map, Shot Follow, and special-ball detail without changing
game rules or the approved non-score Aim controls.

- [x] **3.1 Add `AimScoreStatus`.** Render the success-range domain, star tiers,
  signed in/out-of-range marker, total paint percentage, and R/G shape plus sign
  from `StageData`, `PaintCoverageSnapshot`, and current score. Add fixtures for
  Stage 08 entry/center/overflow, Stage 09 negative, and zero weight.
- [x] **3.2 Retire live vertical `ScoreScale`.** Keep its horizontal Result
  summary behavior only. `HUDController` selects Aim range or compact Map/Follow
  value preset; remove every live 0-100 axis and persistent score explanation.
- [x] **3.3 Recompose `HudRootLayout`.** Apply the locked 24/12 safe margins and
  8 px grid for Aim, Map, and Follow. Preserve queue/right status and the lower
  angle-Fire-power relationship; replace Finish, mode, settings, return, and
  stepper actions with shared semantic icons.
- [x] **3.4 Add `BallDetailCard`.** Replace the detached transparent label, own
  token/card hover continuity, focus, pin/unpin, Escape, viewport clamping,
  compact text, and accessible description in the shared queue.
- [x] **3.5 Update score, queue, HUD, interaction, responsive, localization, and
  capture tests.** Assert the distinct Aim/Map/Follow score presentations,
  exactly one primary action, no clipped controls, and identical detail copy.

Focused gate:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/score_scale_contract_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/ball_queue_tooltip_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/hud_layout_responsive_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/localization_ui_test.gd
```

### Phase 4 — Pause, Settings, and Results

Goal: reproduce the four approved interrupted/terminal surfaces with the shared
foundation and identical alignment rules.

- [x] **4.1 Recompose Pause.** Remove its white sheet and vertical text list;
  use the navy input barrier, centered title, one horizontal icon rail, Resume
  primary, and four routine actions. Preserve paused tree/input behavior,
  Settings child-modal return, and focus restoration.
- [x] **4.2 Recompose Settings.** Move Defaults and Close to the fixed header,
  make both icon actions, align form columns, make only content scroll in compact,
  preserve settings persistence/localization, and keep Restart absent.
- [x] **4.3 Recompose Clear and Failure.** Use the shared right gradient,
  one alignment spine, the same score/result geometry, icon-only action rail,
  correct state-specific primary, failure reason/target gap, and unclamped score.
- [x] **4.4 Update interrupted-state, result, responsive, focus, localization,
  and essential-copy tests.** Remove assertions for old text/sheets and add
  icon/accessibility, one-primary, one-white-surface, bounds, and focus-order
  contracts.

Focused gate:

```powershell
& $env:GODOT_BIN --headless --path . --script res://tests/essential_ui_copy_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/screen_responsive_layout_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/phase7_ui_test.gd
```

### Phase 5 — Canonical truth, production validation, and handoff

Goal: make the durable specifications, full regression gate, and actual
production pixels agree.

- [x] **5.1 Record the approved supersession.** Update `docs/source-brief.md`,
  `.agents/design/UIUX_GUIDELINES.md`, `.agents/design/VISUAL_REFERENCES.md`,
  `.agents/design/DESIGN.md` if reachable-state wording changes, and
  `.agents/Documentation.md`. Update `docs/test-checklist.md` only for actual
  new capture/test procedures. Remove stale claims rather than appending a
  conflicting second contract.
- [x] **5.2 Run the full ordered test and verify gates once after implementation
  stabilizes.** Save compact logs under
  `.agents/evidence/2026-08-21-uiux-image-parity/` and do not rerun passing gates
  unless a relevant input changes.
- [x] **5.3 Export the Windows release and run the task-owned background capture
  sweep.** Capture each selected state separately at 1280x720 and 640x360, plus
  Main hover/focus, Stage selection interaction endpoints, Aim entry/center/
  overflow/negative/zero-weight, ball detail at Stages 08/12/24, and focus states.
  Record build hash, commit, Godot 4.7.1, Compatibility renderer, locale, viewport,
  and state arguments. Do not overwrite historical evidence.
- [x] **5.4 Build deterministic same-viewport comparison sheets and inspect the
  actual pixels.** Record pass/fail separately for button surfaces, score
  comprehension, special-ball card, internal/external alignment, focus,
  overflow, and the one-primary/white-surface limits. A headless structural
  pass cannot substitute for this review.
- [x] **5.5 Run `$codebase-quality-auditor`.** Inspect task-owned shared/public UI
  owners for responsibility creep, competing styles/state, stale reachable
  branches, API/test breakage, and missing validation. Apply only small safe
  task-scoped corrections and rerun only the affected checks.
- [x] **5.6 Close the plan and commit implementation.** Mark all truthful items,
  set `status: done`, record exact evidence and remaining limitations, delete
  task temp files, and create coherent scoped commit(s) with explanatory bodies.

Broad gate, announced before running because it is the costly final validation:

```powershell
pwsh -NoProfile -File scripts/test.ps1 -GodotPath $env:GODOT_BIN
pwsh -NoProfile -File scripts/verify.ps1 -GodotPath $env:GODOT_BIN
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

If later task-owned inputs change the Web output, also run the existing Web
release export and static validation. No local server or remote publication is
needed for image parity; if a Web server becomes necessary, load
`$npjt-port-guard` first and use the fastrun manager's `codex` lane.

## Acceptance matrix

- [x] **Actions:** zero action buttons contain visible text. Main Menu reveals
  at most one sibling hover/focus label. Routine normal white surfaces are zero.
- [x] **Aim score:** exactly one minimum-to-maximum success bar, internal star
  tiers, out-of-range arrow, numeric total-paint percentage, and shape-plus-sign R/G
  roles. No vertical axis, terrain mask, prose, or background card appears.
- [x] **Map/Follow regression:** both retain compact approved value readouts;
  Map has no Aim controls/Fire and Follow uses one compact return icon.
- [x] **Stage flow:** Stage Select contains briefing truth; terrain-side arrows,
  rail click, drag, and keyboard selection agree; gameplay appears directly in
  Aim with no blank/rebuilt terrain frame and no visible standalone Briefing.
- [x] **Ball detail:** one white queue-anchored card, identical hover/focus/press
  copy, pin/unpin, Escape dismiss, trigger/card continuity, and no clipping at
  Stages 08, 12, and 24 in standard and compact.
- [x] **Alignment:** safe margin 24/12, routine target 44/40, primary 56/48,
  shared row-center and edge difference at most 1 px, and no internal/external
  owner crossover.
- [x] **Focus/accessibility:** every icon action has localized accessible name,
  useful tooltip, visible 2 px focus ring, and visual-order traversal. Color-only
  semantics are absent.
- [x] **Overflow:** no clipped or overlapping child at 1280x720 or 640x360;
  compact Settings fixes actions while only content scrolls.
- [x] **Visual hierarchy:** at most one filled blue primary per screen; at most
  one white information/form surface, except the open ball card may add one.
- [x] **Functional truth:** every visible action calls existing real behavior;
  preparation, score, paint, queue, pause, settings, results, localization,
  persistence, and stage rules remain authoritative and pass regression tests.
- [x] **Rendered parity:** each selected reference has a separate same-viewport
  production screenshot whose composition, hierarchy, surface use, and action
  language match the reference. Differences caused only by live authoritative
  terrain/data, font rasterization, or responsive geometry are recorded.

## Regression guards

- Do not move stage state, shot admission, clear/failure, score, paint,
  ball-deal, or saved-selection authority into UI code.
- Do not create a second terrain preview renderer, coverage model, score model,
  palette registry, icon implementation, or localization source.
- Do not retain old text actions, vertical-live score, transparent ball copy,
  rail pager, white Pause sheet, Settings footer, or visible Briefing as hidden
  compatibility branches. Delete obsolete code/tests once replacement passes.
- Do not make action meaning depend on color alone; pair semantic icon, shape,
  state, focus, accessible name, and tooltip.
- Do not reduce gameplay visibility to force screenshot parity. The current
  prepared terrain, camera, projectile, paint, and result state remain real.
- Do not alter stage data, target bands, R/G weights, score math, ball rules,
  physics, paint, or catalog assets for visual convenience.
- Do not add dependencies, plugins, asset packs, services, or remote changes.
- Preserve unrelated worktree changes and historical evidence.

## Contingencies

- If imported white PNG icons cannot be reliably tinted in Godot 4.7.1, keep
  the archive's corresponding black member only for the fixed navy routine role
  and the white member for blue primary roles behind the same semantic icon
  owner; do not fall back to text glyphs, generated bitmap approximations, or
  screen-local drawing.
- If ten full rail nodes cannot meet 40 px compact targets, keep all nodes
  logically focusable and render the active ten-stage window at the logical
  viewport density; do not shrink hit targets or restore visible page buttons.
- If the selected preview artifact is not ready, retain the last prepared world
  frame, disable Start, and expose readiness through accessibility/tooltip. Do
  not show a blank field or build synchronously.
- If automatic Briefing-to-Aim exposes a first-input race, hold gameplay input
  until the one controller transition and HUD presentation finish. Do not add a
  visual intermediate screen.
- If the detail card would cross a viewport edge, flip/clamp it within the queue
  owner's safe rectangle while keeping its active-token attachment visually
  clear.
- If compact result content cannot fit at approved physical text size, preserve
  score, target, reason, and actions; suppress only duplicate metadata already
  available elsewhere. Do not shrink key values below the contract.
- If production pixels materially disagree with a selected image, correct the
  responsible shared owner and recapture only affected states. Do not change the
  report image or weaken acceptance to match the implementation.

## Progress and checkpoints

- [x] **2026-08-21 discovery.** Inspected the selected TO-BE image set and report,
  current running-state evidence, shared/screen/runtime owners, capture and test
  infrastructure, design authority, implemented-status record, and prior
  ExecPlans. Resolved the vertical-scale and Briefing conflicts in favor of the
  latest user direction. Identified remote publication as excluded unfinished
  work and preserved relevant local UI/runtime contracts above.
- [x] **Phase 1 — Shared action, icon, and Theme foundation.** Imported only the
  needed members from the previously approved and hash-verified Kenney archive,
  recorded their provenance, removed `ActionControl` text/glyph fallbacks, added
  the four shared icon roles, and removed white routine surfaces from shared HUD
  and stepper roles. Godot 4.7.1 editor import plus
  `shared_ui_component_ownership_test.gd` and
  `cross_stage_ui_theme_test.gd` pass.
- [x] **Phase 2 — Main Menu and Stage Select plus Briefing.** Completed with focused flow, responsive-layout, and rendered comparison evidence.
- [x] **Phase 3 — Aim score, live HUD, and ball detail.** Completed with focused score, queue, responsive HUD, localization, cross-stage, and rendered-state evidence.
- [x] **Phase 4 — Pause, Settings, and Results.** Replaced Pause with the upper-centered icon rail while preserving the live Aim context beneath the scrim; rebuilt the Settings header/form sheet; aligned Clear and Failure to one right-gradient spine with stage, score, target, contributions, result scale, gap, and icon actions. Same-viewport target/current comparison sheets were inspected at 1280x720. Focused essential-copy, responsive, flow, result-truth, component ownership, HUD layout, score, localization, cross-stage, feedback, and shortcut checks pass.
- [x] **Phase 5 — Canonical truth, production validation, and handoff.** Updated
  canonical product/design truth, passed the full ordered suite and final
  verification, exported the Windows release, captured 27 production states,
  inspected 10 same-viewport reference/current sheets plus the compact sweep,
  and completed the shared-UI quality audit. Evidence is retained under
  `.agents/evidence/2026-08-21-uiux-image-parity/`; implementation commit is
  `311d3d6`.

After each phase, update these checkboxes and record focused validation evidence
here before moving to the next phase. Do not create a separate progress report.

## Stop conditions and next step

Ask before adding a dependency/plugin/asset pack, changing gameplay rules or
stage data, deleting historical evidence, publishing, pushing, merging, or
changing remote visibility. A failed test or difficult implementation is not a
stop condition; trace the responsible owner, apply the smallest correction, and
continue.

Completed outcome: the selected TO-BE hierarchy and interaction contract are
implemented in the production Godot UI, validated, captured, documented, and
committed. No remote publication was requested or performed.
