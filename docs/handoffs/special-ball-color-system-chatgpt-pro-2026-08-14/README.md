---
type: handoff
status: active
created: 2026-08-14
topic: ChatGPT Pro analysis of special-ability balls, individual paint colors, queue feasibility, and terrain reuse
related:
  - ../../../project-specs/paint-mountain-difficulty-progression/PRD.md
  - ../../source-brief.md
---

# Special-Ability Ball and Individual-Color External Review Handoff

- Reviewer target: ChatGPT Pro
- Workspace: `D:\npjt\paint-mountain`
- Branch: `master`
- Review baseline: `377d71398fe526043ad0158328bbe0bac04abd2e`
- Package commit: the `master` commit that contains this file
- Dirty state: documentation-only changes during packaging; expected clean after commit
- Remote: `https://github.com/simpleusername96/paint-mountain`

## Current State

Paint Mountain currently ships a stationary-cannon physics puzzle with one
basic paintball, one scalar paint-coverage representation, thirty generated
terrains, and terrain glyph mechanisms. A proposed replacement based on nine
special balls, a four-position queue, blue/orange paint quotas, and complete
glyph removal was documented but never implemented. Subsequent discussion
changed the colors to red/green, required reuse of current terrain geometry,
required every queue to remain clearable, and rejected the authoring cost of
terrain-specific queue sets. A universal paired-bag fallback also did not feel
right. No queue algorithm, color interaction, roster, or MVP is approved now.

## Objective

Help select a coherent, low-authoring-cost MVP for special-ability balls and
individual paint colors. The answer must explain what planning decision the
system adds, how limited queue knowledge improves that decision, how red/green
paint affects clearing, how existing terrain remains useful, and how the game
guarantees feasible ball supply without a bespoke queue for every terrain.

## Reading Order

1. `idea-history.md`
2. `current-state.md`
3. `constraints-and-decisions.md`
4. `source-map.md`
5. `external-model-prompt.md`
6. `../../../project-specs/paint-mountain-difficulty-progression/PRD.md`

The seven images under `../../concepts/queued-ball-ui-2026-08-14/` are optional
historical evidence. They show the superseded blue/orange interpretation, not
an approved visual target.

## Requested Output

- Identify the central design problem before proposing mechanics.
- Compare at least four materially different system architectures.
- Recommend one small MVP only after the comparison.
- Define a clearability guarantee that does not require bespoke queues per stage.
- State what current terrain and glyph responsibilities to preserve, transform,
  or eventually remove.
- Label user requirements, assumptions, tuning hypotheses, and uncertainty.
- Separate product decisions from later implementation tasks.

## Next Steps

1. Give ChatGPT Pro the repository URL, branch, and `external-model-prompt.md`.
2. Save its response verbatim as `external-review-raw.md`.
3. Validate each recommendation against current code and project constraints.
4. Ask the user to select or revise the reconciled MVP before implementation.

## Risks

- The superseded ExecPlan is detailed enough to look approved. It is not.
- Red and green create an accessibility risk if hue is the only signal.
- Random queues can create impossible or unfair attempts; reroll can reduce the
  queue to repeated fishing instead of planning.
- Solvability claims based only on color counts ignore terrain reachability and
  special-ball behavior.
- Deleting glyph code before the replacement owns all responsibilities would
  break generated catalogs, stage hydration, observations, tests, and UI wiring.

## Do Not Do

- Do not implement, delete, or migrate files as part of the external review.
- Do not treat the nine-ball roster, exact four-slot preview, fixed queues,
  prevalidated queue variants, paired bag, reroll, or either color-clear rule as
  accepted.
- Do not replace the one authoritative `PaintSystem` representation with
  independent score masks.
- Do not propose in-flight steering or abandon the pre-shot planning puzzle.
- Do not turn the answer into generic game-design advice detached from the repo.
