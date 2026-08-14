---
type: record
status: active
created: 2026-08-14
source: current conversation plus commits e1f5491 and 377d713
topic: history of the special-ability ball and individual-color idea
related:
  - README.md
  - ../../source-brief.md
  - ../../../project-specs/paint-mountain-difficulty-progression/DECISIONS.md
---

# Idea History

## Context

Earlier attempts to raise difficulty through path choices and shared propellant
did not satisfy the user. The user then initiated a new direction: balls should
have different colors or physical properties, appear in a Tetris-like queue,
and replace the terrain-glyph presentation. This record separates the user's
requirements from assistant-generated interpretations and later rejections.

## Decision

There is no approved design yet. The current outcome is to preserve the history,
deactivate the detailed queued-ball plan, and request a fresh external analysis.
Only the boundaries explicitly retained by the user should constrain that review.

## Timeline

### 1. User-originated direction: intrinsic balls, limited information, colors

The user asked for:

- balls with different colors or properties;
- a Tetris-like queue in which the next ball is known but a later ball, roughly
  four positions away, is unknown;
- removal of glyph-related UI, design, and scripts;
- at least three intrinsic behaviors: burst on terrain contact, split in `N`
  directions at the apex, and extreme rebound that needs a high-angle landing
  on flat ground;
- additional ball concepts;
- comparison of two color-rule families: per-color minimums with later paint
  overwriting earlier paint, or total coverage with complementary colors erasing
  their overlap.

The user did not select an exact preview count, full roster, clear formula, or
queue-generation algorithm.

### 2. First formalization: nine balls, four visible positions, blue/orange

Commit `e1f5491` recorded an assistant-selected implementation plan:

- current ball plus three future balls visible;
- fixed deterministic stage queues and the same queue on Retry;
- nine balls: Standard, Impact Burst, Apex Split, Hyper Bounce, Anchor, Climber,
  Wide Roller, Triple Skimmer, and Contact Fuse;
- blue/orange paint, total coverage plus per-color minimums, and latest-writer
  ownership;
- full glyph-contract removal after replacement systems were ready.

These details were an interpretation, not a user-approved final design.

### 3. UI exploration based on that interpretation

Commit `377d713` added seven generated concept images for Stage Select,
Briefing, Aim, Map Inspection, Shot Follow, Clear, and Failed screens. They show
blue/orange paint and a four-position queue. The images are historical evidence
only; no runtime UI or gameplay code changed.

### 4. Assistant-proposed first MVP

The assistant reduced the concept to four ball types: Standard, Impact Burst,
Apex Split, and Hyper Bounce. It suggested six teaching stages, fixed queues,
blue/orange ownership, and total plus per-color targets. The user did not accept
this version and changed key assumptions.

### 5. User revision: red/green, preserve terrain, guarantee clearability

The user required red and green instead of blue and orange. The user also said
not to delete the existing terrain unconditionally and asked how it could remain
useful. For the queue, the user asked whether it would be random and required
that any policy still allow the clear condition; a quick reroll was raised as a
possible escape valve.

This established three durable concerns:

- use red/green if individual colors remain;
- reuse current terrain geometry where practical;
- queue feasibility is mandatory, regardless of randomness.

Reroll was a question, not an approved feature.

### 6. Assistant proposal: small per-stage queue-variant pools

The assistant proposed three or four prevalidated queue variants for each stage,
random selection at stage entry, one reroll before the first shot, and the same
selected queue on Retry. It also proposed constraints such as balanced colors,
both colors in the visible prefix, and a known witness solution.

### 7. User rejection: terrain-specific authoring cost

The user objected that individual queue generation for each terrain would
consume too many resources. This rejects per-stage authored or manually
maintained queue pools as the default content pipeline.

### 8. Assistant fallback: universal paired bag

The assistant then proposed a stage-independent six-ball bag made from two
red/green Standard pairs and one red/green special pair. Pair order and color
order would shuffle. Stages would store only targets, unlocked special types,
and a seed. Reroll was removed from the MVP.

This solved color-count balance cheaply but did not prove physical reachability,
made the special balls optional bonuses, and risked turning the queue into a
formula rather than a terrain-planning system.

### 9. Current outcome: reopen the design

The user said this also did not seem right and requested a complete history,
commit, remote push, and ChatGPT Pro handoff. Therefore the paired bag is not
accepted, the earlier detailed plan is superseded, and implementation remains
paused.

## Rationale

- A detailed plan should not remain active when its core decisions were never
  accepted and later revisions contradict them.
- The failed proposals reveal the actual design tension: useful uncertainty and
  varied tools versus guaranteed feasibility and low content-authoring cost.
- Keeping attribution prevents ChatGPT Pro from mistaking assistant suggestions
  for user requirements.

## Consequences

- No special-ball, queue, red/green paint, or glyph-removal code should be built
  from the superseded ExecPlan.
- Current terrain and glyph implementation remain intact during analysis.
- The next proposal must solve authoring cost and clearability as first-class
  product problems, not as late validation details.
- The earlier images and documents remain available as negative and historical
  evidence.

## Alternatives

- **Nine-ball deterministic per-stage design:** superseded; too many fixed
  decisions were made before the core rule was accepted.
- **Small prevalidated queue pool per terrain:** rejected for content-authoring
  and maintenance cost.
- **Universal paired bag:** not accepted; it guarantees counts but not compelling
  terrain-dependent planning or physical feasibility.
- **Fast reroll:** unresolved; it can recover from bad supply but may reward
  queue fishing and weaken planning.
- **Per-color overwrite quotas versus complementary cancellation:** unresolved;
  both need failure-state and readability analysis.
