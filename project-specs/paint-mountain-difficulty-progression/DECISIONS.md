---
type: record
status: active
created: 2026-08-13
scope: Paint Mountain difficulty progression decisions
related:
  - PRD.md
  - RESEARCH.md
  - research-context/exploration/02-comparison-and-selection.md
---

# Difficulty Progression Decisions

## Context

The user requested broad hypothesis exploration, comparison, one final
direction, and an implementation plan. Four exploration rounds produced and
froze twelve candidates before evaluation.

## Decision

Select **C12, Contrastive Risk-Route Ladder**.

- Divide thirty stages into five six-stage focus bands.
- Repeat Anchor, Contrast A, Contrast B, Transfer, Interleave, and Fusion in
  every band.
- Require readable safe and high-leverage route opportunities in the eight
  advanced Interleave/Fusion stages.
- Replace scalar monotonicity as the product contract with typed challenge
  identity and comparisons derived from actual stage and route data.
- Lock the thirty stage briefs and fifteen comparison declarations in `PRD.md`;
  implementation may tune numeric geometry but may not redesign those
  relationships without revising the product decision.
- Add only a compact localized focus label to Stage Select. Do not change the
  gameplay HUD, result score, save schema, controls, physics, or mechanisms.

## Rationale

The selected direction scored highest against core fit, planning depth,
legibility, thirty-stage headroom, architectural fit, validation feasibility,
UI simplicity, and all-open compatibility. It combines the strongest sequence
candidate with the strongest in-stage decision candidate while reusing the
current route authoring pipeline.

## Consequences

- The active PRD and ExecPlan are decision-complete for implementation.
- Content work must preserve deterministic comparison and authoritative paint.
- A full adaptive system, optional contracts, mastery badges, and paint-driven
  physics remain outside scope.

## Alternatives

- C07, Contrastive Stage Curriculum: strong sequence, but no defined in-stage
  strategic tradeoff.
- C08, Risk-and-Bailout Route Setting: strong in-stage choice, but no coherent
  thirty-stage learning sequence.
- C02, Geometry and Mechanism Density: useful implementation lever, but opaque
  when many axes rise together.
- C01, Numeric Compression: cheap but shallow as the main strategy.
- C03, Preview Withholding: rejected by a hard source-brief requirement.
- C04/C09: defer secondary challenge and mastery layers until the base ladder
  is validated.
- C05: no calibrated item bank or reliable failure classifier exists.
- C06: too much UI and input friction for the core loop.
- C10: retain recovery as a content boundary, not the organizing system.
- C11: changes the core causal model and expands `PaintSystem` responsibility.
