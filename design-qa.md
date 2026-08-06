---
type: evidence
status: active
created: 2026-08-06
scope: Command Columns HUD same-state visual comparison and interaction review
related:
  - docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png
  - .agents/evidence/command-columns-hud-2026-08-06/exported-aim-lock-stage30-ko-1280x720.png
  - .agents/evidence/command-columns-hud-2026-08-06/map-inspection-stage30-ko-1280x720.png
  - .agents/evidence/command-columns-hud-2026-08-06/main-menu-ko-1280x720.png
  - .agents/execplans/2026-08-06-command-columns-hud.md
---

# Command Columns HUD Design QA

## Review Contract

- UI/UX Gate invocation: Level 4, because this changes shared UI styling and the
  complete in-game aiming HUD composition.
- Visual source of truth:
  `docs/concepts/ui-layout-directions-2026-08-06/command-columns-hud.png`.
- Implementation capture:
  `.agents/evidence/command-columns-hud-2026-08-06/exported-aim-lock-stage30-ko-1280x720.png`.
- Viewport: 1280x720 source and implementation, native 1:1 pixels, without crop
  or scaling. Device scale factor is not applicable to the native Godot capture.
- Compared state: Korean, Stage 30, Aim Lock, before launch, 03:00 remaining,
  seven shots, 0.0% coverage, 15% target, upward wind at 99% strength.
- Review method: the full source and full running-game capture were supplied in
  one comparison input. All HUD text, icons, borders, focus states, and the open
  world center were readable at original resolution, so a separate cropped
  comparison was not needed.

## Fidelity Review

| Surface | Result | Evidence |
| --- | --- | --- |
| Typography | Passed | Pretendard is applied through shared 500, 600, and 700 weight roles. Captions, section labels, values, metrics, and the primary action follow the specified hierarchy without clipping. |
| Layout and spacing | Passed | The upper-left joined command card, vertical coverage rail, lower-left aim group, centered Fire action, and narrow segmented right rail reproduce the reference hierarchy while keeping the cannon and trajectory area unobstructed. |
| Color and surface treatment | Passed | Shared navy text, blue action/accent color, warm white panels, restrained borders, radii, separators, focus, disabled treatment, and progress styling replace scene-local presentation values. |
| Images and icons | Passed | Existing approved project icons are used for Gear and mode. The live Compatibility renderer supplies the world image; no placeholder or newly invented production asset was added. |
| Copy and runtime truth | Passed | Stage, mode, absolute coverage and target, aim values, time, shots, resident activity, wind, forecast, Fire, and Finish remain connected to their existing runtime owners. |

## Intentional Product Constraints

These are accepted differences from the generated concept, not fidelity defects:

- The implementation uses a 24 px safe edge instead of the concept's roughly
  14 px edge so focus borders and controls do not touch the viewport boundary.
- Gear remains a separate focusable action beside the right rail because it is
  a supported product action that the generated concept simplified.
- Yaw, elevation, power, and both power-step controls remain visible and
  operable. The concept did not show the complete current input contract.
- The interaction mode uses the closest existing target asset instead of a new
  generated crosshair asset, because this task did not approve new production
  assets.
- Dynamic wind direction retains the runtime Unicode arrow and pairs it with
  direction text and tooltips. Wind meaning therefore does not depend on color
  alone.

## State and Cross-Surface Regression Review

- Map Inspection:
  `.agents/evidence/command-columns-hud-2026-08-06/map-inspection-stage30-ko-1280x720.png`.
  The mode control remains visible and focused while aim-only controls and Fire
  are hidden. The very wide world view in this state predates this HUD task and
  is outside its camera-free scope.
- Main menu:
  `.agents/evidence/command-columns-hud-2026-08-06/main-menu-ko-1280x720.png`.
  Shared primary-button typography inherits without clipping or changing the
  menu layout.
- Accessibility and input: visible focus treatment remains; actionable controls
  are at least 40 px high; Finish has a distinct disabled state; the icon-only
  Gear action retains its accessible name and tooltip; wind has text in addition
  to color.

## Findings and Iteration History

| Severity | Count | Disposition |
| --- | ---: | --- |
| P0 | 0 | No blocking workflow or crash defect found. |
| P1 | 0 | No major hierarchy, overlap, clipping, or missing-function defect found. |
| P2 | 0 | No visible mismatch requiring another design-QA iteration found. |
| P3 | 0 | No optional polish item recorded. |

Before the formal comparison, implementation review corrected the right-rail
height, activity-line wrapping, icon margin, and target copy. The first formal
same-input comparison used the final stable capture; no P0, P1, or P2 finding
remained, so no design-QA fix iteration was required.

final result: passed
