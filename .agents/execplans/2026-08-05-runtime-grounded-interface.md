---
type: plan
status: superseded
created: 2026-08-05
last_reviewed: 2026-08-05
scope: Korean-first design system, nine runtime-grounded screens, honest gameplay HUD states, responsive desktop layout, accessibility, and final rendered handoff
source: runtime-grounded current-versus-proposed review selected by the user as the planning basis on 2026-08-05
superseded_by: 2026-08-05-gameplay-contract-recovery.md
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../research/concepts/runtime-grounded-ui-2026-08-05/README.md
  - 2026-08-05-physical-gameplay-mvp.md
  - 2026-08-05-rapid-fire-thirty-stage-progression.md
---

# Runtime-Grounded Interface - Execution Contract

> Superseded on 2026-08-05 because its observation/repeat-fire surface depended
> on gameplay contracts that were only partially implemented. Preserve its
> approved static visual direction, but execute the live aiming/readiness repair
> only through
> [`2026-08-05-gameplay-contract-recovery.md`](2026-08-05-gameplay-contract-recovery.md).

This plan turns the nine selected, current-runtime-grounded concepts into the
actual Godot interface after the physical and progression plans are complete.
It does not ask the UI executor to invent gameplay, stage data, paint, or result
states. Every visible value and world image must come from the owners delivered
by the first two plans.

### Execution override (2026-08-05)

The user authorized the complete plan set in one pass. Both predecessor
contracts were implemented and checked before the interface changes in this
run; the prerequisite wording below remains useful ownership guidance but is
not a remaining execution blocker.

The user explicitly requested new ExecPlans in the plural, so the separately
scoped multiple-active-plan exception in `.agents/PLANS.md` applies. This plan's
`active` status records current decisions; its prerequisite makes it
non-executable until both predecessors are done.

## Purpose

- Objective: make Paint Mountain clean, bold, Korean-first, readable, and
  visually consistent across the whole reachable flow while retaining the
  approved sparse HUD and mountain-dominant composition.
- Deliverable: one shared Theme/type system; Main Menu, Stage Select, Briefing,
  Aiming, Observation, Pause, Settings, Clear, and Failure screens; complete
  Korean/English behavior; keyboard focus; responsive 1280x720 and 1600x900
  layout; and actual exported-build comparison evidence.
- Completion state: the real game reaches all nine states through real owners,
  matches the selected hierarchy and art direction, contains no clipped or fake
  information, and passes a user-facing final review.

## Prerequisite and Authority

- `2026-08-05-physical-gameplay-mvp.md` and
  `2026-08-05-rapid-fire-thirty-stage-progression.md` must both be `done` before
  this plan changes runtime files.
- `docs/source-brief.md` governs gameplay and truth. The nine proposed images
  govern visual hierarchy, density, grouping, and presentation direction only.
- The example stage numbers, percentages, shot counts, paint paths, and selected
  controls inside concept images are illustrative. Actual runtime resources and
  state owners always supply those values.
- If a concept image depicts physically impossible paint, camera framing, or
  state, the real gameplay owner wins and the implementation report records the
  bounded visual deviation.

## Scope and Boundaries

In scope:

- Shared Pretendard weights, color/type/spacing/radius/shadow/focus tokens,
  reusable UI components, and one global Theme owner.
- All nine screen scenes/controllers and their AppRoot/HUD wiring.
- Korean default, English switch, persistent settings, truthful copy, focus
  order, keyboard/Escape behavior, accessible names, hover/selected/disabled/
  focus states, clipping and overflow checks.
- UI scrim/panel opacity and HUD-safe-area integration around the already
  accepted world; physical materials, lighting, and camera remain predecessor
  owned.
- Delivery capture states/sizes, actual result scenarios, production export,
  current-versus-actual HTML report, and user review.

Out of scope:

- Shot-family, StageController, PaintSystem, generator, catalog, SaveSystem or
  GameState schema, replay, Agent API, mechanism-effect, ball/collider, coverage,
  reachability, physical material/light, or camera changes. The interface
  consumes those APIs and stops/routes back if one is missing.
- New dependencies, plugins, downloaded packs, fonts, network assets, mobile
  layouts, gamepad-specific navigation, installers, or a new renderer.
- Fake menu/gameplay paint state, placeholder statistics, force-clear result
  capture, direct HUD-state mutation, fabricated stage thumbnails, or decorative
  geometry that hides a physical-world problem.
- Pixel-identical reproduction of AI concept artifacts. The locked requirement
  is their hierarchy, spacing intent, weight, contrast, and state grouping on
  the real runtime.

## Visual Evidence Set

Each proposed file is paired with the corresponding current runtime capture in
`.agents/research/concepts/runtime-grounded-ui-2026-08-05/current/`:

| State | Selected direction |
| --- | --- |
| Main Menu | `proposed/00-main-menu-grounded.png` |
| Stage Select | `proposed/01-stage-select-grounded.png` |
| Briefing | `proposed/02-stage-briefing-grounded.png` |
| Aiming | `proposed/03-aiming-grounded.png` |
| Observation / repeat fire | `proposed/04-observation-grounded.png` |
| Pause | `proposed/05-pause-grounded.png` |
| Settings | `proposed/06-settings-grounded.png` |
| Stage Clear | `proposed/07-stage-clear-grounded.png` |
| Stage Failed | `proposed/08-stage-failed-grounded.png` |

These files are direction evidence, never completion evidence. The final report
must show proposed and actual exported-build images side by side.

## Discovery Closure

| Surface | Verified owner | Starting limitation | Locked response |
| --- | --- | --- | --- |
| Global style | `resources/ui/paint_mountain_theme.tres` loads Pretendard variable font | No explicit 500/600/700 role resources; mixed dimensions | Add three FontVariation resources and reusable Theme variations; keep this Theme sole owner |
| Main Menu | `main_menu.tscn`, `MainMenuScreen`, `AppRoot` preview world | Fixed-offset card and internal “vertical slice” label; live preview work contributes transition cost | Use a container-driven left action surface and a committed real-game hero image; remove internal label/live menu generation |
| Stage Select | StageSelect scene/controller, StageCatalog/GameState | Three wired cards and live 3D preview cache | Bind 3 pages/10 numeric cards and one selected committed preview from the completed catalog |
| Briefing | `hud.tscn::BriefingPanel`, HUDController | Centered overlay competes with terrain and does not scale to six mechanism instances | Use one bottom summary bar and group mechanisms by kind/count |
| Aiming | HUD subscenes and HUDController | Weak type/alignment; current world is visually obscured by scattered cards | Preserve approved edge contract with one left vertical coverage, lower-left aim, bottom-center Fire, and top edge status |
| Observation | ObservationControls/HUD/StageController | Aim/Fire disappear and six raw text buttons occupy top center | Keep aim/Fire; show one camera segment, one speed control, pause, and active family truth |
| Pause | PauseOverlay and StageController.toggle_pause | Hierarchy and spacing do not match selected compact modal | One modal with Continue primary and Restart/Settings/Stage Select/Main Menu below |
| Settings | Settings scene/controller, GameState/SaveSystem/AppRoot | One undifferentiated form; Main Menu and paused-gameplay return contexts already exist | Four-category modal that presents predecessor-delivered keys, auto-saves through existing APIs, and closes to Main Menu or Pause; no Result route and no Restart |
| Results | ResultPanel/HUD/GameplayScene | Current centered card hides world; old capture path may force terminal state | Right-side clear/failure cards with actual values and real deterministic terminal scenarios; terminal gear is hidden because Pause rejects terminal states |
| Localization/focus | translation CSV/imports and screen scripts | Korean exists but weights, copy fit, and component focus are inconsistent | Korean default, persistent English, explicit focus graph and accessible text at all five supported sizes |
| Rendered QA | DeliveryCaptureRunner | 1280 fixed size and unreliable/fabricated terminal capture fallback | Add requested sizes and real action-driven clear/failure scenarios; keep window off-screen/no-focus |

Readiness statement:

- The design system, screen inventory, layout regions, state visibility, copy
  semantics, data owners, assets, responsive sizes, focus behavior, evidence,
  and execution order are locked.
- No new asset choice, UI framework, layout direction, or gameplay meaning is
  left to the executor.

## Locked Design System

### 1. Color and surface roles

| Role | Value | Use |
| --- | --- | --- |
| Canvas / warm white | `#FFFDFC` | menus, modal surfaces, neutral HUD panels |
| Primary navy | `#172538` | primary text, dark status chips, hardware accents |
| Paint / action blue | `#2584FF` | Fire, selected state, progress, focus accent |
| Hover blue | `#4094FF` | primary hover only |
| Pressed blue | `#1268D8` | primary pressed only |
| Border / rail | `#C9CDD2` | control border, divider, progress rail |
| Secondary text | `#5E6A79` | helper copy and metadata |
| Disabled fill | `#E2E5E9` | disabled surfaces |
| Danger | `#D94C4C` | failure amount and destructive emphasis only |
| Modal scrim | navy at 72% opacity | Pause, Settings, and owned overlays |

- Ordinary panels have 16 px corner radius, primary buttons and large modals 20
  px, small chips 12 px. Borders are 1 px. Shadows use navy at 14% opacity,
  0/4 px offset, and 12 px blur-equivalent; no glassmorphism or stacked heavy
  shadows.
- Spacing uses an 8 px base rhythm. Supported screen-safe margin is 24 logical
  px at all five sizes. Minimum control height is 44 px; primary actions are
  64-72 px.
- Target Top/paint/mechanism world colors remain those delivered by preceding
  plans. UI styling cannot recolor physical semantic owners.

### 2. Typography

- Create `resources/ui/fonts/pretendard_500.tres`,
  `pretendard_600.tres`, and `pretendard_700.tres`, each wrapping the already
  bundled `PretendardVariable.woff2` at that exact variable weight.
- `paint_mountain_theme.tres` remains the sole Theme owner and defines reusable
  type variations: Helper 14/500, Body 16/600, Button 16/700, Value 24/700,
  Heading 28/700, and Display 46/700. No runtime text is lighter than 500 or
  smaller than 14 px.
- Korean and English use the same hierarchy. Text containers grow/wrap before
  font size is reduced. Numeric values use tabular alignment if supported;
  otherwise reserve fixed minimum widths.
- Internal/debug build labels are absent from production UI.

### 3. Components and assets

- Add reusable owners under `scenes/ui/components/` and `src/ui/components/`
  for: primary/secondary icon-text button, status chip, segmented control,
  modal shell, stage card, settings category row, and a drawn `StarRating`.
- Reuse only existing approved local icons: `target`, `restart`, `minus`, `plus`,
  `pause`, `settings`, and `paint_splash`. No download or production dependency
  is needed.
- Missing decorative icons do not trigger asset search. Use visible Korean/
  English text; the Follow camera segment reuses `target`. Back and Close
  are text buttons. `StarRating` draws five-point vector shapes and exposes an
  accessible `N of 3 stars` label rather than relying on emoji/glyph rendering.
- Icon-only Settings and Pause controls have localized accessible names and
  tooltips. Primary/destructive/navigation actions retain visible labels.
- Selected, hover, pressed, disabled, and keyboard-focus states are visually
  distinct. Selected state uses fill plus border/label, never color alone.

## Locked Screen Contracts at 1280x720

All screens use anchors and Containers. Pixel values below are intended control
caps and margins, not permission to use brittle child offsets.

### 1. Main Menu

- Use `00-main-menu-grounded.png` for hierarchy. A 428 px wide action surface is
  inset 28 px from left/top/bottom. The remaining viewport is a cropped real-
  game Stage 01 hero image whose mountain remains dominant.
- The hero is generated once from the accepted Stage 01 layout by running its
  real reliable solution through DeliveryCaptureRunner with HUD hidden, then
  saving `assets/ui/presentation/main_menu_hero.png` at 1280x720. It is a static
  promotional image, not save/coverage state and not a second runtime paint mask.
- Copy/action order is eyebrow, `페인트 마운틴`, `플레이`, `스테이지 선택`,
  `설정`, `종료`. Play starts the persisted selected stage. Four real actions
  remain; no invented Continue/news/account action appears.
- Focus begins on Play and proceeds vertically. Escape does nothing on Main Menu.

### 2. Stage Select

- Use `01-stage-select-grounded.png`. Back and `스테이지 선택` occupy the upper
  left; below them a 462 px capped left column contains three page tabs and a
  5-column x 2-row numeric grid with 12 px gaps.
- Page tabs are `1-10`, `11-20`, `21-30`. All ten visible cards are enabled.
  Selection uses a blue fill, 2 px focus/selection ring, stage number, and the
  localized selected label. Cards show no completion ornament; best coverage and
  stars appear only in the selected detail panel and never as a lock.
- The remaining right area displays the one selected 768x432 real preview,
  aspect-filled without distortion. A 340 px wide detail panel anchors lower-
  right and shows localized title/band, objective, target, shots, best, and one
  `시작하기` primary action.
- The selected preview always includes the authoritative target-mask overlay at
  22% blue opacity and labels it `목표 구역`; it is never described as paint.
  Paging never generates terrain and holds at most one selected preview texture.
- Arrow keys move inside the grid; PageUp/PageDown change ranges; focus remains
  on the corresponding numeric position when possible.

### 3. Briefing / Terrain Review

- Use `02-stage-briefing-grounded.png`. Keep stage/mode upper-left and shots/
  gear upper-right. No center card covers the mountain.
- One bottom-center bar is capped at 800x90. It shows stage title, target,
  mechanism total, the at-most-three unique mechanism kinds with `xN` counts,
  `뒤로`, and `조준 시작` primary.
- Briefing camera and world remain fully visible behind the bar. Mechanism names,
  silhouettes, and amber/violet/coral cues come from actual stage entries.
- Back returns Stage Select without regenerating its page; Aim starts the real
  StageController transition.

### 4. Aiming

- Use `03-aiming-grounded.png` and the physical plan's actual world evidence.
- Upper-left: stage chip and dark `조준` mode chip. Upper-right: shots panel plus
  existing Settings icon. Left-center: a 116x334 vertical coverage panel with
  `칠한 면적`, current percentage, rail/fill, and target label.
- Lower-left: a capped 320x124 aim panel showing signed direction, elevation,
  power, and existing minus/plus controls. The mouse owns yaw/elevation and the
  buttons/wheel own power exactly as current input contracts specify.
- Bottom-center: one 192x72 `발사` primary with paint-splash icon. Restart never
  appears in Aiming. The trajectory dots and first-hit ring remain world-space
  and are not hidden by panels.
- The existing `R` quick-restart shortcut remains available and routes through
  the same StageController restart action, but it has no Aiming-screen button.
- Upper/top center is intentionally empty in pure Aiming so the mountain remains
  dominant. Fire status appears only when needed through disabled copy or a
  small nonmodal status line.

### 5. Observation and repeat fire

- Use `04-observation-grounded.png`. Aiming controls, trajectory preview for the
  next shot, coverage, and bottom-center Fire remain present while prior families
  fly/roll.
- Under shots/gear, one right-aligned group contains camera segments `추적`,
  `전체`, `대포`, one speed toggle showing `속도 2x` or `속도 1x`, and the
  existing Pause icon. Segments have one selected state and never steer a ball.
- A restrained line reads `공 N개 추적 중`. At family capacity, Fire alone is
  disabled and reads `다음 공 대기`; aim controls stay enabled. When Terminal
  Pending, it reads `결과 계산 중`.
- Speed tooltip/accessibility copy states that 2x applies after verified ground
  contact for physics safety. Replay speed remains in Replay only.
- Family gain appears near the responsible trail as a pooled, nonmodal `+N.N%`
  chip, then fades at the shortened duration. It never hides contact.

### 6. Pause

- Use `05-pause-grounded.png`. A navy 72% scrim leaves the actual paused world
  legible. One centered modal is capped at 390 px wide.
- Header is `일시정지` with a visible `닫기` action. Vertical actions are
  `계속하기` primary, `다시 시작`, `설정`, `스테이지 선택`, and `메인 메뉴`.
  Reuse the Restart icon; other rows rely on labels rather than missing assets.
- Escape, Settings gear, and Pause icon all enter/leave the same StageController
  pause owner. Continue restores the exact prior camera, aim, active families,
  and speed preference. Restart is absent from Aiming/Settings and lives here and
  result/replay flows.

### 7. Settings

- Use `06-settings-grounded.png`. The modal is capped at 768x472 and uses the
  same scrim. Header has `설정`, auto-save helper copy, and visible `닫기`.
- A 200 px left category list contains `소리`, `게임`, `화면`, `언어`. The
  right content column shows one category at a time. No nested cards are added.
- Sound presents predecessor-delivered `master_volume`, `music_volume`, and
  `sfx_volume`. Game presents `fast_progress`, `follow_camera` under the label
  `자동 추적 카메라`, `camera_shake`, and `trajectory_preview`. Display presents
  `fullscreen`, `resolution`, and `quality`. Language presents the existing
  `language` choice. This plan adds no setting key or save migration.
- Changes save immediately. Closing returns to the exact owner: Main Menu,
  or paused gameplay. In gameplay, simulation remains paused while Settings is
  open and focus returns to the Pause menu's Settings row. Settings contains no
  Restart action and never opens directly from a terminal Result.

### 8. Clear result

- Use `07-stage-clear-grounded.png`. Keep the final actual painted terrain
  unobscured on the left; place a 412 px capped result panel 24 px from the right,
  vertically centered. Top stage/status/shots remain restrained; the Settings
  gear is hidden because terminal states are not pausable.
- Show `스테이지 성공`, drawn stars, authoritative final coverage, target, and
  only values already owned by StageController/observations. `다음 스테이지` is
  primary; `다시 도전` and `스테이지 선택` are secondary side by side;
  `플레이 다시 보기` is tertiary full width.
- Stage 30 replaces Next with `스테이지 선택` as primary. There is no unlock
  celebration because all stages were always open.

### 9. Failure result

- Use `08-stage-failed-grounded.png` with the same right-side shell and visible
  actual terrain and no terminal gear. Show `목표에 도달하지 못했습니다`, final
  coverage in danger, exact remaining percentage, and target.
- `다시 도전` is the sole primary. `스테이지 선택` is secondary and
  `플레이 다시 보기` tertiary. There is no Next action.
- Clear and Failure are reached only through real StageController terminal
  rules after family/paint drain. The UI never calculates or injects results.

### 10. Replay preservation

- Replay is an ancillary reachable mode rather than a tenth redesign concept.
  `replay_bar.tscn` keeps visible Pause/Resume, Restart, 1x, 2x, and Exit controls
  and consumes the predecessor's format-7 presentation owner.
- Apply the shared Theme, type, focus, and safe-margin rules without moving raw
  1x/2x controls into normal Observation. Exit returns to the owning Result and
  restores normal time-scale/camera ownership.
- Replay controls and values come from ReplayPresentationController; UI never
  synthesizes actions, family observations, or outcomes.

## Responsive, Localization, and Accessibility Contract

- Supported Windows desktop viewports are exactly 1280x720, 1280x800,
  1366x768, 1600x900, and 1920x1080, matching `docs/design-spec.md` and
  `docs/test-checklist.md`. There is no mobile requirement.
- Keep the 1280x720 logical baseline and `canvas_items` stretch. At 16:9 sizes,
  the complete 2D canvas scales proportionally, so 1600x900 is physically 1.25x
  and 1920x1080 is 1.5x while logical dimensions remain unchanged. At 1280x800
  and 1366x768, root Containers/anchors consume the extra logical edge space;
  capped panel widths remain logical caps and world visibility expands. A 24
  logical px safe margin therefore scales with the canvas where applicable.
- Pin `display/window/stretch/aspect="expand"` in `project.godot`; do not rely on
  an engine default for the two non-16:9 supported viewports.
- Resolutions below 1280x720 are unsupported and are not silently accepted.
- Every screen explicitly checks left/right/top/bottom clipping, Korean/English
  expansion, modal overflow, grid focus, and world obstruction at all five
  supported sizes.
- Korean is default unless a prior persisted user choice exists. The language
  switch persists and immediately refreshes every visible screen/component via
  translation keys; StageData never stores display text.
- Keyboard focus is always visible. Tab order follows visual order; arrow keys
  operate segments/grids; Enter/Space activates focused buttons; Escape closes
  Settings to its owner, closes Pause by continuing, and opens Pause from live
  gameplay.
- Icon-only controls expose localized accessible labels/tooltips. Semantic state
  uses text/shape as well as color. Contrast is at least 4.5:1 for body text and
  3:1 for large text/control boundaries.

## Tasks

### Phase 0: Freeze truthful inputs and component ownership

- [ ] **0.1 Verify both predecessor handoffs**
  - Owners: predecessor plans/evidence, Documentation, current build.
  - Change: record final APIs, state names, catalog paths, settings, actual world
    captures, and known deviations. Do not infer missing values from concepts.
  - Accept: every UI field/action has one live owner and both plans are done.
- [ ] **0.2 Build the shared type/style/component layer**
  - Owners: FontVariation resources, global Theme, new component folder, and
    `project.godot` stretch-aspect setting.
  - Change: implement exact tokens, type roles, reusable controls, StarRating,
    visible focus/selected/disabled states, and the locked `expand` aspect.
  - Accept: screens can consume components without local font/style duplication;
    existing seven icons are the complete image-asset set.

Phase gate: run `scripts/verify.ps1` once and render a component sheet off-screen
at the smallest 1280x720 and largest 1920x1080 sizes. Do not open a foreground
window.

### Phase 1: Implement navigation surfaces

- [ ] **1.1 Replace Main Menu composition and hero**
  - Owners: MainMenu scene/controller, AppRoot, delivery hero generation.
  - Change: generate the actual Stage 01 hero by playing the predecessor-owned
    stored reliable solution, remove the live preview/cache and internal label,
    and implement the locked action surface and focus order.
  - Accept: four actions work, the mountain dominates, and menu entry/navigation
    performs no terrain generation.
- [ ] **1.2 Implement the final Stage Select layout**
  - Owners: StageSelect scene/controller, StageCard component, catalog previews.
  - Change: bind three pages, ten numeric cards, selected real preview/detail,
    target label, start/back, keyboard paging, and texture release.
  - Accept: all thirty stages are reachable; neither page change nor selection
    generates 3D work; 1280/1600 captures do not clip.

Phase gate: run the relevant part of `phase7_ui_test.gd`, capture Main Menu and
Stage Select first at 1280x720 for phase iteration, inspect them against concepts,
then run `scripts/verify.ps1` once. This phase updates the corresponding
`phase7_ui_test.gd` navigation/page assertions before running them.

### Phase 2: Implement Briefing, Aiming, and live repeat-fire HUD

- [ ] **2.1 Recompose Briefing around the real world**
  - Owners: HUD scene/controller and mechanism summary component.
  - Change: implement the bottom bar, unique-kind counts, real target/shots,
    Back/Aim actions, and terrain-safe framing.
  - Accept: up to six mechanisms summarize without overflow and no modal hides
    the mountain.
- [ ] **2.2 Recompose Aiming edge HUD**
  - Owners: aim/coverage/action/top status scenes/controllers and HUDController.
  - Change: implement exact regions, type weights, truthful aim values, settings,
    vertical coverage, and sole bottom-center Fire.
  - Accept: actual terrain, cannon, arc, hit ring, and mechanisms stay readable;
    Restart is absent; mouse/power/Fire work through existing actions.
- [ ] **2.3 Implement Observation without removing aim or Fire**
  - Owners: ObservationControls, HUDController, camera/speed action bindings,
    family gain component.
  - Change: implement camera segment, one speed toggle, pause, active count,
    capacity/terminal copy, and pooled gain chip.
  - Accept: every visible state matches actual capacity/speed/camera/family data;
    launched balls remain unsteerable and current aim controls only the next root.

Phase gate: run the relevant UI/state check, capture Briefing/Aiming/Observation
at 1280x720, inspect paired concepts, then run `scripts/verify.ps1` once. Update
`phase7_ui_test.gd` from serial-state visibility assertions to the predecessor's
activity/capacity signals before running it.

### Phase 3: Implement Pause, Settings, and owner-safe return paths

- [ ] **3.1 Rebuild Pause as the sole in-game action menu**
  - Owners: PauseOverlay scene/controller, StageController/HUD/AppRoot signals.
  - Change: implement locked modal/actions and unify Esc/gear/pause entry.
  - Accept: simulation and active families freeze/resume exactly; every
    navigation action owns cleanup; Restart appears here, not Aiming.
- [ ] **3.2 Rebuild categorized Settings**
  - Owners: Settings scene/controller, GameState, SaveSystem, AppRoot return
    context, translations.
  - Change: implement four categories, named settings, immediate persistence,
    language refresh, and exact Main Menu/Pause returns using existing setting
    APIs only.
  - Accept: gameplay remains paused underneath; no setting is lost; Restart is
    absent; both locales fit all five sizes.

Phase gate: update/run `localization_ui_test.gd`, capture Pause and Settings at
1280x720, inspect concepts, then run `scripts/verify.ps1` once. The test update
must cover four categories, exact Main Menu/Pause return focus, and absence of
Restart/result routes.

### Phase 4: Implement truthful Clear, Failure, and Replay entry

- [ ] **4.1 Rebuild the shared right-side Result shell**
  - Owners: ResultPanel scene/controller, StarRating, HUDController.
  - Change: implement separate clear/failure copy/action configurations with
    authoritative data and real painted-world visibility.
  - Accept: action priority, Stage 30 behavior, stars, coverage, target, missing
    percentage, and replay entry exactly follow the screen contracts.
- [ ] **4.2 Make delivery terminal scenarios real**
  - Owners: DeliveryCaptureRunner and completed stage/shot owners.
  - Change: clear by replaying Stage 01's stored reliable solution through normal
    actions; fail by firing a bounded deterministic legal non-target sequence
    until shots exhaust. Never call `force_stage_clear`, direct HUD methods, or
    representative-value setters.
  - Accept: capture fails unless StageController naturally reaches the requested
    terminal state after all family/paint drain.
- [ ] **4.3 Preserve and restyle Replay mode**
  - Owners: `scenes/ui/hud/replay_bar.tscn`, `src/ui/hud/replay_bar.gd`,
    HUDController, and ReplayPresentationController bindings.
  - Change: apply shared components/focus/copy while retaining exact format-7
    pause/restart/1x/2x/exit behavior and Result return.
  - Accept: Replay controls never appear in normal play, playback state remains
    truthful, and Exit restores the terminal Result without changing its data.

Phase gate: run the result portion of `phase7_ui_test.gd`, capture Clear/Failure
and one Replay state at 1280x720, inspect the actual painted world and values,
then run `scripts/verify.ps1` once. Update that test to assert clear/failure action
variants, Stage 30 behavior, hidden terminal gear, and natural terminal entry.

### Phase 5: Responsive/localization pass and delivery-state integration

- [ ] **5.1 Complete Korean/English copy and focus behavior**
  - Owners: `translations/ui.csv`, imported translations, every screen's focus
    graph and accessibility metadata.
  - Change: remove hard-coded user-facing strings, implement immediate refresh,
    tooltips/names, segment/grid arrow behavior, and exact Escape semantics.
  - Accept: both locales, all five sizes, mouse and keyboard produce no clipping,
    trapped focus, unlabeled icon, or color-only state.
- [ ] **5.2 Implement every delivery state and viewport argument**
  - Owners: `src/delivery/delivery_capture_runner.gd` and its delivery fixtures.
  - Change: parse/validate `--capture-size=WIDTHxHEIGHT`; implement the exact nine
    comparison states plus the ancillary `replay` state in Validation; route
    navigation, repeat fire, pause, settings, terminal, and replay through real
    public owners; move the window off-screen and remove focus before any frame.
  - Accept: each comparison state succeeds and exits at all five supported sizes;
    Replay succeeds at 1280x720 and 1920x1080; unknown state, invalid size, or a
    failed natural transition exits nonzero; no state calls force-clear or
    directly populates HUD data.
- [ ] **5.3 Verify world integration without reopening its owners**
  - Owners: UI safe areas, scrims, panels, and the predecessor evidence links.
  - Change: inspect world/HUD contrast and obstruction. Correct only UI opacity,
    allocation, and safe-area ownership. Route any required camera, material,
    lighting, geometry, or paint change back to the owning predecessor plan.
  - Accept: predecessor evidence remains valid and the mountain stays dominant;
    this task contains no world-owner diff.

Phase gate: run updated `phase7_ui_test.gd` and `localization_ui_test.gd`, then
all nine comparison states at all five supported sizes plus Replay at its two
sizes; run `scripts/verify.ps1` once after the owned inputs settle.

### Phase 6: Audit, export, compare, and hand off

- [ ] **6.1 Run the task-scoped quality audit**
  - Change: use `codebase-quality-auditor` read-only and save task-scoped findings
    about component responsibility, duplicated styles, public bindings, and
    obsolete UI paths.
  - Accept: the audit covers Theme/components/screens and verifies that gameplay
    owners did not leak into UI.
- [ ] **6.2 Correct blocking audit findings**
  - Change: correct only task-owned fixed-offset remnants, duplicate local
    styles, stale motion-state UI branches, live menu preview paths, direct
    result injection, or contract defects identified by 6.1.
  - Accept: each blocking finding is fixed or triggers replan; audit and fix
    evidence remain separate.
- [ ] **6.3 Export and capture the final actual build**
  - Change: export once. Through the exported off-screen path, capture all nine
    states at all five supported sizes plus Replay at 1280x720 and 1920x1080.
    Also create the seven canonical separate
    1920x1080 release screenshots and the 1280x800 Korean/English aiming plus
    Korean Pause images named by `docs/test-checklist.md`. Record predecessor
    responsiveness/navigation telemetry without rerunning unrelated broad suites.
  - Accept: every image is from the real Compatibility renderer, correct state,
    locale, size, and owner; the desktop never receives focus.
- [ ] **6.4 Build the current/proposed/actual review report**
  - Owners: `docs/reports/runtime-grounded-interface/index.html` and assets,
    evidence README.
  - Change: show the original current capture, selected concept, and actual build
    for each state, plus concise notes for intentional truth-driven deviations.
  - Accept: the report never presents concept art as implementation and links
    exact build/commit/commands.
- [ ] **6.5 Update records and request final user review**
  - Owners: this plan, Documentation, test checklist, design docs only where
    stable guidance changed.
  - Change: update stale UI/schema/resolution items in `docs/test-checklist.md`,
    record proof and known remaining issues, mark done only after every gate,
    then hand the report and canonical fastrun command to the user.
  - Accept: foreground QA is explicitly the user's next action; the agent does
    not open Godot over the desktop.

## Validation and Rework Controls

Use the engine path and smoke/export forms defined by the predecessor plans.
The final capture command form is:

```powershell
$evidence = (Resolve-Path '.agents').Path + '\evidence\runtime-grounded-interface'
& '.\builds\windows\PaintMountain.exe' --capture-background --capture-screen=aiming --capture-size=1280x720 --capture-output="$evidence\aiming-1280x720.png"
```

Required named states are `main_menu`, `stage_select_page_2`, `briefing`,
`aiming`, `observation_two_families`, `pause`, `settings`, `stage_clear`, and
`stage_failed`; `replay` is the required ancillary state.

| Cadence | Evidence | Run when | Rerun condition |
| --- | --- | --- | --- |
| Phase smoke | `scripts/verify.ps1` | Once after a phase changes scripts/scenes/resources/settings | Relevant input changes |
| Focused UI | Existing `phase7_ui_test.gd` | The owned screen group is complete | Screen/component/state binding changes |
| Localization | Existing `localization_ui_test.gd` | Settings/copy/focus phase complete | Translation, locale, font, or layout changes |
| Render review | Named off-screen capture paired with its concept | Each screen phase and final export | Visible owner/capture scenario changes |
| Final export | Windows Desktop release | All focused checks pass | Production-owned input changes |

Rules:

- Do not add a fragmented screenshot-test suite or run the broad historical
  matrix. Existing focused UI/localization checks plus rendered evidence are the
  complete UI validation scope.
- Inspect actual images during every user-facing phase; scene text/DOM-like node
  inspection alone cannot pass a visual task.
- Never launch a normal visible game/editor window. Use off-screen/no-focus
  capture and let the user choose when to run fastrun in the foreground.
- Rerun a failing check only after a relevant change. Keep a passing capture
  until its visible owner, data scenario, locale, or viewport changes.
- On resume, begin at the first unchecked task and update evidence/progress in
  the same edit.

## Predetermined Contingencies

| Trigger | Required response | Forbidden shortcut |
| --- | --- | --- |
| A concept value conflicts with runtime data | Render the runtime value and note the difference in the report | Hard-code the concept number or fake state |
| Korean/English copy clips at any supported size | Let containers grow/wrap or use an approved shorter semantic label | Reduce text below 14 px/weight 500 or truncate an action ambiguously |
| A missing icon is desired | Use the visible label and existing component contract | Download an asset, use emoji, or invent an unlabeled icon |
| Stage preview/menu transition stutters | Verify no generation/cache path remains and release the selected texture | Hide it with a loading animation or restore live preview generation |
| Clear/failure scenario cannot be reached | Treat as a predecessor contract defect and stop at the owning plan | Force controller state or directly populate the ResultPanel |
| UI change requires gameplay-owner mutation | Stop and route the defect to the owning predecessor plan | Duplicate state/coverage/capacity logic inside HUD |
| A physical world cannot match concept framing | Preserve physical truth and record a bounded composition deviation for user review | Add fake geometry, paint, or a hidden camera-only board |

## Progress and Next Steps

- Canonical progress: the checkboxes in this file.
- Execution checkpoint (2026-08-05): Phases 0–5 are implemented. The shared
  theme/components, Korean-first menu and stage grid, runtime aiming/
  observation/pause/settings flows, replay/result wiring, and owner-safe
  off-screen capture states are present in the running build.
- Current evidence: `aiming_execution.png`, `observation_execution3.png`,
  `stage_select_execution.png`, `main_execution_final.png`,
  `paint_execution_final.png`, `settings_execution_final.png`, and the passing
  `responsiveness_final.json` are indexed in the execution evidence record.
- UI contract correction applied during execution: the top-center target chip
  was removed so the left vertical coverage meter is the sole target owner;
  the First Session hint is hidden outside AIMING to keep it off the Fire and
  observation controls.
- Phase 6 handoff remains: quality-audit report, release export, and final
  evidence index. The user—not the agent—performs any foreground Godot play
  review, so no desktop-blocking window is opened here.

## Completion and Stop Conditions

Complete only when all tasks/gates pass, actual exported-build images prove all
nine states, all five supported sizes and both locales are unclipped, focus/accessibility
contracts hold, the comparison report is truthful, and the user receives the
final review handoff.

Replan when a verified fact requires new gameplay meaning, a new design
direction, dependency, screen inventory, ownership, or supported viewport.
Do not replan for a local layout defect already covered here, a passing unchanged
capture, or small terrain/image differences that preserve the selected hierarchy
and real runtime truth.
