---
type: spec
status: draft
created: 2026-08-13
last_reviewed: 2026-08-14
scope: unresolved special-ability ball, limited-preview queue, red/green paint, and terrain-reuse direction
source: ../../docs/source-brief.md
related:
  - ../../.agents/research/paint-mountain-difficulty-progression/RESEARCH.md
  - DECISIONS.md
  - OPEN_QUESTIONS.md
  - TASKS.md
  - ../../docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/README.md
---

# Special-Ability Balls and Individual Paint Colors

## Purpose

Preserve the user-approved boundaries of the special-ball and individual-color
idea while its actual game rule is reconsidered. This is a draft problem
definition, not an implementation-ready selection.

## Scope

This draft covers only the product question. It does not authorize runtime,
catalog, save, UI, terrain, or mechanism changes. The external-review handoff
owns the current analysis request.

## Requirements

- Preserve the stationary cannon, pre-shot yaw/elevation/power choice, and no
  in-flight steering.
- Explore balls with intrinsic behaviors. The user explicitly named an
  impact-burst ball, an apex-splitting ball, and an extremely bouncy ball.
- Use a limited-preview queue: the near future is visible and a later tail is
  unknown. The exact horizon, generation policy, Retry behavior, and reroll
  rule are not selected.
- Use red and green as the individual paint colors. Never rely on red/green hue
  alone to communicate gameplay state.
- Reuse current terrain geometry where it helps the new rule. Do not assume the
  terrain or its authored shapes must be deleted.
- Any fixed or generated ball supply must allow the stage clear condition to be
  met. Avoid a workload that requires individually authoring and maintaining a
  bespoke queue for every terrain.
- Reconsider glyph-related UI, art, and scripts only after the replacement rule
  explains which terrain and mechanism responsibilities remain useful.
- `StageController` owns queue progression and clear/failure decisions.
- `PaintSystem` keeps one authoritative owner-aware paint representation used
  for terrain visuals and coverage. Do not create a second authoritative mask.
- Human and future agent interfaces must receive the same gameplay facts.

## Acceptance Criteria

- A proposed MVP identifies one central planning question rather than combining
  unrelated complexity.
- It compares materially different queue and color-rule architectures before
  selection, including their clearability guarantees and authoring costs.
- It explains how existing terrain remains useful without making every stage
  depend on a custom queue.
- It separates user requirements, design assumptions, and tuning hypotheses.
- It includes a cheap feasibility-validation strategy before implementation.

## Non-Goals

- Implementing the earlier nine-ball roster, blue/orange colors, fixed
  per-stage queues, prevalidated queue variants, or universal paired bag.
- Deleting existing terrain or glyph systems during this analysis.
- Choosing numerical quotas, all thirty stage configurations, or production UI.

## Related

- `DECISIONS.md` preserves the superseded earlier selection.
- `OPEN_QUESTIONS.md` contains the current unresolved decisions.
- The ChatGPT Pro package starts at
  `../../docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/README.md`.
