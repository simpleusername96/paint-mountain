---
type: evidence
status: active
created: 2026-08-10
topic: resident-activity HUD removal
scope: top-right runtime status row and preserved internal projectile state
source: ../../../docs/source-brief.md
related:
  - ../../../docs/test-checklist.md
  - release-aim-stage30-1280x720-ko.png
---

# Resident-Activity HUD Removal Evidence

## Purpose

Verify that resident-ball activity is no longer presented to the player while
the gameplay systems retain the internal state needed for rules and diagnostics.

## Sources

- The 2026-08-10 user supersession in `docs/source-brief.md`.
- The exported Windows Desktop build at the current task revision.
- Focused HUD, localization, HUD-truth, and user-QA contract tests.
- `scripts/verify.ps1` and the Windows release export.

## Findings

- `release-aim-stage30-1280x720-ko.png` is a Korean 1280x720 Stage 30 Aim View
  capture from the exported executable. The capture process exited with code 0
  and produced empty stderr.
- The top-right status row shows only time, remaining/maximum shots, and Finish;
  Settings remains the adjacent separate action.
- The resident-ball icon, moving/resting values, tooltip, and the space they
  occupied are absent. The compact row has no visible overlap or clipping.
- HUD state and gameplay-to-HUD wiring for resident activity are absent. The
  projectile manager's internal residency and motion accounting remains intact
  for gameplay rules, mechanisms, scoring, completion, and diagnostics.
- All focused tests, project verification, and the release export passed.

## Limitations

- This gate checks the player-facing removal and its direct contracts. It does
  not requalify unrelated gameplay systems or the repository-wide historical
  test baseline.
