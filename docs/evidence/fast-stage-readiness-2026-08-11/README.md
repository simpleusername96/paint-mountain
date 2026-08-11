---
type: evidence
status: active
created: 2026-08-11
topic: stage readiness performance
source: builds/windows/PaintMountain.exe
related:
  - ../../../.agents/execplans/2026-08-11-fast-stage-readiness.md
  - ../../test-checklist.md
---

# Fast Stage Readiness Evidence

## Purpose

Verify that the canonical Windows release shortens the truthful stage-loading
boundary without changing terrain, collision, paint, camera, or stage rules.
The measured interval starts at `app_root_ready` and ends at
`gameplay_prepared`, immediately before Gameplay becomes visible and enabled.

## Sources

- Godot 4.7.1 Compatibility release:
  `builds/windows/PaintMountain.exe`
- Three independent delivery-telemetry logs for each of Stage 01 and Stage 30:
  `stage_01-run1.log` through `stage_01-run3.log`, and `stage_30-run1.log`
  through `stage_30-run3.log`
- Settled Korean 1280x720 running-game captures and their telemetry:
  `stage_01-briefing-1280x720.png`, `stage_30-briefing-1280x720.png`,
  `stage_01-visual.log`, and `stage_30-visual.log`
- Repository verification: focused preparer/entry/warm-up/UI/localization tests,
  `scripts/verify.ps1`, and the complete ordered `scripts/test.ps1` suite

## Findings

| Stage | Run 1 | Run 2 | Run 3 | Median readiness | Largest artifact slice |
| --- | ---: | ---: | ---: | ---: | ---: |
| Stage 01 | 615.258 ms | 527.232 ms | 623.006 ms | 615.258 ms | 7.497 ms |
| Stage 30 | 779.513 ms | 796.946 ms | 851.981 ms | 796.946 ms | 13.312 ms |

- Both medians pass the 700/900 ms release budgets. The largest cooperative
  artifact slice passes the 16 ms ceiling.
- Compared with the fresh pre-change 858/1,154 ms medians, readiness improved
  by about 28% on Stage 01 and 31% on Stage 30.
- The final release and all retained capture runs exited with code 0 and empty
  stderr. Both briefing captures were inspected at native size. Terrain,
  ground, sky, mechanisms, Korean copy, button labels, focus treatment, and
  framing are complete with no clipping or debug overlay.
- The fastrun registry still launches
  `& '.\builds\windows\PaintMountain.exe'`. The rebuilt executable SHA-256 is
  `512186CBAA6E08DD16CB092A5BFA68764E454063A5D5CF790C99BA731903078F`.
- No itch.io upload or visibility setting was changed.
