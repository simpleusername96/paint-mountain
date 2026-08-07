---
type: spec
status: active
created: 2026-08-02
last_reviewed: 2026-08-07
source: ../docs/source-brief.md
scope: repository purpose and non-negotiable product constraints
related:
  - ../docs/source-brief.md
  - ../docs/design-spec.md
  - ../docs/technical-architecture.md
  - execplans/2026-08-03-gameplay-visual-reset.md
  - execplans/2026-08-05-gameplay-contract-recovery.md
  - execplans/2026-08-06-ballistic-terrain-preparation.md
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

- Deliver thirty all-open, gradually harder stages, the full menu-to-result loop,
  Aim Lock/Map Inspection/result cameras, continuous physical-contact paint,
  target-mask coverage, saving, replay, debug tools, audio/visual feedback, and
  exactly Burst, Splitter, and Uphill Rebound mechanisms.
- Use Godot 4.x and GDScript with no backend, Docker, or unnecessary external dependencies.
- Make visual paint and calculated coverage share one authoritative mask.
- Generate a thick, collidable, one-height-per-XZ route-graph mountain whose
  render, Playable Terrain Surface collision, queries, target rasterization,
  and paint reconstruction consume one exact triangle list. Close its perimeter
  with a non-paintable Support Shell and bottom; keep the environment open with
  no visible, collidable, or hidden rear/side containment walls. A restrained
  non-target apron may remain below the play space.
- Keep one stationary baked cannon transform per stage. Map View may orbit for
  inspection, but the player cannot move the launch position around the
  mountain. Persistent paint is limited to the Playable Terrain Surface, and
  only Target Area overlap contributes coverage.
- Generate and verify one legal stage-start/restart aim near the target centroid
  and one separate legal first hit for the global highest playable region. Do
  not expose either witness as auto-aim. Exhaustive first-hit certification for
  every target texel is optional diagnostic QA, not a release requirement.
- Reject a terrain seed during generation when any scoreable projectile-center
  sample lies outside the shared analytic yaw/horizon/height envelope; never
  delete target pixels to force admission.
- Keep the next yaw/elevation/power aim and trajectory usable after Fire while up
  to two root-shot families move; motion is not an input-blocking stage phase.
- Use the current `1.20 m` parent physical radius with `1.40 m` continuous and
  `1.75 m` impact paint radii, all reconstructed through the authoritative mask;
  map power `0..100` linearly to `32..160 m/s`.
- Keep repeated launches effectively deterministic and the initial trajectory preview consistent with real launch physics.
- Keep menu and stage-select navigation responsive: load validated baked layouts
  asynchronously, retain only a bounded selected/nearby set, and create scene,
  render, physics, preview, and paint state on the main thread.
- Keep the human UI independent from an in-process observation/action API suitable for later AI play and automated testing.
- Validate the finished project with focused physics and interaction regressions,
  production-style representative gameplay captures, and user-directed play
  checks for concrete issues. Do not require a prescribed solution route or an
  all-stage manual playthrough.

## Non-Goals

- No monetization, currencies, shops, gacha, ads, daily systems, live service, multiplayer, leaderboards, user-generated maps, story, inventory, character customization, or projectile/cannon collections in the vertical slice.
- No full fluid simulation, orthographic tabletop primary gameplay, direct projectile steering, caves, or overhangs.
- No feature claims based on mockups or documentation alone.

## Hard Constraints

- The perspective aiming camera keeps the cannon within roughly 20–30% of the
  frame while the complete mountain remains visible as a smaller distant mass.
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
