---
type: evidence
status: active
created: 2026-08-20
scope: M7 container-owned responsive HUD, Stage Select, Settings, component interior, contrast, locale, and compact-window verification
related:
  - ../../execplans/2026-08-18-three-ball-target-band-prototype.md
  - ../../design/UIUX_GUIDELINES.md
  - ../2026-08-20-local-itch-stability-audit/README.md
---

# M7 responsive UI evidence — 2026-08-20

## Outcome

The gameplay HUD, Stage Select, and Settings now use safe-area anchors or
screen-owned responsive layout instead of 1280x720-only rectangles. Aim
controls have consistent label/decrement/value/increment geometry, Fire
readiness stays inside its component, and the shared context legend has a
Theme-owned backdrop and bounded priority behavior.

Accepted desktop captures retain all information. A physical window below
900 px wide or 500 px high is an explicit stress fallback: the gameplay HUD
keeps stage/score/queue/Fire bounded and suppresses the secondary AimControls
and context legend. Keyboard aim and Fire input remain available. Stage Select
keeps the selected card and Start visible while its card list scrolls; Settings
keeps its footer fixed and scrolls one content column.

## Automated checks

The following passed under Godot 4.7.1:

- `hud_layout_responsive_test.gd`: Korean/English at 1280x720, 1280x800,
  1366x768, 1600x900, 1920x1080, 1024x576, 1024x768, and 640x360; safe bounds,
  component minimums, focus, compact priority, and overlap contracts.
- `screen_responsive_layout_test.gd`: Korean/English Stage Select and Settings
  at 1280x720, 1024x576, 1024x768, 1920x1080, and 640x360; responsive columns,
  safe bounds, focus, and overflow ownership.
- Existing localization, essential-copy, stage-selection truth/readiness,
  shortcut, HUD-truth, Phase 7 UI flow/user-QA, first-Fire, and projectile
  ordinal regressions.
- `scripts/verify.ps1` after the final scene and script changes.

## Runtime renders reviewed

All PNGs were captured from a real Windows Compatibility/OpenGL 3.3 process on
Intel Iris Xe after `RenderingServer.frame_post_draw`. The implementing agent
reviewed every image at original resolution and compared the affected states
with the audit baseline.

| File | Review |
| --- | --- |
| `01-aiming-1280x720-ko.png` | Fire is centered; AimControls, queue, score, and legend are bounded and readable. |
| `02-aiming-1920x1080-en.png` | Wide accepted layout retains edge hierarchy and full English copy. |
| `03-map-1366x768-en.png` | Map controls and the high-contrast context legend remain distinct from the world. |
| `04-pause-1280x720-ko.png` | Pause panel, focus, and reused legend remain inside the safe area. |
| `05-briefing-1280x800-ko.png` | Briefing rule/actions and lower legend do not clip or cover the mountain route. |
| `06-result-1280x720-ko.png` | Result panel remains fully visible with all supported actions. |
| `07-aiming-640x360-ko.png` | Stress fallback keeps primary status, queue, and Fire bounded without overlap. |
| `08-stage-select-1280x720-ko.png` | Eight-card two-column balance and preview remain visible; no idle scrollbar. |
| `09-stage-select-640x360-en.png` | One-column card scroll and Start stay in bounds; selected-card copy is not clipped. |
| `10-settings-1280x720-en.png` | Two readable columns fit without an idle scrollbar; footer remains fixed. |
| `11-settings-640x360-ko.png` | One-column scroll owns overflow while Restore/Close remain visible. |
| `12-fire-readiness-1280x720-ko.png` | Long Korean disabled reason remains wholly inside ActionButtons above the centered Fire control. |

No capture output contained `ERROR`, `WARNING`, or `SCRIPT ERROR`. The final
captures show no child outside its container, fixed-size idle scrollbar,
overlap, debug overlay, or clipped primary action.

## Limits

This evidence closes the Windows runtime M7 visual gate. It does not claim Web
frame pacing, browser resize/fullscreen behavior, or deployed itch behavior;
those remain M8 and M9 gates in the active ExecPlan.
