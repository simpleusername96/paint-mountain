---
type: evidence
status: active
created: 2026-08-14
source: docs/source-brief.md plus repository architecture constraints
topic: accepted constraints and unaccepted proposals for external review
related:
  - README.md
  - idea-history.md
---

# Constraints and Decision State

## Purpose

Prevent the external reviewer from treating detailed past proposals as approved
requirements or from recommending changes that violate current architecture.

## Sources

- `docs/source-brief.md`
- Root `AGENTS.md`
- `.agents/Documentation.md`
- `docs/design-spec.md`
- `docs/technical-architecture.md`
- Current conversation history summarized in `idea-history.md`

## Findings

### Must preserve

- Stationary cannon; pre-shot yaw, elevation, and power; no in-flight steering.
- Continuous painting of traversed target surfaces while a projectile is in
  contact.
- `StageController` as the sole owner of stage state, shot progression, and
  terminal decisions.
- `PaintSystem` as the one authoritative runtime paint representation for both
  terrain visuals and coverage.
- Typed Resources for projectile, stage, mechanism, and result tuning.
- The same gameplay actions and observable facts for human and future AI play.
- Current terrain geometry as reusable design material, not disposable content.
- A feasible clear path for every allowed ball supply.
- Low per-stage authoring and maintenance cost.

### Explicit user direction that remains in scope

- Explore special-ability balls, including contact burst, apex split, and
  extreme rebound.
- Explore a Tetris-like limited-preview queue with an unknown later tail.
- Use red and green as the individual paint colors.
- Reconsider and potentially remove glyph-related UI, visual design, and
  scripts, while looking for ways to reuse the actual terrain.

### Not selected

- Exact preview count or whether the current ball counts as a preview slot.
- Fixed, seeded, random, draft, bag, adaptive, or reroll queue policy.
- Retry behavior and whether the hidden tail repeats.
- Nine-ball roster or any assistant-invented ball beyond the three user examples.
- Per-color quotas, latest-writer ownership, complementary cancellation, or
  total-only clear conditions.
- Exact red/green hues, thresholds, stage count, shot counts, or introduction order.
- Complete deletion, transformation, or retention of glyph mechanisms.

### Prior proposals not to revive without new reasoning

- **Blue/orange nine-ball deterministic plan:** superseded by later user input.
- **Three or four prevalidated variants per terrain:** rejected because the
  content-authoring and maintenance burden scales with terrain count.
- **Universal red/green paired bag:** not accepted; balanced counts alone do not
  prove reachability or create a compelling terrain-dependent decision.
- **Reroll as the primary solvability fix:** unresolved and risky because it can
  turn planning into repeated queue fishing.

### Evaluation criteria for alternatives

1. Does it create a clear decision before every shot?
2. Does partial preview matter without making failure depend on hidden luck?
3. Can feasibility be guaranteed cheaply as stages or tuning change?
4. Do red/green paint rules create readable strategy instead of bookkeeping?
5. Does it give existing terrain shapes new uses?
6. Can a four-or-fewer-ball, small-stage MVP falsify the idea quickly?
7. Does it preserve prediction clarity and avoid in-flight input?
8. Is the UI legible without relying on red/green hue alone?

### Source-of-truth hierarchy

1. `AGENTS.md` for repository operating and architectural guardrails.
2. `docs/source-brief.md` for product intent and verbatim later user revisions.
3. Current code, tests, and `.agents/Documentation.md` for implemented truth.
4. Active design and technical specifications for non-conflicting contracts.
5. The draft PRD and this handoff for the current open problem.
6. External model feedback as advisory evidence only.

## Recommendations

- Compare complete rule systems, not isolated ball ideas.
- Require each option to state its feasibility mechanism and authoring model.
- Recommend the smallest experiment that can prove or disprove the central loop.

## Limitations

- The user has not yet ranked surprise, replayability, color strategy, special
  physics, and content cost against one another.
- No playtest data distinguishes an interesting queue from a merely fair queue.
