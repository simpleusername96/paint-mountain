---
type: evidence
status: active
created: 2026-08-13
topic: Paint Mountain difficulty calibration questions
scope: bounded questions that do not block implementation
related:
  - PRD.md
  - DECISIONS.md
---

# Open Questions

## Purpose

Record bounded calibration questions after the product decision. No blocking
product question remains.

## Sources

- `PRD.md`
- `research-context/exploration/02-comparison-and-selection.md`

## Findings

- **How much wider must a safe route be?** Initial contract: at least 4 m wider
  than its paired challenge route. The executor may increase this value after
  representative rendered and physics checks; decreasing it requires a PRD
  revision because it weakens the readability claim.
- **What makes the challenge route meaningfully different?** Initial contract:
  at least one extra mechanism slot or one extra grade reversal. If neither is
  legible in the running build, retune the authored layout; do not add an arrow
  or solution hint.
- **How is productive experimentation checked without telemetry?** Use the
  current local attempt and shot observations plus a fixed six-stage manual
  protocol. Do not persist an attempt history or infer a player model.
- **What if a contrast pair cannot hold secondary axes stable?** Keep the band
  and lesson roles, change the pair's declared primary/reference relation, and
  regenerate before promotion. Do not waive the typed comparison silently.

## Limitations

- The 4 m width and one-slot/reversal values are authoring thresholds, not
  empirical universal difficulty laws.
- A future multi-player balance study could revise tuning, but it is not a
  dependency for implementing or locally validating the selected structure.
