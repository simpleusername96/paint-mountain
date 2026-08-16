---
type: plan
status: done
created: 2026-08-10
last_reviewed: 2026-08-10
objective: implement the approved Essential UI refinements faithfully across Paint Mountain's normal player-facing screens
scope: visible copy, semantic boundaries, menu and gameplay HUD composition, briefing and result framing, responsive layout, tests, and rendered release evidence
source: ../../docs/source-brief.md
related:
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../../docs/reports/screen-audit-2026-08-10/index.html
  - ../../docs/test-checklist.md
  - ../Documentation.md
---

# Essential UI Fidelity Implementation

## Purpose

Implement the seven user-approved refined screen images as one coherent runtime
UI pass while preserving the accepted Quiet Context style, real game behavior,
Korean-first localization, keyboard operation, and the mountain-first
composition. The pass removes visible copy and thin boundaries that do not help
the current decision, makes Briefing communicate through the terrain and its
surface glyphs, and gives Main Menu, Stage Select, Briefing, Settings, and
Results the same restraint already intended for Aim View.

This is an implementation plan, not evidence that the current build already
matches the images. Completion requires release-build captures reviewed against
the approved references.

## Deliverable

A Windows desktop build in which:

- Main Menu, Stage Select, Briefing, Aim View, Settings, Manual Result, and
  Timeout Result match the approved refined references in copy inventory,
  visual hierarchy, boundary use, action prominence, and relative world/UI
  occupancy;
- Map View, Shot Follow, and Pause retain their approved behavior and style but
  lose any shared decorative bottom divider introduced by the current context
  legend;
- normal gameplay shows each shortcut once, in the lower-edge context legend;
- Briefing shows the actual terrain glyphs without floating mechanism names or
  objective prose;
- explanatory content remains available to future guidebook/tutorial/UI-guide,
  accessibility, localization, and diagnostic owners without appearing as
  normal-screen filler;
- focused controls, selected stage, editable inputs, switch/slider/progress
  affordances, target marker, and modal containment retain clear semantic
  boundaries; and
- automated checks, production export, and a documented capture matrix prove
  behavior and rendered fidelity at supported 16:9 sizes.

## Completion Definition

The plan is done only after all of the following are true:

1. Tasks EUI-01 through EUI-13 are checked complete in order.
2. All focused UI, localization, shortcut, state, camera, and capture contracts
   pass with the shared Godot 4.7.1 runtime.
3. `scripts/verify.ps1` passes after the final scene/script/resource edits.
4. a release Windows executable exports successfully and is used for the final
   background captures;
5. Korean 1280x720 captures exist for all ten named states, representative
   English 1920x1080 captures exist for five named states, and Korean 1600x900
   Stage Select and Settings captures exist;
6. the implementer directly reviews reference/runtime comparison sheets and
   records no blocking difference in hierarchy, clipping, overlap, copy,
   boundaries, focus, or world obstruction;
7. `.agents/Documentation.md` and `docs/test-checklist.md` record only the
   behavior and evidence that actually shipped; and
8. this document is changed from `status: active` to `status: done` with the
   completed evidence paths and final commit identifiers.

## Authority and Requirement Reconciliation

Use sources in this order when they conflict:

1. The effective baseline plus dated supersessions in
   `docs/source-brief.md`.
2. The behavior and copy contracts in
   `.agents/design/UIUX_GUIDELINES.md` and world-composition rules in
   `.agents/design/ART_DIRECTION.md`.
3. The seven registered refined images for their named screens.
4. The approved Quiet Context reference for shared visual language and for
   screens not in the refined set.
5. Current scenes, scripts, tests, and release captures as implementation
   evidence, not design authority.

The 2026-08-10 Essential-Only supersession intentionally replaces these older
visible-UI clauses and only these clauses:

- “preserve the briefing objective” becomes “preserve its content data but do
  not show the objective paragraph in normal Briefing”;
- “integrate Space, Tab, and F into their controls” becomes “show those key
  names once in the lower-edge context legend and keep the controls semantic”;
- “use hairline dividers before panels” becomes “use semantic boundaries only”;
- “mechanisms may display names/functions during briefing” becomes “show the
  actual glyph without its world-space name during normal Briefing.”

No older gameplay, progression, paint, input, accessibility, loading/failure,
or localization truth is removed by this reconciliation.

## Verified Baseline

Discovery was completed against the repository on 2026-08-10 before writing
this plan.

### Existing visual and content owners

| Area | Current owner | Verified issue | Locked direction |
| --- | --- | --- | --- |
| Main Menu structure | `scenes/ui/screens/main_menu.tscn` | `Eyebrow` and `Subtitle` are visible; action column is over-wide | Remove both meta labels; retain title and four actions; constrain action width |
| Main Menu preview | `src/app/app_root.gd` | preview camera/terrain placement is authored with fixed vectors | Fit the real Stage 01 preview into the right-side safe region without changing gameplay terrain |
| Stage Select | `stage_select.tscn`, `stage_select_screen.gd` | `PreviewObjective`, `Divider`, repeated bordered cards, broad Start | Remove objective/detail divider; expose facts only; selected-only outline; compact Start |
| Briefing HUD | `hud.tscn`, `hud_controller.gd`, `top_status_bar.*` | lower central `BriefingPanel` owns title, objective, duplicate hint, and actions | Move identity/mode to upper-left; use a lower-left action lane; no objective or duplicate hint |
| Glyph labels | `terrain_glyph_mechanism.gd`, `gameplay_scene.gd` | normal Briefing calls the label-visibility path | Keep normal labels hidden; retain debug-only label toggle |
| Gameplay shortcut copy | `action_buttons.gd`, `run_status_card.gd`, `camera_interaction_control.gd` | controls append Space, F, and Tab | Controls show action labels only; shortcuts stay functional and appear once in legend |
| Shared context legend | `context_legend.tscn/.gd`, `shortcut_hint.tscn/.gd` | full-width divider and outlined Tab/Esc keycaps add decorative weight | Remove divider and keycap component; use aligned inline labels plus the real wheel asset |
| Aim grouping | `aim_controls.tscn` | `PowerDivider` is decorative | Remove it and use spacing/alignment |
| Settings | `settings.tscn` | `Autosave`, `LanguageNote`, `ColumnDivider`, and bordered CheckButton rows add filler | Remove helper copy/divider; add a shared unboxed switch-row variation |
| Results | `result_panel.tscn/.gd`, `hud_controller.gd` | “final coverage” caption and explanation repeat the metric; 420 px panel weakens world | Show terminal title, value, compact target, facts, and tiered actions in a 340-360 px panel |
| Camera framing | `camera_director.gd`, `terrain_camera_framer.gd`, `terrain_surface.gd` | Briefing/Result fit uses broad render AABB and does not reserve screen-specific UI regions | Fit real presentation points into mode-specific normalized safe regions while preserving authored view direction and safety |
| Theme | `resources/ui/paint_mountain_theme.tres` | global 1 px normal borders, general separators, and `HudKeycap` support obsolete repetition | Add narrow semantic variations, remove dead keycap/general separator styles after use audit, retain focus/selection/control/rail styles |

### Existing behavior that must survive

- Main Menu Play preparation, disabled reason, retry/failure, Settings, Stage
  Select, and Quit actions.
- Thirty open stages, keyboard/controller list navigation, page navigation,
  selected-stage facts, loading/preparation state, and Start.
- Briefing orbit, click focus, wheel zoom, Back, and Start Aiming.
- Aim/Map toggle by control and Tab, selected target, S/W angle edit, wheel power
  edit, Space Fire, F Finish, Esc Pause, Gear, and disabled/readiness tooltips.
- Shot Follow, its edge return action, automatic impact hold/return, and
  background projectile simulation.
- Settings persistence and its existing selective display-apply behavior.
- Manual and timeout result reasons, authoritative coverage, target, grade,
  previous best, elapsed time, shots used, Retry, Next availability, and Stage
  Select.
- `StageController` ownership of stage state/finish truth and `PaintSystem`
  ownership of coverage.

### Content retention boundary

Do not remove or rewrite `StageData.objective_key`, stage objective rows, typed
mechanism description keys, or the thirty stage Resources in this pass. They are
not normal-screen copy after this change, but they remain valid inventory for a
future guidebook, first tutorial, UI guide, accessibility, and diagnostics.
Remove a localization row only when the row is exclusively owned by a deleted
normal-screen node and has no retained tooltip, accessibility, error, guide, or
future-learning owner.

## Approved Reference Contract

All seven references are 1672x941, 16:9. Compare them to normalized 1280x720
runtime captures; do not stretch either image.

| Screen | Approved file | SHA-256 | Literal fidelity targets | Directional only |
| --- | --- | --- | --- | --- |
| Main Menu | `assets/refined/01-main-menu-refined.png` | `3180F3...A0AB` | title + four actions only, Play hierarchy, no lines | exact mountain topology and paint marks |
| Stage Select | `assets/refined/02-stage-select-refined.png` | `534AE4...788B` | fact-only detail, selected-only outline, no divider, compact Start | exact stage values outside the real selected state |
| Briefing | `assets/refined/03-briefing-refined.png` | `6A391F...D6D5` | identity/mode/actions/one guide, no objective/name label, dominant mountain | exact generated glyph placement and terrain shape |
| Aim View | `assets/refined/04-aim-view-refined.png` | `38F752...76B1` | no Space/F/Tab in controls, no decorative bottom/power lines | exact trajectory, target, paint, and camera pixels |
| Settings | `assets/refined/08-settings-refined.png` | `F6C5A4...845E` | actual controls only, no helpers/divider, unboxed switch rows | platform-specific select rendering |
| Manual Result | `assets/refined/09-manual-result-refined.png` | `BAB754...604` | compact facts, no explanatory labels, tiered actions, large world | illustrative coverage value and paint pattern |
| Timeout Result | `assets/refined/10-timeout-result-refined.png` | `178BB8...28B` | timeout reason motif, compact facts, no explanatory labels/lines | illustrative coverage value and paint pattern |

The complete hashes and provenance remain in
`.agents/design/VISUAL_REFERENCES.md`; abbreviated hashes above are navigation
aids only.

## Visible Copy Contract

### Global allowlist

Normal screens may visibly render only:

1. screen, stage, or interaction-mode identity;
2. authoritative current values and units;
3. real enabled/disabled actions;
4. terminal result or failure reason;
5. conditional loading, failure, retry, or disabled-readiness reason;
6. one mode-specific lower-edge input guide during interactive gameplay.

Tooltips, accessible names, focus announcements, debug overlays, and future
learning surfaces are not governed by the visible-copy limit, but they must be
truthful and localized.

### Screen-by-screen inventory

| Screen | Visible copy after implementation | Explicitly absent |
| --- | --- | --- |
| Main Menu | `페인트 마운틴`, Play, Stage Select, Settings, Quit, conditional preparation/failure reason | English eyebrow, marketing/tagline sentence, generic helper copy |
| Stage Select | screen title, page position, stage number/name, target %, best %, duration, shots, Back/Prev/Next/Start, loading/failure state | selected-stage objective/strategy sentence, duplicated instructions |
| Briefing | stage number, stage name, `지형 확인`, Back, Start Aiming, one lower guide | objective paragraph, floating mechanism names, second mouse hint |
| Aim View | stage identity, `조준`, time, shots, Finish, coverage/target, angle, power, Fire, readiness reason when disabled, one lower guide | Space beside Fire, F beside Finish, Tab beside mode, yaw, passive prose |
| Map View | stage identity, `지도 보기`, time/shots/Finish as current contract permits, one lower guide | aim-only controls, duplicate Tab, instructional paragraph, bottom divider |
| Shot Follow | stage identity/status, Return to Cannon, one lower guide | steering cues, duplicate return instruction, bottom divider |
| Pause | Pause, Continue, Restart, Settings, Stage Select, Main Menu | background helper copy, new shortcuts not owned by the menu |
| Settings | title, section names, setting names, current values/states, Restore Defaults, Close | autosave note, language-application note, tutorial prose |
| Manual Result | Completed, coverage %, target %, grade, previous best, elapsed, shots, Retry, Next, Stages | “final target coverage” caption, coverage explanation |
| Timeout Result | timeout icon + Time Expired, coverage %, target %, grade, previous best, elapsed, shots, Retry, Next, Stages | “final target coverage” caption, coverage explanation |

### Localization deletions

After a repository-wide use check, remove the Korean and English catalog rows
for these keys if and only if no retained non-visible owner uses them:

- `app.eyebrow`
- `app.subtitle`
- `settings.autosave`
- `settings.language_note`
- `result.final`
- `result.coverage_explanation`

Keep `stage.target`, all stage objective keys, mechanism display/description
keys, Finish/Fire/tooltips, loading/failure copy, and all context-legend keys.

## Semantic Boundary Contract

### Allowed

- 2 px focus treatment for keyboard/controller focus;
- 2 px selected-stage outline;
- one restrained outer boundary/shadow for Settings, Pause, and Result surfaces;
- functional Button, OptionButton, slider, switch, and editable control bounds;
- progress/coverage rails and the coverage target tick;
- a filled hover/pressed/selected state when it communicates interaction;
- world geometry edges and painted/glyph contours.

### Forbidden

- full-width line above the shared context legend;
- divider between Stage Select list and detail;
- divider between Settings columns;
- divider inside angle/power grouping;
- internal Result rules;
- default border around every unselected stage row;
- default border around every settings switch row;
- thin outlines used only to fill empty space or imitate a card grid.

### Theme cleanup rule

Do not globally remove a style until `rg` and scene instantiation prove it has no
semantic consumer. Prefer a new responsibility-named variation such as
`StageCardUnselected` or `SettingsSwitchRow` over changing the global Button
normal style and unintentionally flattening real actions. Delete
`shortcut_hint.tscn`, `shortcut_hint.gd`, their UID, and `HudKeycap*` theme roles
only after the shared ContextLegend no longer instantiates them and a full use
search is empty. Keep `HudTargetMarker` even if general H/V separators are gone.

## Responsive Composition Contract

Use a logical 1280x720 baseline, a 24 px gameplay safe margin, and containers or
anchors rather than proportional font scaling. The references establish visual
ratios; these rectangles make those ratios testable without making every child
pixel-fixed.

### Main Menu

- Left content region: x 56-380; title above actions; action width 288-304 px.
- Play: 52-56 px high, sole filled blue action.
- Secondary actions: 44-48 px high, quiet surface/text treatment, no repeated
  outer frame.
- Preview terrain safe region: normalized `Rect2(0.42, 0.10, 0.56, 0.82)`.
- The preview mountain should occupy 48-56% of viewport width and 68-80% of
  viewport height without entering the action column or clipping its silhouette.
- At 1920x1080, preserve the logical maximum content width; do not widen actions
  in direct proportion to the viewport.

### Stage Select

- Outer safe margin: 48 px at 1280x720; 24 px minimum at smaller supported
  16:9 windows.
- Left two-column list width: 600-616 px; inter-column gap: 56-72 px; no
  separator node. This corrects the earlier single-column-width transcription
  against the approved 1672x941 reference, which maps to about 612 logical px
  at the 1280x720 baseline.
- Stage rows: minimum 44 px high and 16 px horizontal padding; number/name left,
  target/best facts right or on a stable second line when localization requires.
- Only the selected row receives the accent outline; hover uses a soft fill and
  focus remains separately visible.
- Right detail shows no prose; Start is 200-240 px wide and 48-52 px high.
- At 1600x900 and 1920x1080, increase whitespace before line length; do not
  expand list/detail controls to fill the viewport.

### Briefing

- Upper-left identity stack: x 24-280, y 16-132; stage number, stage name, mode.
- Lower-left action lane: x 24-380, ending above the context guide; Back remains
  quiet, Start Aiming remains the sole blue action.
- Context guide: one line at the safe lower edge, no top rule.
- Terrain presentation safe region:
  `Rect2(0.27, 0.07, 0.69, 0.79)` before the context-guide reserve.
- The complete presentation silhouette should occupy 58-68% of viewport width
  and 68-82% of viewport height; it may not collide with identity/actions or
  clip the terrain/glyph silhouette.
- Normal gameplay sets mechanism labels hidden before the first rendered frame
  and never flashes them during the Briefing-to-Aiming transition.

### Aim View, Map View, and Shot Follow

- Preserve the current accepted world/cannon composition and control ownership.
- Remove only duplicate key text and decorative separator nodes/styles.
- Keep the lower guide inside the 24 px safe area; at 1280x720 it must fit on one
  line in Korean and English without clipped items or overlap with Fire, aim
  controls, Return to Cannon, or the coverage rail.
- If English cannot fit in one line at the minimum supported size, reduce
  inter-item gaps before reducing type; do not reintroduce keycap boxes or a
  second line unless the supported-size contract itself is revised.

### Settings

- Outer panel remains centered and modal, with a maximum logical width of
  1080 px and maximum height of 600 px at the 1280x720 baseline.
- Two content columns remain equal width, separated by 32-48 px whitespace and
  aligned section headings; no VSeparator.
- Every slider, switch row, OptionButton, and footer action has at least a 44 px
  target. Switch rows have no outer row border, but the switch track, label,
  on/off state, hover fill, pressed state, disabled state, and focus ring remain
  explicit.
- Removing helper rows must not vertically stretch remaining controls to fill
  the freed space; preserve a calm, even rhythm and footer alignment.

### Results

- Right result panel: 340-360 px wide at 1280x720, x anchored 24 px from the
  right, 500-532 px high, with 24 px internal padding.
- World safe region: `Rect2(0.06, 0.08, 0.64, 0.82)`.
- The complete result terrain silhouette should occupy 50-62% of viewport width
  and 58-74% of viewport height without entering the panel.
- Information order: terminal title/motif, large coverage, compact target,
  grade, previous best, elapsed/shots, Retry, Next, Stages.
- Retry is the only filled blue action. Next is quiet secondary. Stages is a
  tertiary text action. Stack the actions vertically to preserve Korean/English
  fit at 340-360 px.
- Use a real local 22-28 px transparent clock asset for Timeout Result. Generate
  it with built-in ImageGen from the approved reference, inspect it at native
  size and 2x, and save it as `assets/ui/icons/result_timeout_clock.png`; do not
  substitute an emoji, ASCII mark, handcrafted SVG, or unrelated icon pack.
- Manual Result has no clock motif. Both reasons share the same metric/action
  layout and differ only in truthful terminal reason presentation.

## Camera and World Framing Design

### Ownership

- `CameraDirector` remains the sole runtime owner of presentation mode and
  camera transitions.
- `TerrainCameraFramer` owns deterministic frustum-fit math.
- `TerrainSurface` may expose read-only presentation points derived from its
  existing generated layout/render geometry; it must not own camera policy.
- `AppRoot` owns the noninteractive Main Menu preview and may reuse the framer;
  it must not mutate the gameplay camera or stage data.

### Locked implementation approach

1. Add a tested `TerrainCameraFramer.framed_pose_in_normalized_rect(...)` API.
   Inputs: world points, authored position/focus, vertical FOV, viewport aspect,
   normalized safe rectangle, and margin. Output: position/focus that preserves
   the authored view direction as closely as possible and projects all supplied
   points within the safe rectangle.
2. The fit must use asymmetric left/right/top/bottom frustum limits derived from
   the safe rectangle, not a post-render image crop. It must reject empty points,
   invalid rectangles, invalid FOV/aspect, and non-finite values in tests.
3. Add `TerrainSurface.presentation_world_points()` as a read-only point set
   representing actual playable-top silhouette, summit headroom, and visible
   skirt/base perimeter. Do not use the eight corners of a broad AABB as the
   only interest set when those corners describe empty space.
4. For Briefing and Result, use existing authored bookmarks to retain the stage
   view direction, the presentation point set to determine fit, and the
   screen-specific safe rectangles above to determine placement. Apply current
   terrain safety after the fit and verify the safety correction still contains
   the point set.
5. Keep Map Inspection user orbit/focus behavior. Initial Briefing inspection
   distance comes from the fitted Briefing pose; its existing bounded zoom then
   operates from that truthful baseline.
6. For Main Menu, fit the real cached Stage 01 preview geometry into its safe
   rectangle after the layout artifact is ready. Keep the preview noninteractive
   and deterministic. Do not create a second fake mountain asset.
7. Cache framing by layout checksum, mode, viewport aspect, safe rectangle,
   camera FOV, and authored bookmark. Invalidate on stage/layout/viewport/FOV
   change. Do not recompute interest points every frame.

### Camera regression guards

- Aim View continues to use `AimCameraComposer`; do not route it through the new
  Briefing/Result fit unless evidence shows the existing aiming contract is
  broken.
- Follow remains projectile-relative and does not adopt static terrain framing.
- Camera safety rays and fixed-step ownership stay intact.
- No StageData camera bookmark or generated stage resource is bulk-rewritten in
  this pass.
- No camera work may change targeting, launch velocity, collision, paint,
  coverage, mechanism, or stage progression.

## Ordered Implementation Tasks

### Phase 1 — Contracts and shared visual primitives

- [x] **EUI-01 — Build the essential-copy contract test before deleting nodes.**
  - Add `tests/essential_ui_copy_test.gd`.
  - Instantiate Main Menu, Stage Select, Settings, HUD Briefing, Aim View, and
    Result without requiring live physics.
  - Assert the removed node names/visible copy are absent and the retained
    actions/state owners remain.
  - Assert loading, failure, disabled-readiness, tooltip, and accessibility text
    paths are not blanked by the allowlist.
  - Assert Korean and English semantic control labels do not contain `Space`,
    `Tab`, or ` F`, while the context legend contains each active shortcut once.
  - Stopping condition: the test fails for the current implementation for the
    intended reasons and has no gameplay-rule assertions.

- [x] **EUI-02 — Replace decorative shared boundaries with semantic Theme roles.**
  - Update `paint_mountain_theme.tres` with selected-stage and unboxed settings
    switch-row variations; preserve global action, focus, rail, and target styles.
  - Update `context_legend.tscn` to remove its HSeparator and replace Tab/Esc
    `ShortcutHint` instances with aligned inline labels.
  - Remove `PowerDivider` from `aim_controls.tscn`.
  - Remove `shortcut_hint.tscn/.gd`, UID, `HudKeycap`, general separator mappings,
    and dead StyleBoxes only after a use search proves they have no consumer.
  - Update `context_legend.gd` only as needed for the new node structure; it still
    displays authoritative mode-specific prompts and owns no input.
  - Acceptance: the legend fits Korean/English at 1280x720, uses the real wheel
    asset, has no top line/keycap boxes, and preserves all current shortcut facts.

### Phase 2 — Entry screens

- [x] **EUI-03 — Make Main Menu title-and-actions only.**
  - Remove `Eyebrow` and `Subtitle` from `main_menu.tscn`.
  - Constrain the action column to 288-304 px at the baseline and keep Play the
    only filled blue action.
  - Preserve preparation progress, disabled tooltip/reason, failure recovery,
    button order, focus restoration, locale refresh, and Quit.
  - Update `main_menu_screen.gd` only if a deleted-node reference exists; do not
    change navigation or preparation behavior.
  - Acceptance: no dead vertical gap replaces the deleted copy and 1920x1080
    does not widen the actions beyond their logical maximum.

- [x] **EUI-04 — Fit and rebalance the real Main Menu preview.**
  - Route `AppRoot` preview framing through the new deterministic safe-rectangle
    framer after the Stage 01 artifact is available.
  - Preserve actual generated mesh, material, target mask, paint preview,
    dressing, lighting, cache identity, and stage preparation.
  - Add a focused test or capture assertion for right-safe-region containment and
    menu-column non-overlap at 1280x720 and 1920x1080.
  - Acceptance: the preview occupies the target range, remains fully visible,
    and does not flash between fixed and fitted poses when the layout becomes
    ready.

- [x] **EUI-05 — Simplify Stage Select without reducing selection truth.**
  - Remove `Divider` and `PreviewObjective` from `stage_select.tscn` and their
    references/assignments from `stage_select_screen.gd`.
  - Keep target, best, duration, shots, selected identity, page state, Start,
    preparation/failure, and unlocked-state truth.
  - Apply selected-only accent outline, soft unselected/hover fills, minimum row
    padding/height, fact alignment, compact Start, and whitespace-only columns.
  - Preserve keyboard/controller traversal, selection visibility, focus vs
    selection distinction, and pagination.
  - Acceptance: all thirty stages remain reachable; Korean/English facts fit at
    1280x720 and 1600x900; no strategy sentence or decorative divider remains.

### Phase 3 — Gameplay HUD, Briefing, and presentation framing

- [x] **EUI-06 — Make the lower context legend the single visible shortcut owner.**
  - Change `ActionButtons.refresh_locale()` to set only `tr("ui.fire")`.
  - Change `RunStatusCard.refresh_locale()` to set only `tr("ui.finish")`; retain
    the real F `Shortcut` and truthful enabled/disabled tooltips.
  - Change `CameraInteractionControl._refresh_copy()` to set only Aim/Map label;
    retain Tab behavior in the gameplay input owner and truthful mode tooltips.
  - Keep Space, F, and Tab in the correct mode-specific ContextLegend once each.
  - Update `shortcut_prompt_test.gd` to assert both the single visible owner and
    unchanged action behavior.
  - Acceptance: no screenshot state contains a duplicate key name, and keyboard
    input continues to work when controls have focus.

- [x] **EUI-07 — Recompose Briefing around the terrain.**
  - Replace the central `BriefingPanel` with a responsibility-named lower-left
    action lane containing only Back and Start.
  - Add stage display name to `TopStatusBar`, populated from StageData and shown
    only during Briefing; keep stage number and mode in the same upper-left stack.
  - Remove `BriefingTitle`, `BriefingObjective`, and duplicate `Hint`; remove their
    controller assignments and locale-refresh paths.
  - Keep Start focus, Back behavior, inspection inputs, Gear behavior, and the
    one lower ContextLegend.
  - Change normal state transitions so `_set_mechanism_labels_visible(true)` is
    never called for Briefing. Keep the debug overlay's explicit label toggle for
    diagnostics, with normal labels false by default.
  - Add a test that reaches Briefing and inspects every terrain glyph mechanism:
    actual glyph geometry is visible, `BriefingLabel` is hidden, and no one-frame
    visible label occurs before Aiming.
  - Acceptance: identity/actions do not overlap the terrain safe region, no
    objective/name/hint text remains, and Start Aiming is the sole blue action.

- [x] **EUI-08 — Implement mode-specific deterministic terrain framing.**
  - Add the framer API, presentation-point API, cache keys, validation tests, and
    CameraDirector integration described in “Camera and World Framing Design.”
  - Use the locked Briefing and Result safe rectangles and occupancy ranges.
  - Add numeric projection tests for 1280x720, 1600x900, and 1920x1080 aspects,
    including a tall/ridged and a broad/low stage from the baked catalog.
  - Verify immediate cuts, smooth transitions, orbit baseline, safety correction,
    and cache invalidation; measure no per-frame interest-point rebuild.
  - Acceptance: every tested presentation point projects inside the safe region,
    full silhouette remains visible, UI reserve is respected, and Aim/Follow
    framing tests are unchanged.

- [x] **EUI-09 — Check untouched gameplay states for shared-style regressions.**
  - Capture Map View, Shot Follow impact hold, and Pause after EUI-02/EUI-06.
  - Verify the removed legend divider/keycaps do not cause overlap or unclear
    prompts, Return to Cannon stays edge-aligned, and Pause still blocks world
    input with visible focus.
  - Make only small shared-style corrections needed by those regressions; do not
    redesign these three screens in this plan.
  - Acceptance: all real actions remain; no new explanatory copy or line is added.

### Phase 4 — Settings and Results

- [x] **EUI-10 — Remove Settings helper copy and repeated row boxes.**
  - Remove `Autosave`, `LanguageNote`, and `ColumnDivider` from `settings.tscn`.
  - Apply the shared unboxed switch-row variation to Camera Shake, Reduced
    Motion, Trajectory Preview, and Fullscreen where the same row language fits.
  - Preserve switch track/state, slider and OptionButton bounds, minimum targets,
    focus, locale switch, selective display application, persistence, defaults,
    close/return flow, and pause-child behavior.
  - Rebalance column gaps/vertical rhythm without stretching controls to fill
    removed rows.
  - Acceptance: no helper/divider text remains, all controls work, and Korean/
    English fit without clipping at 1280x720, 1600x900, and 1920x1080.

- [x] **EUI-11 — Rebuild Results as compact fact-and-action panels.**
  - Remove `CoverageLabel` and `CoverageExplanation` from `result_panel.tscn` and
    the script onready/refresh path.
  - Add a compact target label driven from `StageData.target_coverage`; add the
    narrow `ResultPanel` configuration method and call it from `HUDController`.
  - Keep coverage/grade/best/time/shots authoritative and locale-safe; do not
    duplicate scoring calculations in UI.
  - Recompose actions vertically: Retry primary, Next secondary/disabled when no
    stage, Stages tertiary text-led. Preserve signal names and navigation.
  - Add and integrate the real timeout clock asset. Show it only for timeout;
    show the correct localized title for both finish reasons.
  - Anchor the 340-360 px panel and use Result safe-region camera framing.
  - Acceptance: manual/timeout reasons are distinguishable without color alone,
    no explanation caption/line remains, values agree with result snapshots, and
    the complete painted mountain remains readable beside the panel.

### Phase 5 — Localization, tests, release evidence, and records

- [x] **EUI-12 — Close automated behavior and localization validation.**
  - Update `localization_ui_test.gd` for removed exclusive keys and retained
    target/tooltip/objective content.
  - Update `phase7_ui_test.gd` for the Briefing action lane, result target, new
    theme roles, and removed keycap/separator roles.
  - Update `shortcut_prompt_test.gd`, `phase7_user_qa_contract_test.gd`,
    `phase8_aiming_composition_test.gd`, `phase8_hud_truth_test.gd`, and focused
    camera-framer tests only where their owned contract changed.
  - Run focused tests during implementation, then one final full
    `scripts/verify.ps1` after the complete file set stabilizes.
  - Run `$codebase-quality-auditor` because the pass changes shared UI, camera
    APIs, theme roles, and multiple screens. Apply only small safe task-scoped
    corrections from that audit.
  - Acceptance: no stale deleted-node lookup, dead localization use, competing
    shortcut owner, second result formula, or catch-all UI responsibility remains.

- [x] **EUI-13 — Export, capture, compare, rework, and record.**
  - Export the release executable with the canonical Windows preset.
  - Capture the matrix below from the exported executable through the existing
    hidden background delivery path.
  - Create same-size side-by-side comparison sheets: approved reference on the
    left, runtime capture on the right, labeled by state/locale/viewport.
  - Directly inspect each comparison for content inventory, type hierarchy,
    alignment, safe margins, relative occupancy, action prominence, boundary
    policy, focus, clipping, overlap, and world obstruction.
  - Rework blocking differences and repeat only affected focused tests/captures;
    rerun broad verification only after a material code/resource change.
  - Update `docs/test-checklist.md` with final screenshot paths and pass/fail
    results. Update `.agents/Documentation.md` with implemented facts and final
    evidence. Do not claim generated images as runtime proof.
  - Mark this plan done only after no required rework remains.

## Validation Commands

Use the shared runtime from `GODOT_BIN`; on the verified workstation it resolves
to `D:\tools\Godot\4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe`.

### Focused tests during implementation

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/essential_ui_copy_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/shortcut_prompt_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/localization_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase7_ui_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase7_user_qa_contract_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_aiming_composition_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/phase8_hud_truth_test.gd
& $env:GODOT_BIN --headless --path . --script res://tests/terrain_camera_safe_rect_test.gd
& $env:GODOT_BIN --headless --path . --quit-after 7200 --script res://tests/camera_safety_test.gd
```

If the existing camera-framing test uses another verified filename, extend that
owner rather than create a competing runner; record the actual command here.

### Final repository verification

Explain before starting that this is the broad final gate, expected to run the
repository's complete validation suite and stop on the first blocking failure.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/verify.ps1
```

### Production export

```powershell
& $env:GODOT_BIN --headless --path . --export-release 'Windows Desktop' 'builds/windows/PaintMountain.exe'
```

Do not use a debug editor play session as the final visual authority.

## Final Capture Matrix

### Korean 1280x720 — all states

1. `main_menu`
2. `stage_select`
3. `briefing` using Stage 02 so the terrain glyph is visible
4. `aiming`
5. `map_inspection`
6. `shot_follow_impact_hold`
7. `pause`
8. `settings`
9. `manual_result`
10. `timeout_result`

### English 1920x1080 — representative responsive states

1. `main_menu`
2. `stage_select`
3. `aiming`
4. `settings`
5. `manual_result`

### Korean 1600x900 — density-sensitive states

1. `stage_select`
2. `settings`

### Background capture command pattern

Use the existing delivery runner and an absolute output path:

```powershell
Start-Process builds/windows/PaintMountain.exe -WindowStyle Hidden `
  -ArgumentList @(
    '--',
    '--capture-background',
    '--capture-screen=<state>',
    '--capture-stage=<stage>',
    '--capture-size=<width>x<height>',
    '--capture-language=<ko|en>',
    '--capture-output=<absolute-png-path>'
  ) -PassThru -Wait
```

Store final evidence under a new task-specific directory, for example
`.agents/evidence/essential-ui-fidelity-2026-08-10/`, with `runtime/`,
`comparisons/`, and a short evidence index. Use `$doc-lifecycle-steward` for the
evidence index and mark its lifecycle truthfully.

## Visual Review Checklist

For every final capture, answer each item explicitly:

- Does visible copy match the per-screen allowlist exactly?
- Is any explanation duplicated between a control, panel, and lower guide?
- Does each shortcut appear exactly once in the current interactive state?
- Is every remaining line/border tied to focus, selection, containment,
  editing, progress, or target truth?
- Is the primary action the only blue filled action?
- Are secondary and tertiary actions visually quieter but still discoverable?
- Does the complete relevant mountain/impact/paint state remain visible?
- Does UI avoid the intended world safe region and current interaction target?
- Does Korean/English copy fit without clipping, forced microscopic type, or
  awkward wrap?
- Do focus, hover, pressed, selected, disabled, paused, timeout, and manual
  result states remain distinct without relying on color alone?
- At 1920x1080, do actions retain a reasonable maximum width rather than
  stretching with the viewport?
- At 1280x720 and 1600x900, do containers respect minimum content geometry and
  avoid overflow?

Any “no” is a blocking difference unless the written product behavior requires
the divergence. Record required divergences beside the comparison; do not edit
the generated reference to hide an implementation problem.

## Expected File Scope

The implementation is expected to touch these responsibility groups. Exact
deletions/additions may vary only when repository inspection proves a listed
file is not the owner.

### Specifications and records

- `docs/source-brief.md`
- `.agents/design/UIUX_GUIDELINES.md`
- `.agents/design/VISUAL_REFERENCES.md`
- this ExecPlan
- `docs/test-checklist.md` after release evidence
- `.agents/Documentation.md` after implementation

### Screens and shared UI

- `scenes/ui/screens/main_menu.tscn`
- `scenes/ui/screens/stage_select.tscn`
- `scenes/ui/screens/settings.tscn`
- `scenes/ui/hud/hud.tscn`
- `scenes/ui/hud/top_status_bar.tscn`
- `scenes/ui/hud/result_panel.tscn`
- `scenes/ui/hud/aim_controls.tscn`
- `scenes/ui/components/context_legend.tscn`
- deletion of `scenes/ui/components/shortcut_hint.tscn` when unused

### UI scripts

- `src/ui/screens/main_menu_screen.gd` only if deleted-node wiring requires it
- `src/ui/screens/stage_select_screen.gd`
- `src/ui/hud_controller.gd`
- `src/ui/hud/top_status_bar.gd`
- `src/ui/hud/action_buttons.gd`
- `src/ui/hud/run_status_card.gd`
- `src/ui/hud/camera_interaction_control.gd`
- `src/ui/hud/result_panel.gd`
- `src/ui/components/context_legend.gd`
- deletion of `src/ui/components/shortcut_hint.gd` when unused

### World/camera presentation

- `src/app/app_root.gd`
- `src/gameplay/gameplay_scene.gd`
- `src/camera/camera_director.gd`
- `src/camera/terrain_camera_framer.gd`
- `src/terrain/terrain_surface.gd`

### Resources/assets/localization

- `resources/ui/paint_mountain_theme.tres`
- Korean and English translation catalogs that own the six exclusive keys
- `assets/ui/icons/result_timeout_clock.png`

### Tests

- new `tests/essential_ui_copy_test.gd`
- existing shortcut, localization, Phase 7 UI/QA, Phase 8 composition/HUD, and
  camera-framing owners named in EUI-12

Do not touch gameplay physics, `StageController` rules, `PaintSystem` coverage,
projectile data, generation profiles, baked stage Resources, saves, or agent API
schemas unless an unanticipated correctness dependency is proven and the scope
expansion is approved first.

## Regression Guards

- No second visible coverage representation and no UI-side coverage formula.
- No new action, page, route, tutorial, guidebook, or UI guide in this pass.
- No removal of stage objective/mechanism content inventory.
- No loss of keyboard shortcuts merely because their labels move.
- No removal of accessibility names/tooltips or conditional error/loading text.
- No global flattening of all Buttons to remove a few decorative borders.
- No per-stage camera constants or edits to thirty stage Resources.
- No changes to projectile motion, fixed 60 Hz physics, two-times active pace,
  wall-clock duration, paint, mechanisms, or progression.
- No external dependency, plugin, asset pack, network service, or renderer change.
- No claim of fidelity from headless tests or generated images alone.

## Contingencies

### Translation fit

If English text does not fit, first widen the component within its specified
range, reduce inter-item spacing, allow the designated facts row to wrap, or use
the existing shorter approved translation. Do not shrink essential text below
the Theme role, truncate an action, add a tooltip-only action label, or restore
removed helper text.

### Camera safety changes the fitted pose

If terrain safety moves the camera enough to violate the safe rectangle, feed
the corrected pose back through one bounded refit/safety pass and assert
convergence. Do not skip collision/occlusion safety, edit stage data, or accept a
cropped silhouette. If two bounded passes cannot converge on a verified baked
stage, stop EUI-08 and record the exact stage/checksum/pose before expanding the
camera contract.

### Presentation points are too expensive

Build and cache them once per accepted layout checksum. If mesh traversal is
materially expensive, derive the same silhouette/base set from existing baked
layout arrays; do not sample every frame or introduce a background service.

### Timeout icon quality

If the generated icon is unclear at 22-28 px, regenerate it with the same visual
reference and stronger native-size constraints. Do not use emoji, ASCII, a fake
CSS/GDScript drawing, or install an icon pack. The textual localized timeout
title remains required regardless of icon success.

### Generated-reference artifact

If a reference pixel conflicts with real behavior, localization, accessibility,
or the written specs, preserve the real behavior and match the hierarchy rather
than the artifact. Record the divergence in the final evidence index.

### Unrelated dirty worktree

Preserve all user-authored unrelated changes. Stage and commit only files owned
by this plan. If an overlapping user change cannot be reconciled safely, stop
before editing that file and ask for direction.

## Stop Conditions

Stop and request user direction before:

- adding or upgrading a production dependency, plugin, renderer, or asset pack;
- changing gameplay rules, physics, paint/coverage ownership, progression,
  stage timing, or save format;
- deleting content that a future guide/tutorial/accessibility owner needs;
- creating the guidebook, first tutorial, or UI guide rather than only
  reserving their content boundary;
- bulk-editing stage Resources for camera composition;
- changing supported viewport/aspect requirements; or
- accepting a visual mismatch that materially changes the approved hierarchy.

Do not stop for small reversible layout constants, node renames, or task-owned
test updates already resolved by this plan.

## Progress

- [x] Current release captures and seven approved refinements collected.
- [x] Visual, copy, boundary, camera, scene, script, theme, localization, and
  test owners inspected.
- [x] Source brief and active UI/visual guidance updated with the new bounded
  requirement and reference authority.
- [x] EUI-01 through EUI-13 implemented and verified.
- [x] Final release evidence reviewed and indexed.
- [x] Documentation updated and plan marked done.

## Next Step

No implementation work remains in this plan. Use
`.agents/evidence/essential-ui-fidelity-2026-08-10/README.md` and
`design-qa.md` as the release evidence for later UI changes.

## Completion Record

- Implementation commit:
  `3fe50727e89002ebc49adc244dd73ad9de144a3f`.
- Documentation and release-evidence closeout commit:
  `a2639468c84d5f80c067bd05c73910d6f6af68ab`.
- `scripts/verify.ps1`: passed.
- Windows Desktop release export: passed; executable SHA-256
  `13D098963544B4878D648370E35C9402139D0AE1D75D81A66A4AE1D97611E2DB`.
- Required capture matrix: 17 exported-runtime captures, all native-size and
  exit code 0.
- Additional same-state QA capture: Korean Stage 30 Aim at 1280x720, exit code
  0.
- Final comparisons: seven proportional, unstretched, equal-frame sheets
  directly inspected.
- Final Product Design QA: `passed`; no actionable P0/P1/P2 issue remains.
- Evidence index:
  `.agents/evidence/essential-ui-fidelity-2026-08-10/README.md`.
