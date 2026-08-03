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
  - execplans/2026-08-03-gameplay-visual-reset.md
---

# Paint Mountain Project Brief

## Purpose

Create a polished, playable vertical slice of a deterministic 3D gravity-driven paintball puzzle game. The mountain is a distant, dominant landform; the cannon is a small stationary foreground tool; success comes from reading terrain and planning one high-value launch.

## Scope

This file is a compact routing summary. The original directive plus the dated
later-user supersessions in `docs/source-brief.md` govern the complete local
single-player vertical slice and win if any summary differs. Detailed working
behavior is in `docs/design-spec.md`; runtime ownership is in
`docs/technical-architecture.md`.

## Requirements

- Deliver three stages, the full menu-to-result loop, inspection/aim/follow/result
  cameras, continuous physical-contact paint, target-mask coverage, saving,
  replay, debug tools, audio/visual feedback, and exactly Burst, Splitter, and
  Bumper mechanisms.
- Use Godot 4.x and GDScript with no backend, Docker, or unnecessary external dependencies.
- Make visual paint and calculated coverage share one authoritative mask.
- Generate a thick, collidable, one-height-per-XZ route-graph mountain whose
  render, top collision, queries, target rasterization, and paint reconstruction
  consume one exact triangle list. A visible collidable rear wall and faceted
  apron contain the current board.
- Prove that every target-mask texel has a legal manual first-hit aim and derive
  the stage-start/restart aim from the certified hit nearest the target centroid;
  never expose the certificate as auto-aim.
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
- A fixed timestep, continuous collision detection, low ordinary-terrain rebound,
  bounded child counts and paint-command work, and seeded behavior protect
  predictability and performance. There is no payload depletion or downhill
  paint flow.
- The Korean-first aiming HUD uses a left vertical goal-relative coverage gauge
  with absolute text, Fire alone at bottom-center, and shots plus gear at
  top-right. Gear/Escape open one input-capturing paused game menu; Restart is in
  that menu, never in the aiming HUD or Settings form.
- Concept images guide composition, off-white low-poly material separation,
  apparent depth, and readability only; their exact HUD, geometry, seed,
  placements, and paint topology are non-authoritative.
- The first delivery targets stable 60 FPS at 1920×1080 on modest Windows hardware using a lightweight renderer.

## Acceptance Criteria

The complete acceptance contract is maintained in `docs/test-checklist.md`. Current implementation status is maintained separately in `Documentation.md`.
