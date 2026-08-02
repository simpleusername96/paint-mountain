---
type: spec
status: active
created: 2026-08-02
source: ../docs/source-brief.md
scope: repository purpose and non-negotiable product constraints
related:
  - ../docs/source-brief.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
---

# Paint Mountain Project Brief

## Purpose

Create a polished, playable vertical slice of a deterministic 3D gravity-driven paintball puzzle game. The mountain is a distant, dominant landform; the cannon is a small stationary foreground tool; success comes from reading terrain and planning one high-value launch.

## Scope

This file is a compact routing summary. The unabridged directive in `docs/source-brief.md` governs the complete local single-player vertical slice and wins if any summary differs. Detailed working behavior is in `docs/design-spec.md`; runtime ownership is in `docs/technical-architecture.md`.

## Requirements

- Deliver three stages, the full menu-to-result loop, inspection/aim/follow/result cameras, finite paint, coverage, saving, replay, debug tools, audio/visual feedback, and exactly Burst, Splitter, and Bumper mechanisms.
- Use Godot 4.x and GDScript with no backend, Docker, or unnecessary external dependencies.
- Make visual paint and calculated coverage share one authoritative mask.
- Keep repeated launches effectively deterministic and the initial trajectory preview consistent with real launch physics.
- Keep the human UI independent from an in-process observation/action API suitable for later AI play and automated testing.
- Validate the finished project by running it, testing at least one reliable solution per stage, and capturing seven separate full-resolution screenshots from the actual game.

## Non-Goals

- No monetization, currencies, shops, gacha, ads, daily systems, live service, multiplayer, leaderboards, user-generated maps, story, inventory, character customization, or projectile/cannon collections in the vertical slice.
- No full fluid simulation, orthographic tabletop primary gameplay, direct projectile steering, caves, or overhangs.
- No feature claims based on mockups or documentation alone.

## Hard Constraints

- The perspective aiming camera keeps the cannon within roughly 15–20% of the frame while the mountain fills most of the middle and upper view.
- Stage progression is controlled by one explicit state machine; restart removes all temporary gameplay state in under one second after confirmation.
- A fixed timestep, continuous collision detection, bounded child counts, finite paint flow, and seeded behavior protect predictability and performance.
- The first delivery targets stable 60 FPS at 1920×1080 on modest Windows hardware using a lightweight renderer.

## Acceptance Criteria

The complete acceptance contract is maintained in `docs/test-checklist.md`. Current implementation status is maintained separately in `Documentation.md`.
