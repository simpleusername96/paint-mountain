---
type: plan
status: draft
created: 2026-08-04
last_reviewed: 2026-08-05
scope: all-open thirty-stage progression, concurrent repeat firing, projectile/paint scale correction, faster perceived cadence, and Korean-first HUD redesign
source: explicit user directives through 2026-08-04 and a preliminary visual proposal later rejected as insufficiently grounded in current runtime captures
supersedes: 2026-08-03-gameplay-visual-reset.md
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - ../../docs/asset-licenses.md
  - ../design/DESIGN.md
  - ../design/ART_DIRECTION.md
  - ../design/UIUX_GUIDELINES.md
  - ../design/VISUAL_REFERENCES.md
  - ../../docs/concepts/rapid-fire-progression-2026-08-04/01-stage-select.png
  - ../../docs/concepts/rapid-fire-progression-2026-08-04/02-aiming.png
  - ../../docs/concepts/rapid-fire-progression-2026-08-04/03-rapid-multishot.png
  - ../../docs/concepts/rapid-fire-progression-2026-08-04/04-pause-settings.png
  - ../../docs/concepts/rapid-fire-progression-2026-08-04/05-stage-clear.png
---

# Paint Mountain Rapid-Fire Progression Redesign - Execution Contract

> **Draft only — do not execute.** On 2026-08-05 the user rejected the visual
> grounding of this plan because its mockups were generated without attaching
> the corresponding current runtime screens. The user will decide whether a new
> plan should be written only after reviewing a replacement, runtime-grounded
> mockup set.

The observable outcome is a clean Korean-first Paint Mountain build in which all
thirty stages are available immediately, the player may prepare and launch the
next paintball without waiting for the previous one to stop, rolling paint has a
credible scale relative to the ball, later stages grow gradually in physical
size and complexity, and every primary screen follows the five selected visual
mockups. The verified starting point is commit 721e899: it has a useful closed
mountain and paint foundation, but exactly three hard-coded stages, a serial
one-shot state machine, an oversized paint footprint, a fixed-size version-5
generation contract, an unbounded 3D preview cache, and fragmented fixed-offset
HUD controls.

## Purpose

- Objective: turn the current vertical slice into a coherent thirty-stage MVP
  without reopening product, UX, architecture, asset, or tuning decisions during
  implementation.
- Deliverable: one production-launchable Godot 4.x desktop build plus the
  resource catalog, schemas, UI, localized copy, and off-screen running-build
  evidence that implement this contract.
- Completion state: Stage 01 through Stage 30 are selectable from a fresh or
  migrated save; repeat fire, paint, mechanisms, results, and replay observations
  remain authoritative under overlapping shots; and actual running-build screens
  visibly match the hierarchy and art direction of the five linked mockups.

## Scope and Boundaries

In scope:

- All-open Stage 01 through Stage 30 catalog and paged stage selection.
- Version-6 variable-size mountain-range generation and deterministic accepted
  layouts, default aims, mechanism slots, decoration counts, and thumbnails.
- At most two concurrent root-shot families while preserving the existing total
  physical-projectile cap of eight.
- Per-shot-family observations and authoritative paint attribution on the single
  PaintSystem mask.
- Projectile, paint footprint, bounce, damping, settlement, and cadence tuning.
- Shared Pretendard weight resources, layout components, top observation
  controls, HUD, pause/settings, and result redesign.
- Save normalization, replay/schema version migration, Agent API observations,
  background capture states, documentation, and focused final verification.

Out of scope:

- New mechanism kinds, elemental terrain materials, projectile types, steering
  after launch, caves, overhangs, terrain traversal beyond the visible backstop,
  online services, mobile UI, installers, or new production dependencies.
- Full bespoke art replacement, fluid paint simulation, runtime terrain search,
  or loading thirty live 3D menu previews.
- Broad performance micro-optimization or numerical-precision work unrelated to
  visible stutter, collision continuity, paint continuity, or stage transitions.
- The legacy all-tests matrix during implementation. Focused checks occur only
  after the functional and visual slices exist; scripts/verify.ps1 remains the
  required smoke check after script, scene, resource, or setting changes.

Constraints and invariants:

- docs/source-brief.md remains highest product authority.
- StageController remains the sole stage-state, shot-progression, and terminal
  result owner.
- PaintSystem retains one and only one authoritative 512 by 512 runtime mask for
  both visible paint and coverage.
- Projectile, stage, mechanism, progression, and result tuning live in typed
  Resources. Runtime scenes do not invent stage-specific constants.
- The Compatibility renderer and a fixed 60 Hz physics tick remain unchanged.
- A launched projectile is never steerable. Repeat fire only operates the
  stationary cannon and the next aim tuple.
- Every stage uses one closed shared top surface for rendering, collision,
  height/normal queries, target rasterization, and paint reconstruction.
- Implementation work must not open a visible Godot or game window on the
  user's desktop. Running-image checks use DeliveryCaptureRunner with a
  non-focusable off-screen window and a bounded automatic exit.
- The primary agent owns analysis, this contract, diff review, and final
  synthesis. Implementation phases are delegated as bounded worker tasks; the
  worker may not choose alternative product or architecture contracts.

Destructive or irreversible actions:

- None. Save and replay migrations preserve user progression data where
  meaningful; incompatible old replay payloads fail with an explicit version
  message instead of being rewritten.

Exact actions requiring owner or user approval:

- Adding any dependency or external asset pack not already approved.
- Substituting another named external implementation model if the user again
  requires a specific unavailable Luna Max executor. This does not reopen any
  product or implementation decision in this plan.

## Discovery Closure

| Requirement or concern | Verified current owner and behavior | Evidence | Locked decision | Task IDs |
| --- | --- | --- | --- | --- |
| All stages open | StageCatalog and StageSelectScreen enumerate exactly three resources; GameState rejects locked IDs | src/stage/stage_catalog.gd, src/ui/screens/stage_select_screen.gd, src/autoload/game_state.gd | Materialize Stage 01-30, select by catalog membership only, and normalize every save to the full catalog ID list | 0.1, 2.3, 3.1, 3.2 |
| Immediate repeat fire | StageController.request_fire accepts only AIMING and rejects while any projectile or paint is active; it owns one ShotObservation | src/stage/stage_controller.gd, src/stage/shot_observation.gd | Stay aim-ready after a valid fire and allow two active root-shot families; only Fire reaches capacity, not aiming | 1.1, 1.3 |
| Overlapping shot truth | ProjectileManager has an eight-projectile cap but no family ID; paint commands only carry spawn ordinal | src/projectile/projectile_manager.gd, src/paint/radial_paint_mark.gd, src/paint/surface_paint_sweep.gd | Add monotonic shot_id propagation and family-local sealing while retaining one globally ordered paint mask | 1.1, 1.2, 1.5 |
| Ball/paint mismatch | Basic ball radius is 0.52 m while trail, impact, and settle paint radii are 4.0, 6.0, and 4.0 m | resources/projectiles/basic_paintball.tres | Use the exact tuning table in this contract; moving paint diameter becomes 3.75 times ball diameter | 1.4 |
| Approximately doubled pace | Existing UI exposes raw 1x/2x, but normal speed changes are conditional and StageController adds modal settlement/result waits | src/gameplay/gameplay_scene.gd, src/ui/hud/observation_controls.gd, src/stage/stage_controller.gd | Keep airborne physics at 1.0, remove modal waits, halve presentation delays, shorten settlement, and apply optional 2.0 time scale only after all active roots have made first target contact | 1.3, 4.3 |
| Physics safety at faster pace | At fixed ticks, Engine.time_scale increases logical delta and values above 1 can reduce physics precision | Godot 4.7 MainLoop and Engine documentation | Never use 2.0 while any root projectile is airborne; retain CCD and prove continuous grounded contact/paint at fast progress | 1.3, 6.2 |
| Thirty gradual mountains | Version-5 contract fixes 72x48 cells, 180x120 bounds, eight stations, and 6,912 top triangles | src/stage_generation/stage_generation_contract.gd, resources/stage_generation/version5_generation_contract.tres | Replace fixed equality checks with the bounded version-6 progression formulas below; maximum remains 12,288 top triangles | 2.1, 2.3 |
| More mechanisms | StageRouteProfile has one mechanism pad and placement resolves the first pad of a kind | src/stage_generation/stage_route_profile.gd, src/stage_generation/mechanism_placement_generator.gd | Introduce stable typed pad slots and stage slot assignments; counts rise from one to six with at most two of one kind | 2.2, 2.3 |
| No menu-transition stutter | AppRoot builds and caches a full mesh/material/dressing artifact per previewed stage without eviction | src/app/app_root.gd | Stage selection uses committed static thumbnails; gameplay owns at most the selected generated layout and an explicit one-entry preview cache | 3.3, 5.1 |
| Clean bold UI | Pretendard is loaded but the shared theme has no explicit variable-font weight owners; HUD scenes use fixed offsets and mixed card dimensions | resources/ui/paint_mountain_theme.tres, scenes/ui, src/ui | Add shared 500/600/700 FontVariation resources and the exact responsive screen contracts below | 4.1-4.5 |
| Intuitive top controls | ObservationControls is a six-text-button strip: follow, wide, cannon, 1x, 2x, pause | scenes/ui/hud/observation_controls.tscn, src/ui/hud/observation_controls.gd | Use one three-mode camera segment, pause icon, and one honest Fast Progress toggle; selected and disabled states include text and color | 4.3 |
| Icons | Six approved Kenney icons exist; the pinned approved archive contains the exact additional files and its SHA-256 matches the ledger | docs/asset-licenses.md and inspected Kenney Game Icons archive hash 7A86D8D58E0B851E22004B3C70BF90B003632BBF9AC633424DAA3BB17D9E7E4E | Import only the ten exact files in the asset manifest below; no new pack or approval is required | 0.3 |
| Visual target | Existing direction requires a warm off-white thick faceted mountain, blue paint, sparse edge HUD, and Korean-first type | .agents/design files, original target reference, current running captures, five new mockups | The five mockups lock hierarchy and composition; runtime geometry and values remain authoritative | 4.1-4.5, 6.3 |
| Non-disruptive rendered QA | DeliveryCaptureRunner already moves a real Compatibility-renderer window off-screen and removes focus | src/delivery/delivery_capture_runner.gd | Extend named states and size arguments; never launch an ordinary visible editor/game window | 5.2, 6.3 |

Readiness statement:

- Every material product, architecture, dependency, data, UX, ownership, safety,
  and validation decision is closed.
- Required engine, fonts, approved assets, generation foundation, paint mask,
  projectile manager, background capture path, and export preset already exist.
- Remaining unknowns are implementation-local defects that cannot change this
  contract. A material contradiction triggers the predetermined replan rule.

## Locked Product and Technical Contract

### 1. Repeat-fire state and terminal rules

- StageController assigns a monotonically increasing positive shot_id for every
  accepted root fire.
- A shot family is one root projectile plus every Splitter child carrying the
  same shot_id.
- Maximum active root families is 2. Maximum physical projectiles remains 8.
- A valid fire consumes one shot immediately and leaves yaw, elevation, power,
  trajectory prediction, and the cannon available for the next aim.
- Fire is enabled when shots remain and active root families are fewer than 2.
  At capacity, only Fire is disabled; the aim controls continue to respond.
- Existing balls never inherit later aim changes and never accept steering.
- Each family seals after all family projectiles terminate and every paint
  command carrying that shot_id has drained into PaintSystem.
- A family coverage gain is the count of target pixels that family first changed
  from unpainted to painted. Global command ordering resolves simultaneous
  overlap deterministically; overlap still counts once globally.
- A nonmodal +N.N% chip appears when a family seals. There is no input-blocking
  SHOT_RESULT state or fixed result delay between shots.
- Stage clear or failure is evaluated only after no root family and no paint
  command remains. This preserves paint from a last already-fired ball.
- If the target is exceeded while a family remains active, the stage waits for
  that already-fired family, but does not permit additional shots after the
  terminal condition has become inevitable.

### 2. Projectile, paint, and pacing values

| Parameter | Locked value |
| --- | ---: |
| Visible and collision ball radius | 0.60 m |
| Continuous contact paint radius | 2.25 m |
| First-impact paint radius | 3.20 m |
| Settlement paint radius | 2.25 m |
| Physics bounce | 0.03 |
| Physics friction | 0.90 |
| Linear damp | 0.55 |
| Angular damp | 1.10 |
| Minimum movement speed | 1.70 m/s |
| Stop-duration threshold | 0.50 simulation seconds |
| Maximum lifetime | 12.0 simulation seconds |
| Maximum active root families | 2 |
| Maximum physical projectiles | 8 |
| Airborne time scale | 1.0 |
| Grounded Fast Progress time scale | 2.0 |

The continuous paint diameter is 4.50 m and the ball diameter is 1.20 m, a
3.75-to-1 relationship. The only permitted first visual rework range is
continuous/settle radius 2.00 to 2.50 m; changing outside that range is a
contract change, not executor discretion.

Fast Progress is on by default. Engine.time_scale is 1.0 whenever no projectile
is active or any active root has not yet reached its first target-top contact.
It becomes 2.0 only while all active roots and descendants are in grounded
post-contact motion. Turning Fast Progress off keeps 1.0 throughout. Muzzle,
camera blend, family-gain chip, clear reveal, and failure reveal durations become
50 percent of their existing values. Replay retains its separate playback-speed
control and recorded physics-tick semantics.

### 3. Version-6 stage progression

Let n be the integer stage number 1 through 30 and t be (n - 1) / 29.
Round-even means nearest even integer, with exact ties rounded upward.

- Terrain X size is round-even(180 + 60t) metres.
- Terrain Z size is round-even(120 + 40t) metres.
- Cell count X is round-even(72 + 24t); cell count Z is round-even(48 + 16t).
- Maximum top-triangle count is exactly 2 times the two cell counts and cannot
  exceed 12,288.
- Nominal peak is round(72 + 54t) metres. Accepted height is nominal minus
  4 metres through nominal plus 10 metres.
- Mask size stays 512, accepted-seed attempts stay 32, seed stride stays 7,919,
  and the fixed P01-to-P10 cell diagonal remains.
- Route stations are 8 for Stage 01-10, 9 for Stage 11-20, and 10 for Stage
  21-30. Stations span the same normalized rear-to-front range for every bound.
- Route count is 1 for Stage 01-05, 2 for Stage 06-15, and 3 for Stage 16-30.
- Exact per-route grade reversals are 0 for Stage 01-03, 1 for Stage 04-10,
  2 for Stage 11-20, and 3 for Stage 21-30.
- Broad ridge counts by five-stage band are 3, 4, 5, 6, 7, and 8.
- Wide basin counts are 0, 1, 1, 2, 2, and 2. Basin depth stays between 3.5
  and 5.5 percent of nominal peak, cannot cover the central summit, and cannot
  disconnect or hollow the solid mass.
- Broad pass counts are 0, 1, 1, 2, 2, and 3. Wave counts are 0, 1, 1, 2, 2,
  and 3. These increase macro undulation; noise amplitude stays at or below
  0.60 m and never creates needle peaks.
- Base route widths by band are 28, 24, 22, 20, 19, and 18 m. A designated
  safe route is 4 m wider. No route is narrower than 18 m.
- Decoration count is 10 + round(22 times t), producing 10 through 32.
- Backstop, apron, closed side faces, immutable top triangles, collision,
  target mask, paint reconstruction, and height queries scale from the same
  version-6 contract.

| Band | Stages | Mean target slope | Target p95 max | Target absolute max | Route p95 max | Corridor lip max | Mechanisms |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| First Ridge | 01-05 | 16-28 degrees | 34 | 38 | 32 | 30 | 1 |
| Forked Valley | 06-10 | 17-29 degrees | 35 | 39 | 33 | 31 | 2 |
| Winding Range | 11-15 | 18-30 degrees | 36 | 40 | 34 | 32 | 3 |
| Device Corridor | 16-20 | 19-31 degrees | 37 | 41 | 35 | 33 | 4 |
| Layered Peaks | 21-25 | 20-32 degrees | 38 | 42 | 36 | 34 | 5 |
| Summit Chain | 26-30 | 21-33 degrees | 40 | 44 | 38 | 35 | 6 |

Localized band labels are respectively 첫 능선, 갈라진 골짜기, 굽이치는 산맥,
장치 회랑, 겹친 봉우리, and 정상 연쇄. The display title is
스테이지 NN · band label. Stable IDs are stage_01 through stage_30.

Target coverage is deterministic:

- Stage 01-10: 4.0 + 0.5 times (n - 1) percent.
- Stage 11-20: round to nearest 0.5 of 9.0 + 0.35 times (n - 11).
- Stage 21-30: round to nearest 0.5 of 12.5 + 0.30 times (n - 21).
- Maximum shots are 4, 5, 5, 6, 6, and 7 by the six five-stage bands.
- One, two, and three stars require target, target plus 2.5, and target plus
  5.0 percentage points.

Every accepted stage stores a default aim whose first physical target hit is the
certified hit nearest the target-mask centroid. The same aim is restored on
start and restart. The existing legal yaw, elevation, and power ranges remain;
the offline builder rejects a stage whose full target is not legally reachable.

### 4. Multiple mechanism slots

- Add MechanismPadProfile with stable slot_id, kind, normalized_t, and radius.
- StageRouteProfile owns an array of pad profiles rather than one kind/t/radius
  triple.
- Add StageMechanismEntry with slot_id and MechanismData; StageData owns an
  array of these entries.
- Route resolution splits the proper edge at every ordered pad and the generated
  graph resolves pads by slot_id, never by first matching kind.
- Mechanism count is exactly 1 through 6 by five-stage band. Types rotate from
  the fixed cycle Burst, Splitter, Bumper using (n + slot index - 1) modulo 3,
  so six slots contain exactly two of each.
- Slots distribute round-robin across routes and use normalized candidate
  positions 0.22, 0.38, 0.54, 0.68, 0.80, and 0.30 in that order.
- The accepted-seed validator requires at least 18 m center separation, 12 m
  separation from summit and exit anchors, the existing collider clearance,
  and visibility from the stage overview camera.
- Pad radii remain Burst 8 m, Splitter 10 m, and Bumper 9 m.
- Semantic colors remain amber Burst, violet Splitter, and coral Bumper, with
  the existing radial, three-way, and directional silhouettes. Color is never
  the only cue.

### 5. Persistence, replay, and catalog

- The production catalog loads one typed StageCatalogData index listing thirty
  StageData resources in numeric order; no scene or script contains thirty
  hand-wired buttons.
- Fresh saves contain all catalog IDs. Loading any older save replaces its
  unlocked list with all current catalog IDs, preserves valid best scores and
  settings, maps first_descent/burst_basin/split_ridge to stage_01/stage_02/
  stage_03, and falls back to stage_01 only for an unknown selected ID.
- Selecting a stage checks only catalog membership.
- Completing a stage records score/stars and offers the numeric next stage; it
  does not mutate unlock state.
- Replay and ShotObservation schema versions increment together. Each Fire
  action stores shot_id and active-family order. Old replay versions are rejected
  with a localized incompatibility message; save data is not rejected.
- Agent observations add active_shot_families, active_projectiles,
  ready_for_action, and fire_capacity. ready_for_action means aiming is legal;
  fire_capacity greater than zero means Fire is legal.

### 6. UI, copy, typography, and icon contract

Shared color roles remain warm surface #FFFDFC, navy #172538, primary paint blue
#2584FF, rail #C9CDD2, and danger #D94C4C. Mechanism semantic colors remain in
ART_DIRECTION.md. Corner radii are 16 px for ordinary controls and 20 px for
primary/modal surfaces. Spacing uses an 8 px rhythm with 20-24 px screen-safe
margins.

PretendardVariable.woff2 is wrapped by three shared FontVariation resources:
helper 500, interface 600, and emphasis 700. Body text and ordinary buttons use
600; headings, values, selected tabs, and primary actions use 700. No user-facing
gameplay text uses a weight below 500.

At 1280 by 720:

- Stage Select uses a 24 px margin, 64 px header, a left 740 px five-column by
  two-row grid, a 12 px gap, a right 456 px selected-stage image/summary, and
  three page tabs 1-10, 11-20, 21-30. Every card is enabled. Only ten 512 by
  288 committed PNG thumbnails for the current page are loaded; there is no live
  3D preview in the menu.
- Aiming keeps stage at top-left, shots plus gear at top-right, a 96 px wide
  vertical coverage meter at left center, a 340 by 154 aim card at lower-left,
  and one 220 by 80 Fire button at bottom center. Restart is absent.
- The top-center group contains three camera segments: target icon plus 공 추적,
  zoom-out icon plus 산 전체, and home-view icon plus 대포 시점. Beside it are
  pause and one fast-forward icon toggle labelled 빠른 진행. Raw 1x/2x controls
  do not appear in normal gameplay.
- The status line reads 발사 가능 · 진행 중인 공 N/2 while capacity remains,
  or 다음 공 대기 · 진행 중인 공 2/2 at capacity. The disabled bottom action
  reads 다음 공 대기. A sealed family shows a nonmodal +N.N% near its trail.
- Settings is a centered 760 by 560 panel with text navigation 게임, 소리, 언어;
  it owns Fast Progress, default camera, aim guide, vibration, language, and
  audio. Restart is an action in the paused panel footer, not a settings value.
- Result is a centered 460 px panel showing authoritative coverage, target,
  stars, 사용한 탄, 최고 한 발, and 남은 탄. Actions are 다시 하기, 다음
  스테이지, and 스테이지 선택. There is no unlock celebration.
- At 1600 by 900, container anchors expand world visibility and gaps while the
  above control widths remain capped. No fixed child offsets may clip Korean or
  English copy.

The additional icon import is fixed to the already approved Kenney Game Icons
archive, directory PNG/White/2x:

| Upstream file | Local file | SHA-256 | Use |
| --- | --- | --- | --- |
| zoomOut.png | assets/ui/icons/camera_wide.png | A5304AA80AB12E4319599799F67C088F4B6ADC270DC77FEE8B2EC18EE85D91A0 | mountain overview |
| home.png | assets/ui/icons/camera_cannon.png | 1F6D39DF47CB8849FEB8F01AAD329583F5F014C449C622B39AA154A3ECA55160 | cannon/home view |
| fastForward.png | assets/ui/icons/fast_progress.png | 7530D9BDFC4FC12A682365DB063A1EBAAB54184F4ACF849F6FC02652BAC1B4CE | Fast Progress |
| cross.png | assets/ui/icons/close.png | 8293E3758E7DF2EB1C5BB8D6979CCCC826E66C28F8C703E6CBB0A54A3C0EFC33 | close modal |
| right.png | assets/ui/icons/play.png | 4A03B4912262EF74A04DAC87A59DB2ED9DC8C1C9C527439E490630CA899CF252 | play/continue |
| next.png | assets/ui/icons/next.png | D78A2548F8A2360F4496ED499CA280FA377F1E486510C6957B9703E597F550E6 | next stage |
| star.png | assets/ui/icons/star.png | 8E10578B82D6D46AFF27A9939F4C1ADCCD1BE6DC93C8302C9E28D281E126AAE2 | score stars |
| checkmark.png | assets/ui/icons/checkmark.png | 00E3025322DDB4948598B7FB8D385762073DE7B2B534D2CFD44372072608A92A | completed stage |
| audioOn.png | assets/ui/icons/audio_on.png | AEE49FF7B9151214178079EB860A341958BA54627C93D0B2636B05670A37A585 | audio group |
| gamepad.png | assets/ui/icons/gameplay.png | 409EC081344F893B7103C98EC3AEC00B1709A4EE74679E3DA2B877D9FB0A2275 | gameplay group |

Existing target, restart, minus, plus, pause, settings, and paint-splash assets
are reused. No emoji, text glyph stars, handmade SVG, or placeholder icon enters
the runtime UI.

### 7. Menu and runtime performance boundaries

- Stage Select never generates terrain, materials, paint textures, dressing, or
  collision. It loads at most ten card thumbnails plus the selected thumbnail.
- AppRoot removes the unbounded preview-artifact dictionary. Gameplay may retain
  one prepared GeneratedStageLayout for the selected stage and must release it
  when returning to Stage Select.
- Starting a stage uses its accepted seed directly; it never searches 32
  candidates at runtime.
- Stage generation, mesh building, target rasterization, and decoration setup
  occur before the aiming state is shown and never repeat on camera changes.
- Camera modes only change transforms and tracked targets. They never rebuild
  terrain, target masks, paint textures, or UI scenes.
- Projectile rendering remains interpolated; paint commands remain bounded and
  drained by the existing deterministic queue. Two families may not create a
  second paint representation or an unbounded per-frame allocation.

## Tasks

### Phase 0: Align authority, schemas, and approved assets

Goal: remove conflicts before behavior changes and establish the exact typed
owners that every later phase consumes.

Preconditions:

- The five concept images and this contract are committed.
- No production gameplay implementation has begun under this plan.

Source owners: docs/source-brief.md, docs/design-spec.md,
docs/technical-architecture.md, docs/test-checklist.md, README.md,
docs/asset-licenses.md, resources/ui, assets/ui/icons, StageData,
StageRouteProfile, ShotObservation, replay schemas

- [ ] **0.1 Align active specifications with the superseding user contract**
  - Change: update design, architecture, checklist, README, and implemented-status
    wording so thirty all-open stages, two-family repeat fire, honest Fast
    Progress, and the five screens replace exact-three and settle-before-fire
    claims. Do not claim implementation.
  - Accept: targeted searches find no active-spec requirement for exactly three
    stages, unlock gating, Fire blocked until full settlement, or normal-game
    raw 1x/2x buttons.
- [ ] **0.2 Introduce versioned typed schema owners**
  - Change: add version-6 generation/progression resources, mechanism pad and
    slot-assignment resources, family-aware ShotObservation fields, and explicit
    save/replay schema constants without changing runtime behavior yet.
  - Accept: resources parse, old stage resources still load through the named
    migration path, and no stage-specific constants move into UI or scripts.
- [ ] **0.3 Import only the locked Kenney icon subset**
  - Change: extract the ten manifest files from the already approved pinned
    archive, verify archive and file hashes, commit the renamed local files, and
    append their runtime uses to docs/asset-licenses.md.
  - Accept: every committed file hash matches this contract; no other archive
    member or dependency is added.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.

### Phase 1: Deliver repeat fire, truthful paint, and faster cadence

Goal: make the core loop immediately feel different before expanding content.

Preconditions:

- Phase 0 acceptance and batch gate pass.

Source owners: src/stage/stage_controller.gd, src/stage/shot_observation.gd,
src/projectile, src/paint, src/mechanisms, src/gameplay/gameplay_scene.gd,
src/input/aim_input_controller.gd, src/replay, src/agent,
resources/projectiles/basic_paintball.tres

- [ ] **1.1 Add root-shot family identity and capacity**
  - Change: StageController issues shot_id; ProjectileManager and every child
    carry it; active families are tracked independently from physical projectile
    count; aiming remains legal after Fire.
  - Accept: a second root shot can launch while the first remains active; a third
    cannot launch at two active families; later aim changes do not affect either
    launched family.
- [ ] **1.2 Attribute one authoritative paint mask by shot family**
  - Change: add shot_id to radial/sweep commands and the deterministic ordering
    key; PaintSystem records first-painted target pixels per family without a
    second coverage map.
  - Accept: simultaneous overlap counts once globally, each sealed family has a
    deterministic gain, and visible paint equals coverage source data.
- [ ] **1.3 Remove serial result waits and implement Fast Progress**
  - Change: replace PAINT_SETTLING/SHOT_RESULT input locks with family sealing,
    defer terminal state until all already-fired work drains, halve presentation
    delays, and switch to grounded-only 2.0 according to the locked rule.
  - Accept: the player can re-aim immediately after Fire; airborne movement stays
    at 1.0; Fast Progress changes only post-contact cadence; the last ball's
    paint is included before clear/failure.
- [ ] **1.4 Apply the locked ball, brush, and settlement tuning**
  - Change: update the typed ProjectileData resource and any visual mesh scale or
    collision radius consumers from the table above.
  - Accept: renderer, collision, predictor, CCD, contact classifier, and paint
    reconstruction use the same 0.60 m radius; trail width is visibly moderate
    and continuous.
- [ ] **1.5 Version replay and shared observations**
  - Change: update replay actions/observations and Agent API fields; reject old
    replay format explicitly while preserving save data.
  - Accept: a recorded two-family sequence replays with the same family order,
    paint gains, coverage, terminal result, and active/capacity observations.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.
- Do not start the broad legacy test script in this phase.

### Phase 2: Deliver the version-6 thirty-stage mountain catalog

Goal: materialize thirty progressively larger, more undulating, solid mountain
ranges and their visible mechanisms without runtime search.

Preconditions:

- Phase 1 acceptance and batch gate pass.

Source owners: src/stage_generation, resources/stage_generation,
src/stage/stage_data.gd, resources/stages, scripts/build_stage_catalog.gd,
src/mechanisms, src/terrain, src/camera

- [ ] **2.1 Parameterize the shared version-6 terrain contract**
  - Change: replace fixed version-5 equality checks with bounded per-stage
    contract validation; parameterize stations, bounds, cells, ridge/pass/basin
    complexity, and slope gates while preserving one closed indexed surface.
  - Accept: Stage 01 and Stage 30 resolve to the exact formula endpoints; no
    emitted layout exceeds 12,288 top triangles or contains a second top,
    detached mass, tunnel, spike, or open side.
- [ ] **2.2 Support multiple stable mechanism pad slots**
  - Change: implement MechanismPadProfile, StageMechanismEntry, edge splitting
    for all ordered pads, lookup by slot_id, and separation/visibility checks.
  - Accept: one through six mechanisms appear according to band; Stage 30 has two
    of each kind; every visible body and collider agrees with its slot and kind.
- [ ] **2.3 Add one typed progression resource and deterministic offline builder**
  - Change: store the formulas and band values in StageProgressionData; add a
    headless builder that writes StageData, profiles, contracts, accepted seeds,
    default aims, solutions where available, and the catalog index.
  - Accept: the command
    & $env:GODOT_BIN --headless --path . --script
    res://scripts/build_stage_catalog.gd -- --write
    produces identical checksums on two clean runs and stops with a clear error
    if any stage cannot meet the contract within 32 attempts.
- [ ] **2.4 Materialize Stage 01-30 resources and static thumbnails**
  - Change: commit the thirty generated resources and 512 by 288 PNG thumbnails;
    thumbnails use the real accepted terrain, camera, mechanisms, palette, and
    no gameplay paint fabrication.
  - Accept: numeric IDs are complete and unique, every resource references its
    accepted seed/checksum, thumbnail count is exactly thirty, and later bands
    visibly increase size/undulation/items without abrupt silhouettes.
- [ ] **2.5 Reframe cannon, default aim, backstop, and cameras per stage**
  - Change: derive camera bookmarks, cannon-to-mountain composition, wall/apron,
    bounds, and centroid-near default hit from each accepted layout.
  - Accept: every default aim's first physical hit is its stored target triangle;
    trajectory dots reach that hit; overview and cannon views contain the whole
    board; legal shots do not pass over the current backstop.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.
- Inspect Stage 01, 10, 20, and 30 emitted geometry metadata before UI work.

### Phase 3: Deliver all-open progression and a non-stuttering stage browser

Goal: make all thirty stages directly reachable and keep menu navigation cheap.

Preconditions:

- Phase 2 acceptance and batch gate pass.

Source owners: src/stage/stage_catalog.gd, src/autoload/game_state.gd,
src/autoload/save_system.gd, src/app/app_root.gd,
src/ui/screens/stage_select_screen.gd, scenes/ui/screens/stage_select.tscn,
resources/stages/catalog, translations/ui.csv

- [ ] **3.1 Replace hard-coded catalog and cards with data-driven paging**
  - Change: load StageCatalogData, create reusable card components, render five
    columns by two rows, and bind the three fixed page ranges.
  - Accept: every Stage 01-30 card is enabled and focusable; keyboard/controller
    traversal stays within the visible page and updates the selected summary.
- [ ] **3.2 Normalize fresh and existing saves to all-open selection**
  - Change: apply the locked ID migration and remove unlock-state mutation from
    completion while preserving valid best scores, settings, and selected stage.
  - Accept: a fresh save, old three-stage save, and partially unlocked save can
    select Stage 30 immediately; no lock icon or disabled stage remains.
- [ ] **3.3 Remove live menu generation and unbounded preview caching**
  - Change: Stage Select loads only current-page thumbnails; AppRoot no longer
    creates mesh/material/dressing previews during card changes and releases the
    prepared layout when leaving gameplay.
  - Accept: switching pages or selections never calls SeededStageGenerator,
    RouteGraphMountainSynthesizer, PaintSystem.configure, or dressing generation;
    repeated paging does not grow preview cache ownership.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.

### Phase 4: Deliver the five-screen UI and typography system

Goal: implement the selected visual hierarchy with honest controls and bold,
stable Korean typography.

Preconditions:

- Phase 3 acceptance and batch gate pass.

Source owners: resources/ui/paint_mountain_theme.tres, resources/ui/fonts,
scenes/ui, src/ui, src/gameplay/gameplay_scene.gd, translations/ui.csv,
assets/ui/icons, the five linked concept images

- [ ] **4.1 Build shared type, spacing, panel, and control owners**
  - Change: add the three FontVariation resources, shared styleboxes, selected,
    hover, focus, disabled, and modal states, and reusable icon/text button and
    segmented-control scenes.
  - Accept: no screen adds a one-off font or duplicate primary style; Korean
    body is 600 and headings/actions are 700; keyboard focus is visible.
- [ ] **4.2 Implement Stage Select and aiming HUD composition**
  - Change: match the exact layout contract and 01-stage-select/02-aiming
    mockups using containers and anchors; keep world-space mountain dominant.
  - Accept: 1280x720 and 1600x900 show no overlap, clipping, or off-screen child;
    Fire remains the sole bottom-center primary action.
- [ ] **4.3 Replace the top strip with camera, pause, and Fast Progress groups**
  - Change: implement the three camera segments, selected state, pause, Fast
    Progress toggle, status line, active-family count, and capacity copy.
  - Accept: every control's visible state matches actual behavior; raw 1x/2x is
    absent during normal play; capacity 2/2 disables only Fire.
- [ ] **4.4 Redesign pause/settings and result states**
  - Change: implement the 760x560 paused settings surface and centered 460 px
    result surface from the mockups, with truthful values and all-open next-stage
    behavior.
  - Accept: pause captures input and time; Restart lives in the paused action
    footer; result values come from StageController/ShotObservation rather than
    placeholder copy.
- [ ] **4.5 Keep replay distinct and localization complete**
  - Change: retain explicit replay 1x/2x controls only inside replay, update
    Korean/English strings, accessible names, tooltips, and focus order.
  - Accept: Korean is default, English switch persists, neither locale clips at
    the two supported sizes, and icons never replace required accessible labels.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.
- Do not open an ordinary visible editor/game window.

### Phase 5: Integrate cameras, paint, and transition responsiveness

Goal: make the completed features remain smooth through menus, firing, follow
camera motion, paint publication, and result transitions.

Preconditions:

- Phase 4 acceptance and batch gate pass.

Source owners: src/camera, src/projectile, src/paint, src/app/app_root.gd,
src/delivery/delivery_capture_runner.gd, project settings

- [ ] **5.1 Remove work from navigation and camera-motion hot paths**
  - Change: verify generation occurs only at stage preparation; reuse mesh,
    collision, material, mask texture, and UI components; remove per-frame or
    per-camera-change geometry/material rebuilds and avoid transient allocations
    in follow updates.
  - Accept: page changes do no 3D work, Fire does not synchronously generate a
    stage or rebuild paint resources, and camera changes only update camera state.
- [ ] **5.2 Extend off-screen delivery capture states**
  - Change: add stage-select page 1/page 3, aiming, rapid_multishot,
    pause_settings, stage_clear, and stage_30_aiming states plus
    --capture-size=1280x720 or 1600x900.
  - Accept: each state is reached through real application/gameplay owners,
    captures from a non-focusable off-screen Compatibility window, writes one
    PNG, and exits without user interaction.
- [ ] **5.3 Stabilize multi-projectile camera and paint feedback**
  - Change: frame both families without violent recentering, preserve
    interpolation, keep landing/contact readable, and pool gain chips/VFX.
  - Accept: two balls remain visually trackable, the rolling ball paints directly
    under contact, trajectory/landing cues remain visible, and no camera mode
    causes terrain or HUD disappearance.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.

### Phase 6: Verify the completed MVP and hand off real evidence

Goal: verify after the functional and visual work exists, without taking over the
user's desktop or substituting mockups for runtime proof.

Preconditions:

- Phases 0-5 and every batch gate pass.

Source owners: tests, scripts/verify.ps1, export_presets.cfg,
src/delivery/delivery_capture_runner.gd, .agents/evidence,
docs/test-checklist.md, .agents/Documentation.md

- [ ] **6.1 Run the scoped architecture and quality audit**
  - Change: use codebase-quality-auditor on the multi-file diff; correct only
    task-owned responsibility creep, duplicate owners, public-contract drift,
    stale fallback paths, and obsolete serial-shot/three-stage code.
  - Accept: StageController, PaintSystem, typed Resources, UI, persistence, and
    generator ownership still match AGENTS.md; obsolete owners are removed.
- [ ] **6.2 Run focused post-feature contract checks**
  - Change: add/update only tests for thirty-stage catalog formulas, all-open
    migration, repeat-fire capacity, family paint attribution, last-family
    terminal drain, v6 closed geometry, multiple pads, and UI copy/state.
  - Accept: the focused commands named in Validation pass. Continuous paint has
    no gaps under grounded Fast Progress and no persistent paint occurs off the
    scoreable top.
- [ ] **6.3 Export and compare real running-build screens**
  - Change: export Windows Desktop once, run every named capture off-screen at
    1280x720 and the layout-sensitive states at 1600x900, then inspect each actual
    capture paired with its corresponding concept/reference image.
  - Accept: actual screens preserve the selected hierarchy, thick solid mountain,
    bold typography, semantic mechanism colors, moderate paint width, and
    unclipped layouts. Mockups are never reported as implementation evidence.
- [ ] **6.4 Update truthful project status and finish the plan**
  - Change: record implemented status, commands, evidence paths, known remaining
    issues, and final file/commit scope; change this plan to done only after every
    acceptance item passes.
  - Accept: Documentation.md and test-checklist.md distinguish verified runtime
    behavior from unverified or future work and link the separate actual captures.

Batch gate:

- Run powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1.
- Export once with:
  & $env:GODOT_BIN --headless --path . --export-release "Windows Desktop"
  "builds\windows\PaintMountain.exe"
- Run captures only through the off-screen --capture-background path.

## Validation and Rework Controls

| Cadence | Exact check | Run when | Do not rerun until |
| --- | --- | --- | --- |
| Inner loop | powershell -ExecutionPolicy Bypass -File .\scripts\verify.ps1 | After a phase changes scripts, scenes, resources, or settings | A relevant implementation input changes |
| Focused gameplay | & $env:GODOT_BIN --headless --path . --script res://tests/rapid_fire_contract_test.gd | Phase 6 after repeat-fire implementation is complete | Repeat-fire, projectile, paint, or state inputs change |
| Focused content | & $env:GODOT_BIN --headless --path . --script res://tests/stage30_progression_test.gd | Phase 6 after all generated content is committed | Progression, generation, catalog, or mechanism inputs change |
| Focused UI | & $env:GODOT_BIN --headless --path . --script res://tests/ui_contract_test.gd | Phase 6 after all five screens exist | UI scene, theme, localization, or state-binding inputs change |
| Final export | & $env:GODOT_BIN --headless --path . --export-release "Windows Desktop" "builds\windows\PaintMountain.exe" | Once after all phase and focused checks pass | A production-owned input changes |
| Final rendered evidence | Exported executable with --capture-background, the named --capture-screen state, and --capture-size | Once per required final state and size after export | A visible owner or capture-state input changes |

Validation rules:

- Run the narrowest check that proves the current task.
- Run each named phase gate once after its owned tasks pass.
- Do not run scripts/test.ps1 or the historical broad matrix during Phases 0-5.
- Keep the exported process off-screen and non-focusable; terminate it
  automatically after the bounded capture.
- Pair actual and concept/reference images in the same visual-inspection turn.
- Rerun a failed check only after a relevant implementation change or a new
  hypothesis can produce new evidence.
- Record known non-blocking warnings once instead of rediscovering them.

## Predetermined Contingencies and Change Control

| Trigger | Required response | Boundary or escalation point |
| --- | --- | --- |
| A verified material fact contradicts this contract | Stop the affected branch, update the contract, and obtain any required approval before resuming | The executor may not choose a new product, architecture, dependency, data, UX, safety, or validation contract |
| One of thirty stages cannot satisfy generation gates within 32 deterministic attempts | Record the failing stage/metric; adjust only that band's typed progression bounds within the locked size, slope, count, and no-spike limits; rebuild the complete catalog deterministically | Do not hand-author repair coordinates, accept a fallback layout, or search at runtime |
| Two-family Fast Progress creates missed grounded contacts or paint gaps | Keep airborne 1.0, lower grounded Fast Progress to 1.5, and record the deviation with evidence | Do not raise physics ticks above 60 or widen paint to hide gaps |
| A 1280x720 Korean label does not fit | Shorten only to the exact approved compact alternatives 공 추적, 산 전체, 대포 시점, 빠른 진행, 다음 공 대기; otherwise adjust container allocation | Do not reduce body text below 14 px or weight below 500 |
| Stage Select memory grows while paging | Release page textures and retain only current page plus selected thumbnail | Do not restore live 3D previews or an unbounded cache |
| Existing save contains unknown stage IDs | Preserve unrelated settings/scores, drop only unknown stage keys, select stage_01, and normalize the available list | Do not delete the save or block startup |
| Old replay format is loaded | Show localized incompatibility copy and return safely to its owning screen | Do not guess missing shot-family data or silently replay incorrectly |
| The requested named external execution model is unavailable | Keep this plan active and report the unavailable executor before implementation delegation | Do not silently impersonate or substitute a model identity |

Implementation-local discoveries may be handled inside the locked contract when
they cannot change scope, visible behavior, ownership, architecture, safety, or
acceptance.

## Progress and Next Steps

- Canonical progress: the task checkboxes in this contract.
- Current phase: Phase 0.
- Next task: 0.1 Align active specifications with the superseding user contract.
- Last completed gate: Discovery Closure Gate; five visual mockups saved; pinned
  Kenney archive and ten additional icon hashes verified.
- Update rule: after a checkpoint passes, record concise evidence, check the
  task, and advance this pointer in the same edit.

## Completion and Stop Conditions

Complete when:

- Every task acceptance check passes.
- Every guard, phase gate, and final gate named by this contract passes.
- No placeholder or unresolved material product/technical decision remains.
- Every Stage 01-30 resource, thumbnail, default aim, and catalog entry exists.
- Actual off-screen running-build evidence, not concept art, proves the five
  screen families and Stage 30 gameplay composition.
- Durable decisions and new run/verify knowledge are recorded in their owning
  spec, record, documentation, or repo-local skill.
- Frontmatter status is changed to done only after implementation is complete.

Replan when:

- A material discovery invalidates the locked contract.

Do not replan or stop for:

- Implementation-local mechanics already contained by this contract.
- A passing check whose relevant inputs have not changed.
- Small visual differences in generated terrain silhouette that still satisfy
  the approved art, readability, geometry, and layout contracts.
