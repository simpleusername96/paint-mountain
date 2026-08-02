---
type: record
status: active
created: 2026-08-02
scope: implemented project state and durable bootstrap decisions
related:
  - Plan.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
---

# Project Record

## Context

The repository was created from a complete vertical-slice brief. The current milestone includes the verified Phase 2 cannon/projectile sandbox and Phase 3 authoritative paint system; the complete stage loop remains planned work.

## Decision

- The project uses Godot 4.x, GDScript, the Compatibility renderer, Windows desktop, and a fixed 60 Hz physics tick.
- The initial runnable entry is an explicitly labeled bootstrap scene that checks project loading, 3D rendering, procedural heightfield geometry, collision generation, and the intended distant-mountain composition.
- Phase 2 replaces the configured main entry with a projectile sandbox while preserving the isolated bootstrap scene. `ProjectileData` owns tuning, `CannonBallistics` is shared by preview and launch, and `ProjectileManager` bounds and cleans up rigid bodies.
- `PaintSystem` owns one 512×512 runtime paint image and its derived texture. The terrain shader samples that texture, while incremental threshold accounting derives coverage from the same pixel writes and an inset eligible mask.
- Product behavior, technical ownership, planned work, and implemented status are stored separately to avoid treating plans as working features.

## Rationale

- A small real scene gives the next implementation phase a verified engine baseline without pretending the vertical slice already exists.
- The provided brief already locks the engine, core architecture, mechanisms, scope exclusions, performance target, and acceptance artifacts.
- Compatibility rendering and dependency-free procedural primitives keep the initial project portable on modest Windows hardware.

## Consequences

- The bootstrap scene remains as an isolated baseline, while the verified projectile sandbox is now the temporary main entry until the complete gameplay scene passes the same smoke checks.
- Aiming, projectile physics, finite-payload deposits, paint visuals, coverage, short downhill flow, and mask debug views are implemented in the sandbox. Mechanisms, stage rules, menu flow, persistence, replay, audio, and required screenshots are not implemented yet.
- Future feature completion claims must cite running-game checks and update this record.

## Current Status

- Repository and agent environment: complete.
- Godot project configuration and bootstrap scene: complete.
- Phase 2 cannon and projectile sandbox: complete.
- Phase 3 authoritative paint system: complete.
- Phase 4 through Phase 8: not started.

## Known Risks

- Godot is not currently on PATH; local verification needs `-GodotPath` or a `GODOT_BIN` environment variable.
- Final coverage targets and stage solutions require manual tuning against the implemented mask and physics; the brief's percentages are requirements, not yet validated balancing data.
- The Phase 2 deterministic check measured 0.12567 m between repeated first-contact positions at an accelerated 2× test rate; replay coverage tolerance cannot be measured until Phase 3 exists.
- Current sandbox coverage is intentionally small because stage targets and route tuning begin after the Phase 4 state loop; target percentages are not balanced yet.

## Verification

- Run: `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath <path-to-Godot-console.exe>`
- Phase 2 pure check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_test.gd`
- Phase 2 rigid-body check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase2_physics_test.gd`
- Observed 2026-08-02: import/runtime smoke passed; 31 deterministic ballistic samples matched exactly; two repeated rigid-body shots physically impacted, settled, and differed by 0.12567 m at first contact.
- Phase 3 mask check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase3_paint_test.gd`
- Phase 3 integration check: `Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://tests/phase3_projectile_paint_test.gd`
- Observed 2026-08-02: overlap remained 0.2634%; bounded flow increased a 0.010672% direct stamp to 0.011099%; one physical shot emitted 66 finite requests and accepted only the 2 deposits aligned with terrain, producing 0.0922% authoritative coverage.
- Documentation-only fallback: `git diff --check`
