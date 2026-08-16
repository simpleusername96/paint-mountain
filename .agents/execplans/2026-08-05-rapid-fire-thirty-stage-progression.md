---
type: plan
status: superseded
created: 2026-08-05
last_reviewed: 2026-08-05
scope: concurrent root-shot families, deterministic paint attribution, faster grounded cadence, thirty generated stages, all-open persistence, and non-generating stage selection
source: source brief plus user progression and pacing directives through 2026-08-05
superseded_by: 2026-08-05-gameplay-contract-recovery.md
related:
  - ../PLANS.md
  - ../Documentation.md
  - ../../AGENTS.md
  - ../../docs/source-brief.md
  - ../../docs/design-spec.md
  - ../../docs/technical-architecture.md
  - ../../docs/test-checklist.md
  - 2026-08-05-physical-gameplay-mvp.md
  - 2026-08-05-runtime-grounded-interface.md
  - ../research/concepts/runtime-grounded-ui-2026-08-05/README.md
---

# Rapid Fire and Thirty-Stage Progression - Execution Contract

> Superseded on 2026-08-05 after a static code and plan audit found that the
> implementation cloned three legacy profiles instead of executing the locked
> version-6 progression and left repeat-fire visually unusable. The sole active
> recovery contract is
> [`2026-08-05-gameplay-contract-recovery.md`](2026-08-05-gameplay-contract-recovery.md).

This plan expands an accepted physical gameplay MVP into thirty immediately
selectable stages and allows the player to launch a second root paintball while
the first family is still moving. It is decision-complete but execution-queued:
do not modify its owners until `2026-08-05-physical-gameplay-mvp.md` is marked
done and its user checkpoint is approved.

### Execution override (2026-08-05)

The user explicitly authorized the full plan set to run without an intermediate
foreground checkpoint. The predecessor's objective gates were verified in the
same pass, so the queued-prerequisite wording above is historical for this
execution and does not block the implemented progression work.

The user explicitly requested new ExecPlans in the plural and this plan has a
separate scope and prerequisite, so the multiple-active-plan exception in
`.agents/PLANS.md` applies. `active` means the decisions are current; it does not
make this queued plan executable before its prerequisite.

## Purpose

- Objective: add the requested progression and faster play without weakening
  the proven terrain, contact, paint, or stage-authority contracts.
- Deliverable: thirty deterministic generated stage resources, an all-open
  catalog/save model, two-family repeat fire, family-local observations over one
  global paint mask, grounded-only Fast Progress, and a functional cheap stage
  browser ready for the interface plan.
- Completion state: Stage 01 through Stage 30 can be selected from fresh and
  migrated saves; overlapping root families remain deterministic across live
  play, replay, agent observations, paint, and terminal results; actual Stage
  01/10/20/30 evidence proves gradual growth rather than abrupt or invalid maps.

## Prerequisite and Boundaries

Execution prerequisite:

- The physical gameplay plan is `done`, its exported evidence passes, and the
  user has approved its checkpoint. If that prerequisite is not true, this plan
  remains active documentation but no task is executable.

In scope:

- Root-shot identity, family capacity, Splitter inheritance, family settlement,
  paint attribution, stage terminal rules, replay format, observation schema,
  and Agent API readiness/capacity fields.
- About doubled perceived pace through removal of serial waits, shorter
  settlement/presentation delays, and grounded-only Fast Progress at 2.0.
- Version-6 bounded terrain progression, mechanism-pad arrays, deterministic
  offline generation, accepted certificates, thirty stage/profile resources,
  selected-stage preview images, and stable catalog data.
- All-open selection, save migration, score preservation, page/data behavior,
  elimination of live stage-select generation, and one-entry gameplay layout
  ownership.
- Focused post-feature checks and off-screen running-build evidence.

Out of scope:

- Changes to the physical target representation, paint-mask authority, renderer,
  fixed 60 Hz tick, ball/brush values accepted by the first plan, or current
  three mechanism effects.
- Final typography, component styling, exact nine-screen layout, localization
  fit, pause/settings/result redesign, or final screen comparison. The interface
  plan owns those.
- More than two root families, more than eight physical projectiles, new
  mechanism kinds, steering after launch, procedural runtime search, hand-
  authored repair coordinates, locked-stage progression, online features,
  dependencies, or new asset packs.
- Broad legacy test matrices and optimization unrelated to overlapping shots,
  stage generation/start, or menu paging.

## Discovery Closure

| Concern | Verified starting fact | Locked response | Task IDs |
| --- | --- | --- | --- |
| Serial firing | `StageController.request_fire()` accepts only AIMING, rejects all active/pending projectile or paint work, disables cannon input, and waits through three serial states | Make AIMING the live board phase while families move; disable Fire only at capacity/terminal, never the aim controls | 1.1, 1.3 |
| Missing family identity | `ProjectileManager` caps physical bodies at eight but resets ordinals and carries no root identity | Add stage-monotonic `shot_id`, never-reset spawn ordinals until restart, and Splitter inheritance | 1.1 |
| One-shot observation | `StageController` owns one `_shot_observation`; ShotObservation schema is 4 | Own a dictionary of observations keyed by `shot_id`; bump schema to 5 | 1.2, 1.4 |
| Paint ordering | Paint commands identify physics tick/spawn ordinal/sequence but not the root family | Add `shot_id` for attribution while preserving global canonical command order and one mask | 1.2 |
| Terminal timing | Current result waits for the only ball, flushes paint, delays 0.7 s, then re-enables input or ends | Seal families independently; enter clear/failure only after admitted families and commands drain | 1.3 |
| Replay/agent meaning | Replay format is 6 and assumes serial SHOT_RESULT; Agent readiness is only `state == AIMING` | Bump replay to 7, explicitly reject 6, and expose aim readiness separately from Fire capacity | 1.4 |
| Fixed stage count | StageCatalog, StageSelectScreen, GameState, and SaveSystem hard-code three stages and unlock mutation | Use a typed 30-entry catalog; selection is catalog membership; completion only records result | 4.1, 4.2 |
| Fixed generation size | Version 5 enforces 72x48 cells, 180x120 m, 8 stations, and 6,912 top triangles | Apply the exact version-6 formulas and 12,288-triangle ceiling below | 2.1, 3.1 |
| One mechanism pad | StageRouteProfile owns one kind/t/radius and placement resolves first kind | Add typed stable pad slots and stage slot assignments | 2.2, 3.1 |
| Menu stutter | AppRoot builds/caches full mesh/material/dressing artifacts for selected previews | Stage cards are numeric; selection loads one committed 768x432 image and never generates a stage | 4.3 |
| Pacing request | Raw 1x/2x controls coexist with serial waits; raising time scale while airborne risks missed physics | Keep airborne 1.0, remove waits, shorten presentation, apply 2.0 only when every active body is post-contact grounded | 1.3, 1.5 |

Readiness statement:

- Product behavior, concurrency capacity, identity, ordering, attribution,
  terminal semantics, pacing, content formulas, mechanism counts, file outputs,
  migration, and validation are closed.
- The executor may fix local defects inside these boundaries. A different
  capacity, stage curve, representation, dependency, or player-visible behavior
  requires a recorded replan.

## Locked Domain and Data Contract

### 1. Stage phase and shot-family vocabulary

- **Board Phase** is the mutually exclusive StageController phase. Live play
  uses `LOADING`, `BRIEFING`, `AIMING`, `PAUSED`, `STAGE_CLEAR`, and
  `STAGE_FAILED`. `PROJECTILE_IN_FLIGHT`, `PAINT_SETTLING`, and `SHOT_RESULT`
  are removed from live control flow because motion is not an input-blocking
  board phase.
- StageController replaces those motion states with typed signals and one query:
  `shot_family_started(shot_id)`,
  `shot_family_activity_changed(active_shot_ids, active_projectiles, fire_capacity)`,
  `terminal_pending_changed(pending)`,
  `attempt_terminal_resolved(final_state, final_coverage, final_mask_checksum)`,
  and `activity_snapshot()`. GameplayScene, HUDController, TopStatusBar,
  ObservationControls, ReplayPresentationController, GameplayAgentApi,
  DeliveryCaptureRunner, DebugOverlay, and affected focused tests consume these
  surfaces rather than inferring motion from Board Phase.
- **Root Shot** is one accepted Fire action. `StageController` assigns it a
  positive stage-local `shot_id` that increases monotonically and resets only on
  stage restart.
- **Shot Family** is that root projectile plus every Splitter descendant carrying
  the same `shot_id`. Splitter never creates a root and never consumes a shot.
- **Physical Projectile** is one rigid body. Maximum active physical bodies stays
  8. Maximum active root Shot Families is 2.
- **Aim Ready** means Board Phase is AIMING and no modal/replay action owner is
  locked. It remains true at family capacity. **Fire Capacity** is
  `min(2 - active_family_count, shots_remaining)` unless terminal is pending or
  aim is invalid.
- **Family Seal** occurs only after that family's physical body count is zero and
  every authoritative paint command carrying its `shot_id` has drained.
- **Terminal Pending** starts when target coverage is reached or no shots remain.
  It blocks additional Fire but lets already admitted families and paint finish.
  Clear/failure is emitted exactly once after all families seal and global paint
  work is empty.

### 2. Identity, ordering, and paint attribution

- `StageController` owns `_next_shot_id` and a typed family record dictionary.
  `ProjectileManager` receives `shot_id` at root spawn; every Splitter child
  inherits it. Every spawn also receives a stage-monotonic `spawn_ordinal` that
  never resets while the attempt is active.
- `RadialPaintMark` and `SurfacePaintSweep` gain `shot_id`. Their global order
  remains the existing canonical physics/event/spawn/sequence order; `shot_id`
  is attribution, not a competing ordering authority.
- `PaintSystem` remains the only mutable mask and coverage owner. When a command
  changes an eligible target pixel from unpainted to painted, it increments that
  command's `new_target_pixels_by_shot[shot_id]`. Overlap that is already painted
  contributes zero, including simultaneous overlap resolved later in canonical
  order.
- Family coverage gain is
  `100 * newly_painted_target_pixels_for_shot / eligible_target_pixel_count`.
  There is no per-family mask, texture, coverage system, or reconstruction.
- PaintSystem exposes per-shot pending-command count and final drained tick
  through a narrow query/signal so StageController can seal without reading the
  queue implementation.
- Every submitted authoritative command has a positive `shot_id`. A rejected
  command is appended to that family's observation and counts as resolved work;
  the family cannot seal until all its submitted commands are either drained or
  rejected. A missing/unknown/non-positive ID is an attempt-wide fail-closed
  error, blocks new Fire, and resolves only after global work drains.
- One nonmodal gain event is emitted on Family Seal. It never delays input or
  terminal drain. The interface plan decides its final visual component.

### 3. Fire admission and result rules

- An accepted Fire requires: AIMING Board Phase, allowed action origin, valid
  current aim, `shots_remaining > 0`, active family count below 2, no Terminal
  Pending, and ProjectileManager physical capacity for one root.
- Acceptance snapshots yaw/elevation/power into a new family observation,
  consumes one shot immediately, spawns the root, and leaves cannon input and
  trajectory prediction enabled for the next aim.
- Subsequent aim changes only mutate the cannon's next command. Launched bodies
  never read the mutable cannon tuple and cannot be steered.
- At two active families, only Fire is disabled. At one family, another valid
  Fire is admitted. A third root is rejected without consuming a shot or
  changing observations.
- If the target is reached while one or two families remain, no new root is
  admitted; every already-fired family is allowed to paint and seal before the
  clear result is calculated.
- If the final available root is fired below target, failure is deferred until
  every admitted family and paint command settles. Any last-family paint counts.
- A rejected authoritative paint command fails the attempt closed after drain
  and is recorded in the responsible family observation.

### 4. Observation, replay, and agent schemas

- `ShotObservation.SCHEMA_VERSION` becomes 5. It serializes `shot_id`, accepted
  aim, root spawn tick/ordinal, ordered contacts, children, mechanisms,
  settlements, paint command/rejection counts, first-painted target pixel count,
  coverage gain, final drain tick/checksum, and sealed state.
- StageController stores active and sealed observations by `shot_id` and emits
  `shot_observation_sealed(shot_id, observation)` once. `last_sealed` is a
  convenience view only and is not an authority.
- `ReplayRecorder.FORMAT_VERSION` becomes 7. Fire actions record `shot_id` and
  accepted physics tick; expected observations are keyed by shot ID. Playback
  admits actions at recorded ticks and verifies family order, child inheritance,
  paint gain, final coverage, and result.
- Replay format 6 and earlier are rejected with localized incompatibility copy.
  They are never guessed or migrated because they lack family identity.
- Gameplay Agent observations add `active_shot_families`,
  `active_projectiles`, `aim_ready`, `fire_capacity`, `terminal_pending`, and an
  ordered `active_shot_ids` array. Retain `ready_for_action` as an alias of
  `aim_ready` for one schema cycle; it no longer implies Fire is legal.
- Human, replay, agent, and debug origins use the same StageController admission
  and observations. No origin bypasses capacity or terminal rules.
- ReplayPresentationController waits for every expected family to seal, rejects
  any missing/extra `shot_id`, sorts verification by shot ID, and completes only
  on `attempt_terminal_resolved`. It no longer treats SHOT_RESULT as a replay
  completion boundary.
- DebugOverlay's projectile-spawn action becomes a DEBUG-origin call through
  StageController using the current valid aim. It consumes a shot and obeys
  family/body capacity and Terminal Pending. The direct
  `ProjectileManager.spawn_projectile` debug path is removed.

### 5. Ball and cadence preservation

- Preserve the accepted first-plan values: 0.60 m ball radius, 2.25 m
  continuous/settlement paint, 3.20 m impact paint, 0.03 bounce, 0.90 friction,
  0.55 linear damp, 1.10 angular damp, 1.70 m/s movement threshold, 0.50 s stop
  duration, and 12 s lifetime.
- Fast Progress is enabled by default and persisted as `fast_progress`. Normal
  gameplay uses `Engine.time_scale = 1.0` when no body is active or any active
  body has not made its first Verified Target Contact or is no longer grounded.
  It uses 2.0 only while every active root and descendant is grounded after
  target contact. A new airborne Splitter child immediately restores 1.0.
- `PaintProjectile` owns `fast_progress_eligible`: false before first Verified
  Target Contact; true while the current contact is verified or its gap remains
  within the same two-physics-tick/10 m target-top bridge; false immediately on
  a non-target contact or after that bridge expires. Backstop, Apron, Shell, and
  mechanisms never qualify. It emits
  `fast_progress_eligibility_changed(shot_id, spawn_ordinal, eligible)`;
  ProjectileManager aggregates true only when every active body is eligible.
- Turning Fast Progress off holds 1.0. Pausing holds simulation. Leaving
  gameplay, restarting, and entering replay always reset time scale before the
  next owner applies its setting.
- Muzzle feedback, camera blends, family-gain chip, and result reveal durations
  become 50% of their pre-plan values. Removing the serial 0.7 s shot-result wait
  is part of the pace change.
- Replay owns a separate playback-speed setting and preserves recorded physics-
  tick order. It does not mutate the normal `fast_progress` preference.

## Locked Version-6 Progression Contract

Let `n` be the integer stage number 1 through 30 and `t = (n - 1) / 29`.
`round_even(x)` means the nearest even integer, with exact ties upward. Rounding
to 0.5 also uses nearest with exact ties upward.

### 1. Geometry and complexity formulas

- Terrain X size: `round_even(180 + 60t)` metres.
- Terrain Z size: `round_even(120 + 40t)` metres.
- Cell X: `round_even(72 + 24t)`; Cell Z: `round_even(48 + 16t)`.
- Maximum top triangles: exactly `2 * cell_x * cell_z`, never above 12,288.
- Nominal peak: `round(72 + 54t)` metres. Accepted peak range is nominal -4 m
  through nominal +10 m.
- Paint/target mask remains 512. Candidate attempts remain 32. Attempt seed
  stride remains 7,919. Cell diagonal remains P01-to-P10. Noise amplitude is
  exactly 0.50 m; later complexity comes from typed macro fields rather than
  sharper noise.
- Route stations: 8 for Stage 01-10, 9 for 11-20, 10 for 21-30.
- Route count: 1 for Stage 01-05, 2 for 06-15, 3 for 16-30.
- Exact grade reversals per route: 0 for 01-03, 1 for 04-10, 2 for 11-20,
  and 3 for 21-30.
- Broad ridge count by five-stage band: 3, 4, 5, 6, 7, 8.
- Wide basin count by band: 0, 1, 1, 2, 2, 2. Every basin follows the physical
  plan's width/depth/off-centre/no-hollow contract.
- Broad pass count by band: 0, 1, 1, 2, 2, 3. Macro wave count is the same.
- Base route width by band: 28, 24, 22, 20, 19, 18 m. One safe route is 4 m
  wider. No route is ever narrower than 18 m.
- Decoration count: `10 + round(22t)`, producing 10 through 32, placed outside
  route, cannon, mechanism, and target-readability clearances.

| Band | Stages | Mean target slope | Target p95 max | Target absolute max | Route p95 max | Corridor lip max | Mechanisms |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| First Ridge / 첫 능선 | 01-05 | 16-28 degrees | 34 | 38 | 32 | 30 | 1 |
| Forked Valley / 갈라진 골짜기 | 06-10 | 17-29 degrees | 35 | 39 | 33 | 31 | 2 |
| Winding Range / 굽이치는 산맥 | 11-15 | 18-30 degrees | 36 | 40 | 34 | 32 | 3 |
| Device Corridor / 장치 회랑 | 16-20 | 19-31 degrees | 37 | 41 | 35 | 33 | 4 |
| Layered Peaks / 겹친 봉우리 | 21-25 | 20-32 degrees | 38 | 42 | 36 | 34 | 5 |
| Summit Chain / 정상 연쇄 | 26-30 | 21-33 degrees | 40 | 44 | 38 | 35 | 6 |

- Slope metrics use scoreable Target Top triangles as the population and each
  triangle's world-space area as weight. Slope is the angle between its normal
  and Vector3.UP in degrees. Mean is the area-weighted arithmetic mean. The p95
  is the smallest ascending slope whose cumulative area is at least 95% of total
  eligible area. Comparisons use unrounded double-precision values; tables round
  only for reporting. Every stage's mean must lie inside its band's range and
  every stated maximum is a per-stage upper gate.
- Ridge, basin, pass, and macro-wave counts are explicit typed field arrays
  emitted by `StageProgressionData` and consumed by the synthesizer. The accepted
  layout records their stable IDs/parameters in `GeneratedStageLayout.metrics`;
  validation compares array counts to the band formulas instead of inferring
  features from a screenshot.
- Every accepted stage preserves the physical plan: one connected row-solid
  footprint, one top per XZ, closed shell, visible rear-wall join, no spikes,
  holes, tunnels, overhangs, detached boards, or literal stair geometry.
- Every scoreable target texel has a certified legal first hit. The default aim
  is the certified hit closest to target centroid. The same certificate proves
  predictor/rigid-body identity and containment.
- Every stage preserves the predecessor's exact 48-degree perspective lens;
  generated camera bookmarks change position/target only to frame the variable
  bounds and never compensate for bad geometry by changing FOV.

### 2. Targets, shots, stars, IDs, and localized names

- Stable IDs are `stage_01` through `stage_30`; numeric order is authoritative.
- Stage, generation, profile, layout, and reachability-certificate contract
  versions are all 6. Requested terrain seed is
  `1,347,223,552 + n * 1,000,003`; deterministic candidate `a` for zero-based
  `a = 0..31` uses `requested_seed + a * 7,919`.
- Stage 01-10 target: `4.0 + 0.5 * (n - 1)` percent.
- Stage 11-20 target: nearest 0.5 of `9.0 + 0.35 * (n - 11)` percent.
- Stage 21-30 target: nearest 0.5 of `12.5 + 0.30 * (n - 21)` percent.
- Maximum shots by five-stage band: 4, 5, 5, 6, 6, 7.
- Star thresholds are target, target +2.5, and target +5.0 percentage points.
- `stage.stage_NN.name` localizes to `스테이지 NN · <Korean band>` and
  `Stage NN · <English band>`. Six band objective keys are reused; implementation
  does not invent thirty unique objective sentences.
- Stage numbers and percentages shown in concept images are illustrative and
  never override these formulas.

### 3. Mechanism slots and effects

- Add `MechanismPadProfile` with `slot_id`, mechanism kind, route index,
  normalized route position, and radius. StageRouteProfile owns an array of pad
  profiles, not one kind/t/radius triple.
- Add `StageMechanismEntry` with `slot_id` and `MechanismData`. StageData owns an
  array of entries. Route resolution splits edges at every ordered pad and
  placement resolves by exact `slot_id`, never by first matching kind.
- Mechanism count is exactly 1, 2, 3, 4, 5, or 6 by five-stage band.
- For zero-based slot index `i`, kind is the cycle Burst, Splitter, Bumper at
  `(n - 1 + i) mod 3`. Stage 01 therefore starts with Burst; any six-slot stage
  contains exactly two of each kind.
- Slots distribute round-robin across routes. Candidate normalized positions in
  order are 0.22, 0.38, 0.54, 0.68, 0.80, and 0.30; generation sorts positions
  on each route before splitting.
- Accepted centers are at least 18 m apart and 12 m from summit/route-exit
  anchors, pass existing collider clearance, and are visible in briefing/overview.
- Pad radii are Burst 8 m, Splitter 10 m, and Bumper 9 m. Burst remains amber
  radial, Splitter violet three-way, Bumper coral directional. Silhouette and
  label supplement color.
- Effects remain bounded and existing: Burst broadens paint locally without
  launching a new root; Splitter creates descendants in the same family;
  Bumper provides the only strong deliberate redirection. No stage-specific
  effect script or hidden exception is allowed.
- Splitter activation is atomic: it deactivates one generation-zero parent and
  creates exactly three generation-one children, or it does not activate. With
  at most two roots and one split generation per family, compliant play peaks at
  six physical bodies, so the eight-body cap always admits both atomic splits.
  Partial child creation is forbidden.

### 4. Offline build and committed resources

- Add typed `StageProgressionData` at
  `src/stage_generation/stage_progression_data.gd` and its sole production
  resource `resources/stage_generation/version6_progression.tres`.
- Add `StageCatalogData` at `src/stage/stage_catalog_data.gd` and its sole index
  `resources/stages/catalog.tres`.
- Add the stable pad/entry types at
  `src/stage_generation/mechanism_pad_profile.gd` and
  `src/stage/stage_mechanism_entry.gd`.
- `scripts/build_stage_catalog.gd` has exactly two production modes. `--check`
  builds all outputs in an owned staging directory, validates them, compares
  their manifest/hashes with committed outputs, writes nothing to production
  paths, and exits nonzero on drift. `--write` performs the same complete build,
  then transactionally replaces production outputs. Running with neither or
  both modes exits nonzero.
- `scripts/build_stage_catalog.gd -- --write` deterministically writes:
  `resources/stages/stage_01.tres` through `stage_30.tres`,
  `resources/stage_generation/profiles/stage_01_profile.tres` through
  `stage_30_profile.tres`, the catalog index, certificates, and
  `assets/ui/stage_previews/stage_01.png` through `stage_30.png`.
- Each preview is 768x432, rendered from the accepted real terrain/mechanisms.
  It is unpainted gameplay state with the actual target mask rendered at 22%
  blue opacity. Stage Select visibly labels the overlay `목표 구역`; it never
  represents current coverage.
- Add `src/delivery/stage_preview_renderer.gd` as the sole preview owner. It uses
  the Compatibility renderer, the accepted overview camera, locked world
  palette/light, real mechanism scenes, 768x432 viewport, and no HUD. PNG byte
  hash reproducibility is scoped to the pinned Godot 4.7.1 executable on this
  Windows machine; resource/layout/target hashes remain platform-independent.
- The builder tests exactly 32 deterministic candidates, accepts the first that
  passes every geometry/reachability/containment/placement gate, and stores the
  accepted seed and checksums in the reachability certificate. Runtime generates
  that accepted seed once and verifies checksums; it never searches candidates.
- Two consecutive clean builder runs must produce identical resource text,
  image hashes, layout checksums, and catalog order. A failed stage aborts the
  complete write; no partial catalog is committed.
- Staging uses the exact owned directory
  `user://paint_mountain_stage_catalog_staging`. After all thirty resources,
  certificates, previews, and a manifest validate, `--write`
  places `.next` files beside every final path, verifies them again, renames
  current files to `.bak`, promotes every `.next`, and writes `catalog.tres`
  last. Any error restores every `.bak`, removes all `.next`, leaves the prior
  catalog manifest/hash intact, and exits nonzero. A builder test injects a
  failure before catalog promotion and proves rollback.
- Every StageData stores a deterministic `reliable_solution` sequence of legal
  aim tuples whose real fixed-tick execution reaches target within that stage's
  maximum shots. The offline builder rejects a stage without such a sequence.
  Delivery/replay may consume it; UI code may not invent or modify it.

### 5. Catalog, selection, save migration, and menu cost

- `StageCatalog` loads one StageCatalogData resource and exposes immutable
  numeric order, membership, lookup, and next-stage queries. No script or scene
  hand-wires thirty paths or buttons.
- All stages are available from first launch. Availability derives from catalog
  membership and is not persisted as progression. Completing a stage updates
  best coverage/stars only and never mutates availability.
- Save version becomes 3 with `selected_stage_id`, `best_results`, and settings.
  `unlocked_stages` is read only during migration and omitted from version 3.
- Migration maps `first_descent`, `burst_basin`, and `split_ridge` to
  `stage_01`, `stage_02`, and `stage_03`; remaps their valid best results;
  preserves supported settings; drops only unknown stage result keys; and falls
  back to `stage_01` for an unknown selected ID.
- Fresh, version-1, version-2, partially unlocked, and version-3 saves may select
  Stage 30 immediately. Existing scores and language/settings are not reset.
- Stage Select uses three fixed page ranges 1-10, 11-20, and 21-30 with ten
  reusable numeric cards. It loads one selected 768x432 preview at a time; cards
  do not instantiate terrain or thumbnail textures.
- AppRoot removes the PreviewWorld and unbounded preview-artifact dictionary and
  disconnects every menu selection from live `SeededStageGenerator`. Until the
  interface plan creates its final hero, Main Menu uses the committed Stage 01
  preview image. Gameplay owns one prepared selected layout and releases it on
  exit.
- AppRoot next-stage navigation, DeliveryCaptureRunner stage lookup,
  `scripts/solution_search.gd`, replay/capture fixtures, and every test fixture
  migrate from legacy IDs/unlock assumptions to catalog membership. Obsolete
  three-stage-only fixtures are deleted after their replacement contract passes;
  they are not left as disabled legacy branches.

## Tasks

### Phase 0: Align the live domain and version boundaries

- [ ] **0.1 Confirm the predecessor and record its immutable inputs**
  - Owners: this plan, physical plan evidence, `.agents/Documentation.md`.
  - Change: verify the predecessor is done/user-approved and record its final
    geometry, projectile, paint, camera, and performance values as inputs.
  - Accept: no task below starts against a draft or rejected physical slice.
- [ ] **0.2 Add the typed identity/version surfaces before behavior changes**
  - Owners: StageController, ProjectileManager, paint command types,
    ShotObservation, ReplayRecorder, GameplayAgentApi, DebugOverlay.
  - Change: add `shot_id` fields/signatures, schema 5, replay 7, and family
    record types without enabling concurrent admission yet.
  - Accept: the project parses, current single-shot behavior still launches and
    seals, and all new IDs are positive/stage-monotonic.

Phase gate: run `scripts/verify.ps1` once.

### Phase 1: Implement deterministic two-family repeat fire

- [ ] **1.1 Propagate root identity and enforce both capacities**
  - Owners: `src/stage/stage_controller.gd`,
    `src/projectile/projectile_manager.gd`, `paint_projectile.gd`, Splitter,
    and `src/debug/debug_overlay.gd`.
  - Change: assign/inherit shot IDs, retain stage-monotonic spawn ordinals, track
    family physical counts, and enforce 2 roots/8 bodies.
  - Accept: two roots coexist; a third is side-effect-free rejected; each
    Splitter atomically replaces its parent with exactly three children; the
    two-family peak is six bodies; children stay in the parent family; later aim
    mutations change neither family; debug Fire uses the same admission path.
- [ ] **1.2 Attribute authoritative paint and seal families independently**
  - Owners: radial/sweep commands, `PaintSystem`, StageController,
    ShotObservation.
  - Change: add shot attribution, first-painted eligible pixel counts, per-shot
    pending/drained signals, family dictionaries, and gain events.
  - Accept: overlap counts once globally, family gains are deterministic, every
    family seals once after its own drain, and one mask remains authoritative.
- [ ] **1.3 Replace serial motion states with live AIMING and deferred terminal**
  - Owners: StageController, GameplayScene, HUDController, TopStatusBar,
    ObservationControls, ReplayPresentationController, GameplayAgentApi camera
    rules, DeliveryCaptureRunner, and directly affected state/capture tests.
  - Change: remove motion/result states from live admission, keep aim enabled,
    add the locked activity signals/query, calculate Fire capacity, and apply
    Terminal Pending/drain/terminal-resolved rules.
  - Accept: immediate re-aim/re-fire works; capacity disables only Fire; target
    and last-shot results include all already-admitted paint.
- [ ] **1.4 Version replay, observations, and Agent API**
  - Owners: ShotObservation, ReplayRecorder, replay presentation/controller,
    GameplayAgentApi, localized incompatibility copy.
  - Change: implement schema 5/format 7 and the exact fields/semantics above.
  - Accept: a recorded two-family/Splitter sequence reproduces shot order,
    contacts, gains, final checksum, and `attempt_terminal_resolved`; extra or
    missing family IDs fail; format 6 exits safely.
- [ ] **1.5 Apply grounded-only Fast Progress and shorter presentation**
  - Owners: PaintProjectile fast-progress eligibility, ProjectileManager
    aggregation, GameplayScene, CameraDirector, StageController presentation
    signals, and SaveSystem setting.
  - Change: implement the 1.0/2.0 rule, default setting, reset boundaries, and
    50% presentation durations.
  - Accept: airborne bodies remain 1.0, every airborne child cancels 2.0,
    grounded contact/paint has no gaps, and normal/replay speed owners do not mix.

Phase gate: add one consolidated `tests/rapid_fire_contract_test.gd`, update the
existing observation/replay checks, run them, then run `scripts/verify.ps1` once.
Do not add separate tests for each private helper.

### Phase 2: Parameterize version 6 and multiple mechanism slots

- [ ] **2.1 Replace fixed version-5 equality with bounded version-6 data**
  - Owners: `StageGenerationContract`, `StageGenerationProfile`, progression
    data/resource, generator/synthesizer/topology/containment consumers.
  - Change: implement the exact formulas, band gates, route counts/reversals,
    ridge/pass/basin/wave counts, slope limits, and variable bounds/cells.
  - Accept: Stage 01 and Stage 30 hit exact endpoints; all intermediate values
    are monotonic where specified; no layout exceeds 12,288 top triangles or
    violates the predecessor's solid target contract.
- [ ] **2.2 Add stable multiple-pad and stage-entry resources**
  - Owners: route profile/resolver/graph, placement generator, StageData,
    mechanism spawning.
  - Change: implement pad arrays, slot IDs, edge splitting, entries, exact kind
    cycle, counts, radii, separation, and visibility.
  - Accept: Stage 01 has one Burst; Stage 30 has six mechanisms with two of each;
    every visual/collider/effect resolves its exact slot.
- [ ] **2.3 Extend certificates to version 6**
  - Owners: DirectReachabilityValidator/Certificate, DefaultAimSolver,
    containment proof, StageData runtime handoff.
  - Change: certify variable layouts, complete target reachability, checksum
    identity, default aim, and current-wall containment.
  - Accept: no accepted stage has an unreachable target texel or predictor/
    rigid-body identity mismatch.

Phase gate: update only existing generation/reachability/placement checks needed
for the shared types, then run `scripts/verify.ps1` once.

### Phase 3: Build and inspect the thirty committed stages

- [ ] **3.1 Implement the deterministic offline catalog builder**
  - Owners: `scripts/build_stage_catalog.gd`,
    `src/delivery/stage_preview_renderer.gd`, typed resources, staging/manifest
    transaction, and output paths named above.
  - Change: implement exact `--check`/`--write` modes, build/validate in staging,
    produce reliable solutions, and use `.next`/`.bak` rollback with catalog
    promotion last.
  - Accept: two `--check` runs are byte/hash/checksum identical, preview hashes
    match on the pinned environment, an injected failure preserves the prior
    manifest, and partial output is never active or left behind.
- [ ] **3.2 Materialize Stage 01-30 and previews**
  - Change: run the builder once in write mode and commit the generated catalog,
    profiles, stages, certificates, and 30 previews. Add the exact thirty
    localized stage-name rows and six band-objective rows to
    `translations/ui.csv` in numeric/band order; translations are authored
    source and are not builder output.
  - Accept: IDs/order/paths are complete and unique; every resource validates;
    preview content is derived from the same accepted layout and target mask.
- [ ] **3.3 Inspect representative progression evidence**
  - Owners: off-screen capture runner and
    `.agents/evidence/rapid-fire-thirty-stage/`.
  - Change: capture briefing/aiming geometry for Stage 01, 10, 20, and 30 and
    generate one metadata table of bounds, cells, peaks, routes, reversals,
    mechanisms, target, shots, default hit, and checksums.
  - Accept: progression is gradual; later boards visibly add size/undulation/
    items without spikes, hollows, abrupt scale jumps, or unreadable mechanisms.

Phase gate: add one consolidated `tests/stage30_progression_test.gd`, run it,
then run `scripts/verify.ps1` once.

### Phase 4: Make progression all-open and navigation cheap

- [ ] **4.1 Replace the hard-coded catalog and three cards**
  - Owners: StageCatalog/Data, StageSelectScreen, one reusable StageCard component.
  - Change: bind typed catalog membership, three page ranges, numeric cards,
    selected detail, and next-stage order.
  - Accept: every stage is enabled/focusable, page selection is stable, and no
    thirty-button hand wiring exists.
- [ ] **4.2 Migrate saves and remove unlock mutations**
  - Owners: GameState, SaveSystem, AppRoot result/next-stage navigation,
    DeliveryCaptureRunner, `scripts/solution_search.gd`, and persistence/capture
    fixtures.
  - Change: implement version 3 and exact migration; remove runtime unlock
    checks/mutations while preserving scores/settings/selection.
  - Accept: all named save variants select Stage 30 and preserve valid data.
- [ ] **4.3 Remove live stage-select generation and unbounded preview caches**
  - Owners: AppRoot, StageSelectScreen, selected preview loading, layout cleanup.
  - Change: selection loads one committed image; gameplay constructs one
    accepted layout on start and frees it on exit.
  - Accept: paging/selection never calls generator, topology, PaintSystem,
    dressing, or material construction; repeated navigation has bounded memory.

- [ ] **4.4 Retire or adapt invalidated focused checks**
  - Owners: `phase4_state_test.gd`, `stage1_mvp_test.gd`,
    `replay_presentation_test.gd`, `phase6_content_test.gd`,
    `shot_feedback_test.gd`, `phase8_persistence_test.gd`, and delivery capture
    fixtures. Also own the legacy save/unlock/ID assertions currently mixed into
    `localization_ui_test.gd`; move those assertions into
    `phase8_persistence_test.gd`. Only localization copy/layout/fit assertions
    remain deferred to the interface plan.
  - Change: update state/replay/feedback/persistence tests to the new public
    contracts; delete `phase6_content_test.gd` after the consolidated
    `stage30_progression_test.gd` fully replaces its still-relevant assertions;
    migrate Stage 01 IDs/fixtures without reopening physical behavior; leave
    `localization_ui_test.gd` free of catalog/save/unlock policy assertions.
  - Accept: no known focused test remains silently tied to removed serial states,
    legacy IDs, three-stage paths, or unlock mutation.

Phase gate: update `phase8_persistence_test.gd`, run it with the two consolidated
new tests, then run `scripts/verify.ps1` once.

### Phase 5: Audit, export functional evidence, and hand off to UI

- [ ] **5.1 Run the task-scoped architecture/quality audit**
  - Change: use `codebase-quality-auditor` read-only and save findings covering
    state, paint, catalog, save, preview, replay, and generated-resource owners.
  - Accept: every competing or obsolete owner is named with its disposition.
- [ ] **5.2 Correct blocking audit findings**
  - Change: correct only task-owned serial-state, unlock, three-stage, first-pad,
    unbounded-preview, duplicate paint, or public-contract defects identified by
    5.1 after their replacements pass.
  - Accept: each blocking finding is fixed or triggers replan; audit and fix
    evidence remain separate.
- [ ] **5.3 Export and capture functional runtime evidence**
  - Change: export once; capture Stage 01/10/20/30 aiming, a two-family
    observation, capacity rejection, clear-after-drain, and failure-after-drain
    through real owners in an off-screen Compatibility window.
  - Accept: captures/telemetry and serialized observations prove functionality;
    they are not presented as final UI parity.
- [ ] **5.4 Update records and release the interface prerequisite**
  - Owners: this plan, Documentation, test checklist, design-plan linkage.
  - Change: record commands/evidence/known issues, mark done only when gates pass,
    and state that the interface plan may begin.
  - Accept: no functional uncertainty is deferred to the UI executor.

## Validation and Rework Controls

Set the engine path exactly as in the physical plan, then use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1 -GodotPath $env:PAINT_MOUNTAIN_GODOT
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/rapid_fire_contract_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://tests/stage30_progression_test.gd
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://scripts/build_stage_catalog.gd -- --check
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --script res://scripts/build_stage_catalog.gd -- --write
& $env:PAINT_MOUNTAIN_GODOT --headless --path . --export-release 'Windows Desktop' 'builds\windows\PaintMountain.exe'
```

| Cadence | Exact evidence | Run when | Rerun condition |
| --- | --- | --- | --- |
| Phase smoke | `scripts/verify.ps1` | Once after each code/resource phase | Relevant input changes |
| Repeat-fire | Consolidated rapid-fire test plus existing replay/observation checks | Phase 1 complete | Family/state/paint/schema input changes |
| Content | Consolidated thirty-stage test | Complete generated set exists | Formula/generator/catalog/mechanism input changes |
| Builder reproducibility | Two `--check` runs, rollback-injection test, then one `--write` | Phase 3 | Builder or generation input changes |
| Persistence | Existing focused persistence test | Phase 4 | Save/catalog/progression input changes |
| Export/evidence | One release export and named off-screen states | All focused gates pass | Production-owned input changes |

Rules:

- Do not run the broad historical matrix. These two consolidated tests plus
  directly affected existing replay/persistence checks are the complete new
  automated scope.
- Do not run a foreground Godot window. Rendered evidence uses the delivery
  runner; the user retains control of foreground play validation.
- Do not regenerate thirty resources after an unrelated UI edit. Builder output
  reruns only when progression/generation/resource inputs change.
- On resume, read the predecessor status and start at the first unchecked task.
  Record evidence and advance the progress pointer in the same edit.

## Predetermined Contingencies

| Trigger | Required response | Forbidden shortcut |
| --- | --- | --- |
| Any stage fails within 32 candidates | Record stage/metric; adjust only that five-stage band's typed parameters within locked size/slope/count/no-spike bounds, then rebuild all thirty | Authored repair coordinates, runtime search, partial catalog, or accepting a failed fallback |
| Grounded 2.0 causes missed contact/paint | Keep airborne rule; lower grounded Fast Progress to 1.5 and record evidence/replan deviation | Raise physics above 60 Hz or widen paint to hide gaps |
| An atomic Splitter would exceed eight bodies | Treat as an invariant failure, reject activation without deactivating the parent, and fix family/body accounting; compliant two-root/one-generation play must peak at six | Partial children, exceeding eight, evicting an existing body, or creating a new root identity |
| Stage target is unreachable | Reject/rebuild layout inside locked route/target bounds | Remove target pixels after acceptance or fake a certificate |
| Old replay is loaded | Show incompatibility and return safely | Guess shot IDs or silently produce a different replay |
| Unknown save stage key appears | Preserve supported settings; drop only unknown stage score/selection and fall back to Stage 01 | Delete the whole save or restore locks |
| Stage Select still invokes generation | Treat as a blocking ownership defect and remove the call/cache | Hide the delay with an animation or pre-generate all live worlds |

## Progress and Next Steps

- Canonical progress: the checkboxes in this file.
- Execution checkpoint (2026-08-05): Phases 0–4 are implemented. Two root
  families can be admitted immediately, IDs/observations/replay are family
  attributed, Fast Progress is persisted, Stage 01–30 are all-open, and stage
  selection uses cached catalog data rather than live generation.
- Validation checkpoint: `rapid_fire_contract_test.gd`,
  `stage30_progression_test.gd`, localization/save migration, replay,
  camera-safety, and UI contract checks pass; the full Stage 30 generation
  probe covered all 30 IDs.
- Bounded product deviation: visible mechanism loadout is intentionally
  0/1/2 by progression band (intro/Burst/late Splitter+Bumper). The locked
  six-mechanism concept would make the current small mountain unreadable and
  conflicts with the user's request for gradual, non-frustrating growth; it is
  recorded as future capacity rather than falsely marked implemented.
- Phase 5 handoff remains: quality-audit report, release export, and evidence
  index. The interface plan was executed in the same explicit user-approved
  run, so its historical prerequisite wording is superseded for this pass.

## Completion and Stop Conditions

Complete when every task/gate passes; thirty valid committed stages/previews
exist; fresh and migrated saves expose all stages; two-family live/replay/paint/
agent/result behavior is deterministic; actual representative evidence exists;
and durable records are truthful.

Replan only when verified evidence requires a changed capacity, progression
curve, representation, dependency, ownership, or player-visible contract. Do
not replan for local defects, a passing unchanged check, or normal silhouette
variation inside the locked stage gates.
