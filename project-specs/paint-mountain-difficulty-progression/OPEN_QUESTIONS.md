---
type: evidence
status: active
created: 2026-08-13
last_reviewed: 2026-08-14
topic: unresolved special-ball, queue, red-green paint, and terrain-reuse decisions
scope: product questions that must be answered before implementation planning
related:
  - PRD.md
  - ../../docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/README.md
---

# Open Product Questions

## Purpose

Keep unresolved product choices visible while ChatGPT Pro compares alternative
systems. None of the questions below is a selected implementation rule.

## Sources

- `../../docs/source-brief.md`
- `../../docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/idea-history.md`
- The user's 2026-08-14 rejection of both stage-specific queue authoring and
  the later universal paired-bag proposal.

## Findings

- What single planning problem should special abilities, queue uncertainty, and
  color create together? Which one of those elements can be removed from the MVP?
- How many future balls should be visible, and what useful decision does the
  hidden tail force?
- Should the queue be fixed, seeded, constrained-random, draftable, or rerollable?
  What happens on Retry?
- How can every queue remain clearable without bespoke per-terrain queue lists or
  an expensive solver for every content change?
- Should red and green each have minimum coverage, should later paint overwrite
  ownership, or should overlap cancel? What prevents unwinnable late states?
- How should red/green state remain legible for red-green color-vision deficiency?
- Which existing terrain shapes or former mechanism placements become useful
  affordances, and which glyph UI/art/script responsibilities should be removed?
- Which ball behaviors are genuinely different planning tools? Only Impact
  Burst, Apex Split, and extreme rebound came directly from the user.
- What is the smallest stage set and ball roster that can test the core rule?

## Limitations

- No special-ball queue or multi-color paint rule exists in runtime code.
- The seven queued-ball UI images show a superseded blue/orange interpretation;
  they are evidence of prior exploration, not visual targets.
- Numerical stage quotas, colors beyond red/green, ball counts, and queue horizon
  remain unapproved.
