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
| `MechanismPlacementGenerator` | Stable feature extraction, mechanism scoring, validation, orientation, and tie-breaking | Mechanism activation behavior or stage outcomes |
| `AimInputController` | Mouse/keyboard device mapping, target hover/lock intent, power-step/repeat input | Fire acceptance, shot consumption, or outcome decisions |
| `ImpactTargetSolver` | Lowest valid fixed-tick damped first-impact solution or explicit invalid result | Device input, post-fire steering, or coverage prediction |
| `CannonController` | Aim mode, yaw/elevation/power commands, target validity, shared launch calculation, trajectory query | Device polling, post-fire steering, or stage outcome |
| `PaintProjectile` | Rigid-body behavior, payload/deposit requests, stop/lifetime/bounds, mechanism contact | Coverage totals or stage transitions |
| `ProjectileManager` | Parent/child registry, eight-ball cap, shot-settled signal, cleanup | Projectile physics tuning |
| `PaintSystem` | Mask stamps/flow/clear, eligible mapping, throttled coverage, terrain shader input | Shot limits or UI formatting |
| `GimmickBase` | Shared activation eligibility, state, reset, data contract | Subclass-specific effect |
| `BurstNode` | Direct paint-mask burst and charge/spent feedback | Projectile spawning |
| `SplitterNode` | Consume input and request bounded child fan | Stage settlement decisions |
| `BumperNode` | Cooldown-limited directional impulse and feedback | Direct coverage changes |
| `CameraDirector` | Camera modes, bookmarks, safe interpolation, follow framing | Game rules |
| `HUDController` and screen controllers | Display state and emit user intents | Authoritative state mutation |
| `ReplayRecorder` | Attempt metadata, input stream, deterministic playback/fallback samples | Save progression |
| `GameplayAgentApi` | UI-independent observations, actions, and event stream | Duplicate simulation rules |
| `AppRoot` | Main-menu, stage-select, settings, and gameplay navigation/lifetime | Stage outcomes or paint state |
| `DebugOverlay` | Debug-build-only metrics, derived mask previews, actions, and JSON log export | Alternate gameplay authority |
| `DeliveryCaptureRunner` | Command-line reproduction of named release evidence states | Normal player navigation or game rules |

### Data contracts

- Use typed `Resource` classes for StageData, ProjectileData, and each mechanism's configuration.
- StageData owns targets, shots, colors, bounds, camera bookmarks, generation profile/seed, mechanism loadout, thresholds, and translation keys. Runtime construction consumes one accepted `GeneratedStageLayout`; stage scenes do not own terrain formulas or production mechanism coordinates.
- Runtime state is recreated from immutable configuration on restart. Mechanisms implement `activate(projectile, context)`, `can_activate(projectile)`, and `reset_state()` or an equivalent narrow typed contract.
- Mesh vertices/collision, paint height queries, eligible-mask derivation, mechanisms, decorations, replay checksum, and agent terrain observations all consume the same immutable accepted height grid. `eligible_mask` is static scoring eligibility; `PaintSystem` remains the sole mutable painted/coverage representation.
- Paint requests carry world position, surface direction/normal, radius/shape, amount, source projectile/event, and deterministic ordering information.
- Replay format 2 carries stage ID/version, profile version, requested/accepted seed, height-grid checksum, order, yaw, elevation, power, and optional camera choice.
- Agent observations are immutable snapshots; actions enter through the same validated cannon/stage command layer used by human UI.

### State and event flow

```text
AimInputController / Replay / GameplayAgentApi
          │ shared cannon commands and fire request
          ▼
   StageController ──────► CannonController ──────► ProjectileManager
          │                         │                        │
          │ state/fire authority    │ solver/launch          │ lifecycle
          ▼                         ▼                        ▼
   HUD / CameraDirector       PaintProjectile ──────► Mechanisms
          ▲                         │                        │
          │                         └──── paint requests ────┘
          │                                      ▼
          └──── coverage/state events ───── PaintSystem
```

- Required typed events include shot fired, impact/bounce, paint deposited, mechanism activated/split, projectile stopped, shot settled, coverage changed, stage clear, and stage failed.
- `StageController` changes state only through explicit transition methods that validate allowed predecessors.
- `ProjectileManager` reports settlement only after every parent/child is inactive; `PaintSystem` separately reports flow settled.
- Restart first blocks new actions, cancels speed/camera transitions, frees managed temporary objects, resets mechanisms and timers, clears paint/effects, reapplies immutable data, then enters `BRIEFING` or the chosen retry state.
- Gameplay construction generates or loads the accepted layout before briefing. Restart reuses its requested seed and deterministic acceptance path; generator or placement failure blocks briefing and is a verification/export error, never an authored-coordinate fallback.

### Paint implementation

- The implemented 512×512 CPU-authoritative byte buffers batch texture uploads and increment coverage only when an eligible byte crosses the threshold; no full-mask readback is used during play.
- Maintain a read-only eligible byte mask in the same UV/world X/Z mapping. Coverage increments only when an eligible byte first crosses the paint threshold and therefore counts overlap once without recurring scans.
- Queue stamps during physics updates, apply them in deterministic insertion order, and publish one dirty-region texture update per batch where practical.
- Downhill flow samples the accepted generated-layout height grid for a fixed number of steps and transfer budget; seeded tie-breaking prevents frame-dependent paths.
- Terrain material samples the same runtime texture; no decal nodes or alternative visual-paint state are allowed.

### Physics and determinism

- Use 60 physics ticks per second, rigid bodies with CCD, explicit data-defined materials/damping, and bounded lifetimes.
- Calculate target solutions and preview positions with the exact launch transform, velocity conversion, gravity, linear damping, fixed `1/60 s` recurrence, projectile radius, and collision masks used by the rigid body. Terminate at the first sphere shape-cast collision; never show post-impact behavior.
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
- No device input remains in `CannonController`, and only `StageController` accepts Fire and consumes a shot after cannon aim validity passes.
- No fixed stage height function, unseeded production RNG, authored production mechanism X/Z coordinate, or second terrain/coverage representation remains after migration.
- Restart and stage unload leave zero managed projectiles, flow jobs, temporary mechanism states, or stale timers.
- Visual paint and coverage remain demonstrably identical views of one mask.
- All save/replay formats include explicit versions and deterministic failure behavior.
- The project passes `scripts/verify.ps1` after architectural changes.

## Implemented Delivery Boundary

- `export_presets.cfg` defines the Windows Desktop release path with an embedded PCK and excludes tests, screenshots, reports, builds, and editor state.
- Cross-process probes validate persistence and deterministic replay without relying on the HUD or a shared process.
- The production executable accepts delivery-only capture arguments through `DeliveryCaptureRunner`; normal launches do nothing with this node, and the debug overlay remains unavailable in release builds.
