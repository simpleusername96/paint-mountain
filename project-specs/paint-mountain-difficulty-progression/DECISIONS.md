---
type: record
status: superseded
superseded_by: ../../docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/README.md
created: 2026-08-13
scope: queued-ball and paint-ownership product decisions
source: ../../docs/source-brief.md
related:
  - PRD.md
  - ../../.agents/research/paint-mountain-difficulty-progression/RESEARCH.md
  - ../../.agents/execplans/2026-08-13-queued-ball-paint-ownership.md
---

# Queued Ball and Color Decision

> Superseded on 2026-08-14. This record preserves an earlier assistant-selected
> design; it is not approved for implementation. Red/green, terrain reuse, queue
> feasibility, and authoring cost reopened the product decision.

## Context

The user replaced terrain glyph mechanisms with balls that carry their own
behaviors, requested a Tetris-like preview with an unknown later tail, and asked
for multiple color/overlap rules to be compared. This also replaces the earlier
Shared Propellant selection.

## Decision

- Show the current ball and next three. Keep the fifth and later positions
  hidden from both the player and the public agent API.
- Use nine ball types: Standard, Impact Burst, Apex Split, Hyper Bounce, Anchor,
  Climber, Wide Roller, Triple Skimmer, and Contact Fuse.
- Use fixed blue/orange stage colors, per-color minimums, and latest-writer
  ownership. Keep total painted strength monotonic.
- Make queues deterministic per stage and repeat them on Restart.
- Remove the complete terrain-glyph contract after the replacement queue,
  behaviors, paint mask, and catalog v11 work.

## Rationale

- Four visible positions create multi-shot planning without adding a new player
  action or revealing the complete solution.
- Intrinsic behaviors make the important rule visible before Fire rather than
  depending on a distant terrain marker and post-impact surprise.
- Fixed color quotas make order matter while preserving comparable attempts.
- Latest-writer ownership is visible directly on terrain; cancellation and
  mixing require hidden history or extra score states.
- A deterministic stage queue preserves replay, testability, and learning on
  Retry while still withholding later information on the first attempt.

## Alternatives

### Queue alternatives

- **Runtime-random bag:** rejected because a Retry could become easier or
  impossible for reasons outside the player's plan.
- **Full authored queue visible:** rejected because it removes the intended
  uncertainty and encourages solving the whole list before the first shot.
- **Hold/swap:** rejected because it weakens queue order and adds a second
  inventory-like control.
- **Shared Propellant plus queue:** rejected because both systems tax the same
  pre-shot decision and would obscure why a shot is difficult.

### Color alternatives

- **Complementary cancellation:** rejected because overlap can erase hard-won
  total progress through soft contact edges.
- **Neutral third color:** rejected because it adds a third metric and unclear
  threshold value.
- **Color-locked terrain zones:** rejected because it reintroduces marked world
  regions immediately after glyph removal.
- **Decorative color only:** rejected because color would not change planning.

## Consequences

- The paint representation and save schema must migrate.
- The queue becomes part of launch, prediction, HUD, agent observation, catalog,
  and replay-facing contracts.
- All glyph assets and schemas can be deleted only after ball-owned replacement
  paths and v11 catalog hydration pass.
- Stage results gain true Clear/Failed evaluation based on total/A/B objectives.
