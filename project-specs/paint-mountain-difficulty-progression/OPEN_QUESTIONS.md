---
type: evidence
status: active
created: 2026-08-13
topic: Shared Propellant calibration questions
scope: non-blocking implementation calibration
related:
  - PRD.md
  - DECISIONS.md
---

# Open Questions

## Purpose

Record bounded calibration questions. The product rule and ownership are closed.

## Sources

- `PRD.md`
- `RESEARCH.md`

## Findings

- Are the initial 90/82/75/68 allowances generous enough for current terrain?
  The implementation must answer with reachability and representative playtests.
- Is integer power the exact charged value when the UI displays a rounded
  percentage? Use the authoritative cannon value and expose the same integer to
  the HUD; do not create a second conversion formula.
- Where does the shortage reason fit best in the current Fire disabled-state
  contract? Decide through a focused rendered Level 1 UI check, without adding
  a new panel.

## Limitations

None of these questions authorizes a new mechanic or a lower budget. If a stage
is infeasible, increase the affected band or stage budget and record the reason.
