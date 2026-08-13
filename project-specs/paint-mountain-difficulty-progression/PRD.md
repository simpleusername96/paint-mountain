---
type: spec
status: active
created: 2026-08-13
canonical_for: queued ball types and paint-color difficulty progression for Paint Mountain
scope: limited-preview launch queue, intrinsic ball behaviors, two-color objectives, and glyph removal across thirty stages
source: ../../docs/source-brief.md
related:
  - RESEARCH.md
  - DECISIONS.md
  - OPEN_QUESTIONS.md
  - TASKS.md
  - ../../.agents/execplans/2026-08-13-queued-ball-paint-ownership.md
---

# Queued Ball Types and Paint Ownership

## Purpose

Raise difficulty by making the player plan with a limited preview of balls that
have different intrinsic behaviors and paint colors. Replace terrain glyph
mechanisms instead of stacking the queue on top of them.

## Scope

This spec owns the player queue rule, nine-ball roster, two-color clear rule,
introduction order, and removal of active glyph contracts. The linked ExecPlan
owns implementation order, exact ownership boundaries, migration, and
validation detail.

## Player Rule

- The player always fires the current queued ball. The HUD shows that ball and
  the next three; the fifth and later balls remain hidden until they enter the
  four-position horizon.
- An accepted root launch advances the queue once. A rejected Fire or a derived
  child advances it zero times.
- Each stage queue is deterministic and repeats on Restart. There is no Hold,
  swap, skip, reroll, inventory, or ball-selection action.
- Ball behavior and paint color are separate properties. A shape/icon and name
  identify behavior; blue/orange plus `A`/`B` identify paint ownership.

## Ball Roster

1. **Standard:** current continuous contact-painting ball.
2. **Impact Burst:** makes a large paint stamp and disappears on first valid
   ground contact.
3. **Apex Split:** divides at its first airborne apex into three non-recursive
   Standard children in a fixed fan.
4. **Hyper Bounce:** retains extreme rebound and settles only on a sufficiently
   flat, slow landing.
5. **Anchor:** stops with high friction at its first valid contact.
6. **Climber:** redirects once toward the local uphill tangent.
7. **Wide Roller:** trades range for a wider continuous trail.
8. **Triple Skimmer:** performs exactly three countable shallow skips and then
   becomes Standard.
9. **Contact Fuse:** arms on contact, continues moving, and bursts at a later
   valid contact after a fixed delay.

The ExecPlan fixes initial tuning, trigger boundaries, stable IDs, child
inheritance, and non-symbolic visual silhouettes.

## Paint and Clear Rule

- Paint A is blue `#2584FF`; Paint B is orange `#FF8A3D`.
- Later paint owns an overlap. Repainting may transfer an area between A and B
  but cannot reduce total painted strength.
- Stages 01-03 use A only. Stages 04-30 clear only when total coverage and both
  color minimums are met at Finish or timeout.
- Each color minimum equals 30% of the total target on Stages 04-09, 35% on
  Stages 10-18, and 40% on Stages 19-30.
- Requirements are fixed per stage. There are no random thresholds, color
  cancellation, mixing, coat depth, or third neutral score.
- Total coverage remains the score/star measure. Clear status outranks a failed
  result when saving a best.

## Progression

- Stages 01-09 introduce Standard, Impact Burst, Apex Split, Anchor plus Paint
  B, Hyper Bounce, Climber, Wide Roller, Triple Skimmer, and Contact Fuse in
  that order.
- Each introduction queue contains the new type at least twice and exposes it
  inside the first visible horizon.
- Stages 10-15 use Standard plus two non-standard types; 16-21 use Standard
  plus three; 22-27 use Standard plus four; 28-30 use Standard plus five.
- From Stage 04 onward, both colors occur at least twice when the shot count
  permits and both appear within the first visible horizon.

## Requirements

- `StageController` owns queue progression and clear/failure decisions.
- `PaintSystem` keeps one authoritative owner-aware paint representation used
  for terrain visuals and total/A/B coverage. Separate color masks are
  prohibited.
- Public human and agent views expose the same four queue positions and never
  disclose the hidden tail.
- All ball rules remain deterministic and require no in-flight steering.
- Terrain glyph UI, world art, scripts, scenes, resources, generated fields,
  observations, localization, and active tests are removed after replacements
  and catalog v11 are verified.
- Save v6 must not claim that a v5 scalar result satisfied new color quotas.

## Acceptance Criteria

- Nine behaviors and two paint colors are readable as independent facts.
- Queue consumption, reset, prediction invalidation, derived children, and the
  hidden four-position boundary behave exactly as specified.
- Total/A/B HUD values, terrain colors, terminal evaluation, result data, and
  saved bests agree with the one authoritative paint snapshot.
- All thirty deterministic queues satisfy progression, color-supply, capacity,
  and feasibility validation.
- No active terrain glyph or mechanism contract remains.
- Korean and English running-build captures and Windows/Web production builds
  pass the checks in the active ExecPlan.

## Non-Goals

- Shared propellant, Hold, ball inventory, upgrades, shops, adaptive odds,
  unseeded runtime randomness, projectile steering, or post-contact path hints.
- Complementary-color erasure, true mixing, a third paint state, a second
  coverage mask, or automatic stage completion when thresholds are reached.

## Related

- `DECISIONS.md` records the selected queue/color model and rejected options.
- `RESEARCH.md` separates local facts and cross-domain analogies from product
  authority.
- The active ExecPlan is
  `../../.agents/execplans/2026-08-13-queued-ball-paint-ownership.md`.
