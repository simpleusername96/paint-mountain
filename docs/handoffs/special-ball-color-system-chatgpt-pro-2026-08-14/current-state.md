---
type: evidence
status: active
created: 2026-08-14
source: local repository at review baseline 377d71398fe526043ad0158328bbe0bac04abd2e
topic: implemented baseline and mismatch for external product analysis
related:
  - README.md
  - source-map.md
---

# Current State

## Purpose

Give the external reviewer enough implemented context to distinguish current
gameplay from unimplemented design documents.

## Sources

- `.agents/Documentation.md`
- `docs/source-brief.md`
- Current code and tests listed in `source-map.md`
- Commits `e1f5491` and `377d713`

## Findings

### User intent

The user wants a fresh analysis of special-ability balls and individual red/green
paint. A limited-preview queue remains part of the exploration, but it must be
clearable without bespoke queue authoring for each terrain. Existing terrain
should be reused where it supports the rule. No current proposal is approved.

### Implemented behavior

- The cannon is stationary. The player chooses yaw, elevation, and power before
  firing and does not steer a ball in flight.
- `scenes/gameplay/cannon.tscn` supplies one `basic_paintball.tres` resource.
- `CannonController` launches through `ProjectileManager`; `PaintProjectile`
  continuously paints traversed target surfaces while in contact.
- `PaintSystem` owns the authoritative scalar paint mask and coverage result.
- `StageController` owns stage state, accepted shots, Retry, Finish, timeout,
  and terminal result decisions.
- Thirty generated stages use terrain geometry plus Burst, Splitter, and Uphill
  Rebound glyph-mechanism data and runtime wiring.
- There is no special-ball queue, no red/green ownership layer, and no new
  multi-color clear condition in runtime code.

### Relevant flow

    player yaw / elevation / power
      -> CannonController with basic_paintball.tres
      -> ProjectileManager creates PaintProjectile
      -> projectile flight and terrain/mechanism contacts
      -> PaintSystem authoritative paint mask
      -> StageController Finish or timeout evaluation
      -> HUD and result presentation

### Mismatch

The desired direction needs a reason for ball order, special behavior, color,
and terrain to interact. Prior proposals specified components but did not prove
that the combined rule creates a clear planning problem. Count-balanced queues
do not prove geometric feasibility, while stage-specific witness queues create
an unacceptable content burden.

### Completed work

- `e1f5491`: detailed but now-superseded queued-ball plan and product docs.
- `377d713`: seven historical UI concept images; no gameplay implementation.
- This handoff commit: idea history, neutral draft requirements, reopened
  questions, and deactivated implementation authority.

## Recommendations

- Analyze the product loop before data schemas or full rosters.
- Keep implementation paused until the user accepts a concrete MVP.
- Use existing terrain and current runtime responsibilities as constraints, not
  proof that the glyph mechanics must stay unchanged.

## Limitations

- No special-ball prototype or multi-color playtest exists.
- The baseline has not been rebalanced for any proposed rule.
- Existing terrain reachability data was not designed to prove arbitrary
  special-ball/color queue feasibility.

## Validation Baseline

- Repository status was clean at `377d713` before this documentation task.
- This task changes Markdown lifecycle and handoff files only.
- Runtime verification is not required because no code, scene, resource, or
  project setting changes.
