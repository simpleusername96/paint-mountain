---
type: handoff
status: active
created: 2026-08-14
topic: paste-ready ChatGPT Pro review request
related:
  - README.md
  - idea-history.md
  - current-state.md
  - constraints-and-decisions.md
  - source-map.md
---

# ChatGPT Pro Prompt

## Current State

The following prompt requests product analysis only. The local game still uses
one basic paintball and terrain glyph mechanisms. Detailed queued-ball documents
and blue/orange UI images are superseded historical evidence, not approved work.

## Paste-Ready Prompt

I want you to analyze a not-yet-approved gameplay direction for Paint Mountain.
You are an external design reviewer, not the source of truth, and you must not
implement or delete anything.

Repository:
- Remote: https://github.com/simpleusername96/paint-mountain
- Branch: master
- Handoff folder: docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14

Paint Mountain is a Godot 4.x desktop/browser 3D physics puzzle. A stationary
cannon launches paintballs across a distant mountain. Before firing, the player
chooses yaw, elevation, and power. The player never steers a projectile in
flight. Balls continuously paint target surfaces while traversing them in
contact.

The open direction combines three ideas:
1. Balls can have intrinsic abilities. User examples are contact explosion,
   splitting in N directions at the apex, and extreme rebound that requires a
   good high-angle landing on flat ground.
2. Balls arrive through a Tetris-like limited-preview queue. Near-future balls
   are known and a later tail is hidden.
3. Balls may carry individual red or green paint. The exact overlap and clear
   rule is unresolved.

The current terrain should be reused where useful. Any fixed or generated ball
supply must permit the stage clear condition. The user rejected maintaining
custom queue variants for every terrain as too expensive. A later universal bag
with two red/green Standard pairs plus one red/green special pair also did not
feel right. Do not assume fixed queues, random queues, reroll, a nine-ball
roster, four preview slots, per-color quotas, latest-writer overwrite, color
cancellation, or complete glyph deletion is already selected.

Read these files in order:
1. docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/idea-history.md
2. docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/current-state.md
3. docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/constraints-and-decisions.md
4. docs/handoffs/special-ball-color-system-chatgpt-pro-2026-08-14/source-map.md
5. project-specs/paint-mountain-difficulty-progression/PRD.md
6. docs/source-brief.md, especially the 2026-08-13 and 2026-08-14 revisions

Please answer in this structure:
1. Problem restatement: identify the single central planning problem this system
   should create and any contradictions in the request.
2. Design principles: 4-7 criteria derived specifically from this game.
3. Alternative architectures: at least four materially different complete
   systems. For each, define queue information, generation, Retry/reroll,
   special-ball role, red/green interaction, clear rule, terrain reuse, and the
   clearability guarantee.
4. Comparison matrix: score planning depth, hidden-luck risk, authoring cost,
   automated validation cost, terrain reuse, UI burden, accessibility, and
   engineering risk. Explain the important scores.
5. Recommendation: select one only if it is clearly stronger. Explain why the
   rejected per-stage queue pools and universal paired bag failed, and how your
   recommendation avoids the same failures.
6. Smallest MVP: no more than four ball behaviors and a small set of stages.
   State the exact player loop, visible information, color rule, fail/clear
   rule, and what evidence would invalidate the concept.
7. Feasibility method: give a concrete low-authoring-cost way to guarantee or
   conservatively validate that a queue can meet the clear condition. Separate
   color-supply feasibility from geometric/physics reachability. Pseudocode is
   welcome, but do not pretend a heuristic is a proof.
8. Terrain and glyph migration: list what to preserve, repurpose, defer, or
   eventually remove. Do not recommend deleting the current implementation
   before replacement responsibilities are understood.
9. Open questions: ask only choices whose answers would materially change the
   MVP.

Label each statement as a user requirement, local fact, design assumption, or
tuning hypothesis when its status could be confused. Call out uncertainty. Use
repository evidence and concrete examples instead of generic game-design advice.
Red and green must never be distinguished by hue alone. Preserve StageController
as the stage-rule owner and PaintSystem as the one authoritative paint
representation. Do not add in-flight steering, external dependencies, services,
or a second coverage mask.

## Next Steps

- Paste the external response verbatim into `external-review-raw.md`.
- Validate its claims against the files in `source-map.md`.
- Promote nothing into an active spec or ExecPlan until the user approves it.

## Risks

- An answer that only balances color counts will miss geometric reachability.
- An answer that uses a full solver may replace authoring work with excessive
  validation cost.
- An answer that adds more mechanics without a central planning question will
  repeat the failure of the earlier detailed plan.
