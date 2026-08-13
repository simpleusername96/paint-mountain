---
type: record
status: active
created: 2026-08-13
scope: candidate comparison and provisional product selection
related:
  - 01-candidate-ledger.md
  - ../../PRD.md
  - ../../DECISIONS.md
---

# Candidate Comparison and Selection

## Context

The twelve-candidate ledger was frozen before evaluation. The effective source
brief and local architecture define hard gates. Passing candidates were then
scored against the same weighted criteria.

## Evaluation Method

Raw scores use a 1-5 scale. The weighted result is reported on the same 1-5
scale.

| Criterion | Weight | High score means |
| --- | ---: | --- |
| Core contract fit | 20 | Preserves fixed-cannon deterministic planning, authoritative paint, and no in-flight steering |
| Planning depth | 20 | Creates meaningful hypothesis and route decisions, not only tighter execution |
| Legibility and fair failure | 15 | Added challenge is visible before launch and diagnosable after impact |
| Thirty-stage headroom | 15 | Supports distinct early, middle, and late stages without exhausting the idea |
| Architectural fit | 10 | Reuses current typed Resources, route profiles, offline generation, and owners |
| Validation and calibration | 10 | Has observable structural and playtest checks without a large telemetry system |
| UI and operating simplicity | 5 | Keeps the normal HUD quiet and adds little workflow cost |
| All-open compatibility | 5 | Works when the player may choose any stage |

Hard gates are evaluated first. A hard-gate failure makes a candidate
ineligible regardless of its numeric score.

## Comparison

| ID | Candidate | Gate | Core | Depth | Legible | Headroom | Arch. | Validate | UI | Open | Weighted |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| C01 | Numeric Compression Ladder | Pass | 5 | 2 | 4 | 3 | 5 | 4 | 5 | 5 | 3.85 |
| C02 | Geometry and Mechanism Density | Pass | 5 | 4 | 3 | 5 | 5 | 3 | 4 | 5 | 4.25 |
| C03 | Preview Withholding | **Fail** | 1 | 2 | 1 | 3 | 5 | 4 | 5 | 5 | 2.60 |
| C04 | Self-Selected Challenge Contracts | Pass | 4 | 4 | 4 | 4 | 3 | 4 | 3 | 5 | 3.90 |
| C05 | Adaptive Stage Coach | Pass | 4 | 4 | 2 | 4 | 2 | 1 | 2 | 4 | 3.10 |
| C06 | Outcome-Prediction Ritual | Pass | 5 | 4 | 4 | 3 | 2 | 3 | 1 | 5 | 3.65 |
| C07 | Contrastive Stage Curriculum | Pass | 5 | 5 | 4 | 5 | 4 | 4 | 4 | 5 | 4.60 |
| C08 | Risk-and-Bailout Route Setting | Pass | 5 | 5 | 5 | 5 | 5 | 3 | 4 | 5 | 4.75 |
| C09 | Proficiency Badges | Pass | 4 | 3 | 4 | 4 | 3 | 2 | 2 | 5 | 3.45 |
| C10 | Recovery-First Resilience | Pass | 5 | 4 | 4 | 4 | 4 | 3 | 5 | 5 | 4.20 |
| C11 | Paint-Modified Physics | Pass | 2 | 5 | 1 | 4 | 2 | 2 | 2 | 5 | 2.90 |
| C12 | Contrastive Risk-Route Ladder | Pass | 5 | 5 | 5 | 5 | 5 | 4 | 4 | 5 | **4.85** |

## Decision

Select **C12, Contrastive Risk-Route Ladder**, for the product specification and
execution contract.

The selected system divides the thirty stages into five bands of six. Every
band uses the same sequence:

1. **Anchor** — establish the band's planning invariant in a forgiving layout.
2. **Contrast A** — change one primary difficulty axis while bounding secondary
   changes.
3. **Contrast B** — expose the opposite route tradeoff or a second value of the
   same axis.
4. **Transfer** — require the invariant on a different route shape.
5. **Interleave** — combine it with one earlier-band demand.
6. **Fusion** — combine the band's demands in one readable, recoverable stage.

From Band 2 onward, advanced stages expose at least one broad, lower-yield
route opportunity and one narrower, mechanism-rich, higher-yield route
opportunity when the generated geometry can support both legibly. These are
opportunities, not prescribed solutions or solver-certified clear routes.

## Rationale

- C07 supplies a strong learning sequence but does not by itself define what
  the player decides inside a stage.
- C08 supplies a strong in-stage decision but does not prevent thirty stages
  from becoming an unordered collection of route puzzles.
- C12 integrates both at the content-authoring layer. It uses existing route
  roles and deterministic generation, so it adds planning depth without a new
  runtime rule.
- C12 also retains C10's main lesson: a hard stage may offer recovery, but
  recovery remains geometry, not an assistance system.

## Consequences

- The scalar difficulty score stops being the product definition of difficulty.
  It may remain temporarily for diagnostics, but acceptance moves to a typed
  challenge identity and measurable difficulty vector.
- Existing target, shot, and time tiers remain guardrails. They do not need to
  increase on every stage, and they cannot be the only contrast in a pair.
- Stage geometry becomes the main explanation surface. Stage Select adds only
  one localized focus label; gameplay HUD and result scoring stay unchanged.
- The catalog must be regenerated and versioned because the route profiles and
  baked layouts change.

## Alternatives

- C01 is cheap but shallow as a sole strategy.
- C02 remains a useful content lever but lacks an instructional structure.
- C03 violates a hard product requirement.
- C04 and C09 create secondary challenge/progression layers before the base
  thirty-stage curve is proven.
- C05 lacks the calibrated evidence needed for fair adaptation.
- C06 adds a high-friction UI ritual.
- C10 is retained as a content boundary, not the organizing system.
- C11 changes the core causal model and gives `PaintSystem` a risky new
  responsibility.

## Predetermined Fallback

If running-game prototypes cannot make the safe/high-yield contrast readable,
keep the five-band six-role sequence, relax that stage's dual-route
requirement, and tune the primary structural axis. Do not add route arrows,
solution hints, hidden assists, or a runtime solver to rescue an unreadable
layout.

## Limitations

- The score organizes the decision; it is not empirical proof of fun.
- Final route widths, mechanism positions, and coverage targets require
  deterministic generation checks and representative human playtests.
