---
type: evidence
status: active
created: 2026-08-20
last_reviewed: 2026-08-20
scope: current production-render proof for the player-reported Cannon Focus HUD regressions
related:
  - ../../execplans/2026-08-20-cross-stage-ui-theme.md
  - ../../../docs/reports/ui-refinement-2026-08-20/index.html
---

# Cannon Focus HUD capture-regression evidence

This evidence supersedes the earlier positive visual judgment for the affected
Aim, Map, and Ball Queue states. The user's running-game captures showed a
duplicate native/custom ball message, white queue cards, loose bottom controls,
an isolated left-side mode switch, a short score rail, and redundant icons.

## Final correction

- `BallQueue` is one direct upper-right overlay. Its normal tokens have no
  cards, R/G and ball-kind glyphs have explicit spacing, and hover/focus/press
  use one shared description label. Native tooltip text is empty while full
  accessibility copy remains.
- The fixed vertical score domain is still 0-100. The standard live rail is
  330 px tall and 24 px wide inside a 132x410 shared component; all five ticks,
  the target band, current marker, and signed R/G values remain bounded. The
  redundant vertical target icon is hidden.
- The icon-only Aim/Map action now joins the top-right status row and exposes
  localized tooltip/accessibility copy. Its pressed style follows the
  authoritative camera interaction mode.
- The bottom Aim sequence is `minus / value / plus -> Fire -> minus / value /
  plus`. Floating angle/power captions are visually hidden but remain as
  accessible component names. Shared Theme roles own world contrast.

## Current production captures

All images were generated from the final Windows release through the existing
background `DeliveryCaptureRunner`, checked as non-empty, and visually inspected
at original resolution.

| Capture | Proof |
| --- | --- |
| [01-aiming-stage08-ko-1280x720.png](01-aiming-stage08-ko-1280x720.png) | Tall 0-100 rail, compact top-right queue/action group, and one aligned bottom sequence |
| [02-queue-description-stage08-ko-1280x720.png](02-queue-description-stage08-ko-1280x720.png) | One direct queue description; no native dark tooltip, white queue card, or panel |
| [03-map-stage08-ko-1280x720.png](03-map-stage08-ko-1280x720.png) | Selected top-right map action and no isolated left-side switch |
| [04-aiming-stage01-ko-640x360.png](04-aiming-stage01-ko-640x360.png) | Compact stress layout remains inside 640x360 without overlap or clipping |

Reproduce with `recapture.ps1` from the repository root after a current Windows
release export. The script starts hidden task-owned processes and waits for each
one to exit. No `PaintMountain` process remained after the final run.

## Automated and artifact evidence

- The focused queue, score-scale, localization, ownership, responsive HUD,
  essential-copy, shortcut, cross-stage, and shot-feedback checks pass.
- The complete ordered `scripts/test.ps1` suite and `scripts/verify.ps1` pass.
  The expected invalid-geometry warning in `projectile_settling_test.gd` remains
  a passing recovery fixture, not a production suppression.
- Windows release: 121,978,896 bytes; SHA-256
  `585C0E337B4D7528C1DFE60B59ED599AF1209D151FED3AA862818C3B6A157FEE`.
- Web release: 12 files, 51,809,492 raw bytes and 18,485,674 gzip bytes against
  the 18,996,696-byte allowance. `index.pck` is 11,958,928 bytes with SHA-256
  `E09CEBC1D46EC9C9CA47133EA4323B50F7BD114A4EBCA067979CCEEE25982006`.
- The public itch release was not changed. The final-v11 live built-Web journey
  remains the separate open ExecPlan 8.3 item because the available browser
  bridge is not trusted; no browser claim is inferred from Windows pixels.
