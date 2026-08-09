---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-09
canonical_for: Paint Mountain runtime system ownership and interfaces
scope: Godot runtime architecture, data ownership, signals, persistence, diagnostics, and verification
source: source-brief.md
related:
  - source-brief.md
  - design-spec.md
  - test-checklist.md
  - ../.agents/Plan.md
  - ../.agents/execplans/2026-08-03-gameplay-visual-reset.md
  - ../.agents/execplans/2026-08-03-core-interaction-redesign.md
  - ../.agents/execplans/2026-08-05-gameplay-contract-recovery.md
  - ../.agents/execplans/2026-08-06-ballistic-terrain-preparation.md
  - ../.agents/execplans/2026-08-06-wind-driven-coverage-loop.md
  - ../.agents/execplans/2026-08-08-projectile-scale-balance-and-aim-performance.md
  - ../.agents/execplans/2026-08-07-target-coverage-and-safe-aim-framing.md
  - ../.agents/execplans/2026-08-07-cannon-shot-observation.md
---

# Technical Architecture

## Purpose

Define stable responsibility boundaries for the Godot vertical slice so data,
presentation, game rules, diagnostics, and future AI control remain separable.

## Scope

This architecture covers the single-process desktop game. It does not define a backend, network protocol, live service, editor plugin, or external AI service.

## Requirements

### Runtime owners

| Owner | Responsibility | Must not own |
| --- | --- | --- |
| `GameState` | Global progression, selected stage, settings, best results | Per-shot rules or scene node paths |
| `SaveSystem` | Versioned serialization, load/default/migration, metric-version separation, mouse-sensitivity persistence, and atomic local writes | UI or stage decisions |
| `StageController` | Authoritative Board Phase, shots, first-launch timer, Finish/timeout result, Fire-readiness snapshot, and restart orchestration | Paint pixels, prediction calculation, wind generation, camera transforms, or HUD layout |
| `StageData` | Typed stage configuration, translation keys, one canonical terrain seed, stage duration, wind profile, and content references | Mutable runtime or accepted baked layout state |
| `StageProgressionData`, `StageCatalogData`, `StageCatalog` | Immutable thirty-stage formulas, canonical terrain-family identity, committed membership/order/lookup, and legacy ID migration aliases | Runtime terrain synthesis, candidate search, or mutable progression state |
| `StageCatalogBuilder` | Offline exact-seed generation, complete validation, cannon-standoff derivation, bounded witness/preview/resource emission, and atomic catalog promotion | Runtime search, candidate selection, hand-authored repair, or partial catalog activation |
| `SeededStageGenerator` | Pure authoring-time one-profile/one-canonical-seed route-graph and layout reconstruction plus identity verification | Candidate search, runtime fallback, physics-world solving, stage transitions, paint state, or hand-authored production repair |
| `ProjectileRangeConstraint` | Pure legal yaw, fixed-step damped horizon, and lower/upper height-envelope admission for every target sample and the Summit Region | Physics queries, terrain occlusion, first-hit certification, target deletion, or runtime aim assistance |
| `DirectReachabilityValidator`, `DefaultAimSolver` | Offline bounded real first-hit validation for generated default and summit aims, plus optional diagnostic certificate work | Runtime-frame search, player aim hints, target deletion, or manual repair coordinates |
| `GeneratedStageLayout` | Accepted graph, one-height-per-XZ samples, fixed triangle IDs/diagonals, target and summit identities, bounded default/summit witnesses, optional certificate metadata, open play bounds, checksums, decorations, and mechanism placements | Mutable paint, shot/save state, second height representation, or visual-only playable geometry |
| `MechanismPlacementGenerator` | Exact role-owned centerline shelf transform and candidate validation | Placement scoring, alternate cells, activation behavior, or stage outcomes |
| `TerrainGeometryFactory` | One exact indexed top-triangle list plus closed shell render/collision resources from the accepted layout | Independent triangulation, height interpolation, stage generation, orchestration, or paint state |
| `TerrainSurface` | Generated terrain node ownership, stable collider/triangle identity, and read-only exact-triangle height/normal/Playable Terrain Surface point queries | Bilinear queries, generation policy, paint pixels, or stage decisions |
| `OpenPlayEnvironment` | Collider-matched restrained apron/ground, open-world presentation, and stable non-target contact identity | Rear/side containment walls, scoring, hidden blocking planes, bank-shot behavior, or stage outcomes |
| `PlayBoundsSpec` | Versioned open exit bounds and apron geometry limits used by generation, prediction, projectile escape, and validation | Collision-wall construction, scoring, camera transforms, or terrain formulas |
| `AimInputController` | Presentation-mode-aware target-selection and pinned-control intent, Fire, inspection orbit/refocus/zoom, and contextual return-to-cannon intents | Camera transforms, target solving, Fire acceptance, shot consumption, or outcomes |
| `TerrainAimController` | Latest valid top-target selection from Aim View click/drag, human target-preserving elevation/power intents, and preservation of the last successful explicit constraint across wind refreshes | Map Inspection behavior, camera transforms, inverse solving, Fire admission, or outcomes |
| `TerrainAimSolver` | Bounded current-target inverse solve that keeps the explicitly edited elevation or power pinned and publishes a same-target canonical aim | Device input, Fire admission, target ownership, runtime terrain mutation, or post-impact prediction |
| `TrajectoryPredictionJob` / `TrajectoryPredictor` | Sole resumable fixed-step sphere/collision implementation and its synchronous offline wrapper | Device input, Fire rules, threads, post-impact behavior, mechanisms, or coverage prediction |
| `TrajectoryPredictionScheduler` | Latest prediction key, one replaceable active job, 12-step/approximately-1-ms fixed-tick budget, bounded aim/wind nominations, current-only atomic publication, and runtime diagnostics | Wind generation, Fire admission, prediction math, or prediction history |
| `CannonController` | Committed yaw/elevation/power, same-revision aim commit/restore, shared launch calculation, and last-complete prediction presentation state | Device polling, Fire admission, target ownership/solving, post-fire steering, or stage outcome |
| `ProjectileContact` | Immutable measured contact point/normal/collider/shape/impulse/velocity/tick facts | Mutation, gameplay decisions, or presentation |
| `PaintProjectile` | Rigid-body behavior, every begun measured contact, persistent terrain-rest lifecycle, surface recovery, and Playable Terrain Surface sweep/radial-mark intent | Persistent mask mutation, coverage totals, wind schedule, or stage transitions |
| `ProjectileManager` | Parent/child registry, two initial-flight root slots, 21-resident-body cap, family IDs, root-projectile identity publication, per-shot spawn ordinals, paint-command canonicalization, activity facts, and cleanup | Fire admission, projectile tuning, wind generation, camera transforms, or mask writes |
| `SurfacePaintSweep`, `RadialPaintMark` | Immutable physically justified paint commands with stable source identity and deterministic order | Mask writes, coverage, payload, or flow |
| `PaintSystem` | Ordered command drain, Playable Terrain Surface paint rasterization, first-threshold weighted Target Area accumulation, one authoritative paint mask/coverage, co-published texture/coverage, and clear | Shot limits, contact fabrication, terrain duplication, or UI formatting |
| `TargetSurfaceCoverage` | Metric version and pure canonical-normal physical-area weighting/checksum rules | Mutable paint, texture publication, stage goals, or HUD text |
| `TerrainGlyphMechanism` | Terrain-conforming flat-glyph presentation, selection, state, charges/cooldown, and reset | Projectile collision bodies, contact classification, or subclass-specific effects |
| `TerrainMechanismResolver` | Resolve authoritative Playable Terrain Surface contact against visible glyph footprints and invoke one ordered effect | Fabricated contact, paint-mask mutation, or stage outcomes |
| `BurstNode` | Request one authoritative radial mark, spend its charge, then consume the incoming ball | Projectile spawning |
| `SplitterNode` | Consume input and request a bounded, route-readable three-child fan | Stage decisions or recursive splitting |
| `UphillReboundNode` | Redirect a retained ball toward a stored meaningful local ascent with cooldown | Direct coverage changes |
| `WindProfile` | Typed wind cadence, transition, strength, and wake tuning | Runtime phase, random state, HUD formatting, or projectile mutation |
| `WindController` | One stage-seeded fixed-tick current/next wind schedule and strong-episode identity | Camera projection, HUD layout, stage terminal decisions, or duplicated physics rules |
| `CannonWindFlag` | Non-colliding cannon-side flag/streamer presentation of the current push direction and strength, with reduced-motion behavior | Wind schedule, projectile forces, HUD formatting, paint, or gameplay decisions |
| `CameraDirector` | Authored `AIM_VIEW`, safe `MAP_VIEW`, specific-root `SHOT_FOLLOW`, impact hold, return-to-cannon, result framing, and transitions; existing internal enum names may migrate independently | Board Phase, aim values, Fire admission, prediction solving, projectile selection policy, or game rules |
| `HUDController` and screen controllers | Display Board Phase/readiness/activity/presentation mode and emit typed aim, fire, return-to-cannon, and game-menu intents | Reconstruct Fire admission, authoritative state mutation, direct pause/settings mutation, camera transforms, or alternate coverage |
| `StageLayoutRepository` | Async persisted-layout load, selected/prefetch ordering, accepted identity checks, and a three-entry LRU | Runtime generation, aim solving, scene-tree, render, physics-world, paint, preview-artifact, or stage-outcome work |
| `PauseOverlay`, `SettingsScreen`, `AppRoot` | Full-input game-menu barrier/focus, separate settings form, navigation/return layering, fail-closed repository scheduling, and main-thread gameplay/preview materialization | Terrain generation rules, stage-state ownership, restart rules, aim/fire forwarding, or hidden simulation progress |
| `ShotObservation` | One shot's commanded aim, ordered contacts/effects/children, settlement, coverage, paint-command drain, and checksum facts | Stage transitions, HUD formatting, or independent reconstruction |
| `AttemptRecorder` | Current-run action/shot observations and final outcome for agent/debug diagnostics | Playback, input locking, save progression, or a replay format |
| `GameplayAgentApi` | UI-independent observations, actions, and event stream | Duplicate simulation rules |
| `AppRoot` | Main-menu, stage-select, settings, and gameplay navigation/lifetime | Stage outcomes or paint state |
| `DebugOverlay` | Debug-build-only metrics, derived mask previews, actions, and JSON log export | Alternate gameplay authority |
| `DeliveryCaptureRunner` | Command-line reproduction of named release evidence states | Normal player navigation or game rules |

### Data contracts

- Use typed `Resource` classes for StageProgressionData, StageCatalogData,
  StageData, generation profiles/contracts, ProjectileData, WindProfile,
  certificates, and each mechanism's configuration.
- StageData owns targets, shots, colors, camera bookmarks, duration, wind
  profile, generation profile/canonical seed/certificate reference, mechanism loadout,
  thresholds, and translation keys. `PlayBoundsSpec` owns versioned open exit
  bounds and apron limits, and `GeneratedStageLayout` carries them to runtime consumers. Runtime
  construction consumes one accepted
  `GeneratedStageLayout`; stage scenes do not own terrain formulas, default aim,
  or production mechanism coordinates.
- The generation contract derives each promoted stage's fixed cannon transform
  from board depth and open play bounds so the nearest playable front is at
  least 70 m away. `StageData` stores the accepted result; the player cannot
  orbit or move this launch position, and `CameraDirector` may not fake the
  standoff by changing projection scale alone.
- Runtime state is recreated from immutable configuration on restart. Flat
  mechanisms expose one resolver-invoked Playable Terrain Surface activation
  entry plus shared eligibility and reset. Their visible footprint matches their activation
  footprint and never becomes a projectile collision body.
- `StageLayoutRepository` publishes only an identity-matching persisted layout
  after asynchronous load. AppRoot never synchronously reconstructs a cold
  layout and never falls back to `SeededStageGenerator` or `DefaultAimSolver`
  during navigation. Gameplay receives `GeneratedStageLayout.copy_for_runtime()`
  so runtime annotations cannot mutate the retained source. Meshes, textures,
  Nodes, physics objects, and paint state are never built or accessed by the
  repository worker.
- The current catalog uses one canonical terrain-family seed path and exactly
  one baked layout identity per stage. Offline building does not search a
  candidate range or silently substitute a fallback seed. A missing, corrupt,
  or identity-mismatched resource fails closed; retry never regenerates
  terrain. A future randomized mode must select only among separately versioned,
  validated, persisted catalog variants and requires a new product contract.
- `GeneratedStageLayout` carries one sampled height per in-bounds XZ plus the one
  fixed cell diagonal. `TerrainGeometryFactory` emits the indexed top triangles
  once. Render mesh, top `ConcavePolygonShape3D`, hit identity, height/normal
  queries, target rasterization, paint reconstruction, diagnostic checksums, and
  agent terrain observations consume that exact list. `HeightMapShape3D`,
  bilinear interpolation, independently triangulated collision, visual
  displacement, and query-only playable geometry are prohibited.
- `target_mask` is immutable Target Area eligibility derived from the shared
  Playable Terrain Surface triangles through the configured target-shoulder boundary and copied once
  into `PaintSystem`; `PaintSystem` remains the sole mutable paint/coverage
  representation. It cannot remove target texels because of slope, decoration,
  visibility, shot difficulty, or ballistic failure.
- `TerrainGeometry` carries the render mesh, exact concave Playable Terrain
  Surface shape, matching Support Shell/bottom faces, triangle/cell identity,
  bounds, cell/base dimensions, and parity counts derived by
  `TerrainGeometryFactory`.
- `TerrainSurface` caches deduplicated world points from canonical Playable
  Terrain Surface vertices only. Aim View projects that exact point set, not
  independent AABB extrema, and excludes the Support Shell, bottom, apron, mechanisms, and
  decoration from its framing input.
- `ProjectileContact` carries each real begun direct-body contact point, world
  normal, incoming velocity, relative normal speed, impulse plus measured/
  estimated provenance, stable owner/shape identity, runtime shapes, tick, and
  contact key.
- `SurfacePaintSweep` carries consecutive Playable Terrain Surface samples and
  identity;
  `RadialPaintMark` carries verified impact or Burst center/radius.
  Neither carries amount, payload, or flow. `ProjectileManager` assigns stable
  per-shot ordinals and sequence; `PaintSystem` alone validates/rasterizes them.
- `DirectReachabilityCertificate`, when present, is optional diagnostic QA
  metadata. Runtime may validate a present matching certificate, but catalog
  admission and release do not require exhaustive target-texel witness mappings.
  Generated default and summit aims remain the bounded runtime-entry witnesses
  and are never exposed as player or agent aim assistance.
- `StageMvpPermit` is legacy development evidence only and is absent from the
  active version-10 runtime admission path.
- `AttemptObservation` carries current-run aim/Fire/Finish and physical lifecycle
  events, sealed shot observations, terminal reason, and final paint facts for
  agent/debug diagnostics. It has no playback scheduler, input lock, transform
  samples, or player-facing replay format.
- Agent observations are immutable snapshots; actions enter through the same validated cannon/stage command layer used by human UI.
- Runtime power canonicalization supports `0.1%` increments. Existing whole-power
  keys and integer offline generation retain their stable identities.

### State and event flow

```text
Human / GameplayAgentApi actions
          │ origin-tagged aim/fire/finish/interaction commands
          ▼
   StageController ──────► CannonController ──────► ProjectileManager
          │                         │                        │
          │ timer/result authority  │ launch/prediction      │ lifecycle
          ▼                         ▼                        ▼
 HUD / CameraDirector ◄──── WindController ───────► PaintProjectile
          ▲                                                  │
          │               playable terrain contact ─────────┤
          │                                                  ▼
          └──── attempt observation/state ── PaintSystem ◄─ Glyph Resolver
```

- Required typed events include shot fired, every begun measured contact/bounce,
  projectile rest/wake/recovery/termination, queued and drained paint command,
  glyph activation/split, wind transition, coverage changed, Finish request,
  timeout, and attempt result.
- `StageController` changes Board Phase only through explicit transition methods
  that validate allowed predecessors. Projectile motion and paint drain do not
  leave AIMING; the next aim remains stored and becomes immediately editable
  when presentation is in Aim View.
- `StageController` starts the stage timer when the first accepted root actually
  spawns. Target coverage and exhausted ammunition never auto-end the run.
  Finish after that first launch or timeout snapshots the authoritative coverage
  once, records the terminal reason, and cleans resident bodies only after the
  result snapshot.
- `StageController` remains in gameplay `AIMING` while `CameraDirector` presents
  Aim View, Map View, or Shot Follow. Aim View forwards click/drag top-target
  selection and target-preserving elevation/power intents; Map View forwards
  click-refocus, orbit, and zoom only; Shot Follow hides steering controls and
  accepts only pause or return-to-cannon presentation intent. Switching or
  returning preserves the committed aim and prediction.
- `TerrainAimController` queues latest-only top-target picks and runs the bounded
  pure inverse recurrence immediately for each accepted target or pinned-control
  request. `TerrainAimSolver` samples candidate times at a fixed eight-step
  stride and consumes one cached wind-acceleration horizon; it performs no
  collision query. The first legal deterministic nomination is committed through
  `StageController.set_aim()`. Rejection retains the prior canonical aim.
  Prediction pending or miss remains advisory and never changes Fire admission.
- The Aim View composer uses canonical Playable Terrain Surface points, summit
  headroom,
  cannon, and muzzle to keep the cannon identifiable in the lower foreground
  and the mountain's main mass readable above it at the unchanged 48-degree
  FOV. The shared composer may accept modest peripheral terrain cropping; it
  never changes geometry to satisfy a ratio, reads live prediction, frames
  render-shell bounds, or uses per-stage repair coordinates. Fixed-mode
  transition frames reuse the existing terrain-ray safety correction so
  interpolation cannot cross a ridge.
- After `ProjectileManager.shot_family_started` publishes an accepted root,
  CameraDirector follows only that root through first TerrainSurface contact,
  holds it for 0.8 seconds, and returns automatically or on a typed early-return
  intent. Projectile simulation and Board Phase never depend on camera state.
- Restart first blocks new actions, cancels camera and wind transitions, frees
  managed temporary objects, resets mechanisms and timers, clears paint/effects,
  reapplies immutable data, then enters `BRIEFING` or the chosen retry state.
- Gameplay construction loads and verifies the persisted accepted layout before
  briefing. `StageController` alone applies its stored default witness on first
  entry and restart. Repository identity, placement, bounded-witness, or open-play-bound
  failure blocks briefing and is a verification/export error, never a generation,
  aim-solving, authored-coordinate, or hidden-target fallback.
- Gear and Escape request the same `StageController` pause transition.
  `PauseOverlay` captures all pointer/keyboard/gameplay input while the scene tree
  remains stopped and focuses Continue. Settings opens above that paused menu;
  closing Settings returns focus to the menu without unpausing. Restart closes
  the menu and returns to `AIMING` at the generated default aim.

### Paint implementation

- The 512×512 CPU-authoritative byte mask batches texture uploads and increments
  weighted coverage only when a target byte first crosses threshold; no
  full-mask readback or second mutable coverage representation is used during
  play.
- Maintain a read-only `target_mask` in the same UV/world XZ mapping. Coverage is
  unique painted physical Target Area surface divided by total Target Area
  surface. Immutable per-sample weights come from projected texel area multiplied
  by `1 / abs(canonical_triangle_normal.y)` and count overlap once without
  recurring scans. The terrain shader may use the same immutable classification
  to distinguish dry Target Area and lighter painted non-target terrain, but it
  does not create another paint or coverage representation.
- Queue surface sweeps and radial marks during physics, canonicalize them through
  stable tick/spawn/source/sequence order, drain at one late fixed-physics
  boundary, reconstruct candidates on the exact shared triangle, and upload at
  most once per rendered frame.
- Reject disconnected, opposite-facing, wrong-body, and three-dimensionally
  out-of-radius candidates before persistent writes. Valid Playable Terrain
  Surface paints visibly whether or not it overlaps the Target Area;
  coverage increments only for target-mask overlap. The Support Shell, bottom,
  apron, glyph selection shapes, airborne gaps, downhill flow, fabricated pools,
  decals, and alternative visual-paint state are absent.
- `ShotObservation` records every rejected authoritative paint command. A
  rejection invalidates verification and is surfaced diagnostically; queue drain
  and idle settlement cannot silently convert missing paint into a normal
  coverage result.
- Terrain material samples the same runtime texture. Concept images cannot
  authorize paint that was not produced by a verified surface command.

### Physics and determinism

- Use 60 physics ticks per second, rigid bodies with CCD, explicit data-defined
  materials/damping, and a bounded miss lifetime only before first Playable
  Terrain Surface contact. A terrain-resident ball may sleep naturally but remains present until
  result/restart or an explicit terminal reason.
- `ProjectileData` owns a 6.0-second never-contacted root timeout. A complete
  current prediction that promises a first Playable Terrain Surface contact may
  supply bounded matching-root lifetime through that contact; ordinary unmatched
  misses retain the timeout and real predicted or live bounds exits remain
  immediate. Stage, cannon, and launch tuning aim for a representative default
  contact near three seconds, but no elapsed-time solver or legal-shot rejection
  is added; the implementing agent judges pacing in the actual Shot Follow flow.
- The root ball uses `2.40 m` physical radius, `2.80 m` continuous paint radius,
  and `3.50 m` impact radius. `CannonBallistics` derives one scale-aware centre
  origin for offline solving, preview, and live bodies: one radius beyond the
  muzzle plus only the vertical clearance needed to keep the sphere above the
  fixed cannon platform.
- An accepted launch publishes the specific generation-0 root identity to the
  presentation path. `CameraDirector` follows only that root, holds its first
  `TerrainSurface` contact for 0.8 seconds, and returns automatically or on a
  return intent. Returning never terminates, redirects, or otherwise mutates the
  projectile.
- `ProjectileManager` releases an initial-root Fire slot when the generation-0
  root first traverses the Playable Terrain Surface or terminates. It seals
  observation only when every current family body reached that surface or
  terminated;
  resident terrain bodies remain eligible to move without permanently consuming
  capacity.
- Extract every begun contact from `PhysicsDirectBodyState3D`, identify and sort
  by stable collider/shape key, and debounce each key until absent for two ticks.
  Never discard a simultaneous mechanism/terrain contact by selecting one global
  primary contact or infer contact from projectile center minus world up.
- Calculate preview positions with the exact launch transform, velocity
  conversion, gravity, replace-mode linear damping, authoritative time-indexed
  wind sample, fixed `1/60 s` recurrence, projectile radius, and terrain masks
  used by the rigid body. Terminate at the first sphere-cast collision or bounds
  exit; never show post-impact behavior.
- `TrajectoryPredictionScheduler` advances that exact job by at most 12 steps
  and approximately 1 ms per physics callback. A new nominated context discards
  obsolete active work; only the current key publishes. `TrajectoryPreview`
  presents the selected target independently from exact prediction state: only a
  matching target/aim/wind result receives an impact marker, while stale arc dots
  may remain subdued and stale impact/exit markers are hidden. It owns no normal-
  operation calculation/update label and never shows a post-impact route.
- The scheduler owns only the replaceable exact advisory preview job. Human
  terrain targeting has no scheduler branch, target callback, or pending Fire
  transaction.
- The canonical runtime power curve is linear `32..160 m/s` over `0.1%` power
  increments from `0..100`; whole-power stable keys and integer offline
  generation behavior are preserved. Direct/summit certification and the open play bounds consume
  that same curve and the same damped recurrence; an undamped apex bound cannot
  reject or admit the promoted version-10 board.
- Record stage/wind seeds and player actions only in the current-run diagnostic
  observation. This log cannot drive gameplay playback. Retry resets the same
  fixed-tick wind schedule.
- Normal gameplay has no simulation-speed controls.
- Ordinary terrain Support Shell/apron contacts use the locked low-rebound
  material. Playable Terrain Surface penetration is recovered from the
  authoritative surface point, normal, and
  projectile radius while preserving tangent motion; deletion is not the normal
  penetration response. Uphill Rebound alone may deliberately redirect strongly.
- `OpenPlayEnvironment` contains no rear/side collision wall or hidden blocking
  plane. Its restrained apron is non-target and non-paintable. `PlayBoundsSpec`
  supplies explicit open exit bounds to prediction and live projectiles;
  crossing them seals with `ESCAPED`, while an apron- or Support Shell-only root
  remains never-contacted and reaches the 6.0-second timeout if it does not exit first.

### Persistence and failure handling

- Save a versioned dictionary to `user://` through a temporary file followed by replacement; invalid or newer incompatible data falls back safely while preserving the bad file for diagnosis.
- Never let a save failure block gameplay; surface a restrained warning and keep results in memory.
- Enforce projectile/split/effect and paint-command queue budgets at the request
  boundary. Record authoritative paint-command rejection in the sealed shot
  observation, fail that shot closed, and add development-only diagnostic detail.
- Explicit mechanism consumption, verified escape, never-contacted miss
  timeout, unrecoverable invalid geometry, and stage cleanup converge on
  idempotent projectile termination paths. Age, low speed, sleeping, and paint
  depletion are never terminal after Playable Terrain Surface contact.

### Validation boundary

- `scripts/verify.ps1` is the repository smoke entry for import and main-scene runtime.
- Each subsystem adds focused headless tests or deterministic test scenes beside its owner; no third-party test plugin is required.
- `projectile_range_constraint_test.gd` checks the shared recurrence, both height
  bounds, yaw/horizon rejection, whole-candidate raster rejection, Summit Region
  admission, Stage 01/30 reconstruction, and runtime-copy isolation without a
  scene or physics world. `stage_layout_repository_test.gd` separately checks
  persisted async loading, identity publication, non-blocking selected/prefetch
  requests, and the three-entry LRU with a pure injected layout strategy.
- Prior repository verification and release delivery validation passed:
  `scripts/verify.ps1`, Windows release export at
  `builds/windows/PaintMountain.exe`, and eight background 1280x720 capture
  runs with empty final stderr logs. Exported entry readiness measured
  `1035.5 ms` for Stage 01 and `2068.4 ms` for Stage 30. These automated and
  rendered checks do not replace user-owned gameplay, balance, feel, or
  aesthetic QA.
- The cannon-standoff and Shot Follow implementation requires deterministic
  contracts plus production-build visual captures of Stage 01 and Stage 30. It
  does not require a new timing or performance-profiling pass.
- Stage admission rejects a layout when its configured target falls outside the
  analytic yaw/horizon/height envelope or when its bounded generated default or
  summit aim fails the required real first-hit check. It does not enumerate a
  first-hit witness for every target texel.
- Structural render/collider/query/target/paint triangle parity is exact before
  engine conversion; deterministic engine ray positions may differ by at most
  0.01 m.

## Acceptance Criteria

- No two owners can authoritatively decide stage state, paint coverage, or projectile settlement.
- Human UI, debug actions, and AI actions cannot bypass the same command validation.
- No device input or target solver remains in `CannonController`, and only
  `StageController` accepts Fire and consumes a shot after canonical-aim,
  state, capacity, and origin guards pass. Prediction is never a Fire guard.
- No lobe-first or fixed stage height function, unseeded production RNG,
  authored production mechanism X/Z coordinate, alternate collider/query
  surface, or second target/paint/coverage representation remains after
  migration.
- Restart and stage unload leave zero managed projectiles, queued paint commands,
  temporary mechanism states, or stale timers.
- Visual paint and coverage remain views of one authoritative mask, every
  persistent painted texel traces to a verified Playable Terrain Surface
  command, and only
  target-mask overlap contributes to coverage.
- The configured target lies inside the legal analytic aim domain; the generated
  centroid-near default and global-highest-region aims first-hit the Playable
  Terrain Surface; restart applies the default witness. Rear/side containment
  walls and hidden blocking planes are absent; live and predicted misses share
  the same explicit open exit bounds.
- Active Shot Families and camera presentation modes do not replace `AIMING` as
  Board Phase. Aim remains stored at capacity; one authoritative readiness
  snapshot disables only Fire for canonical-aim/capacity/shot/result reasons,
  while prediction status is a separate advisory presentation. Map View and Shot
  Follow also block aim/Fire at the input boundary; returning to Aim View
  restores the stored tuple without changing simulation.
- The edge HUD, bottom-center sole Fire action, interaction-mode toggle, compact
  time, remaining/maximum shots, separate resident activity, wind, Finish, gear,
  and input-capturing paused game menu have one typed state/action path. Shot
  Follow adds only one contextual
  return-to-cannon action; the old Follow/Wide/Cannon preset rail, normal-play
  1x/2x, duplicate Pause, aiming Restart, and Settings Restart are absent.
- Save and observation formats include explicit versions and deterministic failure behavior.
- The project passes `scripts/verify.ps1` after architectural changes.

## Implemented Delivery Boundary

- `export_presets.cfg` defines the Windows Desktop release path with an embedded PCK and excludes tests, screenshots, reports, builds, and editor state.
- Cross-process probes validate persistence without relying on the HUD or a shared process.
- The production executable accepts delivery-only capture arguments through
  `DeliveryCaptureRunner`, including a real paused-game-menu state; normal
  launches do nothing with this node, and the debug overlay remains unavailable
  in release builds.
- `resources/stages/catalog.tres` points at the format-5 persisted bundle
  `resources/generated_stage_catalogs/v10-701b3b63feeee0dc1ce064cc91953fbdab91d90db1f004ef247dc4b8b22d1b4e`.
  It contains all 30 layouts and their default/summit witnesses.
- `MechanismLoadoutPlanner` searches visible Playable Terrain Surface with
  spacing, reuses `AimCameraComposer` without owning camera behavior, and ranks
  anchors inside the projected terrain silhouette's 0.38..0.62 middle band
  before the bounded 0.28..0.74 fallback band. Within a band it preserves
  mechanism score, terrain-draped perimeter safety, and a complete assignment
  of camera-facing glyphs before deterministic fallback; it has no authored
  per-stage coordinates. `CannonWindFlag` replaces generic debris without
  changing `WindController` authority.
- `ProjectileManager` is the capacity authority: it admits no more than two
  root families and releases a generation-0 slot on the first Playable Terrain Surface
  traversal or terminal event. Resident terrain bodies remain physically alive
  without indefinitely consuming Fire capacity.
- Layout profile hydration snapshots summit vertices once before its triangle
  loop, and the repository caches successful immutable readiness. Prior timing
  evidence is historical and is not a retained test or part of the current plan.
- The eight reviewed captures and stdout/stderr logs are in
  `.agents/evidence/fast-stage-entry-and-fire-capacity/`. They cover Stage 30
  aiming, two-family capacity, menu, stage-select pages 1/2, first hint, pause,
  and Settings. Review found no clipping, overlap, or gross terrain obstruction;
  the structural UI contract covers page 3 and Settings is exactly 1280x720.
- Persisted default/summit witnesses and analytic range admission are the active
  validation boundary. Exhaustive target-wide first-hit certification is
  optional diagnostic work, not an open release gap.
