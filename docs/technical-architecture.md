---
type: spec
status: active
created: 2026-08-02
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
| `StageData` | Typed stage configuration and content references | Mutable runtime state |
| `CannonController` | Yaw/elevation/power, shared launch calculation, initial trajectory query | Post-fire steering or stage outcome |
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

### Data contracts

- Use typed `Resource` classes for StageData, ProjectileData, and each mechanism's configuration.
- Stage scenes contain terrain and authored placement; StageData references them and owns targets, shots, colors, bounds, camera bookmarks, mask, thresholds, and tutorial content.
- Runtime state is recreated from immutable configuration on restart. Mechanisms implement `activate(projectile, context)`, `can_activate(projectile)`, and `reset_state()` or an equivalent narrow typed contract.
- Paint requests carry world position, surface direction/normal, radius/shape, amount, source projectile/event, and deterministic ordering information.
- Replay shots carry stage ID/version, physics seed, order, yaw, elevation, power, and optional camera choice.
- Agent observations are immutable snapshots; actions enter through the same validated cannon/stage command layer used by human UI.

### State and event flow

```text
Human UI / GameplayAgentApi
          │ validated intent
          ▼
   StageController ──────► CannonController ──────► ProjectileManager
          │                         │                        │
          │ state                   │ launch                 │ lifecycle
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

### Paint implementation

- Start with a 512×512 CPU-authoritative byte mask and batched texture upload unless measured performance proves a GPU render target simpler and equally testable.
- Maintain a read-only eligible byte mask in the same UV/world X/Z mapping. Coverage scans eligible pixels at a throttled cadence and counts each painted pixel once.
- Queue stamps during physics updates, apply them in deterministic insertion order, and publish one dirty-region texture update per batch where practical.
- Downhill flow samples the StageData height grid for a fixed number of steps and transfer budget; seeded tie-breaking prevents frame-dependent paths.
- Terrain material samples the same runtime texture; no decal nodes or alternative visual-paint state are allowed.

### Physics and determinism

- Use 60 physics ticks per second, rigid bodies with CCD, explicit data-defined materials/damping, and bounded lifetimes.
- Calculate preview positions from the exact launch transform, velocity conversion, and gravity used to initialize the rigid body; terminate at the first space-state collision query.
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
- Restart and stage unload leave zero managed projectiles, flow jobs, temporary mechanism states, or stale timers.
- Visual paint and coverage remain demonstrably identical views of one mask.
- All save/replay formats include explicit versions and deterministic failure behavior.
- The project passes `scripts/verify.ps1` after architectural changes.
