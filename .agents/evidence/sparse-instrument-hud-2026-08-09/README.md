---
type: evidence
status: active
created: 2026-08-09
scope: sparse gameplay instruments, immediate terrain aiming, and display-setting stability
related:
  - ../../execplans/2026-08-08-instant-approximate-landing-feedback.md
  - ../../../docs/source-brief.md
  - ../../../docs/test-checklist.md
---

# Sparse Instrument HUD and Immediate Aim Evidence

## Visual direction

- ImageGen mode: edit.
- Inputs: the implemented Stage 30 Aim View and the approved mountain-first
  hierarchy comparator.
- Final prompt intent: preserve the game world, remove tall side and bottom
  cards, use a top icon/number status row, a thin coverage rail, integrated
  A/D, W/S, wheel, Space, Tab, F, and Escape hints, and no persistent prose.
- Output: `imagegen-target-reference.png`.
- Independent AGY review: `agy-review.md`. Its useful findings were the large
  right-card obstruction, fixed-offset bunching, display reapplication in
  Settings, sparse top-row hierarchy, and height-normalized glyph preference.

## Running-game inspection

- `runtime-aim-1280x720-ko.png`
- `runtime-aim-1920x1080-en.png`
- `runtime-settings-1280x720-ko.png`
- `release-aim-1280x720-ko.png`
- `release-aim-1920x1080-en.png`

The source captures and the two final Windows release captures use the
Compatibility renderer and the actual baked Stage 30 gameplay scene. Both
release processes exited 0 with empty stderr. Direct inspection found:

- the mountain is no longer covered by left/right status cards or a bottom aim
  panel;
- the normal-play prose strip is absent;
- top status, left coverage, centered Fire, and lower-right aim instruments stay
  inside both supported viewports;
- shortcut keycaps are attached to their controlled value/action;
- the first pass exposed a Fire/Space overlap, which was corrected by moving the
  keycap above the Fire button;
- glyphs remain low in these images because they use the pre-change baked
  catalog. The catalog rebuild is a separate active acceptance item.

## Focused runtime facts

- The original synchronous pure inverse pass measured 191,392 microseconds.
- Caching the wind horizon and nominating every eight fixed steps reduced the
  focused deterministic solve below one 60 Hz frame (2,495 microseconds in the
  final focused run; earlier post-change runs measured 6,263 to 7,820).
- Terrain click/drag, target-preserving angle/power edits, immediate Fire
  readiness, and Map View input separation pass in `aim_interaction_test.gd`.
- Passive settings synchronization and non-display setting application leave
  the display mutation count unchanged in `localization_ui_test.gd`.
- Preferred middle/upper-middle glyph ranking passes in
  `mechanism_placement_test.gd`.

Godot 4.7.1 import/startup verification and the Windows release export passed.
This evidence remains active only until the complete baked catalog is rebuilt,
promoted, validated, and inspected in representative running stages.
