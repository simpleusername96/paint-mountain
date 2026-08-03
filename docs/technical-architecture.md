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
| `SeededStageGenerator` | Deterministic bounded generation of one validated immutable `GeneratedStageLayout` | Stage transitions, paint state, or hand-authored production repair |
| `GeneratedStageLayout` | Accepted seed/checksum, height grid, route metrics, eligible inputs, decorations, and mechanism placements | Mutable paint, shot, or save state |
| `MechanismPlacementGenerator` | Exact role-owned centerline shelf transform and candidate validation | Placement scoring, alternate cells, activation behavior, or stage outcomes |
| `TerrainGeometryFactory` | Closed render shell plus top/skirt collision resources from one accepted height grid | Stage generation, scene orchestration, or paint state |
| `TerrainSurface` | Generated terrain node ownership, collider identity, and read-only height/normal/bounds queries | Generation policy, paint pixels, or stage decisions |
| `AimInputController` | Mouse/keyboard mapping to independent yaw/elevation/power actions and deterministic hold repeat | Target solving, Fire acceptance, shot consumption, or outcomes |
| `TrajectoryPredictor` | Read-only complete pre-impact sphere prediction through first collision/bounds exit | Device input, post-impact behavior, mechanisms, or coverage prediction |
| `CannonController` | Yaw/elevation/power commands, clamping, shared launch calculation, and current prediction | Device polling, target solving, post-fire steering, or stage outcome |
| `ProjectileContact` | Immutable measured contact point/normal/collider/shape/impulse/velocity/tick facts | Mutation, gameplay decisions, or presentation |
| `PaintProjectile` | Rigid-body behavior, measured contacts, payload/deposit requests, stop/lifetime/bounds | Coverage totals or stage transitions |
| `ProjectileManager` | Parent/child registry, eight-ball cap, shot-settled signal, cleanup | Projectile physics tuning |
| `PaintDepositRequest` | Immutable physically justified request data and deterministic ordering | Mask writes, coverage, or payload acceptance |
| `PaintSystem` | Eligible-only connected deposits/flow/clear, mask, throttled coverage, terrain shader input | Shot limits, contact fabrication, or UI formatting |
| `GimmickBase` | Shared solid-body strike eligibility, contact debounce, state, reset, and data contract | Subclass-specific effect or invisible gameplay triggers |
| `BurstNode` | Direct paint-mask burst and charge/spent feedback | Projectile spawning |
| `SplitterNode` | Consume input and request bounded child fan | Stage settlement decisions |
| `BumperNode` | Cooldown-limited directional impulse and feedback | Direct coverage changes |
| `CameraDirector` | Camera modes, bookmarks, safe interpolation, follow framing | Game rules |
| `HUDController` and screen controllers | Display state and emit user intents | Authoritative state mutation |
| `ShotObservation` | One shot's commanded aim, ordered contacts/effects, payload, settlement, and coverage facts | Stage transitions, HUD formatting, or independent reconstruction |
| `ReplayRecorder` | Format-3 metadata, deterministic action stream, expected observations, and scheduling | Input lock, save progression, or transform-sample playback |
| `ReplayPresentationController` | Orthogonal replay input/UI lock, replay controls, and exit | Stage-state ownership or gameplay effects |
| `GameplayAgentApi` | UI-independent observations, actions, and event stream | Duplicate simulation rules |
| `AppRoot` | Main-menu, stage-select, settings, and gameplay navigation/lifetime | Stage outcomes or paint state |
| `DebugOverlay` | Debug-build-only metrics, derived mask previews, actions, and JSON log export | Alternate gameplay authority |
| `DeliveryCaptureRunner` | Command-line reproduction of named release evidence states | Normal player navigation or game rules |

### Data contracts

- Use typed `Resource` classes for StageData, ProjectileData, and each mechanism's configuration.
- StageData owns targets, shots, colors, bounds, camera bookmarks, generation profile/seed, mechanism loadout, thresholds, and translation keys. Runtime construction consumes one accepted `GeneratedStageLayout`; stage scenes do not own terrain formulas or production mechanism coordinates.
- Runtime state is recreated from immutable configuration on restart. Mechanisms expose one physical `struck(projectile, contact)` entry plus shared eligibility and reset; their compound collision matches visible primitives.
- Mesh vertices/collision, paint height queries, eligible-mask derivation, mechanisms, decorations, replay checksum, and agent terrain observations all consume the same immutable accepted height grid. `eligible_mask` is static scoring eligibility; `PaintSystem` remains the sole mutable painted/coverage representation.
- `TerrainGeometry` carries the render mesh, heightmap top shape, concave skirt/bottom shape, bounds, cell/base dimensions, and validation counts derived by `TerrainGeometryFactory`.
- `ProjectileContact` carries the real direct-body contact point, world normal, incoming velocity, relative normal speed, impulse, collider identity and shapes, tick, and first-contact flag.
- `PaintDepositRequest` carries source kind, world point/normal, radius, finite amount, flow budget, source identity, tick, and sequence. `PaintSystem` alone validates eligibility and returns accepted amount/written pixels.
- Replay format 3 carries stage/profile versions, accepted seed and height checksum, physics FPS, ordered manual actions, and expected sealed shot observations. It contains no transform samples.
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
          │                         └── PaintDepositRequest ───────┘
          │                                      ▼
          └──── sealed observation/state ── PaintSystem
```

- Required typed events include shot fired, measured contact/bounce, accepted paint deposit, mechanism struck/split, projectile stopped, shot settled, sealed observation, coverage changed, stage clear, and stage failed.
- `StageController` changes state only through explicit transition methods that validate allowed predecessors.
- `StageController` seals its `ShotObservation` only after every parent/child and paint-flow job are inactive for two consecutive physics ticks.
- Restart first blocks new actions, cancels speed/camera transitions, frees managed temporary objects, resets mechanisms and timers, clears paint/effects, reapplies immutable data, then enters `BRIEFING` or the chosen retry state.
- Gameplay construction generates or loads the accepted layout before briefing. Restart reuses its requested seed and deterministic acceptance path; generator or placement failure blocks briefing and is a verification/export error, never an authored-coordinate fallback.

### Paint implementation

- The implemented 512×512 CPU-authoritative byte buffers batch texture uploads and increment coverage only when an eligible byte crosses the threshold; no full-mask readback is used during play.
- Maintain a read-only eligible byte mask in the same UV/world X/Z mapping. Coverage increments only when an eligible byte first crosses the paint threshold and therefore counts overlap once without recurring scans.
- Queue deposits during physics updates, apply them in deterministic sequence order, reconstruct candidate pixels on the shared 3D heightfield, and publish at most one dirty texture update per physics tick.
- Reject ineligible, disconnected, opposite-facing, and 3D-out-of-radius candidates before persistent writes. Every persistent visible pixel is coverage-eligible.
- Downhill flow follows the steepest lower eight-neighbor on the same accepted height grid for the fixed finite amount/radius/decay budget.
- Terrain material samples the same runtime texture; no decal nodes or alternative visual-paint state are allowed.

### Physics and determinism

- Use 60 physics ticks per second, rigid bodies with CCD, explicit data-defined materials/damping, and bounded lifetimes.
- Extract real contacts from `PhysicsDirectBodyState3D`, choose the highest-impulse contact deterministically, and debounce by collider/shape until absent for two ticks. Never infer contact from projectile center minus world up.
- Calculate preview positions with the exact launch transform, velocity conversion, gravity, replace-mode linear damping, fixed `1/60 s` recurrence, projectile radius, and terrain/mechanism masks used by the rigid body. Terminate at the first sphere-cast collision or bounds exit; never show post-impact behavior.
- Record seeds and shot inputs. Run repeated-shot tests on unchanged stages and define a measured position/coverage tolerance before enabling replay completion.
- Simulation-speed changes affect physics consistently and are allowed only in observation after landing.

### Persistence and failure handling

- Save a versioned dictionary to `user://` through a temporary file followed by replacement; invalid or newer incompatible data falls back safely while preserving the bad file for diagnosis.
- Never let a save failure block gameplay; surface a restrained warning and keep results in memory.
- Enforce projectile/split/flow/effect budgets at the request boundary and log rejected debug detail only in development builds.
- Out-of-bounds, lifetime, empty payload, and low-speed timeout all converge on one idempotent projectile deactivation path.

### Validation boundary

- `scripts/verify.ps1` is the repository smoke entry for import and main-scene runtime.
- Each subsystem adds focused headless tests or deterministic test scenes beside its owner; no third-party test plugin is required.
- Final validation includes production export/start, three-stage manual solutions, restart stress, save/replay restart, common-resolution UI review, performance measurement, console review, and exact screenshot checks.

## Acceptance Criteria

- No two owners can authoritatively decide stage state, paint coverage, or projectile settlement.
- Human UI, replay, debug actions, and AI actions cannot bypass the same command validation.
- No device input or target solver remains in `CannonController`, and only `StageController` accepts Fire and consumes a shot after state/origin/prediction guards pass.
- No fixed stage height function, unseeded production RNG, authored production mechanism X/Z coordinate, or second terrain/coverage representation remains after migration.
- Restart and stage unload leave zero managed projectiles, flow jobs, temporary mechanism states, or stale timers.
- Visual paint and coverage remain demonstrably identical views of one mask.
- All save/replay formats include explicit versions and deterministic failure behavior.
- The project passes `scripts/verify.ps1` after architectural changes.

## Implemented Delivery Boundary

- `export_presets.cfg` defines the Windows Desktop release path with an embedded PCK and excludes tests, screenshots, reports, builds, and editor state.
- Cross-process probes validate persistence and deterministic replay without relying on the HUD or a shared process.
- The production executable accepts delivery-only capture arguments through `DeliveryCaptureRunner`; normal launches do nothing with this node, and the debug overlay remains unavailable in release builds.
