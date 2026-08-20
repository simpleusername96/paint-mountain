---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: signed Paint Score continuity through the shared live and Result UI
related:
  - ../../execplans/2026-08-20-cross-stage-ui-theme.md
  - ../../design/UIUX_GUIDELINES.md
  - ../../../docs/test-checklist.md
---

# Signed Paint Score correction evidence

## Purpose

Prove that subtractive target-band stages display the same signed Paint Score
used by `StageController`, while the approved shared score rail remains fixed
to 0-100 in both live and Result orientations.

## Sources

- `StageScoreSnapshot` and `ColorScoreRuleData` remain the calculation owners.
- `ScoreScale`, `HUDController`, and `ResultPanel` are the affected presentation
  owners.
- Stage 08 supplies `Green Add / Red Subtract`; the capture fixture uses the
  real rule with Red 4.0% and Green 1.0%, producing Paint Score `-3.0`.
- `recapture.ps1` runs the current Windows release in hidden task-owned
  processes and rejects non-zero exits or empty images.

## Findings

- The original UI had two independent truth failures: `ScoreScale` and Result
  clamped negative numeric score to zero, and the legacy total-coverage signal
  could overwrite live target-band score after the signed score publication.
- The corrected shared component retains the supplied signed value for visible
  and accessibility copy. Its marker alone projects to the nearest point on the
  fixed 0-100 rail.
- A filled directional triangle at the endpoint communicates underflow by shape
  as well as the signed number. No panel, card, explanatory text block, second
  scale, or screen-local style owner was added.
- Result receives the unchanged signed score. Verdict, stars, target band, R/G
  contributions, actions, and `StageController` clear/failure decisions remain
  unchanged.

## Running-release evidence

All captures were generated from the final task-owned Godot 4.7.1 Windows
release and inspected individually at original resolution.

| Capture | Verified result |
| --- | --- |
| [01-negative-score-stage08-ko-1280x720.png](01-negative-score-stage08-ko-1280x720.png) | Live Aim shows `-3.0`, the complete vertical 100-0 rail, zero-endpoint underflow triangle, target band, and `R -4.0 / G +1.0` without clipping. |
| [02-negative-result-stage08-ko-1280x720.png](02-negative-result-stage08-ko-1280x720.png) | Failed Result shows `-3.0`; the horizontal rail keeps 0-100, target band, left-endpoint underflow triangle, contributions, and actions visible. |
| [03-negative-score-stage08-ko-640x360.png](03-negative-score-stage08-ko-640x360.png) | Compact Aim retains the signed value, full rail, underflow shape, contributions, queue, status, and aim controls inside 640x360. |

Final canonical Windows release: 121,982,464 bytes; SHA-256
`A5E414B009D67CA0985AD6D1A3DBEABF3BE7EFE6B49F2E18A90F1845C673CB5C`.
The task-named check export used for the last capture batch had the identical
size and SHA-256 before the canonical path became available again.

## Verification

- Signed formula, score snapshot, shared scale, HUD, Result, target-band layout,
  responsive HUD, cross-stage presentation, and shot-feedback focused tests
  pass.
- The complete ordered `scripts/test.ps1` suite and `scripts/verify.ps1` import,
  parse, and startup checks pass with Godot 4.7.1. The diff-scoped shared-UI
  quality audit found no competing calculation, result, or presentation owner.
- The first release-render batch exposed the legacy coverage overwrite because
  R/G contributions changed while the large value returned to zero. The signal
  guard was then added, its focused regression passed, and only the invalidated
  release and three captures were regenerated.
- The public itch artifact was not changed. The existing active ExecPlan's
  separate final-v11 built-Web journey remains open.

## Limitations

- The capture states are delivery presentation fixtures. They use the real
  Stage 08 score rule and real production UI/result paths, but do not claim that
  the exact Red/Green percentages came from a human-played physical shot.
