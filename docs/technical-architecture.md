---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-03
canonical_for: Paint Mountain runtime system ownership and interfaces
scope: Godot runtime architecture, data ownership, signals, persistence, replay, and verification
source: source-brief.md
related:
  - source-brief.md
  - design-spec.md
  - test-checklist.md
  - ../.agents/Plan.md
  - ../.agents/execplans/2026-08-03-gameplay-visual-reset.md
  - ../.agents/execplans/2026-08-03-core-interaction-redesign.md
---

# Technical Architecture

## Purpose

Define stable responsibility boundaries for the Godot vertical slice so data, presentation, game rules, replay, and future AI control remain separable.

## Scope

This architecture covers the single-process desktop game. It does not define a backend, network protocol, live service, editor plugin, or external AI service.

## Requirements

### Runtime owners

| Owner | Responsibility | Must not own |
| --- | --- | --- |
| `GameState` | Global progression, selected stage, settings, best results | Per-shot rules or scene node paths |
| `SaveSystem` | Versioned serialization, load/default/migration, atomic local writes | UI or stage decisions |
| `StageController` | Authoritative state machine, shots, settlement, coverage result, clear/fail, restart orchestration | Paint pixels or HUD layout |
| `StageData` | Typed stage configuration, translation keys, generation profile/seed, and content references | Mutable runtime or accepted generated layout state |
| `SeededStageGenerator` | Pure deterministic route-graph/layout generation, cheap structural validation, and accepted identity verification | Physics-world solving, stage transitions, paint state, or hand-authored production repair |
| `StageGenerationCertifier`, `DirectReachabilityValidator`, `DefaultAimSolver` | Headless candidate certification, exact first-hit target-wide reachability, generated default aim, and certificate emission | Runtime-frame search, player aim hints, target deletion, or manual repair coordinates |
| `StageMvpPermitProducer` | Temporary headless proof that one persisted default shot completes the Stage 1 core loop against an exact layout identity | Target-wide reachability claims, release certification, runtime search, or authored repair coordinates |
| `GeneratedStageLayout` | Accepted graph, one-height-per-XZ samples, fixed triangle IDs/diagonals, target mask, full reachability certificate or temporary MVP permit, default aim, containment, checksums, decorations, and mechanism placements | Mutable paint, shot/save state, second height representation, or visual-only playable geometry |
| `MechanismPlacementGenerator` | Exact role-owned centerline shelf transform and candidate validation | Placement scoring, alternate cells, activation behavior, or stage outcomes |
| `TerrainGeometryFactory` | One exact indexed top-triangle list plus closed shell render/collision resources from the accepted layout | Independent triangulation, height interpolation, stage generation, orchestration, or paint state |
| `TerrainSurface` | Generated terrain node ownership, stable collider/triangle identity, and read-only exact-triangle height/normal/bounds queries | Bilinear queries, generation policy, paint pixels, or stage decisions |
| `BackstopEnvironment` | Collider-matched visible rear wall, faceted apron, stable contact IDs, and containment construction | Scoring, hidden kill planes, bank-shot behavior, or stage outcomes |
| `AimInputController` | Mouse/keyboard mapping to independent yaw/elevation/power actions and deterministic hold repeat | Target solving, Fire acceptance, shot consumption, or outcomes |
| `TrajectoryPredictor` | Read-only complete pre-impact sphere prediction through first collision/bounds exit | Device input, post-impact behavior, mechanisms, or coverage prediction |
| `CannonController` | Yaw/elevation/power commands, clamping, shared launch calculation, and current prediction | Device polling, target solving, post-fire steering, or stage outcome |
| `ProjectileContact` | Immutable measured contact point/normal/collider/shape/impulse/velocity/tick facts | Mutation, gameplay decisions, or presentation |
| `PaintProjectile` | Rigid-body behavior, every begun measured contact, target-top sweep/radial-mark intent, stop/lifetime/bounds | Persistent mask mutation, coverage totals, or stage transitions |
| `ProjectileManager` | Parent/child registry, eight-ball cap, per-shot spawn ordinals, paint-command canonicalization, shot-settled signal, cleanup | Projectile physics tuning or mask writes |
| `SurfacePaintSweep`, `RadialPaintMark` | Immutable physically justified paint commands with stable source identity and deterministic order | Mask writes, coverage, payload, or flow |
| `PaintSystem` | Ordered command drain, mountain-top paint rasterization, immutable target-only scoring, one authoritative paint mask/coverage, texture publication, clear | Shot limits, contact fabrication, terrain duplication, or UI formatting |
| `GimmickBase` | Shared solid-body strike eligibility, contact debounce, state, reset, and data contract | Subclass-specific effect or invisible gameplay triggers |
| `BurstNode` | Direct paint-mask burst and charge/spent feedback | Projectile spawning |
| `SplitterNode` | Consume input and request bounded child fan | Stage settlement decisions |
| `BumperNode` | Cooldown-limited directional impulse and feedback | Direct coverage changes |
| `CameraDirector` | Camera modes, bookmarks, safe interpolation, follow framing | Game rules |
| `HUDController` and screen controllers | Display state and emit typed aim, fire, and game-menu intents | Authoritative state mutation, direct pause/settings mutation, or alternate coverage |
| `PauseOverlay`, `SettingsScreen`, `AppRoot` | Full-input game-menu barrier/focus, separate settings form, and navigation/return layering | Stage-state ownership, restart rules, aim/fire forwarding, or hidden simulation progress |
| `ShotObservation` | One shot's commanded aim, ordered contacts/effects/children, settlement, coverage, paint-command drain, and checksum facts | Stage transitions, HUD formatting, or independent reconstruction |
| `ReplayRecorder` | Format-5 layout identities, deterministic action stream, expected observations/checksums, and scheduling | Input lock, save progression, or transform-sample playback |
| `ReplayPresentationController` | Orthogonal replay input/UI lock, replay controls, and exit | Stage-state ownership or gameplay effects |
| `GameplayAgentApi` | UI-independent observations, actions, and event stream | Duplicate simulation rules |
| `AppRoot` | Main-menu, stage-select, settings, and gameplay navigation/lifetime | Stage outcomes or paint state |
| `DebugOverlay` | Debug-build-only metrics, derived mask previews, actions, and JSON log export | Alternate gameplay authority |
| `DeliveryCaptureRunner` | Command-line reproduction of named release evidence states | Normal player navigation or game rules |

### Data contracts

- Use typed `Resource` classes for StageData, ProjectileData, and each mechanism's configuration.
- StageData owns targets, shots, colors, camera bookmarks, generation
  profile/seed/certificate reference, mechanism loadout, thresholds, and
  translation keys. `ContainmentSpec` owns the fixed bounds and
  `GeneratedStageLayout` carries them to runtime consumers. Runtime
  construction consumes one accepted
  `GeneratedStageLayout`; stage scenes do not own terrain formulas, default aim,
  or production mechanism coordinates.
- Runtime state is recreated from immutable configuration on restart. Mechanisms expose one physical `struck(projectile, contact)` entry plus shared eligibility and reset; their compound collision matches visible primitives.
- `GeneratedStageLayout` carries one sampled height per in-bounds XZ plus the one
  fixed cell diagonal. `TerrainGeometryFactory` emits the indexed top triangles
  once. Render mesh, top `ConcavePolygonShape3D`, hit identity, height/normal
  queries, target rasterization, paint reconstruction, replay checksums, and
  agent terrain observations consume that exact list. `HeightMapShape3D`,
  bilinear interpolation, independently triangulated collision, visual
  displacement, and query-only playable geometry are prohibited.
- `target_mask` is immutable scoring eligibility derived from the shared top
  triangles and copied once into `PaintSystem`; `PaintSystem` remains the sole
  mutable paint/coverage representation. It cannot remove target texels because
  of slope, decoration, visibility, or shot difficulty.
- `TerrainGeometry` carries the render mesh, exact concave top shape, identical
  skirt/bottom faces, triangle/cell identity, bounds, cell/base dimensions, and
  parity counts derived by `TerrainGeometryFactory`.
- `ProjectileContact` carries each real begun direct-body contact point, world
  normal, incoming velocity, relative normal speed, impulse plus measured/
  estimated provenance, stable owner/shape identity, runtime shapes, tick, and
  contact key.
- `SurfacePaintSweep` carries consecutive target-top surface samples and identity;
  `RadialPaintMark` carries verified impact, settle, or Burst center/radius.
  Neither carries amount, payload, or flow. `ProjectileManager` assigns stable
  per-shot ordinals and sequence; `PaintSystem` alone validates/rasterizes them.
- `DirectReachabilityCertificate` stores target-wide first-hit witnesses,
  checksums, margins, and generated default aim for one accepted layout. Runtime
  validates its identity but never exposes witness tuples as player or agent aim
  assistance.
- `StageMvpPermit` is a temporary, Stage-1-only admission proof. One serialized
  proof checksum binds the contract and profile versions, stage and accepted
  seeds, height/target/placement/containment checksums, canonical default aim,
  target centroid, and predictor plus production-rigid-body hit identities and
  local points. Runtime accepts it only when no full certificate is present; a
  present but stale full certificate fails closed instead of falling back. The
  permit never satisfies target-wide certification or final release/export.
- Replay format 5 carries stage/profile versions, accepted seed, height/target/
  reachability/containment checksums, generated default aim, physics FPS, ordered
  canonical manual actions, expected sealed observations, and final paint-mask
  checksum. It contains no transform samples and rejects format 4 because the
  authoritative paint-mask checksum algorithm changed.
- Agent observations are immutable snapshots; actions enter through the same validated cannon/stage command layer used by human UI.

### State and event flow

```text
Human / Replay / GameplayAgentApi actions
          │ origin-tagged yaw/elevation/power/fire commands
          ▼
   StageController ──────► CannonController ──────► ProjectileManager
          │                         │                        │
          │ state/fire authority    │ launch/prediction      │ lifecycle
          ▼                         ▼                        ▼
 HUD / CameraDirector       PaintProjectile ──ProjectileContact──► Mechanisms
          ▲                         │                              │
          │                         └── Sweep / Radial Mark ──────┘
          │                                      ▼
          └──── sealed observation/state ── PaintSystem
```

- Required typed events include shot fired, every begun measured contact/bounce,
  queued and drained paint command, mechanism struck/split, projectile stopped,
  shot settled, sealed observation, coverage changed, stage clear, and stage
  failed.
- `StageController` changes state only through explicit transition methods that validate allowed predecessors.
- `StageController` seals its `ShotObservation` only after every parent/child is
  inactive for two consecutive physics ticks and `PaintSystem` has drained
  through the last emitted command tick.
- Restart first blocks new actions, cancels speed/camera transitions, frees managed temporary objects, resets mechanisms and timers, clears paint/effects, reapplies immutable data, then enters `BRIEFING` or the chosen retry state.
- Gameplay construction rebuilds and verifies the certified accepted layout
  before briefing. `StageController` alone applies its generated default aim on
  first entry and restart. Certificate, generation, placement, reachability, or
  containment failure blocks briefing and is a verification/export error, never
  an authored-coordinate or hidden-target fallback.
- Gear and Escape request the same `StageController` pause transition.
  `PauseOverlay` captures all pointer/keyboard/gameplay input while the scene tree
  remains stopped and focuses Continue. Settings opens above that paused menu;
  closing Settings returns focus to the menu without unpausing. Restart closes
  the menu and returns to `AIMING` at the generated default aim.

### Paint implementation

- The 512×512 CPU-authoritative byte mask batches texture uploads and increments
  coverage only when a target byte first crosses threshold; no full-mask
  readback or second coverage representation is used during play.
- Maintain a read-only `target_mask` in the same UV/world XZ mapping. Coverage is
  painted target texels divided by all target texels and therefore counts overlap
  once without recurring scans.
- Queue surface sweeps and radial marks during physics, canonicalize them through
  stable tick/spawn/source/sequence order, drain at one late fixed-physics
  boundary, reconstruct candidates on the exact shared triangle, and upload at
  most once per rendered frame.
- Reject non-target, disconnected, opposite-facing, wrong-body, and
  three-dimensionally out-of-radius candidates before persistent writes. Every
  persistent visible pixel is scoreable target top. Airborne gaps, downhill
  flow, fabricated pools, decals, and alternative visual-paint state are absent.
- `ShotObservation` records every rejected authoritative paint command. Any
  rejection makes that shot fail closed as `STAGE_FAILED`; queue drain and idle
  settlement cannot silently convert missing paint into a normal shot result.
- Terrain material samples the same runtime texture. Concept images cannot
  authorize paint that was not produced by a verified surface command.

### Physics and determinism

- Use 60 physics ticks per second, rigid bodies with CCD, explicit data-defined materials/damping, and bounded lifetimes.
- Extract every begun contact from `PhysicsDirectBodyState3D`, identify and sort
  by stable collider/shape key, and debounce each key until absent for two ticks.
  Never discard a simultaneous mechanism/terrain contact by selecting one global
  primary contact or infer contact from projectile center minus world up.
- Calculate preview positions with the exact launch transform, velocity conversion, gravity, replace-mode linear damping, fixed `1/60 s` recurrence, projectile radius, and terrain/mechanism masks used by the rigid body. Terminate at the first sphere-cast collision or bounds exit; never show post-impact behavior.
- Record seeds and shot inputs. Run repeated-shot tests on unchanged stages and define a measured position/coverage tolerance before enabling replay completion.
- Simulation-speed changes affect physics consistently and are allowed only in observation after landing.
- Ordinary terrain/shell/apron use the locked low-rebound material; the fixed
  fixture requires post-impact normal speed at most 10% of incoming and renewed
  sustained contact/roll/settle within 0.75 seconds on target slopes at or below
  30 degrees. Bumper alone may deliberately redirect strongly.
- A visible six-face rear backstop and collider-matched faceted apron contain the
  full legal aim domain. Backstop contact emits one measured contact, writes no
  paint, zeros motion, seals with `BACKSTOP`, and cannot become a bank shot.

### Persistence and failure handling

- Save a versioned dictionary to `user://` through a temporary file followed by replacement; invalid or newer incompatible data falls back safely while preserving the bad file for diagnosis.
- Never let a save failure block gameplay; surface a restrained warning and keep results in memory.
- Enforce projectile/split/effect and paint-command queue budgets at the request
  boundary. Record authoritative paint-command rejection in the sealed shot
  observation, fail that shot closed, and add development-only diagnostic detail.
- Out-of-bounds safeguards, lifetime, low-speed timeout, and backstop settlement
  converge on idempotent projectile deactivation paths. There is no empty-payload
  termination state.

### Validation boundary

- `scripts/verify.ps1` is the repository smoke entry for import and main-scene runtime.
- Each subsystem adds focused headless tests or deterministic test scenes beside its owner; no third-party test plugin is required.
- Final validation includes production export/start, three-stage manual solutions, restart stress, save/replay restart, common-resolution UI review, performance measurement, console review, and exact screenshot checks.
- Certification rejects any layout unless every target-mask texel has an exact
  runtime-predictor and real-rigid-body first-hit witness on the same shared top
  triangle, and the default witness hits within 8 m of the target centroid.
- The temporary Stage 1 MVP permit proves only its bound canonical default shot.
  It is sufficient for headless core-loop development admission but does not
  satisfy the full-certificate, export, or final-delivery validation gates.
- Structural render/collider/query/target/paint triangle parity is exact before
  engine conversion; deterministic engine ray positions may differ by at most
  0.01 m.

## Acceptance Criteria

- No two owners can authoritatively decide stage state, paint coverage, or projectile settlement.
- Human UI, replay, debug actions, and AI actions cannot bypass the same command validation.
- No device input or target solver remains in `CannonController`, and only `StageController` accepts Fire and consumes a shot after state/origin/prediction guards pass.
- No lobe-first or fixed stage height function, unseeded production RNG,
  authored production mechanism X/Z coordinate, alternate collider/query
  surface, or second target/paint/coverage representation remains after
  migration.
- Restart and stage unload leave zero managed projectiles, queued paint commands,
  temporary mechanism states, or stale timers.
- Visual paint and coverage remain demonstrably identical views of one mask, and
  every persistent painted texel traces to a verified target-top command.
- Every target texel is directly first-hit reachable in the legal manual aim
  domain; restart applies the generated centroid-near witness; legal shots cannot
  escape the collider-matched wall/apron containment.
- The left vertical coverage gauge, bottom-center sole Fire action, top-right
  shots/gear, and input-capturing paused game menu have one typed state/action
  path. Restart is absent from aiming and Settings.
- All save/replay formats include explicit versions and deterministic failure behavior.
- The project passes `scripts/verify.ps1` after architectural changes.

## Implemented Delivery Boundary

- `export_presets.cfg` defines the Windows Desktop release path with an embedded PCK and excludes tests, screenshots, reports, builds, and editor state.
- Cross-process probes validate persistence and deterministic replay without relying on the HUD or a shared process.
- The production executable accepts delivery-only capture arguments through
  `DeliveryCaptureRunner`, including a real paused-game-menu state; normal
  launches do nothing with this node, and the debug overlay remains unavailable
  in release builds.
