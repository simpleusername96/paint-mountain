---
type: evidence
status: active
created: 2026-08-21
last_reviewed: 2026-08-21
topic: User-reported icon alignment and tall-window UI correction
scope: 713x1026 and 1280x720 Windows release renders, focused responsive contracts, full regression, verification, and export
source: ../../../builds/windows/PaintMountain.exe
related:
  - ../../execplans/2026-08-21-ui-layout-and-stage-browsing-polish.md
  - ../2026-08-21-ui-layout-stage-browsing/README.md
---

# Responsive UI Correction Evidence

The user's four screenshots disproved the earlier claim that shared icons and
responsive Result composition were complete. The existing release was first
reproduced at 713x1026, then the same Main Menu, Aim, and target-band Failure
states were captured from the corrected Windows release. The 1280x720 Aim and
Failure states guard the approved desktop composition.

- Implementation commit: `3d651c9` (`fix: correct icon and tall-window layout`)

## Corrected behavior

- `ActionControl`, `ValueStepper`, and the top Settings button now center icon
  content inside the actual Godot `Button`, in addition to normalizing source
  alpha bounds. In the final Main Menu render, the Play alpha bounds are within
  0.5 rendered px of the blue control center; the Fire splat is centered.
- Main Menu rows take their height from the configured primary or routine
  `ActionControl` edge. Play no longer overflows a routine-height row, and the
  visible action bounds retain at least 12 logical px between rows.
- Compact Result uses a right-aligned spine instead of the full safe viewport.
  At 713x1026 it leaves the opposite world side visible, keeps the complete
  horizontal 0-100 axis and actions, and stays below the 54% width and 66%
  height guards.
- Responsive tests now include 713x1026 and 768x1024 in Korean and English.

## Production images

Before correction:

- [`before/main_menu-713x1026.png`](before/main_menu-713x1026.png)
- [`before/aiming-713x1026.png`](before/aiming-713x1026.png)
- [`before/target_failed_result-713x1026.png`](before/target_failed_result-713x1026.png)

Corrected Windows release:

- [`production/main_menu-713x1026.png`](production/main_menu-713x1026.png)
- [`production/aiming-713x1026.png`](production/aiming-713x1026.png)
- [`production/target_failed_result-713x1026.png`](production/target_failed_result-713x1026.png)
- [`production/aiming-1280x720.png`](production/aiming-1280x720.png)
- [`production/target_failed_result-1280x720.png`](production/target_failed_result-1280x720.png)

The final executable SHA-256 is
`98581A86A89443F82BFC382ED9514CC3508A0402141C567D867386F50663C695`.

## Validation

- Focused shared-component, screen-responsive, HUD-responsive, essential-copy,
  and localization tests pass.
- `scripts/test.ps1` passes the complete ordered suite.
- `scripts/verify.ps1` passes import, parse, and main-scene startup.
- Windows release export and all five final production captures exit zero.
- The UIUX Gate Level 4 render review found no task-owned clipping, overlap,
  off-center action glyph, or full-screen Result sheet in the named states.
- The diff-scoped quality audit found no competing shared-UI owner, contract
  break, or reachable failure path. `ActionControl` still owns action geometry;
  `HudRootLayout` still owns screen placement.

## Evidence boundary

These captures prove the named static production states at 713x1026 and
1280x720. They do not prove every arbitrary window size or subjective input
feel. Stage-browsing timing was not rerun because this correction does not
change its preparation, worker, preview, or selection owners; the prior timing
receipt remains current for those unchanged inputs.
