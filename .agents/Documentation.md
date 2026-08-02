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

The repository was created from a complete vertical-slice brief. The current milestone is repository and project setup only; gameplay systems remain planned work.

## Decision

- The project uses Godot 4.x, GDScript, the Compatibility renderer, Windows desktop, and a fixed 60 Hz physics tick.
- The initial runnable entry is an explicitly labeled bootstrap scene that checks project loading, 3D rendering, procedural heightfield geometry, collision generation, and the intended distant-mountain composition.
- Product behavior, technical ownership, planned work, and implemented status are stored separately to avoid treating plans as working features.

## Rationale

- A small real scene gives the next implementation phase a verified engine baseline without pretending the vertical slice already exists.
- The provided brief already locks the engine, core architecture, mechanisms, scope exclusions, performance target, and acceptance artifacts.
- Compatibility rendering and dependency-free procedural primitives keep the initial project portable on modest Windows hardware.

## Consequences

- The bootstrap scene is temporary and must be replaced as the main entry only after the first real gameplay scene passes smoke validation.
- No gameplay, coverage, mechanisms, menu flow, persistence, replay, audio, or required screenshots are implemented yet.
- Future feature completion claims must cite running-game checks and update this record.

## Current Status

- Repository and agent environment: complete.
- Godot project configuration and bootstrap scene: complete.
- Phase 2 through Phase 8 gameplay work: not started.

## Known Risks

- Godot is not currently on PATH; local verification needs `-GodotPath` or a `GODOT_BIN` environment variable.
- Final coverage targets and stage solutions require manual tuning against the implemented mask and physics; the brief's percentages are requirements, not yet validated balancing data.

## Verification

- Run: `powershell -ExecutionPolicy Bypass -File scripts/verify.ps1 -GodotPath <path-to-Godot-console.exe>`
- Documentation-only fallback: `git diff --check`
