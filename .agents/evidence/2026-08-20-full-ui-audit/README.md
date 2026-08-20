---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
topic: Current-run full-screen UI audit captures for the Korean Paint Mountain flow
scope: 1280x720 primary screens and 640x360 stress states from the canonical Windows release
source: ../../../builds/windows/PaintMountain.exe
---

# Full UI Audit Captures

## Purpose

This folder records a fresh, task-owned capture run from the canonical Windows
release. The primary sequence covers every reachable screen named by the design
contract, plus the Ball Queue detail interaction. Every primary image is the
complete 1280x720 game viewport. The final five images are complete 640x360
stress viewports for the densest layouts.

Run from the repository root:

```powershell
& '.agents/evidence/2026-08-20-full-ui-audit/recapture.ps1'
```

## Sources

- Executable: `builds/windows/PaintMountain.exe`
- Size: `121,982,464` bytes
- SHA-256: `A5E414B009D67CA0985AD6D1A3DBEABF3BE7EFE6B49F2E18A90F1845C673CB5C`
- Capture result: all 16 images were written at the requested full viewport;
  none was blank, loading, cropped to a sub-region, or from the wrong window.
- Process hygiene: no process using the captured executable remained after the
  batch completed.

## Findings

### Accepted primary sequence

| Step | State | Visual review |
| --- | --- | --- |
| 01 | Main Menu | Healthy baseline; clear primary action and world-first composition. |
| 02 | Stage Select | Healthy layout; rule shorthand and white terrain contrast need refinement. |
| 03 | Briefing | Needs refinement; the queue is too small and the lower-left cannon is visibly clipped. |
| 04 | Aiming | Healthy core composition; the complete vertical scale and cannon-centered controls are legible. |
| 05 | Ball Queue detail | Needs refinement; behavior text exists without a panel but is too small and visually detached from the active token. |
| 06 | Map Inspection | Healthy; the terrain remains primary and the mode state is visible. |
| 07 | Shot Follow | Needs refinement; the large return action blocks the observation area and competes with the projectile. |
| 08 | Pause | Functional but loose; the interruption surface is taller than its content and the background Gear remains visible. |
| 09 | Settings | Healthy at 1280x720; spacing and two-column grouping are clear. |
| 10 | Clear Result | Healthy; the mountain remains visible and the primary next action is clear. |
| 11 | Failure Result | Healthy signed-score truth; the Red/Green contribution text is too small. |

### Stress-state review

- `12`: Stage Select remains complete at 640x360, but the stage rule and best
  record shrink below comfortable reading size.
- `13`: Briefing has a real top-left overlap between stage identity, mode copy,
  score value, and the horizontal scale. This is the most important responsive
  defect found in the current run.
- `14`: Aiming reflows without clipping; the score ticks, queue, and status are
  nevertheless very small.
- `15`: Settings switches to a scrollable single-column presentation. The next
  group begins below the fold, so keyboard focus order and scroll-follow must be
  tested interactively before calling the state accessible.
- `16`: Failure Result remains complete, but tick labels, contributions, and
  secondary actions are too small for a durable compact preset.

## Limitations

These deterministic captures prove rendered composition and visible state only.
They do not prove keyboard traversal, hover timing, screen-reader naming,
contrast ratios, pointer target sizes, real player comprehension, or full-stage
physical balance. The result fixtures enter the real terminal transition and
then replace visible result values for deterministic layout evidence; they are
not physical clear witnesses.
